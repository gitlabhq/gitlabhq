/*
 * pg_ash: Active Session History for Postgres
 * Version: 2.0 beta 1
 * Fresh install: \i sql/ash-install.sql
 * Upgrade from 1.0: \i sql/migrations/ash-1.0-to-1.1.sql, then \i sql/migrations/ash-1.1-to-1.2.sql, then \i sql/migrations/ash-1.2-to-1.3.sql, then \i sql/migrations/ash-1.3-to-1.4.sql, then \i sql/migrations/ash-1.4-to-1.5.sql, then \i sql/migrations/ash-1.5-to-2.0.sql
 * Upgrade from 1.1: \i sql/migrations/ash-1.1-to-1.2.sql, then \i sql/migrations/ash-1.2-to-1.3.sql, then \i sql/migrations/ash-1.3-to-1.4.sql, then \i sql/migrations/ash-1.4-to-1.5.sql, then \i sql/migrations/ash-1.5-to-2.0.sql
 * Upgrade from 1.2: \i sql/migrations/ash-1.2-to-1.3.sql, then \i sql/migrations/ash-1.3-to-1.4.sql, then \i sql/migrations/ash-1.4-to-1.5.sql, then \i sql/migrations/ash-1.5-to-2.0.sql
 * Upgrade from 1.3: \i sql/migrations/ash-1.3-to-1.4.sql, then \i sql/migrations/ash-1.4-to-1.5.sql, then \i sql/migrations/ash-1.5-to-2.0.sql
 * Upgrade from 1.4: \i sql/migrations/ash-1.4-to-1.5.sql, then \i sql/migrations/ash-1.5-to-2.0.sql
 * Upgrade from 1.5: \i sql/migrations/ash-1.5-to-2.0.sql
 *
 * Transaction behavior: this entrypoint disables ON_ERROR_ROLLBACK, enables
 * ON_ERROR_STOP, and owns its transaction. ON_ERROR_ROLLBACK would reduce
 * statement failures to savepoint rollbacks and permit a partial install to
 * be committed. When invoked with \i inside an existing transaction, the
 * final COMMIT also commits the caller's outer work.
 */

\set ON_ERROR_ROLLBACK off
\set ON_ERROR_STOP on
begin;

/*
 * Preserve function EXECUTE grants across the drop/recreate below (#107).
 * DROP FUNCTION destroys ACLs that CREATE OR REPLACE would keep, so a
 * monitoring role configured via ash.grant_reader() (or a manual GRANT)
 * would silently lose access on every upgrade or installer re-apply.
 * Snapshot every explicit non-owner EXECUTE grant on ash.* functions into
 * a temp table now; the matching block at the very end of this script
 * re-applies them to the recreated functions and drops the snapshot. The
 * argument signature is captured alongside the name so the restore can put
 * the grant back on the exact same overload and never widen a role that
 * held only one overload of a function.
 * PUBLIC (grantee oid 0, which has no pg_roles row) is intentionally
 * excluded: the hardening block below re-applies the REVOKE-from-PUBLIC
 * posture on every install.
 */
do $$
begin
  drop table if exists pg_temp._ash_install_func_acl;
  create temp table _ash_install_func_acl (
    proname   name not null,
    args      text not null,
    grantee   name not null,
    grantable bool not null
  );
  insert into pg_temp._ash_install_func_acl (proname, args, grantee, grantable)
  select distinct
    proc.proname,
    pg_catalog.pg_get_function_identity_arguments(proc.oid),
    grantee_role.rolname,
    acl.is_grantable
  from pg_proc as proc
  join pg_namespace as nsp on proc.pronamespace = nsp.oid
  cross join lateral aclexplode(proc.proacl) as acl
  join pg_roles as grantee_role on grantee_role.oid = acl.grantee
  where nsp.nspname = 'ash'
    and proc.prokind in ('f', 'a')
    and acl.privilege_type = 'EXECUTE'
    and acl.grantee <> proc.proowner;

  /*
   * Reader-role detection. The exact-signature restore at the end of this
   * script can only replay grants on functions that existed BEFORE the
   * upgrade, so a reader role would be left without EXECUTE on helpers
   * introduced by THIS version (e.g. 2.0's _pgss_query_text and the
   * retention helpers) and every reader call would then die mid-function.
   * A role that held EXECUTE on the full pre-upgrade reader bundle (every
   * non-admin ash.* function — exactly what ash.grant_reader() hands out)
   * is recorded here and re-run through ash.grant_reader() during the
   * restore, which grants the complete current closure. Detection uses the
   * snapshotted explicit aclitems, not has_function_privilege(), so
   * superusers and role-membership shortcuts never qualify; roles holding
   * only partial manual FUNCTION grants keep the exact-signature restore
   * path and are not widened. Table ACLs are not snapshotted: a role with
   * the full function bundle is classified as a reader even if an operator
   * narrowed its table access, so the full-bundle restore below re-grants
   * that access and emits a WARNING. ash._admin_funcs() may not exist yet
   * (fresh install, or upgrade from a version predating the #45 hardening —
   * which also predates grant_reader, so there are no reader bundles to
   * detect).
   */
  drop table if exists pg_temp._ash_install_reader_roles;
  create temp table _ash_install_reader_roles (rolname name primary key);
  if to_regproc('ash._admin_funcs') is not null then
    insert into pg_temp._ash_install_reader_roles (rolname)
    select func_acl.grantee
    from pg_temp._ash_install_func_acl as func_acl
    group by func_acl.grantee
    having not exists (
      select 1
      from pg_proc as proc
      join pg_namespace as nsp on proc.pronamespace = nsp.oid
      where nsp.nspname = 'ash'
        and proc.prokind = 'f'
        and proc.proname::text <> all (ash._admin_funcs())
        and not exists (
          select 1
          from pg_temp._ash_install_func_acl as other_grant
          where other_grant.grantee = func_acl.grantee
            and other_grant.proname = proc.proname
            and other_grant.args =
              pg_catalog.pg_get_function_identity_arguments(proc.oid)
        )
    );
  end if;
end $$;

/*
 * Drop ALL overloads of functions whose signatures changed across versions.
 * Using a DO block because DROP FUNCTION requires exact arg types and we
 * can't predict which stale overloads exist from prior installs.
 */
do $$
declare
  func_row record;
begin
  /*
   * 2.0 drops the p_ prefix from every function parameter (p_from -> since,
   * p_wait_event -> wait_event, ...). CREATE OR REPLACE cannot rename an
   * input parameter, so every param-bearing function surviving from a
   * pre-rename install must be dropped first (grants are preserved by the
   * ACL snapshot/restore around this script, #107).
   *
   * _sample_data_is_valid needs special handling: the sample_data_check
   * constraint depends on it, so the constraint is dropped first (only when
   * the function still carries the old p_data parameter name) and re-added
   * by the constraint-migration block further down, which treats a missing
   * constraint as "needs rewrite".
   */
  if exists (
    select from pg_proc as proc
    join pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.proname = '_sample_data_is_valid'
      and proc.proargnames[1] = 'p_data'
  ) then
    if to_regclass('ash.sample') is not null then
      alter table ash.sample drop constraint if exists sample_data_check;
    end if;
    drop function ash._sample_data_is_valid(integer[]);
  end if;

  for func_row in
    select proc.oid::regprocedure as sig
    from pg_proc as proc
    join pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.proname in (
        'top_waits', 'top_waits_at',
        'histogram', 'histogram_at',
        'timeline_chart', 'timeline_chart_at',
        'query_waits', 'query_waits_at',
        'top_by_type', 'top_by_type_at',
        'waits_by_type', 'waits_by_type_at',
        'event_queries', 'event_queries_at',
        'top_queries_with_text',
        '_validate_data',
        'uninstall',
        'debug_logging',
        'rebuild_partitions',
        /*
         * 2.0 reader rework (issue #113): drop every removed v1.x reader,
         * every draft aas_* function (all overloads / _at twins), and the
         * earlier 2.0 draft names that were renamed to the final surface
         * (aas_by -> top, aas_series -> timeline, aas_compare -> compare,
         * aas_periods -> periods, health_report -> report), plus the
         * changed-signature name `samples`, so re-applying this installer
         * over any prior install yields exactly the 2.0 surface (periods,
         * aas, timeline, top, compare, samples, report, chart, summary).
         * `aas` is a stable name but its signature changed, so it is
         * dropped too to clear any old overload.
         */
        'top_queries', 'top_queries_at',
        'wait_timeline', 'wait_timeline_at',
        'activity_summary',
        'samples', 'samples_at',
        'samples_by_database', 'samples_by_database_at',
        'minute_waits', 'minute_waits_at',
        'hourly_queries', 'hourly_queries_at',
        'daily_peak_backends', 'daily_peak_backends_at',
        '_to_sample_ts', '_pick_rollup_source',
        'aas', 'aas_at',
        'aas_periods',
        /*
         * signature/return-type changes during the 2.0 development cycle:
         * periods() renamed minutes_with_data -> buckets_with_data and
         * gained a bucket column; top() gained order_by. Drop stale
         * overloads so re-apply over an earlier 2.0 draft converges on the
         * final surface.
         */
        'periods', 'top',
        /*
         * 2.0 parameter de-prefixing (see the note above the loop): every
         * remaining param-bearing function whose parameter names changed.
         */
        'ts_from_timestamptz', 'ts_to_timestamptz', '_register_wait',
        'decode_sample', 'decode_sample_at',
        'start', 'set_debug_logging',
        '_active_slots_for', '_active_slots_for_at',
        '_merge_wait_counts', '_merge_query_counts', '_truncate_pairs',
        'rollup_minute',
        '_color_on', '_wait_color', '_reset', '_bar',
        '_pick_source', '_pick_source_agg', '_exact_query_uses_coarser',
        '_raise_tie_retention',
        '_minute_counts_valid', '_rollup_1h_has_flat',
        '_grain_counts', '_grain_by',
        'timeline', 'compare', '_pgss_query_text',
        '_hr_top_events', '_hr_top_queryids',
        'report', 'chart', 'summary',
        'grant_reader', 'revoke_reader',
        'aas_series', 'aas_by', 'aas_compare', 'health_report',
        'aas_timeline', 'aas_timeline_at',
        'aas_wait_types', 'aas_wait_types_at',
        'aas_wait_events', 'aas_wait_events_at',
        'aas_queryids', 'aas_queryids_at',
        'aas_summary', 'aas_summary_at',
        'aas_waits', 'aas_waits_at',
        'aas_queries', 'aas_queries_at'
      )
  loop
    execute format('drop function if exists %s', func_row.sig);
  end loop;
end $$;

--------------------------------------------------------------------------------
-- STEP 1: Core schema and infrastructure
--------------------------------------------------------------------------------

-- Create schema
create schema if not exists ash;

/*
 * Epoch function: 2026-01-01 00:00:00 UTC.
 * WARNING: This value must NEVER change after installation. All sample_ts
 * values are seconds since this epoch. Changing it corrupts all timestamps.
 *
 * OVERFLOW HORIZON (issue #37 INFO): sample_ts is stored as int4 seconds
 * since 2026-01-01 UTC. int4 max is 2,147,483,647 seconds (~68.1 years), so
 * this counter is exhausted at roughly 2094-01-19 03:14:07 UTC. Past that
 * point, the `::int4` cast in ash.take_sample() raises `ERROR: integer out
 * of range` and sampling hard-fails — it does NOT silently wrap. ash.status()
 * surfaces the remaining seconds as `epoch_seconds_remaining` for
 * observability. Before ~2090, a bigint migration of the sample_ts column
 * (and all readers) is required to keep sampling working. Do NOT change
 * ash.epoch() to buy time — that corrupts every historical sample. The fix
 * is a column-type migration.
 */
create or replace function ash.epoch()
returns timestamptz
language sql
immutable
parallel safe
set search_path = pg_catalog, ash
as $$
  select '2026-01-01 00:00:00+00'::timestamptz
$$;

-- Configuration singleton table
create table if not exists ash.config (
  singleton                  bool primary key default true check (singleton),
  current_slot               smallint not null default 0,
  num_partitions             smallint not null default 3
                               check (num_partitions between 3 and 32),
  sampling_enabled           bool not null default true,
  skipped_samples            int4 not null default 0,
  missed_samples             bigint not null default 0,
  sample_interval            interval not null default '1 second',
  -- Keep this predicate aligned with _validate_rotation_period() below.
  rotation_period            interval not null default '1 day'
                               constraint config_rotation_period_day_check
                               check (
                                 rotation_period >= interval '1 day'
                                 and extract(year from rotation_period) = 0
                                 and extract(month from rotation_period) = 0
                                 and extract(epoch from rotation_period)
                                   % 86400 = 0
                               ),
  include_bg_workers         bool not null default false,
  debug_logging              bool not null default false,
  encoding_version           smallint not null default 1,
  version                    text not null default '2.0-beta1',
  rotated_at                 timestamptz not null default clock_timestamp(),
  installed_at               timestamptz not null default clock_timestamp(),
  rollup_1m_retention_days   smallint not null default 30
                               check (rollup_1m_retention_days >= 1),
  rollup_1h_retention_days   smallint not null default 1825
                               check (rollup_1h_retention_days >= 1),
  rollup_min_backend_seconds smallint not null default 3,
  last_rollup_1m_ts          int4,
  last_rollup_1h_ts          int4,
  -- M-BUG-4: rows silently dropped by take_sample()'s inner exception handler.
  insert_errors              bigint not null default 0,
  -- M-BUG-6 / H-SEC-3: _register_wait dictionary-cap hit counter.
  register_wait_cap_hits     bigint not null default 0,
  -- Consecutive rotate() failure returns; reset by a successful rotation.
  consecutive_rotate_failures bigint not null default 0
);

-- Insert initial row if not exists.
insert into ash.config (singleton) values (true) on conflict do nothing;

comment on column ash.config.sample_interval is
$$Current nominal sampler interval, not a historical record. In 2.0, sample and rollup rows do not persist the interval in force when collected, so AAS readers weight all retained appearances with this current value; changing it rescales history. Intervals greater than one minute can assign the full tick weight to one minute and overstate minute extrema. Successful idle ticks also write no sample row, so activity-row availability cannot distinguish idle sampling from an outage (issues #137 and #175).$$;

/*
 * Migration: add v1.4 columns if upgrading from pre-1.4. Must run before any
 * code reads these columns. Uses per-column IF NOT EXISTS so the block is
 * safe when some columns (e.g. missed_samples from the PR #29 upgrade) were
 * already added. Also idempotent on fresh installs (the columns are already
 * present from the `create table if not exists` above with matching defaults).
 */
alter table ash.config
  add column if not exists num_partitions smallint not null default 3
    check (num_partitions between 3 and 32),
  add column if not exists sampling_enabled bool not null default true,
  add column if not exists skipped_samples int4 not null default 0,
  add column if not exists missed_samples bigint not null default 0,
  add column if not exists rollup_1m_retention_days smallint not null default 30,
  add column if not exists rollup_1h_retention_days smallint not null default 1825,
  add column if not exists rollup_min_backend_seconds smallint not null default 3,
  add column if not exists last_rollup_1m_ts int4,
  add column if not exists last_rollup_1h_ts int4,
  -- M-BUG-4: track rows silently dropped by take_sample()'s exception handler.
  add column if not exists insert_errors bigint not null default 0,
  /*
   * M-BUG-6 / H-SEC-3: track how often _register_wait hits the dictionary cap
   * and has to skip a new (state,type,event). Non-zero means wait-event
   * registrations are being silently dropped for that sample (those sessions
   * won't appear in encoded data for this tick). Surfaced by ash.status().
   */
  add column if not exists register_wait_cap_hits bigint not null default 0,
  add column if not exists consecutive_rotate_failures bigint not null
    default 0;

/*
 * Keep the day-granularity error reusable and actionable. The explicit call
 * before ADD CONSTRAINT makes upgrades from a formerly accepted sub-day value
 * fail with remediation text instead of PostgreSQL's generic CHECK message.
 */
create or replace function ash._validate_rotation_period(
  rotation_period interval
)
returns void
language plpgsql
immutable
set search_path = pg_catalog, ash
as $$
begin
  -- This predicate mirrors both the declarative CHECKs below.
  if rotation_period < interval '1 day'
     or extract(year from rotation_period) <> 0
     or extract(month from rotation_period) <> 0
     or extract(epoch from rotation_period) % 86400 <> 0 then
    raise exception using
      errcode = '23514',
      message = format(
        'pg_ash: rotation_period must be a whole number of days '
        '(minimum 1 day); sub-day and fractional-day rotation are '
        'unsupported because ash.rotate() is scheduled daily; got %s; '
        'set ash.config.rotation_period to a whole-day interval '
        '(for example, 1 day) before retrying',
        rotation_period
      );
  end if;
end;
$$;

/*
 * Ensure retention CHECK constraints exist for both fresh and upgrade paths.
 * ADD COLUMN IF NOT EXISTS above doesn't apply CHECKs to pre-existing columns,
 * so add them explicitly here (guarded by a not-exists probe for idempotency).
 * The rotation-period CHECK is installed at the end so a legacy invalid value
 * reaches the actionable validator before PostgreSQL can emit a generic CHECK
 * error. The file-level transaction rolls the attempted upgrade back; after
 * correcting the legacy value, the operator re-runs the installer.
 */
do $$
begin
  if not exists (
    select from pg_constraint
    where conname = 'config_rollup_1m_retention_days_check'
      and conrelid = 'ash.config'::regclass
  ) then
    alter table ash.config
      add constraint config_rollup_1m_retention_days_check
      check (rollup_1m_retention_days >= 1);
  end if;
  if not exists (
    select from pg_constraint
    where conname = 'config_rollup_1h_retention_days_check'
      and conrelid = 'ash.config'::regclass
  ) then
    alter table ash.config
      add constraint config_rollup_1h_retention_days_check
      check (rollup_1h_retention_days >= 1);
  end if;
end $$;

/*
 * Validate the ring geometry whenever one of its three knobs changes.
 * This is deliberately an UPDATE-OF trigger rather than a cross-column CHECK:
 * an existing 32-slot / 30-day install must be able to re-apply this installer
 * and use rotate()'s expired-data escape hatch. The next attempted knob change
 * is rejected until the geometry is safe.
 */
create or replace function ash._validate_rotation_config(
  num_partitions int,
  rotation_period interval,
  rollup_1m_retention_days int
)
returns void
language plpgsql
immutable
set search_path = pg_catalog, ash
as $$
declare
  v_geometry interval;
begin
  perform ash._validate_rotation_period(rotation_period);

  v_geometry := (num_partitions - 1) * rotation_period;
  if v_geometry >
     rollup_1m_retention_days * interval '1 day' then
    raise exception using
      errcode = '23514',
      message = format(
        'pg_ash: invalid retention geometry: '
        '(num_partitions - 1) * rotation_period = '
        '(%s - 1) * %s = %s exceeds '
        'rollup_1m_retention_days = %s; increase '
        'rollup_1m_retention_days or reduce num_partitions or '
        'rotation_period',
        num_partitions,
        rotation_period,
        v_geometry,
        rollup_1m_retention_days
          || case
               when rollup_1m_retention_days = 1 then ' day'
               else ' days'
             end
      );
  end if;
end;
$$;

create or replace function ash._validate_config_update()
returns trigger
language plpgsql
set search_path = pg_catalog, ash
as $$
begin
  perform ash._validate_rotation_config(
    new.num_partitions,
    new.rotation_period,
    new.rollup_1m_retention_days
  );
  return new;
end;
$$;

drop trigger if exists config_validate_rotation on ash.config;
create trigger config_validate_rotation
before insert or update of
  num_partitions,
  rotation_period,
  rollup_1m_retention_days
on ash.config
for each row
execute function ash._validate_config_update();

comment on column ash.config.rotation_period is
$$Whole-day partition rotation period (minimum 1 day). ash.start() checks for rotation daily; sub-day and fractional-day values are unsupported.$$;

comment on column ash.config.rollup_1m_retention_days is
$$Minute-rollup retention in days. Must cover the endangered raw-slot age: (num_partitions - 1) * rotation_period.$$;

comment on function ash._validate_rotation_config(int, interval, int) is
$$Internal validator for day-granular rotation_period and safe raw-ring/minute-rollup retention geometry.$$;

comment on function ash._validate_rotation_period(interval) is
$$Internal validator for the whole-day rotation_period contract; raises an actionable check-violation message.$$;

comment on function ash._validate_config_update() is
$$Internal trigger enforcing rotation and retention geometry whenever its ash.config knobs change.$$;

/*
 * Stamp the version on both fresh installs and upgrades. On an existing
 * install the `create table if not exists` above keeps the old row and column
 * default, so set them here explicitly (mirrors the released installer
 * convention). This also keeps the column default schema-identical between a
 * fresh 2.0 install and an upgrade chain landing on 2.0 (the CI
 * schema-equivalence check).
 */
update ash.config set version = '2.0-beta1' where singleton;
alter table ash.config alter column version set default '2.0-beta1';

/*
 * Wait event dictionary.
 * M-BUG-6 / H-SEC-3: id stays smallint (matches legacy upgrade scripts; a
 * widened type would require a separate, coordinated migration because
 * `create or replace function` cannot change the return type of
 * ash._register_wait on a re-apply). DoS mitigation happens via the hard
 * row cap enforced in _register_wait (same pattern as query_map).
 */
create table if not exists ash.wait_event_map (
  id    smallint primary key generated always as identity (start with 1),
  state text not null,
  type  text not null,
  event text not null,
  unique (state, type, event)
);

/*
 * Query ID dictionaries — one per sample partition, TRUNCATE together.
 * Each has its own identity sequence (explicit, not LIKE INCLUDING ALL,
 * because PG14-15 shares sequences with LIKE INCLUDING ALL).
 * Created dynamically based on num_partitions (default 3).
 */
do $$
declare
  v_n int;
begin
  select num_partitions into v_n from ash.config where singleton;

  for i in 0 .. v_n - 1 loop
    execute format(
      'create table if not exists ash.query_map_%s ('
      '  id       int4 primary key generated always as identity (start with 1),'
      '  query_id int8 not null unique'
      ')', i
    );
  end loop;
end $$;

/*
 * Rebuild query_map_all view dynamically for N partitions.
 * Called by rebuild_partitions() after creating/dropping partition tables.
 */
create or replace function ash._rebuild_query_map_view()
returns void
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_n int;
  v_sql text := '';
begin
  select num_partitions into v_n
  from ash.config
  where singleton;

  for i in 0 .. v_n - 1 loop
    if i > 0 then
      v_sql := v_sql || ' union all ';
    end if;

    v_sql := v_sql || format(
      'select %s::smallint as slot, id, query_id from ash.query_map_%s',
      i, i
    );
  end loop;

  execute 'create or replace view ash.query_map_all as ' || v_sql;
end;
$$;

/*
 * Unified view for readers — planner eliminates non-matching partitions when
 * slot is a constant (which it is, from sample_row.slot in reader queries).
 * Built dynamically to support N partitions.
 */
select ash._rebuild_query_map_view();

/*
 * Drop all sample partitions and query_map tables (catalog-based).
 * Uses pg_inherits/pg_class instead of trusting num_partitions config,
 * catching orphaned tables from prior failed rebuilds.
 */
create or replace function ash._drop_all_partitions()
returns void
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_rec record;
begin
  -- Drop sample partitions (children of ash.sample).
  for v_rec in
    select rel.relname
    from pg_inherits as inh
    join pg_class as rel on rel.oid = inh.inhrelid
    join pg_namespace as nsp on nsp.oid = rel.relnamespace
    where inh.inhparent = 'ash.sample'::regclass
      and nsp.nspname = 'ash'
  loop
    execute format('drop table if exists ash.%I', v_rec.relname);
  end loop;

  -- Drop query_map tables by naming pattern.
  for v_rec in
    select rel.relname
    from pg_class as rel
    join pg_namespace as nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'ash'
      and rel.relname ~ '^query_map_[0-9]+$'
      and rel.relkind = 'r'
  loop
    execute format('drop table if exists ash.%I', v_rec.relname);
  end loop;
end;
$$;

-- Current slot function
create or replace function ash.current_slot()
returns smallint
language sql
stable
parallel safe
set search_path = pg_catalog, ash
as $$
  select current_slot from ash.config where singleton
$$;

/*
 * Validate the packed ash.sample.data representation.
 *
 * Layout: one or more groups of:
 *   - negative wait-id marker
 *   - positive backend count N
 *   - exactly N non-negative query_map ids, where 0 means NULL query_id
 *
 * Kept as a standalone immutable helper so both fresh installs and upgrades
 * can use one table CHECK expression. The function intentionally performs
 * shape validation only; wait/query dictionary lookups stay in readers.
 */
create or replace function ash._sample_data_is_valid(data integer[])
returns boolean
language plpgsql
immutable
strict
parallel safe
set search_path = pg_catalog
as $$
declare
  v_len int;
  v_idx int := 1;
  v_count int;
  v_qid_idx int;
begin
  v_len := array_length(data, 1);
  if v_len is null or v_len < 3 or v_len > 100000 then
    return false;
  end if;

  while v_idx <= v_len loop
    if data[v_idx] is null or data[v_idx] >= 0 then
      return false;
    end if;
    v_idx := v_idx + 1;

    if v_idx > v_len then
      return false;
    end if;
    v_count := data[v_idx];
    if v_count is null or v_count <= 0 then
      return false;
    end if;
    v_idx := v_idx + 1;

    if v_idx + v_count - 1 > v_len then
      return false;
    end if;

    for v_qid_idx in 1..v_count loop
      if data[v_idx] is null or data[v_idx] < 0 then
        return false;
      end if;
      v_idx := v_idx + 1;
    end loop;
  end loop;

  return true;
end;
$$;

-- Sample table (partitioned by slot)
create table if not exists ash.sample (
  sample_ts    int4 not null,
  datid        oid not null,
  active_count smallint not null,
  data         integer[] not null
         check (ash._sample_data_is_valid(data)),
  slot         smallint not null default ash.current_slot()
) partition by list (slot);

-- Create partitions and indexes dynamically based on num_partitions.
do $$
declare
  v_n int;
begin
  select num_partitions into v_n from ash.config where singleton;

  for i in 0 .. v_n - 1 loop
    execute format(
      'create table if not exists ash.sample_%s '
      'partition of ash.sample for values in (%s)', i, i
    );

    -- (sample_ts) for time-range reader queries
    execute format(
      'create index if not exists sample_%s_ts_idx '
      'on ash.sample_%s (sample_ts)', i, i
    );

    -- (datid, sample_ts) for per-database time-range queries
    execute format(
      'create index if not exists sample_%s_datid_ts_idx '
      'on ash.sample_%s (datid, sample_ts)', i, i
    );
  end loop;
end $$;

/*
 * Migration (issues #49, #89): align sample.data check across upgrade paths.
 * v1.0 shipped `array_length(data, 1) >= 2`; v1.1 tightened it to `>= 3`;
 * v1.5 validates the full packed shape so impossible wait counts are rejected
 * at INSERT time. Detect and fix in place. Idempotent: only rewrites when the
 * current definition is missing or not using the validator helper. Drops on
 * the partitioned parent cascade to all partitions; ADD CONSTRAINT on the
 * parent propagates back to children.
 */
do $$
declare
  v_def text;
  v_valid boolean;
  v_invalid bigint;
begin
  select pg_get_constraintdef(con.oid), con.convalidated
    into v_def, v_valid
  from pg_constraint as con
  where con.conrelid = 'ash.sample'::regclass
    and con.conname  = 'sample_data_check';

  if v_def is null or v_def !~ '_sample_data_is_valid' then
    select count(*) into v_invalid
    from ash.sample
    where not ash._sample_data_is_valid(data);

    if v_invalid > 0 then
      create table if not exists ash.sample_malformed_1_5 (
        sample_ts int4 not null,
        datid oid not null,
        active_count smallint not null,
        data integer[] not null,
        slot smallint not null,
        quarantined_at timestamptz not null default clock_timestamp()
      );

      insert into ash.sample_malformed_1_5 (
        sample_ts, datid, active_count, data, slot
      )
      select sample_ts, datid, active_count, data, slot
      from ash.sample
      where not ash._sample_data_is_valid(data);

      raise warning
        'pg_ash upgrade: quarantined and deleted % malformed ash.sample '
        'row(s) rejected by the v1.5 data-shape validator',
        v_invalid;
      delete from ash.sample
      where not ash._sample_data_is_valid(data);
    end if;

    if v_def is not null then
      alter table ash.sample drop constraint sample_data_check;
    end if;
    alter table ash.sample
      add constraint sample_data_check
      check (ash._sample_data_is_valid(data));
  elsif not v_valid then
    alter table ash.sample validate constraint sample_data_check;
  end if;
end $$;

/*
 * Convert timestamptz to int4 epoch offset.
 *
 * Clamp to [0, INT4_MAX] so absurd inputs (pre-epoch dates,
 * post-2094-horizon dates) do not raise `integer out of range`. sample_ts is
 * a non-negative int4 by construction, so:
 *   * pre-epoch  -> 0           (no matching samples; readers return empty)
 *   * post-INT4  -> 2147483647  (no matching samples; readers return empty)
 * This centralizes the same-class clamp pattern used by the interval readers
 * (#51 / PR #57) so every _at variant inherits the safety net (#63).
 */
create or replace function ash.ts_from_timestamptz(ts timestamptz)
returns int4
language sql
immutable
parallel safe
set search_path = pg_catalog, ash
as $$
  select greatest(
           least(
             extract(epoch from ts - ash.epoch()),
             2147483647  -- int4 max; sample_ts can't exceed this without overflow
           ),
           0             -- sample_ts can't be negative; pre-epoch -> 0
         )::int4
$$;

-- Convert int4 epoch offset to timestamptz
create or replace function ash.ts_to_timestamptz(ts int4)
returns timestamptz
language sql
immutable
parallel safe
set search_path = pg_catalog, ash
as $$
  select ash.epoch() + ts * interval '1 second'
$$;

comment on table ash.sample is
$$Packed wait-event samples. One row per (sample_ts, datid). Do not join directly — use ash.samples(since, until) for decoded rows, or ash.decode_sample(data, slot) if you need a single sample's contents.$$;

comment on column ash.sample.data is
$$Packed int4[] encoding the sample's wait events and their query_map ids. Layout: groups of (-wait_id, count, query_map_id_1, ..., query_map_id_count). A negative marker starts each group; wait_id is negated for the marker so a positive count cannot be mistaken for a group boundary. Decode via ash.samples(since, until) or ash.decode_sample(data, slot).$$;

/*
 * Register wait event function (upsert, returns id).
 * M-BUG-6 / H-SEC-3: signature intentionally preserved (returns smallint).
 * Widening the return type would break `create or replace` on top of any
 * legacy upgrade script that shipped the smallint signature (PG raises
 * `cannot change return type of existing function`), breaking the
 * re-apply / idempotent-install path. DoS is prevented by a hard row cap
 * below (mirrors the query_map 50 000 pattern but sized to stay within
 * smallint's 32 767 range). When the cap is hit we skip the INSERT and
 * return NULL — callers (take_sample() via PERFORM) ignore the return
 * value, and the later per-datid snapshot JOIN on wait_event_map simply
 * excludes sessions whose (state,type,event) is not registered. The
 * register_wait_cap_hits counter in ash.config surfaces the drop so
 * ash.status() can alert operators instead of silently mis-attributing
 * events to whatever row happened to be id=1.
 */
create or replace function ash._register_wait(state text, type text, event text)
returns smallint
language plpgsql
set search_path = pg_catalog, ash
as $$
/*
 * Parameters share names with wait_event_map columns, so inside queries the
 * parameter side is always function-qualified (_register_wait.state, ...) and
 * the column side alias-qualified; use_column keeps the bare ON CONFLICT
 * column list below unambiguous.
 */
#variable_conflict use_column
declare
  v_id     smallint;
  v_at_cap boolean;
begin
  -- Try to get existing.
  select event_map.id into v_id
  from ash.wait_event_map as event_map
  where event_map.state = _register_wait.state
    and event_map.type  = _register_wait.type
    and event_map.event = _register_wait.event;

  if v_id is not null then
    return v_id;
  end if;

  /*
   * Enforce dictionary size cap before inserting. 32 000 stays well below
   * smallint's 32 767 ceiling while still leaving room for genuine event
   * diversity (real wait-event inventories measure in the hundreds).
   * Use an exact existence probe for the 32 000th row instead of
   * pg_class.reltuples: reltuples can be -1 or stale immediately after
   * TRUNCATE/restore, which bypasses a hard cap until ANALYZE catches up.
   */
  select exists (
    select 1 from ash.wait_event_map offset 31999 limit 1
  ) into v_at_cap;

  if v_at_cap then
    /*
     * Bump the cap-hit counter so ash.status() can surface the drop.
     * Note: counts *registration drops* here — not the number of sampled
     * backends observed for this (state,type,event). Many concurrent
     * backends blocked on the same dropped event only bump it once per tick.
     * Wrap in an inner block: if the UPDATE itself fails (e.g. config row
     * missing mid-uninstall), we still want the outer WARNING to fire and
     * the function to return NULL without aborting take_sample().
     */
    begin
      update ash.config set register_wait_cap_hits = register_wait_cap_hits + 1
        where singleton;
    exception when others then
      null;  -- counter bump is best-effort
    end;
    raise warning
      'ash._register_wait: wait_event_map at cap (>= 32 000 rows); '
      'skipping (state=%, type=%, event=%) — see ash.status()',
      state, type, event;
    return null;  -- caller PERFORMs this; snapshot JOIN drops the session
  end if;

  -- Insert new entry.
  insert into ash.wait_event_map (state, type, event)
  values (_register_wait.state, _register_wait.type, _register_wait.event)
  on conflict (state, type, event) do nothing
  returning id into v_id;

  -- If insert succeeded, return it.
  if v_id is not null then
    return v_id;
  end if;

  -- Race condition: another session inserted, fetch it.
  select event_map.id into v_id
  from ash.wait_event_map as event_map
  where event_map.state = _register_wait.state
    and event_map.type  = _register_wait.type
    and event_map.event = _register_wait.event;

  return v_id;
end;
$$;

-- (_register_query removed — bulk registration in take_sample() handles
-- query_map inserts directly via per-partition INSERT ON CONFLICT)

--------------------------------------------------------------------------------
-- STEP 2: Sampler and decoder
--------------------------------------------------------------------------------

-- Core sampler function (no hstore dependency)
create or replace function ash.take_sample()
returns int
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_sample_ts int4;
  v_include_bg bool;
  v_debug_logging bool;
  v_sampling_enabled bool;
  v_rec record;
  v_datid_rec record;
  v_data integer[];
  v_active_count smallint;
  v_current_wait_id smallint;
  v_current_slot smallint;
  v_rows_inserted int := 0;
  v_missed_count bigint;
  v_seen_waits text[] := '{}';
begin
  -- Get config (single read for all settings).
  select sampling_enabled, include_bg_workers, debug_logging
  into v_sampling_enabled, v_include_bg, v_debug_logging
  from ash.config where singleton;

  if not v_sampling_enabled then
    update ash.config
    set skipped_samples = skipped_samples + 1
    where singleton;

    return 0;
  end if;

  /*
   * Acquire participation lock (xact-level, auto-releases on commit/rollback).
   * All ash advisory locks share classid = hashtext('pg_ash')::int4 with a
   * per-kind objid. The sampler kind is dedicated so it does NOT contend
   * with rollup_minute / rollup_hour / rollup_cleanup — a long catch-up
   * rollup no longer silently bumps skipped_samples on every tick.
   * rebuild_partitions() polls pg_locks for ANY ash lock to drain in-flight
   * operations.
   */
  if not pg_try_advisory_xact_lock(
       hashtext('pg_ash')::int4,
       hashtext('pg_ash_sampler')::int4
     ) then
    update ash.config
    set skipped_samples = skipped_samples + 1
    where singleton;

    return 0;
  end if;

  -- Get sample timestamp (seconds since epoch, from now()).
  v_sample_ts := extract(epoch from now() - ash.epoch())::int4;
  v_current_slot := ash.current_slot();

  /*
   * Sampler: 4 pg_stat_activity reads (single-database setup).
   *   1. Wait event registration loop
   *   2. Query_map registration INSERT
   *   3. Distinct datids loop
   *   4. Per-datid encoding CTE (+ active_count)
   * Reads 1-2 are non-atomic (separate queries) — a backend may appear in
   * one but not the other. This is harmless: query_map gets an extra entry,
   * or a wait event registers one tick early.
   * No temp tables — avoids pg_class/pg_attribute catalog churn per tick.
   */

  -- Read 1: register new wait events; optionally log each sampled session.
  /*
   * CPU* means the backend is active with no wait event reported. This is
   * either genuine CPU work or an uninstrumented code path in Postgres.
   * The asterisk signals this ambiguity. See https://gaps.wait.events
   *
   * Debug logging (when v_debug_logging = true):
   *   Uses RAISE LOG — goes to server log only, never to the client.
   *   Independent of log_min_messages and client_min_messages.
   *   Enable:  select ash.set_debug_logging(true);
   *   Disable: select ash.set_debug_logging(false);
   *
   * Both tasks share one pg_stat_activity scan. Wait event registration skips
   * duplicates via a seen-set (text[] + ANY check) to avoid repeated lookups.
   */
  for v_rec in
    select
      activity.pid,
      activity.state,
      coalesce(activity.wait_event_type,
        case
          when activity.state = 'active'                   then 'CPU*'
          when activity.state like 'idle in transaction%'  then 'IdleTx'
        end
      ) as wait_type,
      coalesce(activity.wait_event,
        case
          when activity.state = 'active'                   then 'CPU*'
          when activity.state like 'idle in transaction%'  then 'IdleTx'
        end
      ) as wait_event,
      activity.backend_type,
      activity.query_id
    from pg_stat_activity as activity
    where activity.state in (
        'active', 'idle in transaction', 'idle in transaction (aborted)'
      )
      and (activity.backend_type = 'client backend'
       or (v_include_bg and activity.backend_type in (
         'autovacuum worker', 'logical replication worker',
         'parallel worker', 'background worker'
       )))
      and activity.pid <> pg_backend_pid()
  loop
    -- Register wait event if not yet seen this tick (in-memory dedup).
    if not (v_rec.state || '|' || v_rec.wait_type || '|' || v_rec.wait_event
            = any(v_seen_waits)) then
      v_seen_waits := v_seen_waits
        || (v_rec.state || '|' || v_rec.wait_type || '|' || v_rec.wait_event);
      if not exists (
        select from ash.wait_event_map
        where state = v_rec.state
          and type = v_rec.wait_type
          and event = v_rec.wait_event
      ) then
        perform ash._register_wait(
          v_rec.state, v_rec.wait_type, v_rec.wait_event
        );
      end if;
    end if;

    /*
     * Debug logging: RAISE LOG goes to server log only, never to the client.
     * Independent of log_min_messages and client_min_messages.
     */
    if v_debug_logging then
      raise log
        'ash.take_sample: pid=% state=% wait_type=% wait_event=% '
        'backend_type=% query_id=%',
        v_rec.pid, v_rec.state, v_rec.wait_type, v_rec.wait_event,
        v_rec.backend_type, coalesce(v_rec.query_id::text, '(null)');
    end if;
  end loop;

  -- Read 2: register query_ids into current slot's query_map.
  /*
   * Partitioned query_map: TRUNCATE resets on rotation, but between rotations
   * PG14-15 volatile SQL comments can flood query_map. 50k hard cap per
   * partition prevents unbounded growth. PG16+ normalizes comments.
   * Dynamic SQL: single query template, bug fixes apply once (not N×).
   * Existence probe at the 50000th row: one index lookup, and — unlike
   * pg_class.reltuples — immediately accurate after TRUNCATE (reltuples
   * can remain stale or be -1 until autovacuum/ANALYZE catches up).
   */
  execute format(
    'insert into ash.query_map_%1$s (query_id) '
    'select distinct activity.query_id '
    'from pg_stat_activity as activity '
    'where activity.query_id is not null '
    '  and activity.state in (''active'', ''idle in transaction'', '
    '    ''idle in transaction (aborted)'') '
    '  and (activity.backend_type = ''client backend'' '
    '   or ($1 and activity.backend_type in (''autovacuum worker'', '
    '     ''logical replication worker'', ''parallel worker'', '
    '     ''background worker''))) '
    '  and activity.pid <> pg_backend_pid() '
    '  and not exists (select 1 from ash.query_map_%1$s offset 49999 limit 1) '
    'on conflict (query_id) do nothing',
    v_current_slot
  ) using v_include_bg;

  -- Read 2+3: per-database encoding. Build and insert encoded arrays — one
  -- per database. Uses CTEs instead of temp tables to avoid catalog churn.
  for v_datid_rec in
    select distinct coalesce(activity.datid, 0::oid) as datid
    from pg_stat_activity as activity
    where activity.state in (
        'active', 'idle in transaction', 'idle in transaction (aborted)'
      )
      and (activity.backend_type = 'client backend'
       or (v_include_bg and activity.backend_type in (
         'autovacuum worker', 'logical replication worker',
         'parallel worker', 'background worker'
       )))
      and activity.pid <> pg_backend_pid()
  loop
    begin
      -- Single query: snapshot → group by wait → encode → flatten.
      with snapshot as (
        select
          event_map.id as wait_id,
          coalesce(query_map.id, 0) as map_id
        from pg_stat_activity as activity
        join ash.wait_event_map as event_map
         on event_map.state = activity.state
        and event_map.type = coalesce(activity.wait_event_type,
            case when activity.state = 'active' then 'CPU*'
              when activity.state like 'idle in transaction%' then 'IdleTx' end)
        and event_map.event = coalesce(activity.wait_event,
            case when activity.state = 'active' then 'CPU*'
              when activity.state like 'idle in transaction%' then 'IdleTx' end)
        left join ash.query_map_all as query_map
          on query_map.slot = v_current_slot
          and query_map.query_id = activity.query_id
        where activity.state in (
            'active', 'idle in transaction', 'idle in transaction (aborted)'
          )
          and (activity.backend_type = 'client backend'
           or (v_include_bg and activity.backend_type in (
             'autovacuum worker', 'logical replication worker',
             'parallel worker', 'background worker'
           )))
          and activity.pid <> pg_backend_pid()
          and coalesce(activity.datid, 0::oid) = v_datid_rec.datid
      ),
      groups as (
        select
          row_number() over (order by snapshot.wait_id) as gnum,
          array[(-snapshot.wait_id)::integer, count(*)::integer]
            || array_agg(snapshot.map_id::integer) as group_arr
        from snapshot
        group by snapshot.wait_id
      ),
      flat as (
        select array_agg(elems.el order by grouped.gnum, elems.ord) as data
        from groups as grouped
        cross join lateral unnest(grouped.group_arr)
          with ordinality as elems(el, ord)
      ),
      backend_count as (
        select count(*)::smallint as cnt from snapshot
      )
      select flat.data, backend_count.cnt into v_data, v_active_count
      from flat
      cross join backend_count;

      if v_data is not null and array_length(v_data, 1) >= 3 then
        insert into ash.sample (sample_ts, datid, active_count, data, slot)
        values (
          v_sample_ts, v_datid_rec.datid, v_active_count, v_data, v_current_slot
        );
        v_rows_inserted := v_rows_inserted + 1;
      end if;

    exception when others then
      /*
       * M-BUG-4: previously a CHECK violation on ash.sample.data (or any
       * other INSERT-time error) was silently swallowed with just a WARNING,
       * dropping a row of observability data without any durable signal.
       * Bump insert_errors so ash.status() can surface the count, and keep
       * the warning so live log watchers still see it.
       *
       * Nested BEGIN/EXCEPTION around the counter UPDATE: the outer
       * `exception when others` is a terminal handler, but the UPDATE
       * itself can fail (e.g. config row absent mid-uninstall, lock
       * timeout) and propagate out of this block. Before widening this
       * handler to do bookkeeping, no propagation path existed — preserve
       * that property so a flaky UPDATE never aborts the whole sampler.
       */
      begin
        update ash.config set insert_errors = insert_errors + 1
        where singleton;
      exception when others then
        null;  -- counter bump is best-effort; don't let it abort take_sample()
      end;
      raise warning
        'ash.take_sample: error inserting sample for datid % [%]: %',
        v_datid_rec.datid, sqlstate, sqlerrm;
    end;
  end loop;

  return v_rows_inserted;

exception when query_canceled then
  /*
   * statement_timeout (or pg_cancel_backend) fired — record the miss.
   * NOTE: query_canceled catches both statement_timeout AND explicit
   * pg_cancel_backend() signals. PG provides no way to distinguish them.
   * This is intentional: either way, the sample was interrupted and the
   * gap should be observable. If you need to hard-cancel take_sample(),
   * use pg_terminate_backend() instead.
   */
  update ash.config set missed_samples = missed_samples + 1
    where singleton
    returning missed_samples into v_missed_count;
  if v_missed_count is null then
    raise warning
      'ash.take_sample: interrupted '
      '(config row missing — missed_samples not tracked)';
  else
    raise warning 'ash.take_sample: interrupted (missed_samples = %)', v_missed_count;
  end if;
  return -1;
end;
$$;

/*
 * Decode sample function.
 * slot: when provided, look up query_ids from that partition only.
 * When NULL (default), search all partitions via query_map_all view.
 *
 * M-BUG-9: validate the entire array shape before emitting ANY rows.
 * Previously the function interleaved validation with `return next`, so a
 * malformed trailing segment still produced one or more valid-looking rows
 * followed by a WARNING. Callers saw silently truncated, partially correct
 * output. Now: walk once to verify shape, then walk again to emit — on
 * validation failure raise a single warning and return zero rows.
 */
create or replace function ash.decode_sample(data integer[], slot smallint default null)
returns table (
  wait_event text,
  query_id int8,
  count int
)
language plpgsql
stable
set search_path = pg_catalog, ash
as $$
declare
  v_len int;
  v_idx int;
  v_wait_id int;
  v_count int;
  v_qid_idx int;
  v_map_id int4;
  v_type text;
  v_event text;
  v_query_id int8;
begin
  -- Basic validation.
  if data is null or array_length(data, 1) is null then
    return;
  end if;

  v_len := array_length(data, 1);

  /*
   * Reject pathologically large arrays. Real ash.sample.data arrays are
   * bounded by pg_stat_activity row count (a few hundred entries even on
   * a busy database) plus the packed query_map_id payload — the largest
   * legitimate data we ever see is well under 10 000 elements. A larger
   * array passed by a malicious caller would force the validator and
   * decoder to walk it twice, sustaining backend memory pressure.
   */
  if v_len > 100000 then
    raise warning 'ash.decode_sample: data array too large (% > 100000)', v_len;
    return;
  end if;

  -- Basic structure check: first element must be negative (wait_id marker).
  if v_len < 3 or data[1] >= 0 then
    raise warning 'ash.decode_sample: invalid data array';
    return;
  end if;

  /*
   * Pass 1: validate shape only, emit nothing. Reuses the same walker logic
   * the old code had, but exits with a single warning and RETURN (no partial
   * rows) if anything is wrong.
   */
  v_idx := 1;
  while v_idx <= v_len loop
    if data[v_idx] is null or data[v_idx] >= 0 then
      raise warning
        'ash.decode_sample: expected negative wait_id at position %', v_idx;
      return;
    end if;
    v_idx := v_idx + 1;

    if v_idx > v_len then
      raise warning
        'ash.decode_sample: unexpected end of array at position % '
        '(missing count)', v_idx;
      return;
    end if;
    v_count := data[v_idx];
    if v_count is null or v_count <= 0 then
      raise warning
        'ash.decode_sample: non-positive count % at position %',
        v_count, v_idx;
      return;
    end if;
    v_idx := v_idx + 1;

    if v_idx + v_count - 1 > v_len then
      raise warning
        'ash.decode_sample: not enough query_ids for count % at position %',
        v_count, v_idx;
      return;
    end if;
    for v_qid_idx in 1..v_count loop
      if data[v_idx] is null or data[v_idx] < 0 then
        raise warning
          'ash.decode_sample: expected non-negative query_id at position %',
          v_idx;
        return;
      end if;
      v_idx := v_idx + 1;
    end loop;
  end loop;

  -- Pass 2: emit rows (shape is known good).
  v_idx := 1;
  while v_idx <= v_len loop
    v_wait_id := -data[v_idx];
    v_idx := v_idx + 1;

    v_count := data[v_idx];
    v_idx := v_idx + 1;

    -- Look up wait event info.
    select event_map.type, event_map.event
    into v_type, v_event
    from ash.wait_event_map as event_map
    where event_map.id = v_wait_id;

    -- Process each query_id.
    for v_qid_idx in 1..v_count loop
      v_map_id := data[v_idx];
      v_idx := v_idx + 1;

      -- Handle sentinel (0 = NULL query_id).
      if v_map_id = 0 then
        v_query_id := null;
      elsif slot is not null then
        select query_map.query_id into v_query_id
        from ash.query_map_all as query_map
        where query_map.slot = decode_sample.slot
          and query_map.id = v_map_id;
      else
        /*
         * No slot context — search all partitions (less efficient).
         * WARNING: after rotation, the same id may exist in multiple
         * partitions with different query_ids (independent sequences).
         * Result is nondeterministic. Always pass slot when available.
         */
        select query_map.query_id into v_query_id
        from ash.query_map_all as query_map
        where query_map.id = v_map_id
        limit 1;
      end if;

      wait_event := case
        when v_event = v_type then v_event
        else v_type || ':' || v_event
      end;
      query_id := v_query_id;
      count := 1;
      return next;
    end loop;
  end loop;

  return;
end;
$$;

/*
 * Convenience overload: decode every ash.sample row whose sample_ts matches.
 * Walks all datids/slots and returns decoded rows annotated with datid so the
 * caller can distinguish them. Implemented as a SQL LATERAL JOIN over the
 * 2-arg decode_sample(data, slot) SRF (passes slot for unambiguous lookup,
 * avoiding the "search-all-partitions" branch that can return stale ids
 * after rotation).
 */
create or replace function ash.decode_sample(sample_ts int4)
returns table (
  datid      oid,
  wait_event text,
  query_id   int8,
  count      int
)
language sql
stable
set search_path = pg_catalog, ash
as $$
  select sample_row.datid, decoded.wait_event, decoded.query_id, decoded.count
  from ash.sample as sample_row
  cross join lateral
    ash.decode_sample(sample_row.data, sample_row.slot) as decoded
  /*
   * function-qualified: in a SQL-language body a bare sample_ts would resolve
   * to the sample_row.sample_ts column (columns take precedence), not the
   * parameter
   */
  where sample_row.sample_ts = decode_sample.sample_ts
$$;

/*
 * Wall-clock convenience: convert timestamptz to the matching sample_ts via
 * ts_from_timestamptz() and delegate to decode_sample(int4). Same return
 * shape. Named decode_sample_at() (matching the samples_at / top_waits_at
 * naming convention) so we don't create a decode_sample(unknown) ambiguity
 * between int4 and timestamptz overloads.
 *
 * Intentionally NOT routed through _active_slots_for_at() (#69): unlike the
 * range-scan _at readers, decode_sample_at is a point-lookup keyed by an
 * exact sample_ts. Restricting to the helper's "now() - 2*rotation_period
 * .. now()" active-slots window would hide rows the caller can prove exist
 * (matching sample_ts in any partition). The silent ts_from_timestamptz()
 * int4 clamp from #63 is sufficient: absurd timestamps still don't error,
 * they just miss every partition.
 */
create or replace function ash.decode_sample_at(ts timestamptz)
returns table (
  datid      oid,
  wait_event text,
  query_id   int8,
  count      int
)
language sql
stable
set search_path = pg_catalog, ash
as $$
  select decoded.datid, decoded.wait_event, decoded.query_id, decoded.count
  from ash.decode_sample(ash.ts_from_timestamptz(ts)) as decoded
$$;

comment on function ash.decode_sample(integer[], smallint) is
$$Decodes a single ash.sample.data array into (wait_event, query_id, count) rows. Pass slot (ash.sample.slot) to resolve query_ids unambiguously; omitting it searches all query_map partitions and may return a stale id after rotation.$$;

comment on function ash.decode_sample(int4) is
$$Convenience overload: decodes every ash.sample row whose sample_ts equals sample_ts (across all datids/slots) and returns (datid, wait_event, query_id, count). Internally calls decode_sample(data, slot) with the row's slot, so query_id resolution is unambiguous.$$;

comment on function ash.decode_sample_at(timestamptz) is
$$Wall-clock convenience: same as decode_sample(int4) but accepts timestamptz, converting via ts_from_timestamptz() to find the matching sample_ts. Named with the _at suffix to avoid an unknown-typed decode_sample(123) literal matching both the int4 and timestamptz overloads.$$;


--------------------------------------------------------------------------------
-- STEP 3: Rotation function
--------------------------------------------------------------------------------

/*
 * Record a returned rotate() failure without letting observability
 * bookkeeping replace the operation's stable text result. rotate() sets a
 * short lock_timeout before touching partitions; a concurrent config writer
 * can therefore make this counter update time out too.
 */
create or replace function ash._record_rotate_failure()
returns void
language plpgsql
set search_path = pg_catalog, ash
set lock_timeout = '250ms'
as $$
begin
  update ash.config
  set consecutive_rotate_failures = consecutive_rotate_failures + 1
  where singleton;
exception when lock_not_available then
  raise warning
    'ash.rotate: config row locked; could not record rotate failure';
end;
$$;

comment on function ash._record_rotate_failure() is
$$Internal best-effort increment for consecutive_rotate_failures; config-row lock timeout must not mask rotate()'s failure result.$$;

/*
 * Rotate partitions: advance current_slot, truncate the old previous
 * partition and its matching query_map partition (lockstep TRUNCATE — zero
 * bloat everywhere). Uses dynamic SQL with modulo-N for configurable
 * partition count.
 */
create or replace function ash.rotate()
returns text
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_old_slot smallint;
  v_new_slot smallint;
  v_truncate_slot smallint;
  v_num_partitions smallint;
  v_rotation_period interval;
  v_rollup_1m_retention_days smallint;
  v_rollup_1m_cutoff int4;
  v_rotated_at timestamptz;
  v_rotation_minutes int;
  v_rollup_result int;
  v_endangered_rows bigint;
  v_unrolled_groups bigint;
begin
  /*
   * Advisory lock prevents concurrent rotation from pg_cron overlap.
   * Xact-level: auto-releases on commit/rollback — no leak risk with pg_cron
   * connection reuse. rotate() is REVOKE'd from PUBLIC — only schema owner.
   * Two-arg form so rebuild_partitions's drain poll (which keys on classid)
   * can see this lock; was a single-arg form in 1.4 betas but that put rotate
   * in a different lock namespace and rebuild couldn't drain it.
   */
  if not pg_try_advisory_xact_lock(
       hashtext('pg_ash')::int4,
       hashtext('pg_ash_rotate')::int4
     ) then
    return 'skipped: another rotation in progress';
  end if;

  begin
    -- Get current config.
    select
      current_slot,
      num_partitions,
      rotation_period,
      rollup_1m_retention_days,
      rotated_at
    into
      v_old_slot,
      v_num_partitions,
      v_rotation_period,
      v_rollup_1m_retention_days,
      v_rotated_at
    from ash.config
    where singleton;

    -- Check if we rotated too recently (within 90% of rotation_period).
    if now() - v_rotated_at < v_rotation_period * 0.9 then
      return 'skipped: rotated too recently at ' || v_rotated_at::text;
    end if;

    -- Calculate new slot dynamically (0 -> 1 -> ... -> N-1 -> 0).
    v_new_slot := (v_old_slot + 1) % v_num_partitions;

    -- The partition to truncate is the one after the new slot.
    v_truncate_slot := (v_new_slot + 1) % v_num_partitions;
    v_rollup_1m_cutoff := ash.ts_from_timestamptz(
      now() - v_rollup_1m_retention_days * interval '1 day'
    );

    -- Set lock timeout to avoid blocking on long-running queries.
    set local lock_timeout = '2s';

    /*
     * Pre-truncation rollup: process endangered minutes before they are lost.
     * For minutes still promised by rollup_1m retention, this is no longer
     * best-effort: if we cannot prove they are represented in rollup_1m,
     * skip rotation rather than deleting the only copy (#81). Older minutes
     * are outside the configured rollup contract and must not deadlock the
     * raw ring after rollup_cleanup() has intentionally deleted them (#162).
     */
    execute format(
      'select count(*) '
      'from ash.sample_%s '
      'where (sample_ts / 60) * 60 >= $1',
      v_truncate_slot
    )
    into v_endangered_rows
    using v_rollup_1m_cutoff;

    /*
     * Every truncate must serialize with rollup_minute(), even when the
     * target contains only expired rows. Otherwise rotate() can lock config
     * and wait for rollup's sample-table lock while rollup waits for config,
     * creating a deadlock on the cleanup/rotation escape path (#162).
     */
    if not pg_try_advisory_xact_lock(
         hashtext('pg_ash')::int4,
         hashtext('pg_ash_rollup')::int4
       ) then
      perform ash._record_rotate_failure();
      return format(
        'failed: pre-truncation rollup busy; slot %s not truncated',
        v_truncate_slot
      );
    end if;

    if v_endangered_rows > 0 then
      v_rotation_minutes :=
        greatest(extract(epoch from v_rotation_period)::int / 60, 1);

      begin
        select ash.rollup_minute(v_rotation_minutes) into v_rollup_result;
      exception when undefined_function then
        perform ash._record_rotate_failure();
        return format(
          'failed: rollup_minute() unavailable; slot %s not truncated',
          v_truncate_slot
        );
      when others then
        raise warning 'ash.rotate: rollup_minute failed [%]: %',
          sqlstate, sqlerrm;
        perform ash._record_rotate_failure();
        return format(
          'failed: pre-truncation rollup failed [%s]; slot %s not truncated',
          sqlstate,
          v_truncate_slot
        );
      end;

      execute format(
        'with raw as ('
        '  select (sample_ts / 60) * 60 as ts, datid,'
        '         count(distinct sample_ts)::smallint as samples,'
        '         max(active_count)::smallint as peak_backends'
        '  from ash.sample_%1$s'
        '  where (sample_ts / 60) * 60 >= $1'
        '  group by 1, 2'
        ') '
        'select count(*) '
        'from raw '
        'left join ash.rollup_1m as rollup_min '
        '  on rollup_min.ts = raw.ts and rollup_min.datid = raw.datid '
        'where rollup_min.ts is null '
        '   or rollup_min.samples < raw.samples '
        '   or rollup_min.peak_backends < raw.peak_backends',
        v_truncate_slot
      )
      into v_unrolled_groups
      using v_rollup_1m_cutoff;

      if v_unrolled_groups > 0 then
        perform ash._record_rotate_failure();
        return format(
          'failed: pre-truncation rollup incomplete for %s group(s) '
          'in slot %s; slot not truncated',
          v_unrolled_groups,
          v_truncate_slot
        );
      end if;
    end if;

    -- Advance current_slot first (before truncate).
    update ash.config
    set current_slot = v_new_slot,
      rotated_at = now(),
      consecutive_rotate_failures = 0
    where singleton;

    /*
     * Lockstep TRUNCATE: sample partition + matching query_map partition.
     * Zero bloat everywhere — no DELETE, no dead tuples, no GC needed.
     * Single statement with RESTART IDENTITY: one AccessExclusiveLock
     * acquisition pair per slot, and resets the query_map_N identity sequence
     * atomically (sample_N has no identity column, so it is unaffected).
     * Dynamic SQL for N-partition support.
     */
    execute format(
      'truncate ash.sample_%1$s, ash.query_map_%1$s restart identity',
      v_truncate_slot
    );

    return format(
      'rotated: slot %s -> %s, truncated slot %s (sample + query_map)',
      v_old_slot, v_new_slot, v_truncate_slot);

  exception when lock_not_available then
    perform ash._record_rotate_failure();
    return 'failed: lock timeout on partition truncate, will retry next cycle';
  when others then
    raise;
  end;
end;
$$;


/*
 * Rebuild partitions: destructive admin function to change partition count.
 * All raw sample data is lost. Rollup tables survive.
 * WARNING: failure after acquiring lock leaves sampling_enabled = false.
 * Manual recovery:
 *   update ash.config set sampling_enabled = true; select ash.start();
 */
create or replace function ash.rebuild_partitions(
  num_partitions int,
  confirm text default null
)
returns text
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_old_n int;
  v_new_n int;
  v_rec record;
  v_rotation_period interval;
  v_rollup_1m_retention_days int;
begin
  /*
   * Destructive: drops all raw sample partitions. Require explicit
   * confirmation BEFORE touching any state (sampling_enabled, pg_cron jobs,
   * partitions).
   */
  if confirm is distinct from 'yes' then
    raise exception 'rebuild_partitions is destructive — all raw sample data '
      'will be lost. To proceed, call: '
      'select ash.rebuild_partitions(%, ''yes'')', num_partitions;
  end if;

  select
    config_row.num_partitions,
    config_row.rotation_period,
    config_row.rollup_1m_retention_days
  into
    v_old_n,
    v_rotation_period,
    v_rollup_1m_retention_days
  from ash.config as config_row
  where config_row.singleton;
  v_new_n := coalesce(rebuild_partitions.num_partitions, v_old_n);

  if v_new_n < 3 or v_new_n > 32 then
    raise exception 'num_partitions must be between 3 and 32, got: %', v_new_n;
  end if;

  /*
   * Reject unsafe geometry before disabling sampling, changing cron jobs, or
   * touching partitions. The endangered slot is (num_partitions - 1)
   * rotation periods old, so its minute rollups must still be retained.
   */
  perform ash._validate_rotation_config(
    v_new_n,
    v_rotation_period,
    v_rollup_1m_retention_days
  );

  -- Step 1: mark sampling disabled. take_sample() checks this and returns
  -- early.
  update ash.config set sampling_enabled = false where singleton;

  -- Step 2: stop pg_cron jobs if available.
  if ash._pg_cron_available() then
    perform ash.stop();
  end if;

  /*
   * Step 3: acquire rebuild exclusive lock (two-key xact-level form).
   * All ash advisory locks share classid = hashtext('pg_ash')::int4. Each
   * kind gets its own objid. This makes the (classid, objid) pair
   * ash-specific and harder for an unrelated extension or a hostile session
   * to squat (using literal classid 0/1 was vulnerable). Xact-level:
   * auto-releases on commit/rollback — no manual unlock needed.
   */
  if not pg_try_advisory_xact_lock(
       hashtext('pg_ash')::int4,
       hashtext('pg_ash_rebuild')::int4
     ) then
    update ash.config set sampling_enabled = true where singleton;
    raise exception 'rebuild_partitions: could not acquire lock — '
      'another rebuild is in progress';
  end if;

  /*
   * Step 4: drain — wait up to 5s for in-flight take_sample / rollup_* /
   * rotate to release their ash advisory locks. STRICT drain: if anyone is
   * still holding a lock at the end of the budget, raise an exception
   * rather than proceeding to drop partitions out from under them. The
   * caller can retry. Drains every ash lock kind (sampler / rollup /
   * rotate) — anything that touches raw sample partitions OR rollup
   * tables we'd be about to invalidate.
   */
  declare
    v_drained boolean := false;
  begin
    for i in 1 .. 10 loop
      if not exists (
        select from pg_locks
        where locktype = 'advisory'
          and classid = hashtext('pg_ash')::int4::oid
          and objid in (
            hashtext('pg_ash_sampler')::int4::oid,
            hashtext('pg_ash_rollup')::int4::oid,
            hashtext('pg_ash_rotate')::int4::oid
          )
          and granted
          and pid <> pg_backend_pid()
      ) then
        v_drained := true;
        exit;
      end if;

      perform pg_sleep(0.5);
    end loop;

    if not v_drained then
      update ash.config set sampling_enabled = true where singleton;
      raise exception 'rebuild_partitions: drain timeout — in-flight '
        'sampler / rollup / rotate operations did not release within 5 s. '
        'Retry after they complete (or call ash.stop() first to halt the '
        'sampler).';
    end if;
  end;

  /*
   * Reuse the installer's #107 reader-bundle snapshot/replay mechanism
   * around this second drop/recreate path. Detect only complete, explicit
   * bundles: schema USAGE, per-overload EXECUTE, and SELECT on every reader
   * relation. Inherited privileges (including members of pg_monitor),
   * function-only manual grants, and superuser bypass must not be widened
   * into direct grants. Replaying pg_monitor itself restores access for all
   * of its members.
   */
  drop table if exists pg_temp._ash_install_reader_roles;
  create temp table _ash_install_reader_roles (
    rolname name primary key
  );
  insert into pg_temp._ash_install_reader_roles (rolname)
  select grantee_role.rolname
  from pg_catalog.pg_roles as grantee_role
  where exists (
    select
    from pg_catalog.pg_proc as proc
    join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
    cross join lateral aclexplode(proc.proacl) as acl
    where nsp.nspname = 'ash'
      and proc.prokind = 'f'
      and acl.privilege_type = 'EXECUTE'
      and acl.grantee = grantee_role.oid
      and acl.grantee <> proc.proowner
  )
    and exists (
      select
      from pg_catalog.pg_namespace as nsp
      cross join lateral aclexplode(nsp.nspacl) as acl
      where nsp.nspname = 'ash'
        and acl.privilege_type = 'USAGE'
        and acl.grantee = grantee_role.oid
        and acl.grantee <> nsp.nspowner
    )
    and not exists (
      select
      from pg_catalog.pg_proc as proc
      join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
      where nsp.nspname = 'ash'
        and proc.prokind = 'f'
        and proc.proname::text <> all (ash._admin_funcs())
        and not exists (
          select
          from aclexplode(proc.proacl) as acl
          where acl.privilege_type = 'EXECUTE'
            and acl.grantee = grantee_role.oid
            and acl.grantee <> proc.proowner
        )
    )
    and not exists (
      select
      from pg_catalog.pg_class as rel
      join pg_catalog.pg_namespace as nsp on rel.relnamespace = nsp.oid
      where nsp.nspname = 'ash'
        and (
          rel.relname in (
            'sample', 'query_map_all', 'config', 'wait_event_map',
            'rollup_1m', 'rollup_1h'
          )
          or rel.relname ~ '^query_map_[0-9]+$'
          or rel.relname ~ '^sample_[0-9]+$'
        )
        and not exists (
          select
          from aclexplode(rel.relacl) as acl
          where acl.privilege_type = 'SELECT'
            and acl.grantee = grantee_role.oid
            and acl.grantee <> rel.relowner
        )
    );

  -- Step 5: drop the query_map_all view first (depends on query_map tables).
  drop view if exists ash.query_map_all;

  -- Drop ALL existing sample partitions and query_maps.
  -- Uses catalog enumeration to catch orphaned tables.
  perform ash._drop_all_partitions();

  -- Step 6: update config.
  update ash.config
  set num_partitions = v_new_n,
    current_slot = 0,
    rotated_at = now()
  where singleton;

  -- Step 7: create new partitions.
  for i in 0 .. v_new_n - 1 loop
    execute format(
      'create table ash.sample_%s '
      'partition of ash.sample for values in (%s)', i, i
    );

    execute format(
      'create table ash.query_map_%s ('
      '  id       int4 primary key generated always as identity (start with 1),'
      '  query_id int8 not null unique'
      ')', i
    );

    execute format(
      'create index sample_%s_ts_idx on ash.sample_%s (sample_ts)', i, i
    );

    execute format(
      'create index sample_%s_datid_ts_idx on ash.sample_%s (datid, sample_ts)',
      i, i
    );
  end loop;

  -- Step 8: rebuild the query_map_all view.
  perform ash._rebuild_query_map_view();

  /*
   * Restore each complete reader bundle only after the view and every child
   * table exist, so grant_reader() covers the entire replacement object set.
   */
  for v_rec in
    select reader_role.rolname
    from pg_temp._ash_install_reader_roles as reader_role
    join pg_catalog.pg_roles as role_row
      on role_row.rolname = reader_role.rolname
    order by reader_role.rolname
  loop
    perform ash.grant_reader(v_rec.rolname);
  end loop;
  drop table pg_temp._ash_install_reader_roles;

  /*
   * Step 9: leave sampling DISABLED. User must explicitly call ash.start() to
   * resume. Prevents accidental data collection into a partially-built schema.
   */
  return format(
    'rebuilt: %s -> %s partitions. all raw data cleared. '
    'call ash.start() to resume sampling.',
    v_old_n, v_new_n
  );
end;
$$;


--------------------------------------------------------------------------------
-- STEP 4: Start/stop/uninstall functions
--------------------------------------------------------------------------------

-- Check if pg_cron extension is available
create or replace function ash._pg_cron_available()
returns boolean
language sql
stable
set search_path = pg_catalog, ash
as $$
  select exists (
    select from pg_extension where extname = 'pg_cron'
  )
$$;

-- Start sampling: create pg_cron jobs
create or replace function ash.start(every interval default '1 second')
returns table (job_type text, job_id bigint, status text)
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_sampler_job bigint;
  v_rotation_job bigint;
  v_cron_version text;
  v_seconds_exact numeric;
  v_seconds int;
  v_hours int;
  v_schedule text;
  v_skip_nodename_update boolean := false;
  v_debug_logging boolean := false;
  v_pg_cron_available boolean;
  v_cron_database text;
begin
  /*
   * Read debug_logging flag so we can trace the pg_cron detection /
   * scheduling path when ash.start() appears to no-op. Treat an error here as
   * "debug off" so ash.start() still works in half-installed / upgrading
   * states.
   */
  begin
    select debug_logging into v_debug_logging from ash.config where singleton;
  exception when others then
    v_debug_logging := false;
  end;

  -- Validate interval.
  if every is null then
    job_type := 'error';
    job_id := null;
    status := 'interval must not be null';
    return next;
    return;
  end if;

  v_seconds_exact := extract(epoch from every);
  if v_seconds_exact < 1 then
    job_type := 'error';
    job_id := null;
    status := format('interval must be at least 1 second, got %s', every);
    return next;
    return;
  end if;

  /*
   * pg_cron schedules whole seconds. Validate the exact numeric epoch before
   * converting to int: PostgreSQL rounds numeric-to-int casts, which used to
   * accept e.g. 0.6s/59.6s while storing the fractional interval in config.
   * That made the real schedule disagree with the cadence used by AAS math.
   */
  if v_seconds_exact <> trunc(v_seconds_exact) then
    job_type := 'error';
    job_id := null;
    status := format(
      'interval must be an exact whole number of seconds, got %s', every);
    return next;
    return;
  end if;

  /* Check the upper bound before the int cast so huge intervals stay errors. */
  if v_seconds_exact > 82800 then
    job_type := 'error';
    job_id := null;
    status := format(
      'interval exceeds maximum 23 hours (82800s), got %s. '
      'Use days or shorter interval.', every);
    return next;
    return;
  end if;

  v_seconds := v_seconds_exact::int;

  /*
   * H-BUG-1: validate interval shape BEFORE branching on pg_cron
   * availability. Previously, the no-pg_cron branch returned early (below),
   * skipping the seconds/minutes/hours checks. Same input must produce the
   * same accept/reject outcome regardless of whether pg_cron is installed.
   *
   * Build schedule string here (also used later when pg_cron is available):
   * seconds format for <60s, cron format for 60s+.
   */
  if v_seconds <= 59 then
    v_schedule := v_seconds || ' seconds';
  elsif v_seconds < 3600 then
    -- Convert to cron: every N minutes.
    if v_seconds % 60 <> 0 then
      job_type := 'error';
      job_id := null;
      status := format(
        'interval must be exact minutes (60s, 120s, etc.), got %s', every);
      return next;
      return;
    end if;
    v_schedule := '*/' || (v_seconds / 60) || ' * * * *';
  else
    -- Convert to cron: every N hours (limit to 23 hours max for step syntax).
    if v_seconds % 3600 <> 0 then
      job_type := 'error';
      job_id := null;
      status := format(
        'interval must be exact hours (3600s, 7200s, etc., up to 23h), '
        'got %s', every);
      return next;
      return;
    end if;
    v_hours := v_seconds / 3600;
    if v_hours = 1 then
      v_schedule := '0 * * * *';  -- every hour at minute 0
    else
      v_schedule := '0 */' || v_hours || ' * * *';  -- every N hours at minute 0
    end if;
  end if;

  /*
   * Privilege check: without pg_read_all_stats (or superuser), query_id is
   * hidden for activity owned by other roles and collapses to the sentinel 0,
   * silently skewing ash.top('query_id') and every query-attributed reader
   * (ash.samples, ash.report top_queryids_*).
   */
  begin
    if not (
      (select rolsuper from pg_roles where rolname = current_user)
      or pg_has_role(current_user, 'pg_read_all_stats', 'MEMBER')
    ) then
      raise notice
        'warning: role % is not a superuser and not a member of '
        'pg_read_all_stats.', current_user;
      raise notice
        '  query_id will be NULL for activity owned by other roles and '
        'bucketed under 0,';
      raise notice
        '  skewing ash.top(''query_id'') / ash.top(''wait_event'', '
        'query_id => ...). Fix: grant pg_read_all_stats to %;', current_user;
    end if;
  exception when others then
    -- Don't let the privilege probe block ash.start(), but surface the failure.
    raise notice 'privilege probe failed: %', sqlerrm;
  end;

  v_pg_cron_available := ash._pg_cron_available();
  if v_debug_logging then
    raise log 'ash.start: pg_cron_available=% interval=% seconds=%',
      v_pg_cron_available, every, v_seconds;
  end if;

  /*
   * If pg_cron is not available, just record the interval and advise on
   * external scheduling.
   */
  if not v_pg_cron_available then
    update ash.config
    set sample_interval = every,
      sampling_enabled = true,
      skipped_samples = 0
    where singleton;

    job_type := 'sampler';
    job_id := null;
    status := format(
      'interval set to %s — schedule externally (pg_cron not available)',
      every);
    return next;

    job_type := 'rotation';
    job_id := null;
    status := format(
      'rotation_period is %s — schedule ash.rotate() externally',
      (select rotation_period from ash.config where singleton));
    return next;

    job_type := 'rollup';
    job_id := null;
    status :=
      'schedule ash.rollup_minute() every minute, ash.rollup_hour() '
      'at minute 1 every hour, ash.rollup_cleanup() daily';
    return next;

    raise notice
      'pg_cron is not available in this database. To sample, call '
      'ash.take_sample() from an external scheduler:';
    v_cron_database :=
      nullif(current_setting('cron.database_name', true), '');
    if v_cron_database is null then
      raise notice
        '  hint: current_setting(''cron.database_name'', true) is not set; '
        'configure pg_cron for this database or use the external scheduler below';
    elsif v_cron_database <> current_database() then
      raise notice
        '  hint: current_setting(''cron.database_name'', true) = %; install '
        'pg_ash in that database to use pg_cron scheduling.',
        v_cron_database;
    else
      raise notice
        '  hint: current_setting(''cron.database_name'', true) = % names this '
        'database, but pg_cron is unavailable here; install or configure '
        'pg_cron here, or use the external scheduler below.',
        v_cron_database;
    end if;
    raise notice
      '  system cron:    * * * * * psql -qAtX -c '
      '"select ash.take_sample()" (for per-second, use a loop)';
    raise notice '  psql:           SELECT ash.take_sample() \watch 1';
    raise notice
      '  any language:   execute "SELECT ash.take_sample()" in a loop '
      'with sleep';
    raise notice
      'Also schedule ash.rotate() at the rotation_period interval '
      '(default: daily).';
    raise notice
      'Schedule rollup: ash.rollup_minute() every minute, '
      'ash.rollup_hour() at minute 1 every hour, '
      'ash.rollup_cleanup() daily.';

    return;
  end if;

  -- Check pg_cron version (need >= 1.5 for sub-minute scheduling).
  select extversion into v_cron_version
  from pg_extension where extname = 'pg_cron';

  /*
   * M-BUG-8: defend against malformed extversion. If regexp_replace() strips
   * everything (e.g. extversion is 'dev', empty, or starts with '.'),
   * string_to_array(...)::int[] raises 'invalid input syntax for type
   * integer' and bubbles up as a crash. Require a leading MAJOR.MINOR pattern
   * before parsing; if it doesn't match, assume a modern pg_cron (>= 1.5)
   * rather than failing the call.
   */
  if v_cron_version ~ '^\d+\.\d+' then
    begin
      if string_to_array(
           regexp_replace(v_cron_version, '[^0-9.]', '', 'g'), '.'
         )::int[] < '{1,5}'::int[] then
        if v_seconds < 60 then
          job_type := 'error';
          job_id := null;
          status := format(
            'pg_cron version %s too old for sub-minute scheduling '
            '(need >= 1.5). Use external scheduler or upgrade pg_cron.',
            v_cron_version);
          return next;
          return;
        end if;
      end if;
    exception when others then
      -- Unparseable version — assume modern pg_cron (>= 1.5) and proceed.
      raise notice
        'ash.start: could not parse pg_cron version "%" — '
        'assuming modern (>= 1.5)', v_cron_version;
    end;
  else
    raise notice
      'ash.start: unrecognized pg_cron version "%" — '
      'assuming modern (>= 1.5)', v_cron_version;
  end if;

  /*
   * Detect whether we need to UPDATE cron.job.nodename after scheduling.
   * Skip when cron.use_background_workers = on (nodename irrelevant)
   * or cron.host is already '' or a socket path (cron.schedule() inherits it).
   */
  begin
    v_skip_nodename_update :=
      coalesce(current_setting('cron.use_background_workers', true), '') = 'on'
      or coalesce(current_setting('cron.host', true), 'localhost') = ''
      or coalesce(current_setting('cron.host', true), 'localhost') like '/%';
  exception when others then
    v_skip_nodename_update := false;
  end;

  /*
   * (schedule string v_schedule already built above, before the pg_cron
   * availability branch — see H-BUG-1 fix.)
   */

  -- Check for existing sampler job (idempotent).
  select jobid into v_sampler_job
  from cron.job
  where jobname = 'ash_sampler';

  if v_sampler_job is not null then
    /*
     * H-BUG-2: re-sync the pg_cron schedule when the job already exists.
     * Previously ash.start(new_interval) updated ash.config.sample_interval
     * (further below) but never touched cron.job.schedule, so pg_cron kept
     * firing at the old cadence — a silent behavioral divergence between
     * configured and actual sampling rate.
     */
    perform cron.alter_job(job_id := v_sampler_job, schedule := v_schedule);
    job_type := 'sampler';
    job_id := v_sampler_job;
    status := format('already exists — schedule updated to %s', v_schedule);
    return next;
  else
    -- Create sampler job.
    select cron.schedule(
      'ash_sampler',
      v_schedule,
      'set statement_timeout = ''500ms''; select ash.take_sample()'
    ) into v_sampler_job;

    /*
     * Clear nodename so pg_cron uses Unix socket instead of TCP.
     * cron.schedule() sets nodename from cron.host GUC (default 'localhost'),
     * which forces TCP and fails when pg_hba.conf only allows sockets.
     * Skipped when cron.use_background_workers = on (no libpq connections)
     * or cron.host is already '' / a socket path (already correct).
     */
    if not v_skip_nodename_update then
      update cron.job set nodename = '' where jobid = v_sampler_job;
    end if;

    if v_debug_logging then
      raise log
        'ash.start: scheduled ash_sampler jobid=% schedule=% '
        'skip_nodename_update=%',
        v_sampler_job, v_schedule, v_skip_nodename_update;
    end if;

    job_type := 'sampler';
    job_id := v_sampler_job;
    status := 'created';
    return next;
  end if;

  -- Check for existing rotation job (idempotent)
  select jobid into v_rotation_job
  from cron.job
  where jobname = 'ash_rotation'
    and username = current_user
    and database = current_database();

  if v_rotation_job is not null then
    /*
     * The supported rotation contract is day-granular. Repair any manually
     * drifted or legacy sub-day cron expression on every idempotent start.
     */
    perform cron.alter_job(
      job_id := v_rotation_job,
      schedule := '0 0 * * *'
    );
    job_type := 'rotation';
    job_id := v_rotation_job;
    status := 'already exists — schedule reset to 0 0 * * *';
    return next;
  else
    -- Create rotation job (daily at midnight UTC).
    select cron.schedule(
      'ash_rotation',
      '0 0 * * *',
      'select ash.rotate()'
    ) into v_rotation_job;

    if not v_skip_nodename_update then
      update cron.job set nodename = '' where jobid = v_rotation_job;
    end if;

    job_type := 'rotation';
    job_id := v_rotation_job;
    status := 'created';
    return next;
  end if;

  -- Schedule rollup cron jobs (idempotent: unschedule first).
  -- rollup_minute: every minute.
  begin
    perform cron.unschedule('ash_rollup_1m');
  exception when others then
    null;
  end;

  select cron.schedule(
    'ash_rollup_1m',
    '* * * * *',
    'select ash.rollup_minute()'
  ) into v_rotation_job; -- reuse variable for job id

  if not v_skip_nodename_update then
    update cron.job set nodename = '' where jobid = v_rotation_job;
  end if;

  job_type := 'rollup_1m';
  job_id := v_rotation_job;
  status := 'created';
  return next;

  -- rollup_hour: every hour at minute 1; its blocking shared lock sequences it
  -- after any in-flight minute rollup before it checks the minute watermark.
  begin
    perform cron.unschedule('ash_rollup_1h');
  exception when others then
    null;
  end;

  select cron.schedule(
    'ash_rollup_1h',
    '1 * * * *',
    'select ash.rollup_hour()'
  ) into v_rotation_job;

  if not v_skip_nodename_update then
    update cron.job set nodename = '' where jobid = v_rotation_job;
  end if;

  job_type := 'rollup_1h';
  job_id := v_rotation_job;
  status := 'created';
  return next;

  -- rollup_cleanup: daily at 03:00 UTC
  begin
    perform cron.unschedule('ash_rollup_gc');
  exception when others then
    null;
  end;

  select cron.schedule(
    'ash_rollup_gc',
    '0 3 * * *',
    'select ash.rollup_cleanup()'
  ) into v_rotation_job;

  if not v_skip_nodename_update then
    update cron.job set nodename = '' where jobid = v_rotation_job;
  end if;

  job_type := 'rollup_gc';
  job_id := v_rotation_job;
  status := 'created';
  return next;

  -- Update sample_interval, enable sampling, reset skip counter.
  update ash.config
  set sample_interval = every,
    sampling_enabled = true,
    skipped_samples = 0
  where singleton;

  /*
   * Warn about pg_cron run history overhead.
   * At 1s sampling, cron.job_run_details grows ~12 MiB/day unbounded.
   * pg_cron has no built-in purge — only cron.log_run = off (disables
   * entirely).
   */
  begin
    if current_setting('cron.log_run', true)::bool then
      raise notice
        'hint: pg_cron logs every sample to cron.job_run_details '
        '(~12 MiB/day).';
      raise notice
        'to disable: alter system set cron.log_run = off; '
        'select pg_reload_conf();';
      raise notice
        'or schedule periodic cleanup: delete from cron.job_run_details '
        'where end_time < now() - interval ''1 day'';';
    end if;
  exception when others then
    null; -- GUC not available
  end;

  return;
end;
$$;

-- Stop sampling: remove pg_cron jobs, disable sampling.
create or replace function ash.stop()
returns table (job_type text, job_id bigint, status text)
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_job_id bigint;
begin
  -- Mark sampling as disabled.
  update ash.config set sampling_enabled = false where singleton;

  -- If pg_cron is not available, just remind about external scheduler.
  if not ash._pg_cron_available() then
    job_type := 'info';
    job_id := null;
    status :=
      'pg_cron not installed — remember to stop your external scheduler '
      '(cron, systemd timer, loop script, etc.)';
    return next;
    return;
  end if;

  -- Remove sampler job.
  select jobid into v_job_id
  from cron.job
  where jobname = 'ash_sampler';

  if v_job_id is not null then
    perform cron.unschedule('ash_sampler');
    job_type := 'sampler';
    job_id := v_job_id;
    status := 'removed';
    return next;
  end if;

  -- Remove rotation job
  select jobid into v_job_id
  from cron.job
  where jobname = 'ash_rotation';

  if v_job_id is not null then
    perform cron.unschedule('ash_rotation');
    job_type := 'rotation';
    job_id := v_job_id;
    status := 'removed';
    return next;
  end if;

  -- Remove rollup jobs (idempotent — tolerate missing jobs).
  begin
    perform cron.unschedule('ash_rollup_1m');
    job_type := 'rollup_1m';
    job_id := null;
    status := 'removed';
    return next;
  exception when others then
    null;
  end;

  begin
    perform cron.unschedule('ash_rollup_1h');
    job_type := 'rollup_1h';
    job_id := null;
    status := 'removed';
    return next;
  exception when others then
    null;
  end;

  begin
    perform cron.unschedule('ash_rollup_gc');
    job_type := 'rollup_gc';
    job_id := null;
    status := 'removed';
    return next;
  exception when others then
    null;
  end;

  return;
end;
$$;

/*
 * Enable or disable debug logging in take_sample().
 * When enabled, every sampled session emits a RAISE LOG message:
 *   ash.take_sample: pid=NNN state=active wait_type=Client
 *   wait_event=ClientRead ...
 *
 * RAISE LOG goes to the server log only — never to the client.
 * It is independent of log_min_messages and client_min_messages.
 *
 * Usage:
 *   select ash.set_debug_logging(true);   -- enable
 *   select ash.set_debug_logging(false);  -- disable
 *   select ash.set_debug_logging();       -- show current state
 */
create or replace function ash.set_debug_logging(enabled bool default null)
returns text
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_current bool;
begin
  select debug_logging into v_current from ash.config where singleton;

  if enabled is null then
    return 'debug_logging = ' || v_current::text;
  end if;

  update ash.config set debug_logging = enabled where singleton;

  if enabled then
    return 'debug_logging enabled — each sampled session will emit RAISE LOG';
  else
    return 'debug_logging disabled';
  end if;
end;
$$;

-- Uninstall: stop jobs and drop schema.
create or replace function ash.uninstall(confirm text default null)
returns text
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_rec record;
  v_jobs_removed int := 0;
begin
  if confirm is distinct from 'yes' then
    raise exception 'to uninstall pg_ash, call: select ash.uninstall(''yes'')';
  end if;

  -- Stop pg_cron jobs first.
  for v_rec in select * from ash.stop() loop
    if v_rec.status = 'removed' then
      v_jobs_removed := v_jobs_removed + 1;
    end if;
  end loop;

  -- Drop the schema.
  drop schema ash cascade;

  return format(
    'uninstalled: removed %s pg_cron jobs, dropped ash schema', v_jobs_removed);
end;
$$;


--------------------------------------------------------------------------------
-- STEP 5: Reader and diagnostic functions
--------------------------------------------------------------------------------

-- Helper to get every raw slot retained by the configured partition ring.
create or replace function ash._active_slots()
returns smallint[]
language sql
stable
set search_path = pg_catalog, ash
as $$
  select array(
    select
      ((config_row.current_slot - slot_offset.i
        + config_row.num_partitions) % config_row.num_partitions)::smallint
    from generate_series(
      0, config_row.num_partitions - 2
    ) as slot_offset(i)
    order by slot_offset.i
  )
  from ash.config as config_row
  where singleton
$$;

/*
 * Helper used by reader functions that accept a user-supplied interval.
 * Returns every raw slot still retained by the configured N-partition ring.
 * For intervals beyond (num_partitions - 2) * rotation_period, returns an
 * empty array so reader `slot = any(...)` JOINs naturally yield zero rows —
 * honoring the NOTICE's "older samples not available" promise (and avoiding
 * the int4-epoch underflow that would otherwise raise `integer out of
 * range`). A single NOTICE is emitted per transaction in that case so callers
 * get a clear signal instead of a silent empty set.
 * Deduplication uses a transaction-scoped GUC (ash.notice_oversized) so
 * multi-query readers (e.g. activity_summary) don't spam the log with one
 * NOTICE per partition/sub-query.
 *
 * NB: distinct name (not an overload of ash._active_slots()) because the
 * upgrade scripts re-create the zero-arg form on idempotent re-apply; an
 * overloaded pair would make bare ash._active_slots() ambiguous.
 */
create or replace function ash._active_slots_for(lookback interval)
returns smallint[]
language plpgsql
stable
set search_path = pg_catalog, ash
as $$
declare
  v_current_slot smallint;
  v_num_partitions smallint;
  v_rotation_period interval;
  v_raw_retention interval;
  v_already text;
begin
  select current_slot, num_partitions, rotation_period
    into v_current_slot, v_num_partitions, v_rotation_period
  from ash.config
  where singleton;

  v_raw_retention := (v_num_partitions - 2) * v_rotation_period;

  -- Negative interval is meaningless and would underflow `now() - lookback`
  -- past the int4 horizon downstream. Treat as out-of-window.
  if lookback is not null and lookback < interval '0' then
    v_already := current_setting('ash.notice_oversized', true);
    if v_already is null or v_already = '' then
      raise notice
        'requested interval % is negative; nothing to retrieve.',
        lookback;
      perform set_config('ash.notice_oversized', '1', true);
    end if;
    return array[]::smallint[];
  end if;

  if lookback is not null and lookback > v_raw_retention then
    -- Suppress duplicate NOTICEs within the same transaction. The GUC is
    -- set local to the current transaction and auto-resets on commit/rollback.
    v_already := current_setting('ash.notice_oversized', true);
    if v_already is null or v_already = '' then
      raise notice
        'requested interval % exceeds raw retention (%); only % completed '
        'partition(s) plus the current partial partition are retained. '
        'Shorten the interval, increase rotation_period, or rebuild with '
        'more partitions.',
        lookback, v_raw_retention, v_num_partitions - 2;
      perform set_config('ash.notice_oversized', '1', true);
    end if;
    /*
     * Honor the NOTICE: return no slots so reader JOINs (`slot = any(...)`)
     * yield empty. Without this, an absurd interval like '1000 years' clamps
     * v_min_ts to 0 and matches every retained sample, contradicting the
     * "older samples not available" promise. Callers wanting all retained
     * data should pass an interval <= raw_retention.
     */
    return array[]::smallint[];
  end if;

  /*
   * Slot enumeration must use the configured num_partitions and include every
   * retained raw slot, not just current+previous. Readers still filter by
   * sample_ts; the slot list only keeps the partition-pruning contract honest.
   */
  return array(
    select
      ((v_current_slot - slot_offset.i + v_num_partitions)
        % v_num_partitions)::smallint
    from generate_series(0, v_num_partitions - 2) as slot_offset(i)
    order by slot_offset.i
  );
end;
$$;

/*
 * Absolute-range counterpart to ash._active_slots_for(interval), used by
 * every _at reader (top_waits_at, samples_at, query_waits_at, etc.). Returns
 * the active slot set when the requested [since, until) range overlaps the
 * logical raw-retention boundary, and an empty array with a NOTICE when it
 * doesn't — restoring loud-warn
 * symmetry with the relative readers (#69). Without this, _at readers silently
 * returned 0 rows on absurd inputs (year 1000, year 3000) thanks to
 * ts_from_timestamptz()'s int4 clamp (#63), which was a UX regression vs the
 * interval path.
 *
 * Out-of-retention conditions (each emits the NOTICE and returns {}):
 *   * until   <= raw_retention_start (range entirely too old)
 *   * since >  now()                  (range entirely in the future)
 *
 * Importantly, an empty range (since >= until) inside the retained window
 * is NOT flagged — callers may legitimately ask for a zero-length window and
 * a NOTICE would be noise. Likewise nulls are passed through silently; the
 * reader's own WHERE clause filters them out as unknown comparisons.
 *
 * Shares the ash.notice_oversized transaction-scoped GUC with
 * _active_slots_for(interval) so multi-call readers (and the relative wrapper
 * chain delegating into _at) don't spam one NOTICE per sub-query.
 *
 * Readers must invoke this helper into a local variable in plpgsql (not as a
 * predicate inside language=sql bodies) — otherwise the planner can fold the
 * accompanying time predicate to false and skip the call entirely, losing the
 * NOTICE side-effect. See top_waits_at and friends for the established
 * pattern.
 */
create or replace function ash._active_slots_for_at(
  since timestamptz,
  until   timestamptz
)
returns smallint[]
language plpgsql
stable
set search_path = pg_catalog, ash
as $$
declare
  v_current_slot    smallint;
  v_num_partitions  smallint;
  v_rotation_period interval;
  v_rotated_at      timestamptz;
  v_now             timestamptz := now();
  v_raw_retention   interval;
  v_retention_start timestamptz;
  v_already         text;
begin
  select current_slot, num_partitions, rotation_period, rotated_at
    into v_current_slot, v_num_partitions, v_rotation_period, v_rotated_at
  from ash.config
  where singleton;

  v_raw_retention := (v_num_partitions - 2) * v_rotation_period;
  /*
   * Use the same stable, minute-aligned planning boundary as status() and the
   * tie guard. Delayed rotation can leave readable evidence older than the
   * nominal ring horizon, so never reject it: the usable boundary is the older
   * of physical coverage and configured capacity. With no samples, retain the
   * geometry fallback solely for the historical out-of-range NOTICE.
   */
  v_retention_start := coalesce(
    ash._raw_retention_start(),
    ash.ts_to_timestamptz(
      ash.ts_from_timestamptz(
        date_trunc('minute', v_rotated_at - v_raw_retention)
      )
    )
  );

  /*
   * Out-of-retention check. Skip when either bound is null (the reader's
   * own WHERE will yield empty without us needing to NOTICE) or when the
   * range is empty inside retention (legitimate degenerate query).
   */
  if since is not null and until is not null
     and (until <= v_retention_start or since > v_now) then
    v_already := current_setting('ash.notice_oversized', true);
    if v_already is null or v_already = '' then
      raise notice
        'requested range [%, %) lies outside the retained window '
        '(raw_retention_start .. now, i.e. [%, %)); only % completed '
        'partition(s) plus the current partial partition are retained. '
        'Adjust the range, increase rotation_period, or rebuild with more '
        'partitions.',
        since, until, v_retention_start, v_now, v_num_partitions - 2;
      perform set_config('ash.notice_oversized', '1', true);
    end if;
    return array[]::smallint[];
  end if;

  return array(
    select
      ((v_current_slot - slot_offset.i + v_num_partitions)
        % v_num_partitions)::smallint
    from generate_series(0, v_num_partitions - 2) as slot_offset(i)
    order by slot_offset.i
  );
end;
$$;

-- Status: diagnostic dashboard
create or replace function ash.status()
returns table (
  metric text,
  value text
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_config record;
  v_last_sample_ts int4;
  v_samples_current int;
  v_samples_total int;
  v_wait_events int;
  v_query_ids int;
  v_rollup_1m_rows bigint;
  v_rollup_1h_rows bigint;
  v_rollup_1m_oldest int4;
  v_rollup_1m_newest int4;
  v_rollup_1h_oldest int4;
  v_rollup_1h_newest int4;
begin
  -- Get config
  select * into v_config from ash.config where singleton;

  -- Last sample timestamp
  select max(sample_ts) into v_last_sample_ts from ash.sample;

  -- Samples in current partition
  select count(*) into v_samples_current
  from ash.sample where slot = v_config.current_slot;

  -- Total samples
  select count(*) into v_samples_total from ash.sample;

  -- Dictionary sizes
  select count(*) into v_wait_events from ash.wait_event_map;
  select count(*) into v_query_ids from ash.query_map_all;

  -- Rollup stats (handle tables not yet existing during upgrade)
  begin
    select count(*), min(ts), max(ts)
    into v_rollup_1m_rows, v_rollup_1m_oldest, v_rollup_1m_newest
    from ash.rollup_1m;

    select count(*), min(ts), max(ts)
    into v_rollup_1h_rows, v_rollup_1h_oldest, v_rollup_1h_newest
    from ash.rollup_1h;
  exception when undefined_table then
    v_rollup_1m_rows := 0;
    v_rollup_1h_rows := 0;
  end;

  metric := 'version'; value := coalesce(v_config.version, '1.0'); return next;
  metric := 'color';
  value := case when ash._color_on() then 'on' else 'off' end;
  return next;
  metric := 'num_partitions'; value := v_config.num_partitions::text; return next;
  metric := 'sampling_enabled'; value := v_config.sampling_enabled::text; return next;
  metric := 'skipped_samples'; value := v_config.skipped_samples::text; return next;
  metric := 'current_slot'; value := v_config.current_slot::text; return next;
  metric := 'sample_interval'; value := v_config.sample_interval::text; return next;
  metric := 'rotation_period'; value := v_config.rotation_period::text; return next;
  metric := 'rotation_period_contract';
  value := 'day-granular; minimum 1 day';
  return next;
  metric := 'raw_retention';
  value := ((v_config.num_partitions - 2) * v_config.rotation_period)::text
    || ' + current partial';
  return next;
  metric := 'include_bg_workers'; value := v_config.include_bg_workers::text; return next;
  metric := 'debug_logging'; value := v_config.debug_logging::text; return next;
  metric := 'missed_samples'; value := v_config.missed_samples::text; return next;
  /*
   * M-BUG-4: surface the counter of rows dropped by take_sample()'s inner
   * exception handler (CHECK violations and similar). Non-zero = silent
   * data loss occurred — check server log for the matching WARNINGs.
   */
  metric := 'insert_errors'; value := v_config.insert_errors::text; return next;
  metric := 'installed_at'; value := v_config.installed_at::text; return next;
  metric := 'rotated_at'; value := v_config.rotated_at::text; return next;
  metric := 'time_since_rotation';
  value := (now() - v_config.rotated_at)::text;
  return next;
  metric := 'consecutive_rotate_failures';
  value := v_config.consecutive_rotate_failures::text;
  return next;

  if v_last_sample_ts is not null then
    metric := 'last_sample_ts';
    value := ash.ts_to_timestamptz(v_last_sample_ts)::text;
    return next;
    metric := 'time_since_last_sample';
    value := (now() - ash.ts_to_timestamptz(v_last_sample_ts))::text;
    return next;
  else
    metric := 'last_sample_ts'; value := 'no samples'; return next;
  end if;

  metric := 'samples_in_current_slot'; value := v_samples_current::text; return next;
  metric := 'samples_total'; value := v_samples_total::text; return next;
  metric := 'wait_event_map_count'; value := v_wait_events::text; return next;
  /*
   * M-BUG-6 / H-SEC-3: denominator tracks the 32 000 cap enforced in
   * _register_wait (stays within smallint's 32 767 ceiling so we don't
   * have to widen the id column / function signature).
   */
  metric := 'wait_event_map_utilization';
  value := round(v_wait_events::numeric / 32000 * 100, 2)::text || '%';
  return next;
  metric := 'register_wait_cap_hits';
  value := v_config.register_wait_cap_hits::text;
  return next;
  metric := 'query_map_count'; value := v_query_ids::text; return next;

  -- Rollup metrics
  metric := 'rollup_1m_rows'; value := coalesce(v_rollup_1m_rows, 0)::text; return next;

  if v_rollup_1m_oldest is not null then
    metric := 'rollup_1m_oldest';
    value := ash.ts_to_timestamptz(v_rollup_1m_oldest)::text;
    return next;
    metric := 'rollup_1m_newest';
    value := ash.ts_to_timestamptz(v_rollup_1m_newest)::text;
    return next;
  end if;

  metric := 'rollup_1m_retention';
  value := v_config.rollup_1m_retention_days || ' days';
  return next;
  metric := 'rollup_1h_rows'; value := coalesce(v_rollup_1h_rows, 0)::text; return next;

  if v_rollup_1h_oldest is not null then
    metric := 'rollup_1h_oldest';
    value := ash.ts_to_timestamptz(v_rollup_1h_oldest)::text;
    return next;
    metric := 'rollup_1h_newest';
    value := ash.ts_to_timestamptz(v_rollup_1h_newest)::text;
    return next;
  end if;

  metric := 'rollup_1h_retention';
  value := v_config.rollup_1h_retention_days || ' days';
  return next;

  if v_config.last_rollup_1m_ts is not null then
    metric := 'last_rollup_1m_ts';
    value := ash.ts_to_timestamptz(v_config.last_rollup_1m_ts)::text;
    return next;
  end if;

  if v_config.last_rollup_1h_ts is not null then
    metric := 'last_rollup_1h_ts';
    value := ash.ts_to_timestamptz(v_config.last_rollup_1h_ts)::text;
    return next;
  end if;

  /*
   * Retention-start boundaries (2.0): raw_retention_start is the reusable,
   * minute-aligned loss boundary (the older of ring capacity and retained
   * evidence); rollup starts are their physical oldest rows. Callers can plan
   * windows before querying. NULL when the source holds no data yet.
   */
  metric := 'raw_retention_start';
  value := coalesce(ash._raw_retention_start()::text, 'no samples'); return next;
  metric := 'rollup_1m_retention_start';
  value := coalesce(ash._rollup_1m_retention_start()::text, 'no rollups'); return next;
  metric := 'rollup_1h_retention_start';
  value := coalesce(ash._rollup_1h_retention_start()::text, 'no rollups'); return next;

  /*
   * Epoch overflow horizon (issue #37): sample_ts is int4 seconds since
   * 2026-01-01 UTC and int4 is exhausted circa 2094-01-19 — at which point
   * the ::int4 cast in take_sample() raises ERROR and sampling hard-fails
   * (no silent wrap). Surface remaining seconds so operators can plan the
   * bigint migration well before the horizon. Value goes negative past the
   * horizon (by design — indicates how long ago sampling would have stopped).
   */
  metric := 'epoch_seconds_remaining';
  value := (
    2147483647::bigint - extract(epoch from (now() - ash.epoch()))::bigint
  )::text;
  return next;

  -- pg_cron status if available.
  if ash._pg_cron_available() then
    metric := 'pg_cron_available'; value := 'yes'; return next;
    /*
     * Issue #61: cron.job is owned by the pg_cron extension and requires
     * USAGE on schema cron + SELECT on cron.job. Monitoring roles granted
     * only ash.* readers will hit insufficient_privilege here, which used
     * to abort status() entirely. Catch and surface a single fallback row
     * so operators can see *why* cron details are missing.
     */
    begin
      for metric, value in
        select 'cron_job_' || jobname,
           format('id=%s, schedule=%s, active=%s', jobid, schedule, active)
        from cron.job
        where jobname in (
          'ash_sampler', 'ash_rotation',
          'ash_rollup_1m', 'ash_rollup_1h', 'ash_rollup_gc'
        )
      loop
        return next;
      end loop;
    exception when insufficient_privilege then
      metric := 'cron_jobs';
      value := format(
        '<no cron.job access; grant USAGE ON SCHEMA cron TO %I>',
        current_user
      );
      return next;
    end;
  else
    metric := 'pg_cron_available'; value := 'no (use external scheduler)'; return next;
  end if;

  return;
end;
$$;

--------------------------------------------------------------------------------
-- STEP 6: Rollup tables and functions
--------------------------------------------------------------------------------

/*
 * Minute-level rollup: aggregated samples per minute per database.
 * Survives raw partition rotation. Retained per rollup_1m_retention_days.
 */
create table if not exists ash.rollup_1m (
  ts              int4 not null,     -- minute-aligned epoch offset
  datid           oid not null,
  samples         smallint not null, -- count of raw samples in this minute (max 60)
  peak_backends   smallint not null, -- max per-database active backends in any
                                     -- single sample within this minute
  wait_counts     int4[] not null,   -- [wait_id, count, wait_id, count, ...]
  query_counts    int8[] not null,   -- [query_id, count, query_id, count, ...]
  primary key (ts, datid)
);

/*
 * Hourly rollup: aggregated from minute rollups.
 * Retained per rollup_1h_retention_days (default 5 years).
 */
create table if not exists ash.rollup_1h (
  ts              int4 not null,     -- hour-aligned epoch offset
  datid           oid not null,
  samples         smallint not null, -- sum of minute samples (max 3600)
  peak_backends   smallint not null, -- max per-database peak across the hour
  wait_counts     int4[] not null,
  query_counts    int8[] not null,
  minute_counts   int4[],            -- 60-slot per-minute total activity counts:
                                     -- element i = sum of wait_counts counts of the
                                     -- rollup_1m row at ts + (i-1)*60; NULL element =
                                     -- no stored rollup_1m row for that minute.
                                     -- A valid array preserves minute-grain totals.
                                     -- NULL/invalid column = legacy or incomplete
                                     -- detail; readers use one disclosed hour-grain
                                     -- datum instead of synthesizing 60 observations.
  primary key (ts, datid)
);

-- Upgrade path: pre-2.0 installs created rollup_1h without minute_counts.
alter table ash.rollup_1h
  add column if not exists minute_counts int4[];

/*
 * A minute_counts array is usable only when all 60 slots are represented and
 * its non-NULL elements preserve the exact hourly activity total. NULL slots
 * can be legitimate because the storage model writes no row for both an idle
 * minute and an uncovered minute (#137); equality, not physical row count, is
 * the strongest invariant the stored data can prove.
 */
create or replace function ash._minute_counts_valid(
  minute_counts int4[],
  wait_counts int4[]
)
returns boolean
language sql
immutable
set search_path = pg_catalog, ash
as $$
  select coalesce(
    cardinality(minute_counts) = 60
    and (
      select coalesce(sum(minute_count), 0)
      from unnest(minute_counts) as minute_count
    ) = (
      select coalesce(sum(wait_counts[pos + 1]), 0)
      from generate_subscripts(wait_counts, 1) as pos
      where pos % 2 = 1
    ),
    false
  )
$$;

/*
 * Upgrade backfill: reconstruct minute_counts for legacy rollup_1h rows whose
 * hour is still covered by rollup_1m (per-minute detail survives there for
 * rollup_1m_retention_days). A candidate is accepted only when it preserves
 * the hourly total. Older hours and partial candidates that fail that
 * invariant keep minute_counts NULL and readers disclose hour grain. Re-apply
 * also repairs partial arrays written by earlier 2.0 beta installers.
 */
update ash.rollup_1h as rollup_hour
set minute_counts = null
where rollup_hour.minute_counts is not null
  and not ash._minute_counts_valid(
    rollup_hour.minute_counts,
    rollup_hour.wait_counts
  );

with candidates as (
  select
    rollup_hour.ts,
    rollup_hour.datid,
    rollup_hour.wait_counts,
    (
      select array_agg(minute_total.total order by minute_series.idx)
      from generate_series(0, 59) as minute_series(idx)
      left join lateral (
        select (
          select coalesce(sum(rollup_min.wait_counts[sub + 1]), 0)::int4
          from generate_subscripts(rollup_min.wait_counts, 1) as sub
          where sub % 2 = 1
        ) as total
        from ash.rollup_1m as rollup_min
        where rollup_min.datid = rollup_hour.datid
          and rollup_min.ts = rollup_hour.ts + minute_series.idx * 60
      ) as minute_total on true
    ) as minute_counts
  from ash.rollup_1h as rollup_hour
  where rollup_hour.minute_counts is null
    and exists (
      select
      from ash.rollup_1m as rollup_min
      where rollup_min.datid = rollup_hour.datid
        and rollup_min.ts >= rollup_hour.ts
        and rollup_min.ts < rollup_hour.ts + 3600
    )
)
update ash.rollup_1h as rollup_hour
set minute_counts = candidates.minute_counts
from candidates
where rollup_hour.ts = candidates.ts
  and rollup_hour.datid = candidates.datid
  and ash._minute_counts_valid(
    candidates.minute_counts,
    candidates.wait_counts
  );

/*
 * Array concatenation aggregates: flat-concatenate arrays of varying lengths.
 * PostgreSQL's built-in array_agg() on arrays requires equal dimensions and
 * produces a multi-dimensional result. These use array_cat() to produce a
 * flat 1-D result, which _merge_wait_counts/_merge_query_counts expect.
 */
do $$
begin
  if not exists (
    select from pg_proc as proc
    join pg_namespace as nsp on nsp.oid = proc.pronamespace
    where nsp.nspname = 'ash' and proc.proname = '_int4_array_cat_agg'
      and proc.prokind = 'a'
  ) then
    create aggregate ash._int4_array_cat_agg(int4[]) (
      sfunc = array_cat,
      stype = int4[],
      initcond = '{}'
    );
  end if;

  if not exists (
    select from pg_proc as proc
    join pg_namespace as nsp on nsp.oid = proc.pronamespace
    where nsp.nspname = 'ash' and proc.proname = '_int8_array_cat_agg'
      and proc.prokind = 'a'
  ) then
    create aggregate ash._int8_array_cat_agg(int8[]) (
      sfunc = array_cat,
      stype = int8[],
      initcond = '{}'
    );
  end if;
end $$;

/*
 * Merge multiple wait_counts arrays: sum counts for matching wait_ids.
 * Input: flat int4[] from _int4_array_cat_agg(wait_counts) — concatenated
 * pairs into one flat array. The function extracts id/count pairs
 * by position parity, groups by id, sums counts, and re-interleaves.
 * Uses CROSS JOIN LATERAL (VALUES ...) for correct pair ordering
 * (avoids the ORDER BY v DESC bug that swaps id/count when count > id).
 */
create or replace function ash._merge_wait_counts(flat int4[])
returns int4[]
language sql
immutable
parallel safe
set search_path = pg_catalog, ash
as $$
  with numbered as (
    select row_number() over () as pos, val
    from unnest(flat) as val
  ),
  pairs as (
    select id_elem.val as id, count_elem.val as cnt
    from numbered as id_elem
    join numbered as count_elem on count_elem.pos = id_elem.pos + 1
    where id_elem.pos % 2 = 1
  ),
  merged as (
    select id, sum(cnt)::int4 as total,
           row_number() over (order by sum(cnt) desc, id asc) as rn
    from pairs
    group by id
  ),
  interleaved as (
    select v, rn, sub
    from merged
    cross join lateral (values (1, id), (2, total)) as pair(sub, v)
  )
  select coalesce(
    array_agg(v order by rn, sub),
    '{}'::int4[]
  )
  from interleaved
$$;

/*
 * Merge multiple query_counts arrays: identical logic to _merge_wait_counts
 * above, but int8 typed. Kept separate for type safety (no polymorphic
 * overhead).
 */
create or replace function ash._merge_query_counts(flat int8[])
returns int8[]
language sql
immutable
parallel safe
set search_path = pg_catalog, ash
as $$
  with numbered as (
    select row_number() over () as pos, val
    from unnest(flat) as val
  ),
  pairs as (
    select id_elem.val as id, count_elem.val as cnt
    from numbered as id_elem
    join numbered as count_elem on count_elem.pos = id_elem.pos + 1
    where id_elem.pos % 2 = 1
  ),
  merged as (
    select id, sum(cnt)::int8 as total,
           row_number() over (order by sum(cnt) desc, id asc) as rn
    from pairs
    group by id
  ),
  interleaved as (
    select v, rn, sub
    from merged
    cross join lateral (values (1, id), (2, total)) as pair(sub, v)
  )
  select coalesce(
    array_agg(v order by rn, sub),
    '{}'::int8[]
  )
  from interleaved
$$;

/*
 * Truncate a paired array to top N entries by count.
 * Preserves [id, count] pairing correctly.
 */
create or replace function ash._truncate_pairs(arr int8[], n int)
returns int8[]
language sql
immutable
parallel safe
set search_path = pg_catalog, ash
as $$
  with numbered as (
    select row_number() over () as pos, val
    from unnest(arr) as val
  ),
  pairs as (
    select id_elem.val as id, count_elem.val as cnt
    from numbered as id_elem
    join numbered as count_elem on count_elem.pos = id_elem.pos + 1
    where id_elem.pos % 2 = 1
  ),
  top_n as (
    select id, cnt,
           row_number() over (order by cnt desc, id asc) as rn
    from pairs
    order by cnt desc, id asc
    limit n
  ),
  interleaved as (
    select v, rn, sub
    from top_n
    cross join lateral (values (1, id), (2, cnt)) as pair(sub, v)
  )
  select coalesce(
    array_agg(v order by rn, sub),
    '{}'::int8[]
  )
  from interleaved
$$;

/*
 * Rollup minute: watermark-based aggregation of raw samples into minute
 * rollups. Processes all unprocessed complete minutes up to batch_limit.
 * Idempotent via ON CONFLICT DO UPDATE (upsert).
 */
create or replace function ash.rollup_minute(
  batch_limit int default 60  -- max minutes to catch up per call
)
returns int
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_last_ts int4;
  v_now_minute_ts int4;
  v_minute_start int4;
  v_minute_end int4;
  v_batch_remaining int;
  v_total int := 0;
  v_count int;
  v_min_backend_seconds smallint;
  v_has_later_data bool;
  v_sampler_lock_acquired bool := false;
begin
  /*
   * Acquire rollup lock (xact-level). Rollup operations serialize with each
   * other, and rebuild_partitions's drain poll waits on this objid.
   */
  if not pg_try_advisory_xact_lock(
       hashtext('pg_ash')::int4,
       hashtext('pg_ash_rollup')::int4
     ) then
    return 0;
  end if;

  v_batch_remaining := batch_limit;

  select last_rollup_1m_ts, rollup_min_backend_seconds
  into v_last_ts, v_min_backend_seconds
  from ash.config where singleton;

  /*
   * Drain in-flight samplers before choosing the "complete minute" boundary.
   * take_sample() gets sample_ts from transaction-start now(), then may block
   * before INSERT. Without this drain, rollup_minute() can advance the
   * watermark while a sampler later commits an old-minute row, permanently
   * excluding it from rollups (#81).
   */
  if not pg_try_advisory_lock(
       hashtext('pg_ash')::int4,
       hashtext('pg_ash_sampler')::int4
     ) then
    return 0;
  end if;
  v_sampler_lock_acquired := true;

  begin
    /*
     * Current minute boundary (only process *complete* minutes). This is
     * computed after the sampler drain, so future samplers cannot commit rows
     * with sample_ts older than this boundary.
     */
    v_now_minute_ts := ash.ts_from_timestamptz(date_trunc('minute', now()));

    perform pg_advisory_unlock(
      hashtext('pg_ash')::int4,
      hashtext('pg_ash_sampler')::int4
    );
    v_sampler_lock_acquired := false;
  exception when others then
    if v_sampler_lock_acquired then
      perform pg_advisory_unlock(
        hashtext('pg_ash')::int4,
        hashtext('pg_ash_sampler')::int4
      );
    end if;
    raise;
  end;

  -- Initialize watermark if NULL (first run after install or upgrade).
  if v_last_ts is null then
    select (min(sample_ts) / 60) * 60
    into v_last_ts
    from ash.sample;

    if v_last_ts is null then
      return 0;  -- no samples at all
    end if;
  end if;

  -- Process each unprocessed complete minute.
  v_minute_start := v_last_ts;

  while v_minute_start < v_now_minute_ts and v_batch_remaining > 0 loop
    v_minute_end := v_minute_start + 60;

    /*
     * Decode samples once, then aggregate wait_counts and query_counts
     * together. Previous version decoded samples 3x per datid (outer + 2
     * correlated subqueries). We walk the packed data[] array inline (same
     * pattern as ash.samples()) rather than calling ash.decode_sample(), so
     * we can group directly on the canonical wait_event_map.id (negative
     * markers in data[]). Grouping on wait_event text would collapse states
     * (e.g., ClientRead under 'active' vs 'idle in transaction') and
     * double-count via the unique (state, type, event) rows in
     * wait_event_map.
     */
    insert into ash.rollup_1m (
      ts, datid, samples, peak_backends, wait_counts, query_counts
    )
    with decoded as (
      select
        sample_row.datid,
        sample_row.sample_ts,
        sample_row.active_count,
        sample_row.slot,
        (-sample_row.data[data_idx])::smallint as wait_id,
        sample_row.data[data_idx + 2 + backend.n] as map_id
      from ash.sample as sample_row
      cross join generate_subscripts(sample_row.data, 1) as data_idx
      cross join generate_series(
        0, greatest(sample_row.data[data_idx + 1] - 1, -1)
      ) as backend(n)
      where sample_row.sample_ts >= v_minute_start
        and sample_row.sample_ts < v_minute_end
        and sample_row.data[data_idx] < 0
        and data_idx + 1 <= array_length(sample_row.data, 1)
        and data_idx + 2 + backend.n <= array_length(sample_row.data, 1)
    ),
    base as (
      select
        datid,
        count(distinct sample_ts)::smallint as samples,
        max(active_count)::smallint as peak_backends
      from decoded
      group by datid
    ),
    wait_agg as (
      /*
       * Aggregate by canonical wait_event_map.id (includes state).
       * Joining on wait_event text would match multiple map rows when the
       * same (type, event) exists under multiple states (e.g., ClientRead
       * under both 'active' and 'idle in transaction') and double-count.
       */
      select
        decoded.datid,
        decoded.wait_id::int4 as wait_id,
        count(*)::int4 as cnt,
        row_number() over (
          partition by decoded.datid
          order by count(*) desc, decoded.wait_id asc
        ) as rn
      from decoded
      group by decoded.datid, decoded.wait_id
    ),
    wait_interleaved as (
      select datid, v, rn, sub
      from wait_agg
      cross join lateral (values (1, wait_id), (2, cnt)) as pair(sub, v)
    ),
    wait_arrays as (
      select
        datid,
        coalesce(array_agg(v order by rn, sub), '{}'::int4[]) as wait_counts
      from wait_interleaved
      group by datid
    ),
    query_agg as (
      /*
       * Resolve map_id -> query_id via the per-slot query_map partition.
       * map_id = 0 is the sentinel for "no query_id" and is skipped.
       */
      select
        decoded.datid,
        query_map.query_id,
        count(*)::int8 as cnt,
        row_number() over (
          partition by decoded.datid
          order by count(*) desc, query_map.query_id asc
        ) as rn
      from decoded
      join ash.query_map_all as query_map
        on query_map.slot = decoded.slot and query_map.id = decoded.map_id
      where decoded.map_id <> 0
        and query_map.query_id is not null
      group by decoded.datid, query_map.query_id
      having count(*) >= v_min_backend_seconds
    ),
    query_top as (
      select datid, query_id, cnt, rn
      from query_agg
      where rn <= 100
    ),
    query_interleaved as (
      select datid, v, rn, sub
      from query_top
      cross join lateral (values (1, query_id), (2, cnt)) as pair(sub, v)
    ),
    query_arrays as (
      select
        datid,
        coalesce(array_agg(v order by rn, sub), '{}'::int8[]) as query_counts
      from query_interleaved
      group by datid
    )
    select
      v_minute_start,
      base.datid,
      base.samples,
      base.peak_backends,
      coalesce(wait_arrays.wait_counts, '{}'::int4[]),
      coalesce(query_arrays.query_counts, '{}'::int8[])
    from base
    left join wait_arrays on wait_arrays.datid = base.datid
    left join query_arrays on query_arrays.datid = base.datid
    on conflict (ts, datid) do update set
      samples = excluded.samples,
      peak_backends = excluded.peak_backends,
      wait_counts = excluded.wait_counts,
      query_counts = excluded.query_counts;

    get diagnostics v_count = row_count;

    -- Gap detection: no samples for this minute but later data exists.
    if v_count = 0 then
      select exists (
        select from ash.sample where sample_ts >= v_minute_end
      ) into v_has_later_data;

      if v_has_later_data then
        raise warning
          'ash.rollup_minute: gap at minute % — no samples but later data '
          'exists (data may have rotated before rollup)',
          ash.ts_to_timestamptz(v_minute_start);
      end if;
    end if;

    -- One loop iteration processes one minute, independent of datid row count.
    v_total := v_total + 1;

    -- Advance watermark transactionally.
    update ash.config
    set last_rollup_1m_ts = v_minute_end
    where singleton;

    v_minute_start := v_minute_end;
    v_batch_remaining := v_batch_remaining - 1;
  end loop;

  return v_total;
end;
$$;

/*
 * Rollup hour: aggregate minute rollups into hourly rollups.
 * Watermark-based, idempotent via upsert.
 */
create or replace function ash.rollup_hour()
returns int
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_last_ts int4;
  v_last_1m_ts int4;
  v_now_hour_ts int4;
  v_hour_start int4;
  v_hour_end int4;
  v_batch_limit int := 24;
  v_total int := 0;
begin
  /*
   * Wait for the shared rollup lock instead of skipping. The hourly pg_cron
   * job runs at minute 1, when the every-minute worker also fires; a try-lock
   * here could lose that race every hour and starve hourly aggregation.
   */
  perform pg_advisory_xact_lock(
    hashtext('pg_ash')::int4,
    hashtext('pg_ash_rollup')::int4
  );

  select last_rollup_1h_ts, last_rollup_1m_ts
  into v_last_ts, v_last_1m_ts
  from ash.config where singleton;

  v_now_hour_ts := ash.ts_from_timestamptz(date_trunc('hour', now()));

  if v_last_ts is null then
    select (min(ts) / 3600) * 3600 into v_last_ts from ash.rollup_1m;

    if v_last_ts is null then
      return 0;
    end if;
  end if;

  v_hour_start := v_last_ts;

  while v_hour_start < v_now_hour_ts and v_batch_limit > 0 loop
    v_hour_end := v_hour_start + 3600;

    /*
     * The minute watermark is the authoritative completion boundary. The
     * blocking lock above observes a completed in-flight minute rollup, while
     * this guard also protects manual/external calls and missing coverage:
     * defer without inserting or advancing rather than seal a partial hour.
     */
    if v_last_1m_ts is null or v_last_1m_ts < v_hour_end then
      exit;
    end if;

    insert into ash.rollup_1h (
      ts, datid, samples, peak_backends, wait_counts, query_counts,
      minute_counts
    )
    with minute_rollup as (
      select datid, ts, samples, peak_backends, wait_counts, query_counts,
             -- per-minute total activity count = sum of the wait_counts counts
             (select coalesce(sum(wait_counts[sub + 1]), 0)::int4
              from generate_subscripts(wait_counts, 1) as sub
              where sub % 2 = 1) as minute_total
      from ash.rollup_1m
      where ts >= v_hour_start and ts < v_hour_end
    )
    select
      v_hour_start,
      minute_rollup.datid,
      sum(minute_rollup.samples)::smallint,
      max(minute_rollup.peak_backends)::smallint,
      ash._merge_wait_counts(
        ash._int4_array_cat_agg(minute_rollup.wait_counts)
          filter (where minute_rollup.wait_counts <> '{}')
      ),
      ash._truncate_pairs(
        ash._merge_query_counts(
          ash._int8_array_cat_agg(minute_rollup.query_counts)
            filter (where minute_rollup.query_counts <> '{}')
        ),
        100  -- top 100 queries per hour
      ),
      /*
       * 60-slot per-minute totals (NULL element = minute without a rollup_1m
       * row); lets rollup_1h-backed readers keep the exact minute-grain
       * peak_aas / p99_aas.
       */
      (select array_agg(minute_slot.minute_total order by minute_series.idx)
       from generate_series(0, 59) as minute_series(idx)
       left join minute_rollup as minute_slot
         on minute_slot.datid = minute_rollup.datid
         and minute_slot.ts = v_hour_start + minute_series.idx * 60)
    from minute_rollup
    group by minute_rollup.datid
    on conflict (ts, datid) do update set
      samples = excluded.samples,
      peak_backends = excluded.peak_backends,
      wait_counts = excluded.wait_counts,
      query_counts = excluded.query_counts,
      minute_counts = excluded.minute_counts;

    -- One loop iteration processes one hour, independent of datid row count.
    v_total := v_total + 1;

    update ash.config
    set last_rollup_1h_ts = v_hour_end
    where singleton;

    v_hour_start := v_hour_end;
    v_batch_limit := v_batch_limit - 1;
  end loop;

  return v_total;
end;
$$;

-- Rollup cleanup: delete expired rows based on retention config.
create or replace function ash.rollup_cleanup()
returns text
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_1m_deleted int;
  v_1h_deleted int;
  v_1m_retention int;
  v_1h_retention int;
  v_cutoff_1m int4;
  v_cutoff_1h int4;
begin
  /*
   * Acquire rollup lock (xact-level). Shares the kind with rollup_minute
   * and rollup_hour so cleanup can't delete rows that an in-flight rollup
   * is upserting into. Also visible to rebuild_partitions's drain poll.
   */
  if not pg_try_advisory_xact_lock(
       hashtext('pg_ash')::int4,
       hashtext('pg_ash_rollup')::int4
     ) then
    return 'cleanup: skipped — another rollup operation in progress';
  end if;

  select rollup_1m_retention_days, rollup_1h_retention_days
  into v_1m_retention, v_1h_retention
  from ash.config where singleton;

  v_cutoff_1m := ash.ts_from_timestamptz(
    now() - (v_1m_retention || ' days')::interval
  );
  v_cutoff_1h := ash.ts_from_timestamptz(
    now() - (v_1h_retention || ' days')::interval
  );

  delete from ash.rollup_1m where ts < v_cutoff_1m;
  get diagnostics v_1m_deleted = row_count;

  delete from ash.rollup_1h where ts < v_cutoff_1h;
  get diagnostics v_1h_deleted = row_count;

  return format('cleanup: deleted %s minute rows, %s hourly rows',
    v_1m_deleted, v_1h_deleted);
end;
$$;

drop function if exists ash.aas_summary(interval);
drop function if exists ash.aas_summary_at(timestamptz, timestamptz);
drop function if exists ash.periods(timestamptz);
drop function if exists ash.aas_waits(interval, text, int);
drop function if exists ash.aas_waits_at(timestamptz, timestamptz, text, int);
drop function if exists ash.aas_queries(interval, int);
drop function if exists ash.aas_queries_at(timestamptz, timestamptz, int);

/*
 * Configured sample interval in seconds (>= a tiny floor to avoid
 * div-by-zero). Each rollup count is one sample appearance =
 * sample_interval_secs of backend time, so
 * AAS = sum(count) * sample_interval_secs / wall_clock_seconds.
 */
create or replace function ash._sample_interval_secs()
returns numeric
language sql
stable
set search_path = pg_catalog, ash
as $$
  select greatest(
           coalesce(extract(epoch from sample_interval)::numeric, 1),
           0.001
         )
  from ash.config
  where singleton
$$;

--------------------------------------------------------------------------------
-- STEP 8: Existing reader functions (raw samples)
--------------------------------------------------------------------------------

/*
 * Wait event color mapping (24-bit RGB, aligned with PostgresAI monitoring).
 *
 *   Wait type       Color          RGB
 *   ─────────────   ─────────────  ───────────────
 *   CPU*            green          80, 250, 123
 *   IdleTx          light yellow   241, 250, 140
 *   IO              vivid blue     30, 100, 255
 *   Lock            red            255, 85, 85
 *   LWLock          pink           255, 121, 198
 *   IPC             cyan           0, 200, 255
 *   Client          yellow         255, 220, 100
 *   Timeout         orange         255, 165, 0
 *   BufferPin       teal           0, 210, 180
 *   Activity        purple         150, 100, 255
 *   Extension       light purple   190, 150, 255
 *   Unknown/Other   gray           180, 180, 180
 *
 * Uses 24-bit RGB escape codes (\033[38;2;R;G;Bm) for consistent rendering
 * across terminal themes (light, dark, solarized, etc.).
 * Colors: off by default. Enable per-call (color := true) or per-session:
 *   set ash.color = on;
 * The session GUC avoids passing color to every function call.
 */

-- Resolve effective color state: explicit param wins, then session GUC.
create or replace function ash._color_on(color boolean default false)
returns boolean
language sql
stable
set search_path = pg_catalog, ash
as $$
  select color
    or coalesce(current_setting('ash.color', true), '') in ('on', 'true', '1');
$$;

create or replace function ash._wait_color(event text, color boolean default false)
returns text
language sql
stable
set search_path = pg_catalog, ash
as $$
  /*
   * All escapes padded to 19 chars: \033[38;2;RRR;GGG;BBBm
   * Uniform length prevents pspg right-border misalignment.
   */
  select case when not ash._color_on(color) then '' else
    case
      when event like 'CPU%' then E'\033[38;2;080;250;123m'         -- green
      when event like 'IdleTx%' then E'\033[38;2;241;250;140m'      -- light yellow
      when event like 'IO:%' then E'\033[38;2;030;100;255m'         -- vivid blue
      when event like 'Lock:%' then E'\033[38;2;255;085;085m'       -- red
      when event like 'LWLock:%' then E'\033[38;2;255;121;198m'     -- pink
      when event like 'IPC:%' then E'\033[38;2;000;200;255m'        -- cyan
      when event like 'Client:%' then E'\033[38;2;255;220;100m'     -- yellow
      when event like 'Timeout:%' then E'\033[38;2;255;165;000m'    -- orange
      when event like 'BufferPin:%' then E'\033[38;2;000;210;180m'  -- teal
      when event like 'Activity:%' then E'\033[38;2;150;100;255m'   -- purple
      when event like 'Extension:%' then E'\033[38;2;190;150;255m'  -- light purple
      else E'\033[38;2;180;180;180m'                                   -- gray (unknown)
    end
  end;
$$;

-- Convenience: reset code, empty when color off.
create or replace function ash._reset(color boolean default false)
returns text
language sql
stable
set search_path = pg_catalog, ash
as $$
  select case when ash._color_on(color) then E'\033[0m' else '' end;
$$;

/*
 * Build a bar string with fixed visible width (for pspg/column alignment).
 * Visible: [blocks padded to width] + ' ' + pct + '%'
 * Invisible ANSI codes don't affect visual width.
 *
 * width is clamped to [1, 500] to prevent reader-callable OOM via
 * unbounded `repeat()` on the █ character (a granted reader role could
 * otherwise pass width => 1_000_000_000 and allocate ~3 GB per row).
 */
create or replace function ash._bar(
  event text,
  pct numeric,
  max_pct numeric,
  width int,
  color boolean default false
)
returns text
language sql
stable
set search_path = pg_catalog, ash
as $$
  /*
   * All color escapes are now exactly 19 chars (zero-padded RGB).
   * reset is always 4 chars. Total invisible = 23 when color on, 0 when off.
   */
  select ash._wait_color(event, color)
    || rpad(
         repeat('█', greatest(1, (
           pct / nullif(max_pct, 0) * least(greatest(width, 1), 500)
         )::int)),
         least(greatest(width, 1), 500)
       )
    || ash._reset(color)
    || lpad(pct || '%', 8);
$$;

--------------------------------------------------------------------------------
-- STEP 8: 2.0 reader / analysis API (AAS)
--------------------------------------------------------------------------------
/*
 * The minimal AAS surface (issue #113, blueprints/AAS_API.md): seven data
 * functions (periods, aas, timeline, top, compare, samples, report) and two
 * render helpers (chart, summary). AAS = Average Active Sessions. Aggregate
 * readers auto-select raw -> rollup_1m -> rollup_1h; typed readers expose a
 * source column, compare exposes both sources, report embeds provenance in
 * JSON, and chart emits a planning NOTICE when hour grain widens its request.
 * Unanswerable exact-query drills raise past raw retention. Internal
 * workhorses (_grain_counts / _grain_by) and retention helpers back the family.
 */

/*
 * Physical raw coverage and logical raw retention are deliberately separate.
 * The oldest sample is exact retained evidence (and follows the active slot
 * set fixed by #128). The retention start is a usable minute boundary: never
 * newer than the configured ring horizon or than older evidence preserved by
 * a delayed rotation. It therefore does not jump to the first post-install or
 * post-outage sample. Null when raw holds no data.
 */
create or replace function ash._raw_oldest_sample()
returns timestamptz
language sql
stable
set search_path = pg_catalog, ash
as $$
  select ash.ts_to_timestamptz(min(sample_ts))
  from ash.sample
  where slot = any(ash._active_slots())
$$;

create or replace function ash._raw_retention_start()
returns timestamptz
language sql
stable
set search_path = pg_catalog, ash
as $$
  with raw_coverage as (
    select ash._raw_oldest_sample() as oldest_sample
  )
  select case
    when raw_coverage.oldest_sample is null then null
    else least(
      date_trunc('minute', raw_coverage.oldest_sample),
      ash.ts_to_timestamptz(
        ash.ts_from_timestamptz(
          date_trunc(
            'minute',
            config_row.rotated_at
            - (config_row.num_partitions - 2) * config_row.rotation_period
          )
        )
      )
    )
  end
  from ash.config as config_row
  cross join raw_coverage
  where config_row.singleton
$$;

create or replace function ash._rollup_1m_retention_start()
returns timestamptz
language sql
stable
set search_path = pg_catalog, ash
as $$
  select ash.ts_to_timestamptz(min(ts)) from ash.rollup_1m
$$;

create or replace function ash._rollup_1h_retention_start()
returns timestamptz
language sql
stable
set search_path = pg_catalog, ash
as $$
  select ash.ts_to_timestamptz(min(ts)) from ash.rollup_1h
$$;

/*
 * True when a rollup_1h window overlaps legacy or incomplete minute detail.
 * Minute-capable readers then conservatively use hour grain for the whole
 * window and publish source = rollup_1h_flat.
 */
create or replace function ash._rollup_1h_has_flat(
  start_ts int4,
  end_ts int4,
  database name default null
)
returns boolean
language sql
stable
set search_path = pg_catalog, ash
as $$
  select exists (
    select
    from ash.rollup_1h as rollup_hour
    left join pg_database as db
      on db.oid = rollup_hour.datid
    /*
     * Keep the primary-key ts range indexable. Moving the arithmetic to the
     * bigint parameter side avoids int4 overflow without casting the column.
     */
    where rollup_hour.ts < _rollup_1h_has_flat.end_ts::bigint
      and rollup_hour.ts
            > _rollup_1h_has_flat.start_ts::bigint - 3600
      and (
        _rollup_1h_has_flat.database is null
        or db.datname = _rollup_1h_has_flat.database
      )
      and not ash._minute_counts_valid(
        rollup_hour.minute_counts,
        rollup_hour.wait_counts
      )
  )
$$;

/*
 * Source auto-selection (the trust property, AAS_API.md §6): the finest
 * source whose retention reaches since. Raw is preferred within raw retention
 * (most accurate, and the only source that can provide exact query attribution
 * or answer while rollups lag/are disabled); then rollup_1m, then rollup_1h.
 * Returns 'none' only when nothing holds data. Callers that need exact query
 * attribution force 'raw' and raise when falling back to a compacted rollup
 * would discard retained history.
 */
create or replace function ash._pick_source(since timestamptz)
returns text
language sql
stable
set search_path = pg_catalog, ash
as $$
  with raw_coverage as (
    select ash._raw_oldest_sample() as oldest_sample
  )
  select case
    when raw_coverage.oldest_sample is not null
         and ash.ts_from_timestamptz(date_trunc('minute', since))
             >= ash.ts_from_timestamptz(
                  date_trunc('minute', raw_coverage.oldest_sample)
                ) then 'raw'
    when ash._rollup_1m_retention_start() is not null
         and since >= ash._rollup_1m_retention_start() then 'rollup_1m'
    when ash._rollup_1h_retention_start() is not null then 'rollup_1h'
    when ash._rollup_1m_retention_start() is not null then 'rollup_1m'
    when raw_coverage.oldest_sample is not null then 'raw'
    else 'none'
  end
  from raw_coverage
$$;

/*
 * Source selection for the AGGREGATE readers (aas / timeline / periods, and
 * unfiltered breakdowns in top / chart). Raw and rollup_1m share per-minute
 * grain, so for anything wider than ~1 hour whose requested start is within
 * rollup_1m retention we prefer rollup_1m (a raw decode of a wide window spills
 * hundreds of MB — the last-24h read cost ~4.5s and ~500MB before this).
 * The rollup watermark must also reach the latest complete minute whenever raw
 * is the preferred source at the window start; otherwise a stalled rollup
 * worker would hide newer raw load. Narrow windows still fall through to
 * _pick_source (raw preferred) so the freshest partial minute is captured.
 * When raw covers the window start, a rollup that is disabled, cannot cover it,
 * or lags the requested end falls back through _pick_source. Completeness for a
 * stalled rollup when the window starts before physical raw coverage remains
 * tracked by #122. Exact-query drills and samples bypass this and force raw.
 * The source column stays honest — it names whatever was actually read.
 */
create or replace function ash._pick_source_agg(
  since timestamptz,
  until timestamptz
)
returns text
language sql
stable
set search_path = pg_catalog, ash
as $$
  with fallback as (
    select ash._pick_source(since) as source
  )
  select case
    when extract(epoch from (until - since)) > 3600
         and ash._rollup_1m_retention_start() is not null
         and since >= ash._rollup_1m_retention_start()
         and (
           fallback.source <> 'raw'
           or coalesce(
                (
                  select ash.ts_to_timestamptz(last_rollup_1m_ts)
                           >= least(
                                until,
                                date_trunc('minute', now())
                              )
                  from ash.config
                  where singleton
                ),
                false
              )
         ) then 'rollup_1m'
    else fallback.source
  end
  from fallback
$$;

/*
 * True only when the source ordinary planning selects has retained rollup
 * coverage in the requested pre-raw slice. _pick_source() deliberately falls
 * back to any nonempty source when no source reaches since; that fallback
 * label alone is not evidence that forcing raw discards history. In
 * particular, a young install's first rollup can cover only the same retained
 * minute as its oldest raw sample.
 *
 * Compare at reader grain: a rollup row in the same minute as raw_start does
 * not prove older coverage. This composes with the landed #163/#189 split
 * between the oldest physical sample and the usable logical raw boundary.
 */
create or replace function ash._exact_query_uses_coarser(
  start_ts int4,
  end_ts int4,
  database name default null
)
returns boolean
language plpgsql
stable
set search_path = pg_catalog, ash
as $$
declare
  v_source text := ash._pick_source(ash.ts_to_timestamptz(start_ts));
  v_raw_start timestamptz := ash._raw_oldest_sample();
  v_pre_raw_end int8 := case
    when v_raw_start is null then end_ts::int8
    else least(
      end_ts::int8,
      ash.ts_from_timestamptz(date_trunc('minute', v_raw_start))::int8
    )
  end;
begin
  if v_pre_raw_end <= start_ts::int8 then
    return false;
  end if;

  if v_source = 'rollup_1m' then
    return exists (
      select
      from ash.rollup_1m as rollup_minute
      left join pg_database as db
        on db.oid = rollup_minute.datid
      where rollup_minute.ts::int8 < v_pre_raw_end
        and rollup_minute.ts::int8 + 60 > start_ts::int8
        and (
          _exact_query_uses_coarser.database is null
          or db.datname = _exact_query_uses_coarser.database
        )
    );
  elsif v_source = 'rollup_1h' then
    return exists (
      select
      from ash.rollup_1h as rollup_hour
      left join pg_database as db
        on db.oid = rollup_hour.datid
      where rollup_hour.ts::int8 < v_pre_raw_end
        and rollup_hour.ts::int8 + 3600 > start_ts::int8
        and (
          _exact_query_uses_coarser.database is null
          or db.datname = _exact_query_uses_coarser.database
        )
        and (
          not ash._minute_counts_valid(
            rollup_hour.minute_counts,
            rollup_hour.wait_counts
          )
          or exists (
            select
            from unnest(rollup_hour.minute_counts)
              with ordinality as minute_count(cnt, idx)
            where minute_count.cnt is not null
              and rollup_hour.ts::int8
                    + (minute_count.idx - 1) * 60 < v_pre_raw_end
              and rollup_hour.ts::int8
                    + minute_count.idx * 60 > start_ts::int8
          )
        )
    );
  end if;

  return false;
end;
$$;

/*
 * Raw-retention guard for exact query attribution. Explicit query_id filters
 * and wait<->query tie drills need raw samples because compacted rollups cannot
 * distinguish a true zero from attribution that was not preserved. Returns
 * silently when raw covers the window start; otherwise raises, with guidance
 * split by case:
 *   * window ENTIRELY past raw retention (or no raw samples at all): exact
 *     attribution is unrecoverable — narrowing cannot help, so point to an
 *     untied / unfiltered aggregate read instead;
 *   * PARTIAL overlap (window starts before raw retention but ends inside
 *     it): narrowing the window to the raw-covered part recovers the drill.
 * start_ts / end_ts are the reader's minute-FLOORED window bounds (the guard
 * must reason about what actually gets queried); since is the un-floored
 * window start the caller passed, echoed in the messages so they reflect the
 * user's arguments rather than looking like pg_ash misheard them.
 */
create or replace function ash._raise_tie_retention(
  raw_start timestamptz,
  start_ts int4,
  end_ts int4,
  since timestamptz
)
returns void
language plpgsql
stable
set search_path = pg_catalog, ash
as $$
declare
  v_raw_start_ts int4;
  v_start_ts int4 := (start_ts / 60) * 60;
  v_end_ts int4 := (end_ts / 60) * 60;
  v_raw_boundary timestamptz;
begin
  if raw_start is not null then
    v_raw_start_ts := ash.ts_from_timestamptz(
      date_trunc('minute', raw_start)
    );
    v_raw_boundary := ash.ts_to_timestamptz(v_raw_start_ts);
  end if;

  if v_raw_start_ts is not null and v_start_ts >= v_raw_start_ts then
    return;  -- raw covers the window start: exact attribution can proceed
  end if;
  if v_raw_start_ts is null or v_end_ts <= v_raw_start_ts then
    raise exception
      'pg_ash: this drill needs exact raw query attribution, but the requested '
      'window (% to %) is entirely outside raw retention (%). Exact query '
      'attribution is unrecoverable for that window — narrowing it will not '
      'help. Use the untied aggregate readers instead: remove query_id (or '
      'drop the wait filter when drilling queries by wait).',
      since,
      ash.ts_to_timestamptz(v_end_ts),
      coalesce(
        'raw retention starts at ' || v_raw_boundary,
        'no raw samples exist'
      );
  end if;
  /*
   * Compare and report the same minute-aligned boundary the reader uses. The
   * floor preserves a partial first minute; rounding up would discard it.
   */
  raise exception
    'pg_ash: this drill needs exact raw query attribution; raw retention '
    'starts at % but the requested window starts at %. Narrow the window '
    'to start at or after % (the window end is still inside raw retention), '
    'or remove query_id.',
    v_raw_boundary, since, v_raw_boundary;
end;
$$;

/*
 * Workhorse: matching backend-count per underlying grain row (minute for raw
 * / rollup_1m, hour for rollup_1h) over [start_ts, end_ts), with uniform
 * filters. One row per grain timestamp that EXISTS in the source (cnt may be 0
 * when nothing matched) so callers can distinguish measured-zero from no-data.
 * 'raw' supports exact query_id filters (including wait<->query ties); rollup
 * query_counts are compacted and must not be used to prove an exact match or
 * zero (callers route those requests to 'raw'). grain_secs is 60 (raw /
 * rollup_1m / rollup_1h_minutes) or 3600 (rollup_1h and legacy/incomplete
 * rollup_1h detail).
 * 'rollup_1h_minutes' is the internal minute-capable view used for
 * unfiltered/database-only totals; invalid detail emits one hourly row.
 */
create or replace function ash._grain_counts(
  start_ts int4,
  end_ts int4,
  source text,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null
)
returns table (
  ts int4,
  cnt numeric,
  grain_secs int4
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_datid oid;
begin
  if database is not null then
    select db.oid into v_datid from pg_database as db
    where db.datname = database;
    if v_datid is null then
      return;  -- unknown database name: no matching rows
    end if;
  end if;

  if source = 'raw' then
    return query
    with mins as (
      select distinct (sample_row.sample_ts / 60) * 60 as mts
      from ash.sample as sample_row
      where sample_row.slot = any(ash._active_slots_for_at(
                       ash.ts_to_timestamptz(start_ts),
                       ash.ts_to_timestamptz(end_ts)))
        and sample_row.sample_ts >= start_ts
        and sample_row.sample_ts < end_ts
        and (v_datid is null or sample_row.datid = v_datid)
    ),
    expanded as (
      select (sample_row.sample_ts / 60) * 60 as mts,
             sample_row.slot,
             sample_row.datid,
             (-sample_row.data[data_idx])::int as wait_id,
             sample_row.data[data_idx + 2 + backend.n] as map_id
      from ash.sample as sample_row
      cross join generate_subscripts(sample_row.data, 1) as data_idx
      cross join lateral generate_series(
        0, greatest(sample_row.data[data_idx + 1] - 1, -1)
      ) as backend(n)
      where sample_row.slot = any(ash._active_slots_for_at(
                       ash.ts_to_timestamptz(start_ts),
                       ash.ts_to_timestamptz(end_ts)))
        and sample_row.sample_ts >= start_ts
        and sample_row.sample_ts < end_ts
        and sample_row.data[data_idx] < 0
        and data_idx + 1 <= array_length(sample_row.data, 1)
        and data_idx + 2 + backend.n <= array_length(sample_row.data, 1)
        and (v_datid is null or sample_row.datid = v_datid)
    ),
    matched as (
      select expanded.mts, count(*)::numeric as cnt
      from expanded
      join ash.wait_event_map as event_map on event_map.id = expanded.wait_id
      left join ash.query_map_all as query_map
        on query_map.slot = expanded.slot
        and query_map.id = expanded.map_id
        and expanded.map_id <> 0
      where (wait_event_type is null or event_map.type = wait_event_type)
        and (wait_event is null
             or (case when event_map.event = event_map.type
                      then event_map.event
                      else event_map.type || ':' || event_map.event
                 end) = wait_event
             or event_map.event = wait_event)
        -- function-qualified: bare query_id is ambiguous against query_id col
        and (_grain_counts.query_id is null
             or query_map.query_id = _grain_counts.query_id)
      group by expanded.mts
    )
    select mins.mts, coalesce(matched.cnt, 0)::numeric, 60
    from mins
    left join matched on matched.mts = mins.mts;

  elsif source = 'rollup_1h_minutes' then
    /*
     * Internal minute-grain view of rollup_1h via the preserved minute_counts
     * arrays, so peak_aas / p99_aas survive the rollup_1m -> rollup_1h seam
     * (same values a rollup_1m read of the window would produce). Totals only:
     * wait filters need hour-grain arrays, while exact query filters are routed
     * to raw. Legacy/incomplete arrays emit one exact hourly datum: callers
     * detect that case up front, normalize the whole window to hour grain, and
     * publish source = rollup_1h_flat.
     */
    if wait_event_type is not null or wait_event is not null
       or query_id is not null then
      raise exception
        'ash._grain_counts: rollup_1h_minutes supports no wait/query filters';
    end if;
    return query
    with hours as (
      select rollup_hour.ts, rollup_hour.datid,
             rollup_hour.minute_counts, rollup_hour.wait_counts,
             ash._minute_counts_valid(
               rollup_hour.minute_counts,
               rollup_hour.wait_counts
             ) as has_minutes
      from ash.rollup_1h as rollup_hour
      where rollup_hour.ts >= start_ts - 3540 and rollup_hour.ts < end_ts
        and (v_datid is null or rollup_hour.datid = v_datid)
    ),
    mins as (
      select (hours.ts + (minute_elem.idx - 1) * 60)::int4 as mts,
             minute_elem.mc::numeric as cnt,
             60::int4 as grain_secs
      from hours
      cross join lateral unnest(hours.minute_counts)
        with ordinality as minute_elem(mc, idx)
      where hours.has_minutes and minute_elem.mc is not null
      union all
      select hours.ts,
             (select coalesce(sum(hours.wait_counts[pos + 1]), 0)
              from generate_subscripts(hours.wait_counts, 1) as pos
              where pos % 2 = 1)::numeric,
             3600::int4
      from hours
      where not hours.has_minutes
    )
    select mins.mts, sum(mins.cnt)::numeric, mins.grain_secs
    from mins
    where mins.mts >= start_ts and mins.mts < end_ts
    group by mins.mts, mins.grain_secs;

  elsif source = 'rollup_1h' then
    if query_id is not null then
      return query
      select rollup_hour.ts, sum(counts.cnt)::numeric, 3600
      from ash.rollup_1h as rollup_hour
      cross join lateral (
        select coalesce(sum(rollup_hour.query_counts[pos + 1]), 0) as cnt
        from generate_subscripts(rollup_hour.query_counts, 1) as pos
        where pos % 2 = 1 and rollup_hour.query_counts[pos] = query_id
      ) as counts
      where rollup_hour.ts >= start_ts and rollup_hour.ts < end_ts
        and (v_datid is null or rollup_hour.datid = v_datid)
      group by rollup_hour.ts;
    else
      return query
      select rollup_hour.ts, sum(counts.cnt)::numeric, 3600
      from ash.rollup_1h as rollup_hour
      cross join lateral (
        select coalesce(sum(rollup_hour.wait_counts[pos + 1]), 0) as cnt
        from generate_subscripts(rollup_hour.wait_counts, 1) as pos
        join ash.wait_event_map as event_map
          on event_map.id = rollup_hour.wait_counts[pos]
        where pos % 2 = 1
          and (wait_event_type is null or event_map.type = wait_event_type)
          and (wait_event is null
               or (case when event_map.event = event_map.type
                        then event_map.event
                        else event_map.type || ':' || event_map.event
                   end) = wait_event
               or event_map.event = wait_event)
      ) as counts
      where rollup_hour.ts >= start_ts and rollup_hour.ts < end_ts
        and (v_datid is null or rollup_hour.datid = v_datid)
      group by rollup_hour.ts;
    end if;

  else  -- rollup_1m
    if query_id is not null then
      return query
      select rollup_min.ts, sum(counts.cnt)::numeric, 60
      from ash.rollup_1m as rollup_min
      cross join lateral (
        select coalesce(sum(rollup_min.query_counts[pos + 1]), 0) as cnt
        from generate_subscripts(rollup_min.query_counts, 1) as pos
        where pos % 2 = 1 and rollup_min.query_counts[pos] = query_id
      ) as counts
      where rollup_min.ts >= start_ts and rollup_min.ts < end_ts
        and (v_datid is null or rollup_min.datid = v_datid)
      group by rollup_min.ts;
    else
      return query
      select rollup_min.ts, sum(counts.cnt)::numeric, 60
      from ash.rollup_1m as rollup_min
      cross join lateral (
        select coalesce(sum(rollup_min.wait_counts[pos + 1]), 0) as cnt
        from generate_subscripts(rollup_min.wait_counts, 1) as pos
        join ash.wait_event_map as event_map
          on event_map.id = rollup_min.wait_counts[pos]
        where pos % 2 = 1
          and (wait_event_type is null or event_map.type = wait_event_type)
          and (wait_event is null
               or (case when event_map.event = event_map.type
                        then event_map.event
                        else event_map.type || ':' || event_map.event
                   end) = wait_event
               or event_map.event = wait_event)
      ) as counts
      where rollup_min.ts >= start_ts and rollup_min.ts < end_ts
        and (v_datid is null or rollup_min.datid = v_datid)
      group by rollup_min.ts;
    end if;
  end if;
end;
$$;

-- ============================================================================
-- 2.0 DATA FUNCTIONS
-- ============================================================================

/*
 * Scalar AAS load summary for one window, optionally filtered. avg_aas is the
 * window average; peak_aas / p99_aas are the max and 99th percentile of per
 * bucket AAS (zero-filled within data coverage) so a short spike is not hidden
 * by the average. backend_seconds is the absolute secondary. The window is
 * snapped to minute boundaries. Every explicit query_id filter needs exact
 * raw attribution and raises when only compacted history covers the window.
 */
create or replace function ash.aas(
  since timestamptz default null,
  until timestamptz default null,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null,
  bucket interval default '1 minute'
)
returns table (
  period_start timestamptz,
  period_end timestamptz,
  source text,
  effective_bucket interval,
  buckets_expected bigint,
  buckets_with_data bigint,
  avg_aas numeric,
  peak_aas numeric,
  p99_aas numeric,
  backend_seconds numeric
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 hour');
  v_to timestamptz := coalesce(until, now());
  v_start_ts int4;
  v_end_ts int4;
  v_bucket_secs int4;
  v_requested_bucket_secs numeric;
  v_grain_secs int4;
  v_si numeric;
  v_source text;
  v_read_source text;
  v_tie boolean;
  v_exact_query boolean;
  v_coarser_query_history boolean;
  v_extrema_supported boolean;
  v_raw_start timestamptz;
begin
  if v_from > v_to then
    raise exception
      'ash.aas: since must be less than or equal to until';
  end if;

  v_requested_bucket_secs := extract(epoch from bucket);
  if v_requested_bucket_secs is null or v_requested_bucket_secs < 60 then
    raise exception 'bucket must be at least 1 minute, got %', bucket;
  end if;
  v_bucket_secs := ceil(v_requested_bucket_secs)::int4;

  v_start_ts := (ash.ts_from_timestamptz(v_from) / 60) * 60;
  v_end_ts := (ash.ts_from_timestamptz(v_to) / 60) * 60;
  /*
   * overflow-safe empty/degenerate-window guard (#63): never let
   * v_start_ts + 60 wrap past INT4_MAX near the 2094 epoch horizon.
   */
  if v_end_ts <= v_start_ts then
    v_end_ts := least(v_start_ts::bigint + 60, 2147483647)::int4;
  end if;
  v_si := ash._sample_interval_secs();

  v_tie := query_id is not null
           and (wait_event_type is not null or wait_event is not null);
  v_exact_query := query_id is not null;

  if v_exact_query then
    v_source := 'raw';
    /*
     * Preserve the existing tie guard. For the broader query_id-only case,
     * raise only when ordinary source selection names a coarser source AND it
     * has retained coverage in the requested pre-raw slice. A young install's
     * first rollup can cover only raw's first retained minute, so forcing raw
     * loses no attribution and must not raise even though _pick_source()'s
     * fallback names the rollup.
     */
    v_coarser_query_history := ash._exact_query_uses_coarser(
      v_start_ts,
      v_end_ts,
      database
    );
    if v_tie or v_coarser_query_history then
      /*
       * The landed #163/#189 split gives the existing tie guard a logical ring
       * boundary. When a selected rollup proves a physical raw-coverage gap,
       * pass the physical oldest sample instead so the guard cannot approve
       * silent data loss.
       */
      v_raw_start := case
        when v_coarser_query_history then ash._raw_oldest_sample()
        else ash._raw_retention_start()
      end;
      perform ash._raise_tie_retention(
        v_raw_start,
        v_start_ts,
        v_end_ts,
        v_from
      );
    end if;
    v_grain_secs := 60;
  else
    v_source := ash._pick_source_agg(ash.ts_to_timestamptz(v_start_ts),
                                     ash.ts_to_timestamptz(v_end_ts));
    v_grain_secs := case when v_source = 'rollup_1h' then 3600 else 60 end;
  end if;
  v_read_source := v_source;

  /*
   * Genuine minute_counts keep unfiltered/database-only reads at minute
   * grain. If any contributing hour has legacy/incomplete detail, disclose
   * rollup_1h_flat and conservatively plan the whole window at hour grain.
   * Wait filters use hour-grain arrays; exact query filters already forced raw.
   */
  if v_source = 'rollup_1h' and wait_event_type is null
     and wait_event is null and query_id is null then
    v_read_source := 'rollup_1h_minutes';
    if ash._rollup_1h_has_flat(v_start_ts, v_end_ts, database) then
      v_source := 'rollup_1h_flat';
      v_grain_secs := 3600;
    else
      v_grain_secs := 60;
    end if;
  end if;

  /*
   * Hour arrays describe whole [ts, ts + 1 hour) intervals. Expand partial
   * requested bounds to complete hours so totals are never divided by a
   * clipped duration (#130). period_start/period_end disclose these effective
   * bounds.
   */
  if v_grain_secs = 3600 then
    v_start_ts := ((v_start_ts::bigint / 3600) * 3600)::int4;
    v_end_ts := least(
      ((v_end_ts::bigint + 3599) / 3600) * 3600,
      2147483647
    )::int4;
  end if;

  /*
   * peak/p99 bucket cannot be finer than the source grain, and must be a
   * whole MULTIPLE of it: a non-multiple bucket (e.g. '90 seconds' over
   * minute grain) misaligns with the grain rows — a bucket then holds up to
   * ceil(bucket/grain) whole grains of activity but divides by its own
   * (shorter) coverage, fabricating AAS peaks that no grain ever reached.
   * Round UP to the nearest grain multiple so the effective bucket is never
   * finer than the caller requested.
   */
  v_bucket_secs := (
    (greatest(v_bucket_secs, v_grain_secs)::bigint + v_grain_secs - 1)
    / v_grain_secs * v_grain_secs
  )::int4;
  v_extrema_supported := v_grain_secs <= v_requested_bucket_secs;

  return query
  /*
   * Assign each grain row to its bucket arithmetically and equi-group (was a
   * range self-join, O(buckets x grains) — a 1-month window planned as a
   * nested-loop range join took ~38s). Only sampler-covered buckets appear in
   * per_bucket, which is exactly the peak/p99 zero-fill frame;
   * buckets_expected is counted arithmetically.
   * Buckets are calendar-aligned: keyed by flooring the grain timestamp to
   * bucket relative to ash.epoch() (midnight UTC), NOT to since's offset —
   * a '1 hour' bucket starts on the hour, '1 day' on the UTC day. The same
   * absolute window therefore always yields the same bucket boundaries
   * (reproducible regardless of when the call is made). Edge buckets clipped
   * by the window divide by their in-window coverage only.
   */
  with grains as (
    select (grain_row.ts / v_bucket_secs) * v_bucket_secs as bstart,
           grain_row.cnt
    from ash._grain_counts(v_start_ts, v_end_ts, v_read_source,
           wait_event_type, wait_event, query_id, database) as grain_row
  ),
  per_bucket as (
    select bstart, count(*) as n, sum(cnt) as cnt
    from grains
    group by bstart
  ),
  bucket_aas as (
    select bstart,
           (cnt * v_si / (least(bstart + v_bucket_secs, v_end_ts)
                          - greatest(bstart, v_start_ts))) as aas
    from per_bucket
  )
  select
    ash.ts_to_timestamptz(v_start_ts),
    ash.ts_to_timestamptz(v_end_ts),
    v_source,
    v_bucket_secs * interval '1 second',
    (((v_end_ts - 1) / v_bucket_secs)
      - (v_start_ts / v_bucket_secs) + 1)::bigint,
    (select count(*) from per_bucket)::bigint,
    round((select coalesce(sum(cnt), 0) from per_bucket) * v_si
          / (v_end_ts - v_start_ts)::numeric, 2),
    case when v_extrema_supported then
      coalesce(round((select max(aas) from bucket_aas), 2), 0)
    end,
    case when v_extrema_supported then
      coalesce(round((
        select percentile_cont(0.99) within group (order by aas)
        from bucket_aas
      )::numeric, 2), 0)
    end,
    round((select coalesce(sum(cnt), 0) from per_bucket) * v_si, 2);
end;
$$;

/*
 * AAS time series: one row per bucket across the whole window (no-data buckets
 * included with data_points = 0 and null AAS). bucket => null auto-selects
 * grain by span. peak_aas is the worst underlying grain within the bucket;
 * p99_aas is the 99th percentile of the per-grain AAS. Genuine rollup_1h
 * minute_counts preserve minute grain for unfiltered/database-only reads.
 * Hour-grain reads widen partial bounds and buckets; peak/p99 are NULL when
 * that retained grain exceeds the bucket the caller requested. Explicit
 * query_id filters force raw and raise only when coarser retained history
 * would otherwise be discarded (apart from the existing wait-query tie guard).
 */
create or replace function ash.timeline(
  since timestamptz default null,
  until timestamptz default null,
  bucket interval default null,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null
)
returns table (
  bucket_start timestamptz,
  source text,
  data_points bigint,
  avg_aas numeric,
  peak_aas numeric,
  p99_aas numeric
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 hour');
  v_to timestamptz := coalesce(until, now());
  v_start_ts int4;
  v_end_ts int4;
  v_span int4;
  v_bucket_secs int4;
  v_requested_bucket_secs numeric;
  v_grain_secs int4;
  v_si numeric;
  v_source text;
  v_read_source text;
  v_tie boolean;
  v_exact_query boolean;
  v_coarser_query_history boolean;
  v_extrema_supported boolean;
  v_raw_start timestamptz;
begin
  if v_from > v_to then
    raise exception
      'ash.timeline: since must be less than or equal to until';
  end if;

  v_start_ts := (ash.ts_from_timestamptz(v_from) / 60) * 60;
  v_end_ts := (ash.ts_from_timestamptz(v_to) / 60) * 60;
  -- overflow-safe empty/degenerate-window guard (#63).
  if v_end_ts <= v_start_ts then
    v_end_ts := least(v_start_ts::bigint + 60, 2147483647)::int4;
  end if;
  v_span := v_end_ts - v_start_ts;

  if bucket is null then
    v_bucket_secs := case
      when v_span <= 6 * 3600 then 60
      when v_span <= 7 * 86400 then 3600
      else 86400 end;
    v_requested_bucket_secs := v_bucket_secs;
  else
    v_requested_bucket_secs := extract(epoch from bucket);
    if v_requested_bucket_secs < 60 then
      raise exception 'bucket must be at least 1 minute, got %', bucket;
    end if;
    v_bucket_secs := ceil(v_requested_bucket_secs)::int4;
  end if;

  v_si := ash._sample_interval_secs();

  v_tie := query_id is not null
           and (wait_event_type is not null or wait_event is not null);
  v_exact_query := query_id is not null;
  if v_exact_query then
    v_source := 'raw';
    v_coarser_query_history := ash._exact_query_uses_coarser(
      v_start_ts,
      v_end_ts,
      database
    );
    if v_tie or v_coarser_query_history then
      v_raw_start := case
        when v_coarser_query_history then ash._raw_oldest_sample()
        else ash._raw_retention_start()
      end;
      perform ash._raise_tie_retention(
        v_raw_start,
        v_start_ts,
        v_end_ts,
        v_from
      );
    end if;
    v_grain_secs := 60;
  else
    v_source := ash._pick_source_agg(ash.ts_to_timestamptz(v_start_ts),
                                     ash.ts_to_timestamptz(v_end_ts));
    if v_source = 'rollup_1h' and wait_event_type is null
       and wait_event is null and query_id is null then
      /*
       * Genuine minute_counts keep the unfiltered/database-only read at
       * minute grain. Any legacy/incomplete contributing hour makes the
       * whole effective read hour-grain and is disclosed in the source.
       */
      v_read_source := 'rollup_1h_minutes';
      if ash._rollup_1h_has_flat(v_start_ts, v_end_ts, database) then
        v_source := 'rollup_1h_flat';
        v_grain_secs := 3600;
      else
        v_grain_secs := 60;
      end if;
    else
      v_grain_secs := case when v_source = 'rollup_1h' then 3600 else 60 end;
    end if;
    v_read_source := coalesce(v_read_source, v_source);
  end if;
  v_read_source := coalesce(v_read_source, v_source);

  if v_grain_secs = 3600 then
    v_start_ts := ((v_start_ts::bigint / 3600) * 3600)::int4;
    v_end_ts := least(
      ((v_end_ts::bigint + 3599) / 3600) * 3600,
      2147483647
    )::int4;
  end if;

  -- snap to a whole grain multiple (see ash.aas): a non-multiple bucket
  -- misaligns with the grain rows and fabricates per-bucket AAS.
  v_bucket_secs := (
    (greatest(v_bucket_secs, v_grain_secs)::bigint + v_grain_secs - 1)
    / v_grain_secs * v_grain_secs
  )::int4;
  v_extrema_supported := v_grain_secs <= v_requested_bucket_secs;
  v_span := v_end_ts - v_start_ts;

  /*
   * Bound the emitted-row count after widening to the effective grain.
   */
  if (v_span::bigint / v_bucket_secs) > 100000 then
    raise exception
      'ash.timeline: % buckets exceeds the 100000-row cap; use a coarser '
      'bucket (or bucket => null for auto grain)',
      (v_span::bigint / v_bucket_secs);
  end if;

  return query
  /*
   * Arithmetic bucket-keying + equi-join (was an O(buckets x grains) range
   * join). No-data buckets still appear via the left join from the full
   * bucket series, with data_points = 0 and null AAS.
   * Buckets are calendar-aligned (floored to bucket relative to ash.epoch(),
   * midnight UTC), not anchored to since: the same absolute window always
   * yields the same bucket_start labels, and an hour/day bucket carries its
   * calendar hour/UTC-day label. The first bucket_start may therefore precede
   * since; edge buckets divide by their in-window coverage only.
   */
  with source_grains as (
    select grain_row.ts, grain_row.cnt
    from ash._grain_counts(v_start_ts, v_end_ts, v_read_source,
           wait_event_type, wait_event, query_id, database) as grain_row
  ),
  normalized_grains as (
    select
      (source_grains.ts / v_grain_secs) * v_grain_secs as gstart,
      sum(source_grains.cnt) as cnt
    from source_grains
    group by 1
  ),
  grains as (
    select
      (normalized_grains.gstart / v_bucket_secs) * v_bucket_secs as bstart,
      normalized_grains.cnt * v_si / v_grain_secs as gaas,
      normalized_grains.cnt
    from normalized_grains
  ),
  agg as (
    select bstart, count(*) as n, sum(cnt) as cnt, max(gaas) as peak,
           percentile_cont(0.99) within group (order by gaas) as p99
    from grains
    group by bstart
  ),
  buckets as (
    select bucket_series.ts::int4 as bstart
    from generate_series(
      ((v_start_ts / v_bucket_secs) * v_bucket_secs)::bigint,
      (v_end_ts - 1)::bigint, v_bucket_secs
    ) as bucket_series(ts)
  )
  select
    ash.ts_to_timestamptz(buckets.bstart),
    v_source,
    coalesce(agg.n, 0)::bigint,
    case when agg.n > 0 then
      round(agg.cnt * v_si / (least(buckets.bstart + v_bucket_secs, v_end_ts)
                            - greatest(buckets.bstart, v_start_ts)), 2)
    end,
    case when agg.n > 0 and v_extrema_supported then
      round(agg.peak, 2)
    end,
    case when agg.n > 0 and v_extrema_supported then
      round(agg.p99::numeric, 2)
    end
  from buckets
  left join agg on agg.bstart = buckets.bstart
  order by buckets.bstart;
end;
$$;

/*
 * Standard trailing windows for triage: one summary row per window requested
 * to end at until. Each delegates to ash.aas(), whose effective bounds may
 * snap outward at hour grain. Short windows may read raw for the freshest
 * partial minute; wide windows read rollups. Genuine minute_counts keep
 * minute-grain peak/p99;
 * legacy flat hours disclose an effective hour bucket and NULL unsupported
 * extremes. buckets_with_data is a true count at the grain named by bucket.
 * After the arithmetic-bucketing fix this is cheap even for the 1-month
 * window (~90ms for the whole call on a month of rollups).
 */
create or replace function ash.periods(
  until timestamptz default null
)
returns table (
  period text,
  period_start timestamptz,
  period_end timestamptz,
  source text,
  bucket interval,
  buckets_with_data bigint,
  avg_aas numeric,
  peak_aas numeric,
  p99_aas numeric
)
language sql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
  with window_end(end_ts) as (
    select date_trunc('minute', coalesce(until, now()))
  ),
  periods(label, span) as (
    values
      ('1m'::text,  interval '1 minute'),
      ('5m',        interval '5 minutes'),
      ('1h',        interval '1 hour'),
      ('1d',        interval '1 day'),
      ('1w',        interval '1 week'),
      ('1mo',       interval '30 days')
  )
  select
    period_def.label,
    aas_result.period_start,
    aas_result.period_end,
    aas_result.source,
    aas_result.effective_bucket,
    aas_result.buckets_with_data,
    aas_result.avg_aas,
    aas_result.peak_aas,
    aas_result.p99_aas
  from periods as period_def
  cross join window_end
  cross join lateral ash.aas(
    window_end.end_ts - period_def.span, window_end.end_ts
  ) as aas_result
$$;

/*
 * Per-key backend-count per grain row for a breakdown dimension, with uniform
 * filters. Companion to _grain_counts. key is the dimension value (text);
 * key_num carries the numeric query_id for the 'query_id' dimension (null
 * otherwise) so the caller can join query text. 'raw' supports exact query
 * filters and wait<->query ties. An unfiltered rollup query breakdown returns
 * retained query IDs plus a NULL residual for uncaptured / compacted-away
 * attribution, keeping its total consistent with the source's wait counts.
 */
create or replace function ash._grain_by(
  start_ts int4,
  end_ts int4,
  source text,
  dimension text,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null
)
returns table (
  ts int4,
  key text,
  key_num bigint,
  cnt numeric
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_datid oid;
  v_tbl text;
  v_disp constant text :=
    '(case when event_map.event = event_map.type then event_map.event '
    'else event_map.type || '':'' || event_map.event end)';
begin
  if dimension not in (
       'wait_event_type', 'wait_event', 'query_id', 'database'
     ) then
    raise exception
      'ash.top: unknown dimension %; '
      'use wait_event_type|wait_event|query_id|database', dimension;
  end if;
  if database is not null then
    select db.oid into v_datid from pg_database as db
    where db.datname = database;
    if v_datid is null then return; end if;
  end if;

  if source = 'raw' then
    return query
    with expanded as (
      select (sample_row.sample_ts / 60) * 60 as mts,
             sample_row.slot,
             sample_row.datid,
             (-sample_row.data[data_idx])::int as wait_id,
             sample_row.data[data_idx + 2 + backend.n] as map_id
      from ash.sample as sample_row
      cross join generate_subscripts(sample_row.data, 1) as data_idx
      cross join lateral generate_series(
        0, greatest(sample_row.data[data_idx + 1] - 1, -1)
      ) as backend(n)
      where sample_row.slot = any(ash._active_slots_for_at(
                       ash.ts_to_timestamptz(start_ts),
                       ash.ts_to_timestamptz(end_ts)))
        and sample_row.sample_ts >= start_ts
        and sample_row.sample_ts < end_ts
        and sample_row.data[data_idx] < 0
        and data_idx + 1 <= array_length(sample_row.data, 1)
        and data_idx + 2 + backend.n <= array_length(sample_row.data, 1)
        and (v_datid is null or sample_row.datid = v_datid)
    ),
    decoded as (
      select expanded.mts,
             event_map.type as wet,
             (case when event_map.event = event_map.type then event_map.event
                   else event_map.type || ':' || event_map.event end) as evt,
             query_map.query_id as qid,
             expanded.datid
      from expanded
      join ash.wait_event_map as event_map on event_map.id = expanded.wait_id
      left join ash.query_map_all as query_map
        on query_map.slot = expanded.slot
        and query_map.id = expanded.map_id
        and expanded.map_id <> 0
      where (wait_event_type is null or event_map.type = wait_event_type)
        and (wait_event is null
             or (case when event_map.event = event_map.type
                      then event_map.event
                      else event_map.type || ':' || event_map.event
                 end) = wait_event
             or event_map.event = wait_event)
        -- function-qualified: bare query_id is ambiguous against query_id col
        and (_grain_by.query_id is null
             or query_map.query_id = _grain_by.query_id)
    )
    select decoded.mts,
           case dimension
             when 'wait_event_type' then decoded.wet
             when 'wait_event' then decoded.evt
             /*
              * unattributed activity (no query_id captured) keeps a NULL key,
              * not a sentinel string: callers can tell "no attribution" from
              * a real key without parsing.
              */
             when 'query_id' then decoded.qid::text
             else coalesce(
                    (select db.datname::text from pg_database as db
                     where db.oid = decoded.datid),
                    '<oid:' || decoded.datid || '>')
           end,
           case when dimension = 'query_id' then decoded.qid else null end,
           count(*)::numeric
    from decoded
    group by 1, 2, 3;
    return;
  end if;

  if source = 'rollup_1h_minutes' then
    /*
     * minute_counts is stored per (hour, datid), so a plain database
     * breakdown retains the same minute precision as an unfiltered scalar
     * read. Wait/query filters cannot be reconstructed from this total.
     */
    if dimension <> 'database'
       or wait_event_type is not null
       or wait_event is not null
       or query_id is not null then
      raise exception
        'ash._grain_by: rollup_1h_minutes supports only an unfiltered '
        'database dimension';
    end if;

    return query
    with hours as (
      select
        rollup_hour.ts,
        rollup_hour.datid,
        coalesce(
          db.datname::text,
          '<oid:' || rollup_hour.datid || '>'
        ) as database_key,
        rollup_hour.minute_counts,
        rollup_hour.wait_counts,
        ash._minute_counts_valid(
          rollup_hour.minute_counts,
          rollup_hour.wait_counts
        ) as has_minutes
      from ash.rollup_1h as rollup_hour
      left join pg_database as db
        on db.oid = rollup_hour.datid
      where rollup_hour.ts >= start_ts - 3540
        and rollup_hour.ts < end_ts
        and (v_datid is null or rollup_hour.datid = v_datid)
    ),
    grains as (
      select
        (hours.ts + (minute_elem.idx - 1) * 60)::int4 as mts,
        hours.database_key,
        minute_elem.mc::numeric as cnt
      from hours
      cross join lateral unnest(hours.minute_counts)
        with ordinality as minute_elem(mc, idx)
      where hours.has_minutes
        and minute_elem.mc is not null
      union all
      select
        hours.ts,
        hours.database_key,
        (
          select coalesce(sum(hours.wait_counts[pos + 1]), 0)
          from generate_subscripts(hours.wait_counts, 1) as pos
          where pos % 2 = 1
        )::numeric
      from hours
      where not hours.has_minutes
    )
    select
      grains.mts,
      grains.database_key,
      null::bigint,
      sum(grains.cnt)::numeric
    from grains
    where grains.mts >= start_ts
      and grains.mts < end_ts
    group by grains.mts, grains.database_key;
    return;
  end if;

  v_tbl := case
    when source = 'rollup_1h' then 'ash.rollup_1h'
    else 'ash.rollup_1m'
  end;

  if dimension in ('wait_event_type', 'wait_event') then
    return query execute format($q$
      select rollup.ts,
             %s as key, null::bigint as key_num,
             sum(rollup.wait_counts[pos + 1])::numeric as cnt
      from %s as rollup
      cross join generate_subscripts(rollup.wait_counts, 1) as pos
      join ash.wait_event_map as event_map
        on event_map.id = rollup.wait_counts[pos]
      where pos %% 2 = 1 and rollup.ts >= $1 and rollup.ts < $2
        and ($3 is null or rollup.datid = $3)
        and ($4 is null or event_map.type = $4)
        and ($5 is null or %s = $5 or event_map.event = $5)
      group by rollup.ts, key
    $q$,
      case when dimension = 'wait_event_type' then 'event_map.type'
           else v_disp end,
      v_tbl, v_disp)
    using start_ts, end_ts, v_datid, wait_event_type, wait_event;

  elsif dimension = 'query_id' then
    return query execute format($q$
      /*
       * Per source row, one grouped query-array pass emits every named query
       * plus a grand-total grouping set. The grand total becomes the
       * non-negative wait-total difference: query_counts intentionally omits
       * below-threshold IDs and an hourly row retains only its top 100.
       *
       * Writer-produced arrays are one-based pairs whose non-negative query
       * totals do not exceed their wait totals. This keeps the residual in the
       * same stream as named rows without the former second query_counts scan
       * or a window-wide materialized expansion. Explicit query_id filters
       * never reach this public rollup path; the residual predicate also keeps
       * direct helper calls honest.
       */
      select
        rollup.ts,
        keyed.query_id::text as key,
        keyed.query_id::bigint as key_num,
        sum(keyed.cnt)::numeric as cnt
      from %s as rollup
      cross join lateral (
        select coalesce(
          sum(rollup.wait_counts[pair_pos + 1]),
          0
        )::numeric as cnt
        from generate_series(
          1,
          coalesce(cardinality(rollup.wait_counts), 0),
          2
        ) as pair_pos
      ) as wait_total
      cross join lateral (
        select
          case
            when grouping(query_pair.query_id) = 0
              then query_pair.query_id
          end as query_id,
          case
            when grouping(query_pair.query_id) = 0
              then sum(query_pair.cnt)
            else greatest(
              wait_total.cnt - coalesce(sum(query_pair.cnt), 0),
              0
            )
          end::numeric as cnt,
          grouping(query_pair.query_id) = 1 as is_residual
        from (
          select
            rollup.query_counts[pair_pos] as query_id,
            rollup.query_counts[pair_pos + 1]::numeric as cnt
          from generate_series(
            1,
            coalesce(cardinality(rollup.query_counts), 0),
            2
          ) as pair_pos
        ) as query_pair
        group by grouping sets ((query_pair.query_id), ())
      ) as keyed
      where rollup.ts >= $1
        and rollup.ts < $2
        and ($3 is null or rollup.datid = $3)
        and keyed.cnt > 0
        and (
          (keyed.is_residual and $4 is null)
          or (
            not keyed.is_residual
            and ($4 is null or keyed.query_id = $4)
          )
        )
      group by rollup.ts, keyed.query_id
    $q$, v_tbl)
    using start_ts, end_ts, v_datid, query_id;

  else  -- database
    if query_id is not null then
      return query execute format($q$
        select rollup.ts,
               coalesce(db.datname::text, '<oid:' || rollup.datid || '>')
                 as key,
               null::bigint as key_num,
               (select coalesce(sum(rollup.query_counts[pos + 1]), 0)
                from generate_subscripts(rollup.query_counts, 1) as pos
                where pos %% 2 = 1
                  and rollup.query_counts[pos] = $4)::numeric as cnt
        from %s as rollup
        left join pg_database as db on db.oid = rollup.datid
        where rollup.ts >= $1 and rollup.ts < $2
          and ($3 is null or rollup.datid = $3)
      $q$, v_tbl)
      using start_ts, end_ts, v_datid, query_id;
    else
      return query execute format($q$
        select rollup.ts,
               coalesce(db.datname::text, '<oid:' || rollup.datid || '>')
                 as key,
               null::bigint as key_num,
               (select coalesce(sum(rollup.wait_counts[pos + 1]), 0)
                from generate_subscripts(rollup.wait_counts, 1) as pos
                join ash.wait_event_map as event_map
                  on event_map.id = rollup.wait_counts[pos]
                where pos %% 2 = 1
                  and ($4 is null or event_map.type = $4)
                  and ($5 is null or %s = $5
                       or event_map.event = $5))::numeric as cnt
        from %s as rollup
        left join pg_database as db on db.oid = rollup.datid
        where rollup.ts >= $1 and rollup.ts < $2
          and ($3 is null or rollup.datid = $3)
      $q$, v_disp, v_tbl)
      using start_ts, end_ts, v_datid, wait_event_type, wait_event;
    end if;
  end if;
end;
$$;

/*
 * The single vertical drill: AAS broken down by one dimension, every row
 * carrying avg/peak/p99 plus its share (pct) of the window total. Filters
 * compose with the dimension. Every explicit query_id filter needs exact raw
 * attribution. An unfiltered rollup query breakdown carries unpreserved
 * attribution in its NULL key. query_text is filled only for the query_id
 * dimension with pg_stat_statements present. order_by picks the
 * ranking metric BEFORE the top-n cut: 'avg' (default; sustained load),
 * 'peak' or 'p99' (spike-first — a query dominant for one minute of an
 * incident ranks above cosmetic baseline rows that beat it on average).
 */
create or replace function ash.top(
  dimension text,
  since timestamptz default null,
  until timestamptz default null,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null,
  n int default 10,
  bucket interval default '1 minute',
  order_by text default 'avg'
)
returns table (
  key text,
  query_text text,
  source text,
  period_start timestamptz,
  period_end timestamptz,
  effective_bucket interval,
  avg_aas numeric,
  peak_aas numeric,
  p99_aas numeric,
  backend_seconds numeric,
  pct numeric
)
language plpgsql
stable
set jit = off
-- pgss data access is schema-qualified via ash._pgss_schema() (#115); public
-- stays in the path only as defense-in-depth and to keep this function in the
-- catalog-derived set that ash._apply_pgss_search_path() rewrites.
set search_path = pg_catalog, ash, public
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 hour');
  v_to timestamptz := coalesce(until, now());
  v_start_ts int4;
  v_end_ts int4;
  v_bucket_secs int4;
  v_requested_bucket_secs numeric;
  v_grain_secs int4;
  v_si numeric;
  v_source text;
  v_read_source text;
  v_tie boolean;
  v_exact_query boolean;
  v_coarser_query_history boolean;
  v_extrema_supported boolean;
  v_raw_start timestamptz;
  v_has_pgss boolean := false;
  v_pgss_schema text;
  v_key_num bigint;
begin
  if v_from > v_to then
    raise exception
      'ash.top: since must be less than or equal to until';
  end if;

  if dimension not in (
       'wait_event_type', 'wait_event', 'query_id', 'database'
     ) then
    raise exception
      'ash.top: unknown dimension %; '
      'use wait_event_type|wait_event|query_id|database', dimension;
  end if;
  if order_by not in ('avg', 'peak', 'p99') then
    raise exception 'ash.top: unknown order_by %; use avg|peak|p99', order_by;
  end if;
  v_requested_bucket_secs := extract(epoch from bucket);
  if v_requested_bucket_secs is null or v_requested_bucket_secs < 60 then
    raise exception 'bucket must be at least 1 minute, got %', bucket;
  end if;
  v_bucket_secs := ceil(v_requested_bucket_secs)::int4;

  v_start_ts := (ash.ts_from_timestamptz(v_from) / 60) * 60;
  v_end_ts := (ash.ts_from_timestamptz(v_to) / 60) * 60;
  -- overflow-safe empty/degenerate-window guard (#63).
  if v_end_ts <= v_start_ts then
    v_end_ts := least(v_start_ts::bigint + 60, 2147483647)::int4;
  end if;
  v_si := ash._sample_interval_secs();

  v_tie := (dimension in ('wait_event_type', 'wait_event')
            and query_id is not null)
        or (dimension = 'query_id'
            and (wait_event_type is not null or wait_event is not null))
        or (dimension = 'database' and query_id is not null
            and (wait_event_type is not null or wait_event is not null));
  v_exact_query := query_id is not null
                   or (
                     dimension = 'query_id'
                     and (
                       wait_event_type is not null
                       or wait_event is not null
                     )
                   );

  if v_exact_query then
    v_source := 'raw';
    v_coarser_query_history := ash._exact_query_uses_coarser(
      v_start_ts,
      v_end_ts,
      database
    );
    if v_tie or v_coarser_query_history then
      v_raw_start := case
        when v_coarser_query_history then ash._raw_oldest_sample()
        else ash._raw_retention_start()
      end;
      perform ash._raise_tie_retention(
        v_raw_start,
        v_start_ts,
        v_end_ts,
        v_from
      );
    end if;
    v_grain_secs := 60;
  else
    -- non-tie breakdown is an aggregate read: prefer rollup for wide windows.
    v_source := ash._pick_source_agg(ash.ts_to_timestamptz(v_start_ts),
                                     ash.ts_to_timestamptz(v_end_ts));
    v_grain_secs := case when v_source = 'rollup_1h' then 3600 else 60 end;
  end if;
  v_read_source := v_source;

  /*
   * minute_counts is per (hour, datid), so a plain database breakdown keeps
   * minute precision. Database reads with wait/query filters and every other
   * rollup_1h dimension use the hourly arrays.
   */
  if v_source = 'rollup_1h'
     and dimension = 'database'
     and wait_event_type is null
     and wait_event is null
     and query_id is null then
    v_read_source := 'rollup_1h_minutes';
    if ash._rollup_1h_has_flat(v_start_ts, v_end_ts, database) then
      v_source := 'rollup_1h_flat';
      v_grain_secs := 3600;
    else
      v_grain_secs := 60;
    end if;
  end if;

  if v_grain_secs = 3600 then
    v_start_ts := ((v_start_ts::bigint / 3600) * 3600)::int4;
    v_end_ts := least(
      ((v_end_ts::bigint + 3599) / 3600) * 3600,
      2147483647
    )::int4;
  end if;

  -- snap to a whole grain multiple (see ash.aas): a non-multiple bucket
  -- misaligns with the grain rows and fabricates per-bucket AAS.
  v_bucket_secs := (
    (greatest(v_bucket_secs, v_grain_secs)::bigint + v_grain_secs - 1)
    / v_grain_secs * v_grain_secs
  )::int4;
  v_extrema_supported := v_grain_secs <= v_requested_bucket_secs;

  /*
   * pgss presence/readability probe, schema-qualified from the catalog (#115):
   * name resolution SKIPS search_path schemas the caller lacks USAGE on, so an
   * unqualified reference could fall through to a planted
   * public.pg_stat_statements and flip v_has_pgss on attacker data.
   */
  v_pgss_schema := case when dimension = 'query_id'
                        then ash._pgss_schema() end;
  if v_pgss_schema is not null then
    begin
      execute format('select 1 from %I.pg_stat_statements limit 1',
                     v_pgss_schema);
      v_has_pgss := true;
    exception when others then
      v_has_pgss := false;
    end;
  end if;

  for
    key,
    v_key_num,
    source,
    period_start,
    period_end,
    effective_bucket,
    avg_aas,
    peak_aas,
    p99_aas,
    backend_seconds,
    pct
  in
  /*
   * Buckets are calendar-aligned (floored to bucket relative to ash.epoch(),
   * midnight UTC), matching ash.aas()/ash.timeline(): the same absolute
   * window always yields the same bucket boundaries. Edge buckets clipped by
   * the window divide by their in-window coverage only.
   */
  with source_keyed as (
    select
      grain_by_row.ts,
      grain_by_row.key,
      grain_by_row.key_num,
      grain_by_row.cnt
    from ash._grain_by(v_start_ts, v_end_ts, v_read_source, dimension,
           wait_event_type, wait_event, query_id, database) as grain_by_row
  ),
  keyed_grains as (
    select
      (source_keyed.ts / v_grain_secs) * v_grain_secs as gstart,
      source_keyed.key,
      max(source_keyed.key_num) as key_num,
      sum(source_keyed.cnt) as cnt
    from source_keyed
    group by 1, source_keyed.key
  ),
  keyed as (
    select
      (keyed_grains.gstart / v_bucket_secs) * v_bucket_secs as bstart,
      keyed_grains.key,
      keyed_grains.key_num,
      keyed_grains.cnt
    from keyed_grains
  ),
  /*
   * Zero-fill frame = the sampler-covered buckets, derived from the source's
   * grain set INDEPENDENT of the dimension/filter (#6). Deriving it from the
   * filtered rows made a key's p99 move when OTHER keys changed and disagree
   * with ash.aas() for the same drill. database is the only filter that
   * legitimately restricts coverage, so it is the only one passed here.
   */
  coverage_grains as (
    select
      (grain_row.ts / v_grain_secs) * v_grain_secs as gstart
    from ash._grain_counts(v_start_ts, v_end_ts, v_read_source,
           null, null, null, database) as grain_row
    group by 1
  ),
  covered as (
    select distinct
      (coverage_grains.gstart / v_bucket_secs) * v_bucket_secs as bstart
    from coverage_grains
  ),
  keys as (
    select keyed.key, max(keyed.key_num) as key_num, sum(keyed.cnt) as total
    from keyed
    group by keyed.key
    having sum(keyed.cnt) > 0
  ),
  grand as (select coalesce(sum(total), 0) as grand_total from keys),
  /*
   * Only the returned top-N need per-bucket peak/p99, so for the default
   * avg ordering, limit before the cross-join zero-fill (bounds it to
   * N x covered buckets). peak/p99 ordering must rank on the per-bucket
   * stats themselves, so it keeps every key through the zero-fill (same
   * cost class as compare(), which already runs top with an unbounded
   * limit) and cuts at the final ORDER BY.
   */
  top_keys as (
    select * from keys order by total desc
    limit case when order_by = 'avg' or not v_extrema_supported
          then greatest(n, 0)
          else 2147483647 end
  ),
  key_bucket_data as (
    select keyed.key, keyed.bstart, sum(keyed.cnt) as bcnt
    from keyed group by keyed.key, keyed.bstart
  ),
  key_bucket as (
    select top_keys.key, top_keys.key_num, top_keys.total, covered.bstart,
           coalesce(key_bucket_data.bcnt, 0) as bcnt
    from top_keys
    cross join covered
    left join key_bucket_data
      on key_bucket_data.key is not distinct from top_keys.key
      and key_bucket_data.bstart = covered.bstart
  ),
  per_key as (
    select key_bucket.key, key_bucket.key_num, key_bucket.total,
           round(key_bucket.total * v_si
                 / (v_end_ts - v_start_ts)::numeric, 2) as avg_aas,
           case when v_extrema_supported then
             round(max(key_bucket.bcnt * v_si
                       / (least(key_bucket.bstart + v_bucket_secs, v_end_ts)
                          - greatest(key_bucket.bstart, v_start_ts))), 2)
           end as peak_aas,
           case when v_extrema_supported then
             round(percentile_cont(0.99) within group (
                     order by key_bucket.bcnt * v_si
                       / (least(key_bucket.bstart + v_bucket_secs, v_end_ts)
                          - greatest(key_bucket.bstart, v_start_ts))
                   )::numeric, 2)
           end as p99_aas
    from key_bucket
    group by key_bucket.key, key_bucket.key_num, key_bucket.total
  )
  select
    per_key.key,
    per_key.key_num,
    v_source,
    ash.ts_to_timestamptz(v_start_ts),
    ash.ts_to_timestamptz(v_end_ts),
    v_bucket_secs * interval '1 second',
    per_key.avg_aas,
    per_key.peak_aas,
    per_key.p99_aas,
    round(per_key.total * v_si, 2),
    round(per_key.total * 100.0 / nullif(grand.grand_total, 0), 2)
  from per_key
  cross join grand
  order by case order_by
             when 'peak' then per_key.peak_aas
             when 'p99' then per_key.p99_aas
             else per_key.total
           end desc, per_key.total desc
  limit greatest(n, 0)
  loop
    query_text := null;
    if dimension = 'query_id' and v_has_pgss and v_key_num is not null then
      -- schema-qualified single lookup point (#115); returns null on any
      -- failure, never text from a shadowing relation.
      query_text := ash._pgss_query_text(v_key_num, 100);
    end if;
    return next;
  end loop;
end;
$$;

-- Before/after comparison of two windows (US-7). dimension => null gives one
-- overall row; a dimension gives the top rows by abs(avg_delta) via a full outer
-- join across the two windows (a key present in only one window still appears).
-- avg_delta is window-2 minus window-1.
-- Coverage honesty: a window with NO data coverage (e.g. entirely past
-- retention) reports NULL on its side — in both overall and per-dimension
-- modes — and avg_delta is NULL, never a fake zero-baseline "regression";
-- a NOTICE names the uncovered window. Within a covered window, a key absent
-- from one side is a true measured zero and the delta stands.
create or replace function ash.compare(
  since_1 timestamptz,
  until_1 timestamptz,
  since_2 timestamptz,
  until_2 timestamptz,
  dimension text default null,
  n int default 10,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null,
  bucket interval default '1 minute'
)
returns table (
  key text,
  query_text text,
  source_1 text,
  source_2 text,
  period_start_1 timestamptz,
  period_end_1 timestamptz,
  period_start_2 timestamptz,
  period_end_2 timestamptz,
  effective_bucket_1 interval,
  effective_bucket_2 interval,
  avg_aas_1 numeric,
  avg_aas_2 numeric,
  avg_delta numeric,
  peak_aas_1 numeric,
  peak_aas_2 numeric,
  p99_aas_1 numeric,
  p99_aas_2 numeric,
  pct_1 numeric,
  pct_2 numeric
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash, public
as $$
declare
  v_from1 timestamptz := coalesce(
    since_1, until_1 - interval '1 hour', now() - interval '1 hour');
  v_to1 timestamptz := coalesce(until_1, now());
  v_from2 timestamptz := coalesce(
    since_2, until_2 - interval '1 hour', now() - interval '1 hour');
  v_to2 timestamptz := coalesce(until_2, now());
  v_aas1 record;
  v_aas2 record;
  v_cov1 boolean;
  v_cov2 boolean;
  v_start1 int4;
  v_end1 int4;
  v_start2 int4;
  v_end2 int4;
  v_requested_bucket_secs numeric;
  v_effective_bucket_secs1 int4;
  v_effective_bucket_secs2 int4;
  v_grain1 int4;
  v_grain2 int4;
  v_source1 text;
  v_source2 text;
  v_exact_query boolean;
  v_extrema_mismatch boolean;
begin
  -- validate here, in compare's own frame, so the error names ash.compare
  -- and never leaks the internal delegation to ash.top.
  if dimension is not null
     and dimension not in (
           'wait_event_type', 'wait_event', 'query_id', 'database'
         ) then
    raise exception
      'ash.compare: unknown dimension %; use '
      'wait_event_type|wait_event|query_id|database '
      '(or null for one overall row)', dimension;
  end if;
  if v_from1 > v_to1 then
    raise exception
      'ash.compare: since_1 must be less than or equal to until_1';
  end if;
  if v_from2 > v_to2 then
    raise exception
      'ash.compare: since_2 must be less than or equal to until_2';
  end if;

  /*
   * Per-window coverage probe (rollup-backed, cheap). buckets_with_data = 0
   * means the window holds no data at all — its side must read NULL, and the
   * caller is warned: comparing against an uncovered window says nothing
   * about a regression.
   */
  select * into v_aas1 from ash.aas(v_from1, v_to1,
    wait_event_type, wait_event, query_id, database, bucket);
  select * into v_aas2 from ash.aas(v_from2, v_to2,
    wait_event_type, wait_event, query_id, database, bucket);
  v_cov1 := v_aas1.buckets_with_data > 0;
  v_cov2 := v_aas2.buckets_with_data > 0;
  if not v_cov1 then
    raise notice
      'ash.compare: window 1 (% to %) has no data coverage — its columns '
      'and avg_delta are NULL, not zero. Check retention with ash.status() '
      'before reading a delta as a change.',
      v_aas1.period_start, v_aas1.period_end;
  end if;
  if not v_cov2 then
    raise notice
      'ash.compare: window 2 (% to %) has no data coverage — its columns '
      'and avg_delta are NULL, not zero. Check retention with ash.status() '
      'before reading a delta as a change.',
      v_aas2.period_start, v_aas2.period_end;
  end if;

  /*
   * The displayed bucket can be the same even when one side consists of one
   * retained hour average and the other consists of minute observations.
   * Track that underlying read grain separately: equal bucket labels alone
   * do not make the extrema distributions comparable.
   */
  v_grain1 := case
    when v_aas1.source in ('rollup_1h', 'rollup_1h_flat')
         and (
           v_aas1.source = 'rollup_1h_flat'
           or wait_event_type is not null
           or wait_event is not null
           or query_id is not null
         ) then 3600
    else 60
  end;
  v_grain2 := case
    when v_aas2.source in ('rollup_1h', 'rollup_1h_flat')
         and (
           v_aas2.source = 'rollup_1h_flat'
           or wait_event_type is not null
           or wait_event is not null
           or query_id is not null
         ) then 3600
    else 60
  end;

  if dimension is null then
    v_extrema_mismatch :=
      v_grain1 <> v_grain2
      or v_aas1.effective_bucket <> v_aas2.effective_bucket;
    return query
    select
      'overall'::text, null::text,
      v_aas1.source,
      v_aas2.source,
      v_aas1.period_start,
      v_aas1.period_end,
      v_aas2.period_start,
      v_aas2.period_end,
      v_aas1.effective_bucket,
      v_aas2.effective_bucket,
      case when v_cov1 then v_aas1.avg_aas end,
      case when v_cov2 then v_aas2.avg_aas end,
      case when v_cov1 and v_cov2
           then round(v_aas2.avg_aas - v_aas1.avg_aas, 2) end,
      case when v_cov1 and not v_extrema_mismatch
           then v_aas1.peak_aas end,
      case when v_cov2 and not v_extrema_mismatch
           then v_aas2.peak_aas end,
      case when v_cov1 and not v_extrema_mismatch
           then v_aas1.p99_aas end,
      case when v_cov2 and not v_extrema_mismatch
           then v_aas2.p99_aas end,
      null::numeric, null::numeric;
    return;
  end if;

  /*
   * Plan the dimensional windows independently. This cannot reuse aas()'s
   * effective grain: an unfiltered scalar rollup_1h read can use minute_counts
   * while a wait/query breakdown over that same physical source is hourly.
   */
  v_requested_bucket_secs := extract(epoch from bucket);
  v_start1 := (ash.ts_from_timestamptz(v_from1) / 60) * 60;
  v_end1 := (ash.ts_from_timestamptz(v_to1) / 60) * 60;
  if v_end1 <= v_start1 then
    v_end1 := least(v_start1::bigint + 60, 2147483647)::int4;
  end if;
  v_start2 := (ash.ts_from_timestamptz(v_from2) / 60) * 60;
  v_end2 := (ash.ts_from_timestamptz(v_to2) / 60) * 60;
  if v_end2 <= v_start2 then
    v_end2 := least(v_start2::bigint + 60, 2147483647)::int4;
  end if;

  v_exact_query := query_id is not null
                   or (
                     dimension = 'query_id'
                     and (
                       wait_event_type is not null
                       or wait_event is not null
                     )
                   );

  if v_exact_query then
    v_source1 := 'raw';
    v_source2 := 'raw';
  else
    v_source1 := ash._pick_source_agg(
      ash.ts_to_timestamptz(v_start1),
      ash.ts_to_timestamptz(v_end1)
    );
    v_source2 := ash._pick_source_agg(
      ash.ts_to_timestamptz(v_start2),
      ash.ts_to_timestamptz(v_end2)
    );
  end if;
  v_grain1 := case when v_source1 = 'rollup_1h' then 3600 else 60 end;
  v_grain2 := case when v_source2 = 'rollup_1h' then 3600 else 60 end;

  if v_source1 = 'rollup_1h'
     and dimension = 'database'
     and wait_event_type is null
     and wait_event is null
     and query_id is null then
    if ash._rollup_1h_has_flat(v_start1, v_end1, database) then
      v_source1 := 'rollup_1h_flat';
    else
      v_grain1 := 60;
    end if;
  end if;
  if v_source2 = 'rollup_1h'
     and dimension = 'database'
     and wait_event_type is null
     and wait_event is null
     and query_id is null then
    if ash._rollup_1h_has_flat(v_start2, v_end2, database) then
      v_source2 := 'rollup_1h_flat';
    else
      v_grain2 := 60;
    end if;
  end if;

  if v_grain1 = 3600 then
    v_start1 := ((v_start1::bigint / 3600) * 3600)::int4;
    v_end1 := least(
      ((v_end1::bigint + 3599) / 3600) * 3600,
      2147483647
    )::int4;
  end if;
  if v_grain2 = 3600 then
    v_start2 := ((v_start2::bigint / 3600) * 3600)::int4;
    v_end2 := least(
      ((v_end2::bigint + 3599) / 3600) * 3600,
      2147483647
    )::int4;
  end if;
  v_effective_bucket_secs1 := (
    (
      greatest(ceil(v_requested_bucket_secs)::int4, v_grain1)::bigint
      + v_grain1 - 1
    )
    / v_grain1 * v_grain1
  )::int4;
  v_effective_bucket_secs2 := (
    (
      greatest(ceil(v_requested_bucket_secs)::int4, v_grain2)::bigint
      + v_grain2 - 1
    )
    / v_grain2 * v_grain2
  )::int4;
  v_extrema_mismatch :=
    v_grain1 <> v_grain2
    or v_effective_bucket_secs1 <> v_effective_bucket_secs2;

  return query
  with window1 as (
    select * from ash.top(dimension, v_from1, v_to1,
      wait_event_type, wait_event, query_id, database, 2147483647, bucket)
  ),
  window2 as (
    select * from ash.top(dimension, v_from2, v_to2,
      wait_event_type, wait_event, query_id, database, 2147483647, bucket)
  )
  select
    coalesce(window1.key, window2.key),
    coalesce(window1.query_text, window2.query_text),
    v_source1,
    v_source2,
    ash.ts_to_timestamptz(v_start1),
    ash.ts_to_timestamptz(v_end1),
    ash.ts_to_timestamptz(v_start2),
    ash.ts_to_timestamptz(v_end2),
    v_effective_bucket_secs1 * interval '1 second',
    v_effective_bucket_secs2 * interval '1 second',
    window1.avg_aas, window2.avg_aas,
    /*
     * a key absent from a COVERED window is a true zero; an UNCOVERED window
     * contributes NULL (no fake regression against an empty baseline).
     */
    case when v_cov1 and v_cov2
         then round(coalesce(window2.avg_aas, 0)
                    - coalesce(window1.avg_aas, 0), 2) end,
    case when not v_extrema_mismatch then window1.peak_aas end,
    case when not v_extrema_mismatch then window2.peak_aas end,
    case when not v_extrema_mismatch then window1.p99_aas end,
    case when not v_extrema_mismatch then window2.p99_aas end,
    window1.pct, window2.pct
  from window1
  /*
   * NULL-safe: raw uncaptured attribution and the broader rollup residual both
   * keep a NULL key and must pair like any named query. (FULL JOIN cannot use
   * IS NOT DISTINCT FROM, so NULL is folded to an out-of-band sentinel for the
   * join only.)
   */
  full outer join window2
    on coalesce(window1.key, chr(1)) = coalesce(window2.key, chr(1))
  order by abs(coalesce(window2.avg_aas, 0)
               - coalesce(window1.avg_aas, 0)) desc
  limit greatest(n, 0);
end;
$$;

/*
 * Query text for a query_id from pg_stat_statements, via dynamic SQL so the
 * reference is never parsed when pgss is absent (a static reference would make
 * the caller fail to plan). Trusts pgss only when the real extension schema is
 * resolvable (#87 anti-spoof), and schema-qualifies the reference with that
 * catalog-derived schema (#115): name resolution SKIPS search_path schemas the
 * caller lacks USAGE on, so an unqualified reference could fall through to a
 * planted public.pg_stat_statements and leak attacker-controlled query_text.
 * Returns null when unavailable (including permission-denied on the real
 * pgss schema) — degraded, never spoofed.
 */
create or replace function ash._pgss_query_text(
  query_id bigint,
  maxlen int default 80
)
returns text
language plpgsql
stable
set search_path = pg_catalog, ash, public
as $$
declare
  v_text text;
  v_pgss_schema text := ash._pgss_schema();
begin
  if query_id is null or v_pgss_schema is null then
    return null;
  end if;
  begin
    execute format(
      'select left(query, $1) from %I.pg_stat_statements '
      'where queryid = $2 limit 1', v_pgss_schema)
      into v_text using maxlen, query_id;
  exception when others then
    v_text := null;
  end;
  return v_text;
end;
$$;

/*
 * Decoded raw sample rows, newest first (2.0 conventions + uniform filters).
 * Raw evidence; reads ash.sample directly.
 *
 * Split into a thin public SQL wrapper (ash.samples, below) and this plpgsql
 * workhorse: PL/pgSQL forbids an IN parameter sharing a name with a RETURNS
 * TABLE column, and samples() both filters BY and returns wait_event /
 * query_id. SQL-language functions have no such restriction, so the wrapper
 * carries the uniform public filter names (wait_event, query_id) and this
 * internal body uses _filter-suffixed names for the two that collide.
 */
create or replace function ash._samples(
  since timestamptz default null,
  until timestamptz default null,
  n int default 100,
  wait_event_type text default null,
  wait_event_filter text default null,
  query_id_filter bigint default null,
  database name default null
)
returns table (
  sample_time timestamptz,
  database_name text,
  active_backends smallint,
  wait_event text,
  query_id bigint,
  query_text text
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash, public
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 hour');
  v_to timestamptz := coalesce(until, now());
  v_start int4;
  v_end int4;
  v_slots smallint[];
  v_datid oid;
  v_has_pgss boolean := false;
  v_pgss_schema text;
begin
  if v_from > v_to then
    raise exception
      'ash.samples: since must be less than or equal to until';
  end if;

  v_start := ash.ts_from_timestamptz(v_from);
  v_end := ash.ts_from_timestamptz(v_to);
  v_slots := ash._active_slots_for_at(v_from, v_to);
  if database is not null then
    select db.oid into v_datid from pg_database as db
    where db.datname = database;
    if v_datid is null then return; end if;
  end if;
  /*
   * pgss presence/readability probe, schema-qualified from the catalog (#115):
   * an unqualified reference could resolve to a planted
   * public.pg_stat_statements when the caller lacks USAGE on the real pgss
   * schema (name resolution skips schemas without USAGE).
   */
  v_pgss_schema := ash._pgss_schema();
  if v_pgss_schema is not null then
    begin
      execute format('select 1 from %I.pg_stat_statements limit 1',
                     v_pgss_schema);
      v_has_pgss := true;
    exception when others then
      v_has_pgss := false;
    end;
  end if;

  return query
  with decoded as (
    select
      sample_row.sample_ts, sample_row.slot, sample_row.datid,
      sample_row.active_count,
      (-sample_row.data[data_idx])::smallint as wait_id,
      sample_row.data[data_idx + 2 + backend.n] as map_id
    from ash.sample as sample_row
    cross join generate_subscripts(sample_row.data, 1) as data_idx
    cross join generate_series(
      0, greatest(sample_row.data[data_idx + 1] - 1, -1)
    ) as backend(n)
    where sample_row.slot = any(v_slots)
      and sample_row.sample_ts >= v_start and sample_row.sample_ts < v_end
      and sample_row.data[data_idx] < 0
      and data_idx + 1 <= array_length(sample_row.data, 1)
      and data_idx + 2 + backend.n <= array_length(sample_row.data, 1)
      and (v_datid is null or sample_row.datid = v_datid)
  ),
  resolved as (
    select
      decoded.sample_ts, decoded.datid, decoded.active_count,
      case when event_map.event = event_map.type then event_map.event
           else event_map.type || ':' || event_map.event end as wait_event,
      event_map.type as wet,
      query_map.query_id as qid
    from decoded
    join ash.wait_event_map as event_map on event_map.id = decoded.wait_id
    left join ash.query_map_all as query_map
      on query_map.slot = decoded.slot
      and query_map.id = decoded.map_id
      and decoded.map_id <> 0
    where (wait_event_type is null or event_map.type = wait_event_type)
      and (wait_event_filter is null
           or (case when event_map.event = event_map.type
                    then event_map.event
                    else event_map.type || ':' || event_map.event
               end) = wait_event_filter
           or event_map.event = wait_event_filter)
      and (query_id_filter is null or query_map.query_id = query_id_filter)
  )
  select
    ash.epoch() + make_interval(secs => resolved.sample_ts),
    coalesce(db.datname, '<oid:' || resolved.datid || '>')::text,
    resolved.active_count,
    resolved.wait_event,
    resolved.qid,
    case when v_has_pgss then ash._pgss_query_text(resolved.qid, 80)
         else null end
  from resolved
  left join pg_database as db on db.oid = resolved.datid
  order by resolved.sample_ts desc, resolved.wait_event
  limit greatest(n, 0);
end;
$$;

/*
 * Public wrapper carrying the uniform filter names (wait_event, query_id) —
 * see ash._samples above for why the plpgsql body cannot. SQL-language
 * functions allow an IN parameter to share a name with a RETURNS TABLE
 * column; positional $n references keep the body immune to that overlap.
 */
create or replace function ash.samples(
  since timestamptz default null,
  until timestamptz default null,
  n int default 100,
  wait_event_type text default null,
  wait_event text default null,
  query_id bigint default null,
  database name default null
)
returns table (
  sample_time timestamptz,
  database_name text,
  active_backends smallint,
  wait_event text,
  query_id bigint,
  query_text text
)
language sql
stable
set jit = off
set search_path = pg_catalog, ash, public
as $$
  select * from ash._samples($1, $2, $3, $4, $5, $6, $7)
$$;

/*
 * report helper: top wait events at a set of minutes for one wait class,
 * from rollup_1m, as pre-formatted "event(aas)" strings (aas = avg per-minute
 * AAS across the given minutes, 1 decimal). Empty array when nothing matched.
 */
create or replace function ash._hr_top_events(
  type text, minutes int4[], n int, si numeric
)
returns text[]
language sql
stable
set search_path = pg_catalog, ash
as $$
  with per_minute_event as (
    select event_map.event as ev,
           sum(rollup_min.wait_counts[pos + 1])::numeric as cnt
    from ash.rollup_1m as rollup_min
    cross join generate_subscripts(rollup_min.wait_counts, 1) as pos
    join ash.wait_event_map as event_map
      on event_map.id = rollup_min.wait_counts[pos]
    /*
     * function-qualified: in a SQL-language body a bare `type` would resolve
     * to the event_map.type column (columns take precedence), not the
     * parameter
     */
    where pos % 2 = 1 and rollup_min.ts = any(minutes)
      and event_map.type = _hr_top_events.type
    group by event_map.event
    order by 2 desc
    limit greatest(n, 0)
  )
  select coalesce(
    array_agg(ev || '(' ||
      round(cnt * si
            / (greatest(array_length(minutes, 1), 1) * 60.0), 1)::text || ')'
      order by cnt desc),
    array[]::text[])
  from per_minute_event
$$;

/*
 * report helper: top query ids at a set of minutes, optionally within one
 * wait class (type null = the five classes included in the 'total' key), read
 * from RAW samples (the wait<->query tie). "queryid(aas)" strings, int64-safe.
 */
create or replace function ash._hr_top_queryids(
  type text, minutes int4[], n int, si numeric
)
returns text[]
language sql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
  with expanded as (
    select sample_row.slot,
           (-sample_row.data[data_idx])::int as wait_id,
           sample_row.data[data_idx + 2 + backend.n] as map_id
    from ash.sample as sample_row
    cross join generate_subscripts(sample_row.data, 1) as data_idx
    cross join lateral generate_series(
      0, greatest(sample_row.data[data_idx + 1] - 1, -1)
    ) as backend(n)
    where sample_row.slot = any(ash._active_slots_for_at(
             ash.ts_to_timestamptz(
               (select min(m) from unnest(minutes) as m)),
             ash.ts_to_timestamptz(
               (select max(m) + 60 from unnest(minutes) as m))))
      /*
       * Sargable range bound so the (sample_ts) index prunes to the extreme
       * minutes instead of seq-scanning the whole active partition (#perf:
       * this runs up to 15x per report()); the exact = any(...) stays as
       * residual.
       */
      and sample_row.sample_ts >= (select min(m) from unnest(minutes) as m)
      and sample_row.sample_ts < (select max(m) + 60 from unnest(minutes) as m)
      and (sample_row.sample_ts / 60) * 60 = any(minutes)
      and sample_row.data[data_idx] < 0
      and data_idx + 1 <= array_length(sample_row.data, 1)
      and data_idx + 2 + backend.n <= array_length(sample_row.data, 1)
  ),
  hits as (
    select query_map.query_id as qid, count(*)::numeric as cnt
    from expanded
    join ash.wait_event_map as event_map on event_map.id = expanded.wait_id
    join ash.query_map_all as query_map
      on query_map.slot = expanded.slot
      and query_map.id = expanded.map_id
      and expanded.map_id <> 0
    /*
     * function-qualified: in a SQL-language body a bare `type` would resolve
     * to the event_map.type column (columns take precedence), not the
     * parameter
     */
    where (
      (_hr_top_queryids.type is null
       and event_map.type in ('CPU*', 'IO', 'IPC', 'Lock', 'LWLock'))
      or event_map.type = _hr_top_queryids.type
    )
    group by query_map.query_id
    order by 2 desc
    limit greatest(n, 0)
  )
  select coalesce(
    array_agg(qid::text || '(' ||
      round(cnt * si
            / (greatest(array_length(minutes, 1), 1) * 60.0), 1)::text || ')'
      order by cnt desc),
    array[]::text[])
  from hits
$$;

/*
 * Machine-readable load report (US-8): one self-contained jsonb load report
 * for the window. Per-class per-minute AAS (zero-filled) drives
 * avg/worst1m/p99/p999; top_events_* come from rollup_1m, top_queryids_* from
 * raw samples, attributed per extreme minute (a key is present iff raw samples
 * still cover that worst/percentile minute set — even when the window start
 * predates raw retention); top_queryids_available + coverage metadata make the
 * attribution state explicit. Returns null when no coverage.
 */
create or replace function ash.report(
  since timestamptz default null,
  until timestamptz default null,
  vcpus int default null,
  n int default 3
)
returns jsonb
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 day');
  v_to timestamptz := coalesce(until, now());
  v_start_ts int4;
  v_end_ts int4;
  v_si numeric;
  v_n int;
  v_cluster text;
  v_raw_min int4;
  v_result jsonb;
  v_class record;
  v_agg jsonb := '{}'::jsonb;
  v_avg jsonb := '{}'::jsonb;
  v_worst jsonb := '{}'::jsonb;
  v_p99 jsonb := '{}'::jsonb;
  v_p999 jsonb := '{}'::jsonb;
  v_te_w jsonb := '{}'::jsonb;
  v_te_9 jsonb := '{}'::jsonb;
  v_te_99 jsonb := '{}'::jsonb;
  v_tq_w jsonb := '{}'::jsonb;
  v_tq_9 jsonb := '{}'::jsonb;
  v_tq_99 jsonb := '{}'::jsonb;
  v_tot_avg numeric := 0;
  v_tot_worst numeric := 0;
  v_tot_p99 numeric := 0;
  v_tot_p999 numeric := 0;
  /*
   * total-series own extreme minutes (drive total worst1m/p99/p999 and the
   * top_queryids_*.total windows); thresholds kept unrounded for minute-set
   * membership.
   */
  v_tworst_min int4;
  v_t99_mins int4[];
  v_t999_mins int4[];
  v_t99_thr numeric;
  v_t999_thr numeric;
  v_available_source text;
  v_raw_retention_start timestamptz;
begin
  if v_from > v_to then
    raise exception
      'ash.report: since must be less than or equal to until';
  end if;

  /*
   * Floor in timestamp space before converting to int4 seconds.
   * ts_from_timestamptz() rounds fractional seconds while casting; converting
   * first could therefore move a :59.5+ endpoint into the next minute.
   */
  v_start_ts := ash.ts_from_timestamptz(date_trunc('minute', v_from));
  v_end_ts := ash.ts_from_timestamptz(date_trunc('minute', v_to));
  -- overflow-safe empty/degenerate-window guard (#63).
  if v_end_ts <= v_start_ts then
    v_end_ts := least(v_start_ts::bigint + 60, 2147483647)::int4;
  end if;
  v_si := ash._sample_interval_secs();

  -- Covered minutes (any rollup_1m row); null result when no coverage at all.
  select count(*) into v_n
  from (select distinct ts from ash.rollup_1m
        where ts >= v_start_ts and ts < v_end_ts) as covered;
  if v_n = 0 then
    /*
     * report's per-class minute payload is rollup_1m-only. Do not synthesize
     * it from another source; just distinguish "pg_ash has no data" from
     * "another reader source holds this window" before returning the same
     * SQL NULL as before.
     */
    /*
     * Reuse the B3 boundary split: _raw_retention_start() is the logical
     * planning boundary, while the row probe below proves physical coverage.
     * _active_slots() excludes the ring slot that readers must not expose.
     */
    v_raw_retention_start := ash._raw_retention_start();

    if v_raw_retention_start is not null
       and ash.ts_to_timestamptz(v_end_ts) > v_raw_retention_start
       and ash.ts_to_timestamptz(v_start_ts) <= now()
       and exists (
         select
         from ash.sample as sample_row
         where sample_row.slot = any(ash._active_slots())
           and sample_row.sample_ts >= v_start_ts
           and sample_row.sample_ts < v_end_ts
       ) then
      v_available_source := 'raw';
    elsif exists (
      select
      from ash._grain_counts(
        v_start_ts, v_end_ts, 'rollup_1h_minutes'
      )
    ) then
      v_available_source := 'rollup_1h';
    end if;

    if v_available_source is not null then
      raise notice
        'ash.report: no rollup_1m coverage for [%, %); % has coverage, '
        'but report reads rollup_1m only and returns NULL',
        ash.ts_to_timestamptz(v_start_ts),
        ash.ts_to_timestamptz(v_end_ts),
        v_available_source;
    end if;
    return null;
  end if;

  /*
   * top_queryids_* attribution needs the raw wait<->query tie, decided PER
   * EXTREME MINUTE (not per window start): the default 1-day window typically
   * starts right at the raw-retention boundary, but the worst/percentile
   * minutes themselves are usually well inside raw retention — dropping the
   * attribution wholesale threw away exactly the answer the report exists to
   * give. v_raw_min is based on the physical oldest sample (not the logical
   * planning boundary) and is the first minute raw samples can attribute; each
   * extreme-minute set below is filtered to covered minutes and attributed
   * when any survive.
   * (greatest/least in ts_from_timestamptz ignore NULLs, so a missing raw
   * oldest sample must be short-circuited here, not passed through.)
   */
  select case
    when raw_coverage.oldest_sample is null then null
    else ash.ts_from_timestamptz(
      date_trunc('minute', raw_coverage.oldest_sample)
    )
  end
  into v_raw_min
  from (
    select ash._raw_oldest_sample() as oldest_sample
  ) as raw_coverage;

  -- Per-class metrics over the zero-filled per-minute AAS series.
  for v_class in
    select * from (values
      ('cpu','CPU*'), ('io','IO'), ('ipc','IPC'),
      ('lock','Lock'), ('lwlock','LWLock')
    ) as class_def(k, t)
  loop
    declare
      v_cavg numeric; v_cworst numeric; v_cp99 numeric; v_cp999 numeric;
      /*
       * unrounded per-class thresholds for the percentile-minute-set
       * membership below (mirrors v_t99_thr/v_t999_thr on the total series):
       * filtering on the ROUNDED display value can round UP above the true
       * class max and match no minute at all, wiping out top_events_p99/p999
       * and top_queryids_p99/p999 for low-AAS classes.
       */
      v_cp99_thr numeric; v_cp999_thr numeric;
      v_worst_min int4;
      v_p99_mins int4[];
      v_p999_mins int4[];
    begin
      with covered as (
        select distinct ts from ash.rollup_1m
        where ts >= v_start_ts and ts < v_end_ts
      ),
      per_minute_class as (
        select rollup_min.ts,
               sum(rollup_min.wait_counts[pos + 1])::numeric as cnt
        from ash.rollup_1m as rollup_min
        cross join generate_subscripts(rollup_min.wait_counts, 1) as pos
        join ash.wait_event_map as event_map
          on event_map.id = rollup_min.wait_counts[pos]
        where pos % 2 = 1 and rollup_min.ts >= v_start_ts
          and rollup_min.ts < v_end_ts
          and event_map.type = v_class.t
        group by rollup_min.ts
      ),
      grid as (
        select covered.ts,
               coalesce(per_minute_class.cnt, 0) * v_si / 60.0 as aas
        from covered
        left join per_minute_class on per_minute_class.ts = covered.ts
      ),
      agg as (
        select
          avg(aas) as cavg, max(aas) as cworst,
          percentile_cont(0.99) within group (order by aas) as cp99,
          percentile_cont(0.999) within group (order by aas) as cp999
        from grid
      )
      select round(cavg, 2), round(cworst, 2),
             round(cp99::numeric, 2), round(cp999::numeric, 2),
             cp99::numeric, cp999::numeric
      into v_cavg, v_cworst, v_cp99, v_cp999, v_cp99_thr, v_cp999_thr
      from agg;

      -- worst minute and percentile-minute sets for top_events / top_queryids.
      select ts into v_worst_min from (
        select covered.ts, coalesce(class_counts.cnt, 0) as cnt
        from (select distinct ts from ash.rollup_1m
              where ts >= v_start_ts and ts < v_end_ts) as covered
        left join (
          select rollup_min.ts,
                 sum(rollup_min.wait_counts[pos + 1])::numeric as cnt
          from ash.rollup_1m as rollup_min
          cross join generate_subscripts(rollup_min.wait_counts, 1) as pos
          join ash.wait_event_map as event_map
            on event_map.id = rollup_min.wait_counts[pos]
          where pos % 2 = 1 and rollup_min.ts >= v_start_ts
            and rollup_min.ts < v_end_ts and event_map.type = v_class.t
          group by rollup_min.ts
        ) as class_counts on class_counts.ts = covered.ts
        order by cnt desc, covered.ts
        limit 1
      ) as worst_candidate;

      -- membership on the UNROUNDED thresholds (v_cp99/v_cp999 are display).
      select coalesce(
               array_agg(ts) filter (where aas >= v_cp99_thr and aas > 0),
               array[]::int4[]),
             coalesce(
               array_agg(ts) filter (where aas >= v_cp999_thr and aas > 0),
               array[]::int4[])
      into v_p99_mins, v_p999_mins
      from (
        select covered.ts,
               coalesce(class_counts.cnt, 0) * v_si / 60.0 as aas
        from (select distinct ts from ash.rollup_1m
              where ts >= v_start_ts and ts < v_end_ts) as covered
        left join (
          select rollup_min.ts,
                 sum(rollup_min.wait_counts[pos + 1])::numeric as cnt
          from ash.rollup_1m as rollup_min
          cross join generate_subscripts(rollup_min.wait_counts, 1) as pos
          join ash.wait_event_map as event_map
            on event_map.id = rollup_min.wait_counts[pos]
          where pos % 2 = 1 and rollup_min.ts >= v_start_ts
            and rollup_min.ts < v_end_ts and event_map.type = v_class.t
          group by rollup_min.ts
        ) as class_counts on class_counts.ts = covered.ts
      ) as minute_grid;

      v_avg := v_avg || jsonb_build_object(v_class.k, v_cavg);
      v_worst := v_worst || jsonb_build_object(v_class.k, v_cworst);
      v_p99 := v_p99 || jsonb_build_object(v_class.k, v_cp99);
      v_p999 := v_p999 || jsonb_build_object(v_class.k, v_cp999);
      /*
       * top_events (rollup) and top_queryids (raw) for the four non-cpu
       * classes; top_queryids 'total' is handled once, outside this loop.
       */
      if v_class.k <> 'cpu' then
        v_te_w := v_te_w || jsonb_build_object(v_class.k,
          to_jsonb(ash._hr_top_events(v_class.t, array[v_worst_min], n, v_si)));
        v_te_9 := v_te_9 || jsonb_build_object(v_class.k,
          to_jsonb(ash._hr_top_events(v_class.t, v_p99_mins, n, v_si)));
        v_te_99 := v_te_99 || jsonb_build_object(v_class.k,
          to_jsonb(ash._hr_top_events(v_class.t, v_p999_mins, n, v_si)));
        /*
         * attribution per extreme minute: a key appears when raw samples
         * still cover its minute(s); percentile sets attribute over the
         * raw-covered subset (a partially-covered set is better than none —
         * the coverage metadata lets a consumer detect the reduced
         * attribution window).
         */
        if v_raw_min is not null and v_worst_min >= v_raw_min then
          v_tq_w := v_tq_w || jsonb_build_object(v_class.k,
            to_jsonb(
              ash._hr_top_queryids(v_class.t, array[v_worst_min], n, v_si)));
        end if;
        if v_raw_min is not null then
          v_p99_mins := array(
            select m from unnest(v_p99_mins) as m where m >= v_raw_min);
          v_p999_mins := array(
            select m from unnest(v_p999_mins) as m where m >= v_raw_min);
          if cardinality(v_p99_mins) > 0 then
            v_tq_9 := v_tq_9 || jsonb_build_object(v_class.k,
              to_jsonb(ash._hr_top_queryids(v_class.t, v_p99_mins, n, v_si)));
          end if;
          if cardinality(v_p999_mins) > 0 then
            v_tq_99 := v_tq_99 || jsonb_build_object(v_class.k,
              to_jsonb(ash._hr_top_queryids(v_class.t, v_p999_mins, n, v_si)));
          end if;
        end if;
      end if;
    end;
  end loop;

  /*
   * Total statistics come from the summed per-minute series (matching the
   * platform ingestion recipe and top_queryids_*.total). Statement 1: average,
   * own extremes, unrounded thresholds, and worst minute.
   */
  with grid as (
    select covered.ts, coalesce(total_counts.cnt, 0) * v_si / 60.0 as aas
    from (select distinct ts from ash.rollup_1m
          where ts >= v_start_ts and ts < v_end_ts) as covered
    left join (
      select rollup_min.ts,
             sum(rollup_min.wait_counts[pos + 1])::numeric as cnt
      from ash.rollup_1m as rollup_min
      cross join generate_subscripts(rollup_min.wait_counts, 1) as pos
      join ash.wait_event_map as event_map
        on event_map.id = rollup_min.wait_counts[pos]
      where pos % 2 = 1 and rollup_min.ts >= v_start_ts
        and rollup_min.ts < v_end_ts
        and event_map.type in ('CPU*', 'IO', 'IPC', 'Lock', 'LWLock')
      group by rollup_min.ts
    ) as total_counts on total_counts.ts = covered.ts
  )
  select
    round(coalesce(avg(aas), 0), 2),
    round(coalesce(max(aas), 0), 2),
    round(coalesce(
      percentile_cont(0.99) within group (order by aas), 0)::numeric, 2),
    round(coalesce(
      percentile_cont(0.999) within group (order by aas), 0)::numeric, 2),
    percentile_cont(0.99) within group (order by aas),
    percentile_cont(0.999) within group (order by aas),
    (select ts from grid order by aas desc, ts limit 1)
  into v_tot_avg, v_tot_worst, v_tot_p99, v_tot_p999,
       v_t99_thr, v_t999_thr, v_tworst_min
  from grid;

  -- Statement 2: the p99/p999 minute sets (>= the unrounded thresholds).
  select
    coalesce(
      array_agg(ts) filter (where aas >= v_t99_thr and aas > 0),
      array[]::int4[]),
    coalesce(
      array_agg(ts) filter (where aas >= v_t999_thr and aas > 0),
      array[]::int4[])
  into v_t99_mins, v_t999_mins
  from (
    select covered.ts, coalesce(total_counts.cnt, 0) * v_si / 60.0 as aas
    from (select distinct ts from ash.rollup_1m
          where ts >= v_start_ts and ts < v_end_ts) as covered
    left join (
      select rollup_min.ts,
             sum(rollup_min.wait_counts[pos + 1])::numeric as cnt
      from ash.rollup_1m as rollup_min
      cross join generate_subscripts(rollup_min.wait_counts, 1) as pos
      join ash.wait_event_map as event_map
        on event_map.id = rollup_min.wait_counts[pos]
      where pos % 2 = 1 and rollup_min.ts >= v_start_ts
        and rollup_min.ts < v_end_ts
        and event_map.type in ('CPU*', 'IO', 'IPC', 'Lock', 'LWLock')
      group by rollup_min.ts
    ) as total_counts on total_counts.ts = covered.ts
  ) as minute_grid;

  v_avg := jsonb_build_object('total', round(v_tot_avg, 2)) || v_avg;
  v_worst := jsonb_build_object('total', v_tot_worst) || v_worst;
  v_p99 := jsonb_build_object('total', v_tot_p99) || v_p99;
  v_p999 := jsonb_build_object('total', v_tot_p999) || v_p999;

  v_result := jsonb_build_object(
    'aas_avg', v_avg,
    'aas_worst1m', v_worst,
    'aas_p99', v_p99,
    'aas_p999', v_p999,
    'top_events_worst1m', v_te_w,
    'top_events_p99', v_te_9,
    'top_events_p999', v_te_99
  );

  /*
   * 'total' top_queryids for each window = top queries at the window's overall
   * worst/percentile minutes (the summed-series extremes computed above), so
   * these agree with aas_worst1m/p99/p999.total. Same per-extreme-minute
   * attribution rule as the per-class keys above.
   */
  if v_raw_min is not null then
    if v_tworst_min >= v_raw_min then
      v_tq_w := v_tq_w || jsonb_build_object('total',
        to_jsonb(ash._hr_top_queryids(null, array[v_tworst_min], n, v_si)));
    end if;
    v_t99_mins := array(select m from unnest(v_t99_mins) m where m >= v_raw_min);
    v_t999_mins := array(select m from unnest(v_t999_mins) m where m >= v_raw_min);
    if cardinality(v_t99_mins) > 0 then
      v_tq_9 := v_tq_9 || jsonb_build_object('total',
        to_jsonb(ash._hr_top_queryids(null, v_t99_mins, n, v_si)));
    end if;
    if cardinality(v_t999_mins) > 0 then
      v_tq_99 := v_tq_99 || jsonb_build_object('total',
        to_jsonb(ash._hr_top_queryids(null, v_t999_mins, n, v_si)));
    end if;
  end if;

  /*
   * Each top_queryids_* object appears when it attributed at least one key
   * (consumers MUST treat these keys as optional per the frozen contract);
   * top_queryids_available (additive, always present) is the explicit signal
   * so ingest can branch on a field rather than on key absence.
   */
  if v_tq_w <> '{}'::jsonb then
    v_result := v_result || jsonb_build_object('top_queryids_worst1m', v_tq_w);
  end if;
  if v_tq_9 <> '{}'::jsonb then
    v_result := v_result || jsonb_build_object('top_queryids_p99', v_tq_9);
  end if;
  if v_tq_99 <> '{}'::jsonb then
    v_result := v_result || jsonb_build_object('top_queryids_p999', v_tq_99);
  end if;

  /*
   * Additive metadata (frozen contract: keys only ever added): the window and
   * coverage actually used, so a consumer can reconcile this payload against
   * ash.aas()/ash.top() for the same window and detect degraded resolution
   * (minutes_with_data < minutes_expected). raw_retention_start is the logical
   * planning boundary; top_queryids_available reports actual attribution.
   */
  v_result := v_result || jsonb_build_object(
    'top_queryids_available',
      (v_tq_w <> '{}'::jsonb or v_tq_9 <> '{}'::jsonb
       or v_tq_99 <> '{}'::jsonb),
    'coverage', jsonb_build_object(
      'from', ash.ts_to_timestamptz(v_start_ts),
      'to', ash.ts_to_timestamptz(v_end_ts),
      'source', 'rollup_1m',
      'minutes_expected', (v_end_ts - v_start_ts) / 60,
      'minutes_with_data', v_n,
      'raw_retention_start', ash._raw_retention_start()
    )
  );

  -- optional / conditional top-level keys.
  if vcpus is not null then
    v_result := jsonb_build_object('vcpus', vcpus) || v_result;
  end if;
  v_cluster := current_setting('cluster_name', true);
  if v_cluster is not null and length(v_cluster) > 0 then
    v_result := jsonb_build_object('cluster_name', v_cluster) || v_result;
  end if;

  return v_result;
end;
$$;

/*
 * Human render helper: stacked per-bucket AAS chart (2.0 port of
 * timeline_chart). Presentation-only; reads the rollup-backed AAS via
 * _grain_by. bucket => null auto-selects grain by span like ash.timeline.
 */
create or replace function ash.chart(
  since timestamptz default null,
  until timestamptz default null,
  bucket interval default null,
  n int default 3,
  width int default 40,
  color boolean default false
)
returns table (
  bucket_start timestamptz,
  aas numeric,
  detail text,
  chart text
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 hour');
  v_to timestamptz := coalesce(until, now());
  v_start_ts int4;
  v_end_ts int4;
  v_span int4;
  v_bucket_secs int4;
  v_grain_secs int4;
  v_si numeric;
  v_source text;
  v_reset text := ash._reset(color);
  v_top_events text[];
  v_event_colors text[];
  v_event_chars text[] := array['█', '▓', '░', '▒'];
  v_other_color text := ash._wait_color('Other', color);
  v_other_char text := '·';
  v_max numeric;
  v_legend text;
  v_legend_len int;
  v_rec record;
  v_bar text;
  v_val numeric;
  v_ch text;
  v_i int;
  v_char_count int;
begin
  if v_from > v_to then
    raise exception
      'ash.chart: since must be less than or equal to until';
  end if;

  width := least(greatest(width, 1), 500);
  v_start_ts := (ash.ts_from_timestamptz(v_from) / 60) * 60;
  v_end_ts := (ash.ts_from_timestamptz(v_to) / 60) * 60;
  -- overflow-safe empty/degenerate-window guard (#63).
  if v_end_ts <= v_start_ts then
    v_end_ts := least(v_start_ts::bigint + 60, 2147483647)::int4;
  end if;
  v_span := v_end_ts - v_start_ts;
  if bucket is null then
    v_bucket_secs := case when v_span <= 6 * 3600 then 60
                          when v_span <= 7 * 86400 then 3600 else 86400 end;
  else
    if extract(epoch from bucket) < 60 then
      raise exception 'bucket must be at least 1 minute, got %', bucket;
    end if;
    v_bucket_secs := ceil(extract(epoch from bucket))::int4;
  end if;

  v_si := ash._sample_interval_secs();
  v_source := ash._pick_source_agg(ash.ts_to_timestamptz(v_start_ts),
                                   ash.ts_to_timestamptz(v_end_ts));
  if v_source = 'none' then v_source := 'rollup_1m'; end if;
  v_grain_secs := case when v_source = 'rollup_1h' then 3600 else 60 end;
  if v_grain_secs = 3600 then
    v_start_ts := ((v_start_ts::bigint / 3600) * 3600)::int4;
    v_end_ts := least(
      ((v_end_ts::bigint + 3599) / 3600) * 3600,
      2147483647
    )::int4;
  end if;
  -- snap to a whole grain multiple (see ash.aas): a non-multiple bucket
  -- misaligns with the grain rows and fabricates per-bucket AAS.
  v_bucket_secs := (
    (greatest(v_bucket_secs, v_grain_secs)::bigint + v_grain_secs - 1)
    / v_grain_secs * v_grain_secs
  )::int4;
  v_span := v_end_ts - v_start_ts;

  /*
   * chart has no metadata columns, so disclose its effective hour-grain plan
   * with a NOTICE instead of silently changing the requested window.
   */
  if v_source = 'rollup_1h' then
    raise notice
      'ash.chart: source rollup_1h uses effective window [% to %) and bucket %',
      ash.ts_to_timestamptz(v_start_ts),
      ash.ts_to_timestamptz(v_end_ts),
      v_bucket_secs * interval '1 second';
  end if;

  /*
   * Bound the emitted-row count (same cap as ash.timeline) after widening.
   */
  if (v_span::bigint / v_bucket_secs) > 100000 then
    raise exception
      'ash.chart: % buckets exceeds the 100000-row cap; use a coarser '
      'bucket (or bucket => null for auto grain)',
      (v_span::bigint / v_bucket_secs);
  end if;

  /*
   * Legend/series events: the window-wide top-n PLUS any event that is
   * top-1 in at least one bucket. A spike event dominant in a single bucket —
   * the very bucket under investigation — would otherwise never make the
   * window-wide top-3 and disappear into Other, hiding the culprit.
   */
  with bucket_events as (
    select (grain_by_row.ts / v_bucket_secs) * v_bucket_secs as bstart,
           grain_by_row.key as ev, sum(grain_by_row.cnt) as cnt
    from ash._grain_by(v_start_ts, v_end_ts, v_source, 'wait_event')
           as grain_by_row
    group by 1, grain_by_row.key
  ),
  totals as (
    select ev, sum(cnt) as tot from bucket_events group by ev
  ),
  wtop as (
    select ev from totals order by tot desc limit greatest(n, 0)
  ),
  btop as (
    select distinct on (bstart) ev from bucket_events
    order by bstart, cnt desc, ev
  )
  select array_agg(totals.ev order by totals.tot desc)
  into v_top_events
  from totals
  where totals.ev in (select ev from wtop union select ev from btop);

  if v_top_events is null then
    return;
  end if;

  /*
   * Calendar-aligned buckets (floored to bucket relative to ash.epoch(),
   * midnight UTC), matching timeline(); edge buckets divide by their
   * in-window coverage.
   */
  select max(tot) into v_max from (
    select (grain_by_row.ts / v_bucket_secs) * v_bucket_secs as bstart,
           sum(grain_by_row.cnt) * v_si
           / (least(
                (grain_by_row.ts / v_bucket_secs) * v_bucket_secs
                  + v_bucket_secs, v_end_ts)
              - greatest(
                (grain_by_row.ts / v_bucket_secs) * v_bucket_secs,
                v_start_ts)) as tot
    from ash._grain_by(v_start_ts, v_end_ts, v_source, 'wait_event')
           as grain_by_row
    group by 1
  ) as bucketed;
  if v_max is null or v_max = 0 then
    return;
  end if;

  v_event_colors := array[]::text[];
  for v_i in 1 .. array_length(v_top_events, 1) loop
    v_event_colors := v_event_colors || ash._wait_color(v_top_events[v_i], color);
  end loop;

  v_legend := '';
  for v_i in 1 .. array_length(v_top_events, 1) loop
    v_ch := coalesce(
      v_event_chars[v_i],
      v_event_chars[array_length(v_event_chars, 1)]);
    if v_i > 1 then v_legend := v_legend || '  '; end if;
    v_legend := v_legend || v_event_colors[v_i] || v_ch || v_reset
      || ' ' || v_top_events[v_i];
  end loop;
  v_legend := v_legend || '  ' || v_other_color || v_other_char || v_reset
    || ' Other';
  v_legend_len := length(v_legend);
  bucket_start := null; aas := null; detail := null; chart := v_legend;
  return next;

  for v_rec in
    with buckets as (
      select bucket_series.ts::int4 as bstart
      from generate_series(
        ((v_start_ts / v_bucket_secs) * v_bucket_secs)::bigint,
        (v_end_ts - 1)::bigint, v_bucket_secs
      ) as bucket_series(ts)
    ),
    per_bucket as (
      select buckets.bstart,
             round(coalesce(sum(bucket_events.cnt), 0) * v_si
                   / (least(buckets.bstart + v_bucket_secs, v_end_ts)
                      - greatest(buckets.bstart, v_start_ts)), 2) as total,
             coalesce(jsonb_object_agg(bucket_events.ev,
               round(bucket_events.cnt * v_si
                     / (least(buckets.bstart + v_bucket_secs, v_end_ts)
                        - greatest(buckets.bstart, v_start_ts)), 2))
               filter (where bucket_events.ev is not null),
               '{}'::jsonb) as events
      from buckets
      left join (
        select (grain_by_row.ts / v_bucket_secs) * v_bucket_secs as bstart,
               grain_by_row.key as ev, sum(grain_by_row.cnt) as cnt
        from ash._grain_by(v_start_ts, v_end_ts, v_source, 'wait_event')
               as grain_by_row
        group by 1, grain_by_row.key
      ) as bucket_events on bucket_events.bstart = buckets.bstart
      group by buckets.bstart
    )
    select ash.ts_to_timestamptz(bstart) as ts, total, events
    from per_bucket order by bstart
  loop
    v_bar := '';
    v_legend := '';
    for v_i in 1 .. array_length(v_top_events, 1) loop
      v_val := coalesce((v_rec.events ->> v_top_events[v_i])::numeric, 0);
      v_ch := coalesce(
        v_event_chars[v_i],
        v_event_chars[array_length(v_event_chars, 1)]);
      if v_val > 0 then
        v_char_count := greatest(0, round(v_val / v_max * width)::int);
        if v_char_count > 0 then
          v_bar := v_bar || v_event_colors[v_i]
            || repeat(v_ch, v_char_count) || v_reset;
        end if;
        v_legend := v_legend || ' ' || v_top_events[v_i] || '=' || v_val;
      end if;
    end loop;
    v_val := greatest(v_rec.total - (
      select coalesce(sum(coalesce((v_rec.events ->> top_event)::numeric, 0)), 0)
      from unnest(v_top_events) as top_event), 0);
    if v_val > 0 then
      v_char_count := greatest(0, round(v_val / v_max * width)::int);
      if v_char_count > 0 then
        v_bar := v_bar || v_other_color
          || repeat(v_other_char, v_char_count) || v_reset;
      end if;
      v_legend := v_legend || ' Other=' || v_val;
    end if;
    if length(v_bar) < v_legend_len then
      v_bar := v_bar || repeat(' ', v_legend_len - length(v_bar));
    end if;
    bucket_start := v_rec.ts; aas := v_rec.total;
    detail := ltrim(v_legend); chart := v_bar;
    return next;
  end loop;
end;
$$;

/*
 * Human render helper: key/value AAS overview (2.0 port of activity_summary),
 * the companion to ash.periods for one window.
 */
create or replace function ash.summary(
  since timestamptz default null,
  until timestamptz default null
)
returns table (
  metric text,
  value text
)
language plpgsql
stable
set jit = off
set search_path = pg_catalog, ash, public
as $$
declare
  v_from timestamptz := coalesce(
    since, until - interval '1 hour', now() - interval '1 hour');
  v_to timestamptz := coalesce(until, now());
  v_aas record;
  v_rec record;
  v_rank int;
  v_drill_source text;
  v_drill_period_start timestamptz;
  v_drill_period_end timestamptz;
  v_drill_effective_bucket interval;
begin
  if v_from > v_to then
    raise exception
      'ash.summary: since must be less than or equal to until';
  end if;

  select * into v_aas from ash.aas(v_from, v_to);
  if v_aas.buckets_with_data = 0 then
    return query select 'status'::text, 'no data in this time range'::text;
    return;
  end if;

  /*
   * The headline can use rollup_1h minute_counts while the embedded
   * wait/query drills necessarily use hourly arrays. Capture that shared
   * dimensional plan so a widened drill is never presented under the
   * headline's narrower bounds.
   */
  select
    top_row.source,
    top_row.period_start,
    top_row.period_end,
    top_row.effective_bucket
  into
    v_drill_source,
    v_drill_period_start,
    v_drill_period_end,
    v_drill_effective_bucket
  from ash.top('wait_event', v_from, v_to, n => 1) as top_row;

  return query select 'period_start'::text, v_aas.period_start::text;
  return query select 'period_end'::text, v_aas.period_end::text;
  return query select 'source'::text, v_aas.source;
  return query select 'buckets_with_data'::text, v_aas.buckets_with_data::text;
  return query select 'avg_aas'::text, v_aas.avg_aas::text;
  return query select 'peak_aas'::text, v_aas.peak_aas::text;
  return query select 'p99_aas'::text, v_aas.p99_aas::text;
  return query select 'backend_seconds'::text, v_aas.backend_seconds::text;
  return query select 'drill_source'::text, v_drill_source;
  return query
    select 'drill_period_start'::text, v_drill_period_start::text;
  return query select 'drill_period_end'::text, v_drill_period_end::text;
  return query
    select 'drill_effective_bucket'::text, v_drill_effective_bucket::text;

  return query
  select 'databases_active'::text,
    count(*)::text from ash.top('database', v_from, v_to, n => 2147483647);

  v_rank := 0;
  for v_rec in
    select top_row.key, top_row.avg_aas, top_row.pct
    from ash.top('wait_event', v_from, v_to, n => 3) as top_row
  loop
    v_rank := v_rank + 1;
    return query select 'top_wait_' || v_rank,
      v_rec.key || ' (avg_aas ' || v_rec.avg_aas
      || ', ' || v_rec.pct || '%)';
  end loop;

  v_rank := 0;
  for v_rec in
    select top_row.key, top_row.query_text, top_row.avg_aas, top_row.pct
    from ash.top('query_id', v_from, v_to, n => 3) as top_row
  loop
    v_rank := v_rank + 1;
    -- NULL is uncaptured attribution on raw or the broader residual on rollup.
    return query select 'top_query_' || v_rank,
      coalesce(v_rec.key, '(other / unattributed)')
      || coalesce(' — ' || left(v_rec.query_text, 60), '')
      || ' (avg_aas ' || v_rec.avg_aas || ', ' || v_rec.pct || '%)';
  end loop;
end;
$$;

/*
 * Catalog comments (\df+ / obj_description): every reader states its unit
 * (AAS = Average Active Sessions; avg_aas is backend-time per wall-clock
 * second, peak/p99 the max/99th-percentile of per-bucket AAS), its column
 * contract, and the recommended next call, so a human or AI agent can
 * navigate the catalog alone. On-CPU/uninstrumented work is spelled 'CPU*'
 * everywhere user-facing.
 */
comment on function ash.periods(timestamptz) is
$$START HERE (US-1 triage): AAS for six standard trailing windows (1m, 5m, 1h, 1d, 1w, 1mo) requested to end at until (default now()), one row each. Columns (period, period_start, period_end, source, bucket, buckets_with_data, avg_aas, peak_aas, p99_aas): period bounds are effective and may snap outward for hour-only reads; peak/p99 vs avg distinguishes a spike from sustained load; buckets_with_data counts covered buckets at the effective grain named by bucket. Genuine rollup_1h.minute_counts keeps minute grain; legacy/incomplete detail on a minute-capable plan reports source = rollup_1h_flat, bucket = 1 hour, and NULL sub-hour peak/p99 instead of fabricated minute extremes. Next: locate the spike in time with ash.timeline(), then drill with ash.top().$$;

comment on function ash.aas(timestamptz, timestamptz, text, text, bigint, name, interval) is
$$Scalar AAS summary for one requested window [since, until) (defaults: last 1 hour). Optional uniform filters wait_event_type/wait_event/query_id/database. Columns (period_start, period_end, source, effective_bucket, buckets_expected, buckets_with_data, avg_aas, peak_aas, p99_aas, backend_seconds). period_start/period_end are effective bounds: hour-only rollup_1h reads snap partial bounds outward, and avg/backend_seconds are exact for those disclosed bounds. peak/p99 are NULL when retained grain exceeds the requested bucket, never hour averages presented as minute extremes. Genuine minute_counts preserves minute grain for unfiltered/database-only reads; legacy/incomplete detail on that minute-capable plan reports source = rollup_1h_flat. Every explicit query_id filter forces raw; it raises only when ordinary planning selects a rollup with coverage in the requested pre-raw slice, while a young query filter reads available raw rows when the first rollup covers only raw's first retained minute. source = raw|rollup_1m|rollup_1h|rollup_1h_flat|none. Next: ash.top('query_id', wait_event => ...).$$;

comment on function ash.timeline(timestamptz, timestamptz, interval, text, text, bigint, name) is
$$AAS time series (US-2 locate / US-6 capacity): one row per effective bucket. bucket => null auto-selects requested grain by span (<= 6h: 1 minute, <= 7d: 1 hour, else 1 day); hour-only rollup_1h reads widen partial bounds/buckets instead of falling through to missing rollup_1m data. Columns (bucket_start, source, data_points, avg_aas, peak_aas, p99_aas). data_points counts retained-grain rows, not one-second samples; 0 with NULL AAS means no stored observation. take_sample() also writes no row for a sampled idle tick, so idle and uncovered time remain indistinguishable until #137. Genuine minute_counts preserves minute extremes; legacy/incomplete detail on a minute-capable plan reports source = rollup_1h_flat. peak/p99 are NULL whenever retained grain exceeds the requested bucket. Every explicit query_id filter follows aas()'s exact-raw/coarser-history rule. Order by peak_aas desc nulls last, then drill with ash.top().$$;

comment on function ash.top(text, timestamptz, timestamptz, text, text, bigint, name, int, interval, text) is
$$The single vertical drill (US-3): AAS broken down by wait_event_type|wait_event|query_id|database. Columns (key, query_text, source, period_start, period_end, effective_bucket, avg_aas, peak_aas, p99_aas, backend_seconds, pct). Hour-only rollup_1h dimensions snap partial bounds outward; the effective bounds/bucket disclose that degradation and peak/p99 are NULL when retained grain exceeds the requested bucket. Plain database breakdowns retain minute precision through per-(hour,datid) minute_counts; database plus a wait filter remains hour-grain. order_by in avg|peak|p99 applies before n; when the requested extreme is unavailable it falls back to avg ordering. For query_id, raw NULL means uncaptured attribution; rollup NULL is the exact uncaptured/compacted-away residual and competes for n. Every explicit query_id filter forces raw and uses the coarser-history retention guard; a query breakdown plus wait filter needs the raw tie. source = raw|rollup_1m|rollup_1h|rollup_1h_flat|none.$$;

comment on function ash.compare(timestamptz, timestamptz, timestamptz, timestamptz, text, int, text, text, bigint, name, interval) is
$$Before/after comparison of two windows (US-7). dimension => null gives one overall row; a dimension gives top keys by abs(avg_delta). Columns (key, query_text, source_1, source_2, period_start_1, period_end_1, period_start_2, period_end_2, effective_bucket_1, effective_bucket_2, avg_aas_1, avg_aas_2, avg_delta, peak_aas_1, peak_aas_2, p99_aas_1, p99_aas_2, pct_1, pct_2). Sources and effective plans are disclosed per window. If retained read grains differ, both peak values and both p99 values are NULL as incomparable even when explicit effective buckets match; honest averages/delta remain. No-coverage sides and avg_delta are NULL plus a NOTICE; within a covered window an absent key is a true zero. Explicit query_id filters force raw on both sides; unfiltered rollup query comparisons include and NULL-safe-pair each side's compacted-attribution residual.$$;

comment on function ash.samples(timestamptz, timestamptz, int, text, text, bigint, name) is
$$Decoded raw sample rows, newest first (US-5 raw evidence) over [since, until) (default last 1 hour), up to n. Uniform filters wait_event_type/wait_event/query_id/database. Columns (sample_time, database_name, active_backends, wait_event, query_id, query_text). query_text needs pg_stat_statements AND that the caller holds pg_read_all_stats (e.g. via pg_monitor membership); it is null otherwise — a plain ash.grant_reader() role without pg_read_all_stats sees null even with pgss installed, because pgss restricts query text to the owning role. When pgss lives outside public, the caller also needs USAGE on that schema, else query_text is null. Reads ash.sample directly (raw retention only).$$;

comment on function ash.report(timestamptz, timestamptz, int, int) is
$$Machine-readable load report as one jsonb (US-8) for [since, until) (no bounds: last 1 day; until-only: preceding 1 hour). Per wait class (cpu=CPU*, io=IO, ipc=IPC, lock=Lock, lwlock=LWLock; total = their sum) at 1-minute resolution: aas_avg / aas_worst1m / aas_p99 / aas_p999. Plus top_events_{worst1m,p99,p999} (keys io/ipc/lock/lwlock, entries "event(aas)") and top_queryids_{worst1m,p99,p999} (keys total+the four non-cpu classes, entries "queryid(aas)"). Query attribution is decided per extreme minute: a top_queryids key appears when raw samples still cover that class's worst/percentile minute(s), even if the window start predates raw retention (percentile sets attribute over their raw-covered minutes). top_queryids_available (boolean, always present) says whether any attribution was possible — branch on it, not on key absence. coverage {from, to, source, minutes_expected, minutes_with_data, raw_retention_start} reconciles the payload against ash.aas()/ash.top() and flags degraded resolution; raw_retention_start is the logical planning/loss boundary, not the physical query-attribution cutoff. vcpus (echoed, never used) and cluster_name are pass-throughs. Reads ash.rollup_1m only. If it has no coverage for the window, returns null even when raw or rollup_1h has coverage, emits a NOTICE naming that source, and never raises for missing coverage. Payload contract is frozen per 2.0 minor line (keys only added, never renamed/removed); scoring/normalization is the consumer's job.$$;

comment on function ash.chart(timestamptz, timestamptz, interval, int, int, boolean) is
$$Human render helper: stacked ASCII per-bucket AAS chart over [since, until) (default last 1 hour). Series/legend = the window-wide top n wait events PLUS any event that is top-1 in at least one bucket, plus Other. bucket => null auto-selects grain by span. On rollup_1h the chart snaps partial bounds/buckets outward and emits a NOTICE naming source and effective plan; it never silently falls through to unavailable rollup_1m data. Presentation-only (bucket_start, aas, detail, chart); for typed data use ash.timeline(). Enable ANSI color with color => true or "set ash.color = on".$$;

comment on function ash.summary(timestamptz, timestamptz) is
$$Human render helper: key/value AAS overview for one window [since, until) (default last 1 hour) — the companion to ash.periods(). Returns (metric, value): headline effective period bounds/source, buckets_with_data, avg/peak/p99 AAS, backend_seconds, databases_active, and top waits/queries. drill_source, drill_period_start/end, and drill_effective_bucket separately disclose the shared wait/query drill plan, which may widen beyond the headline's minute-precise window on rollup_1h. Presentation-only; source = rollup_1h_flat means the bucket count is hourly. For typed data use ash.aas() and ash.top().$$;

/*
 * Schema-level map: one obj_description() lookup orients a human or agent on
 * the whole surface (readers vs operations) before any \df spelunking.
 */
comment on schema ash is
$$pg_ash: Active Session History for Postgres (pure SQL, no extension). Reader entry points (start with ash.periods()): periods, aas, timeline, top, compare, samples, report, chart, summary, status — readers report load in AAS (Average Active Sessions), and their function comments state how provenance is exposed. Operations/admin (owner-only, not granted by grant_reader): start, stop, take_sample, rotate, rollup_minute, rollup_hour, rollup_cleanup, rebuild_partitions, set_debug_logging, uninstall, grant_reader, revoke_reader. Each function documents itself: select obj_description('ash.<name>(<argtypes>)'::regprocedure).$$;

/*
 * Operational / admin surface: obj_description for every entry point, so the
 * reader-vs-ops split is legible from \df+ alone.
 */
comment on function ash.status() is
$$Installation health snapshot (readable by monitoring roles): sampling state and interval, the day-granular rotation_period contract (whole days, minimum 1 day), pg_cron job status, partition slots and sizes, rollup progress/lag, retention starts (raw_retention_start is a reusable minute-aligned planning/loss boundary; rollup_1m_retention_start and rollup_1h_retention_start are physical starts), error counters (consecutive_rotate_failures, insert_errors, register_wait_cap_hits, missed/skipped samples), and version. Returns (metric, value) rows. Start here when pg_ash misbehaves; readers are documented on the schema: obj_description('ash'::regnamespace).$$;

comment on function ash.start(interval) is
$$Admin: start sampling — schedules take_sample() at the given interval (every => ..., default 1 second; accepts 1–59 whole seconds, whole minutes, or whole hours up to 23h) plus rollup_minute()/rollup_hour()/rollup_cleanup() and a daily rotation check via pg_cron when available. rotation_period accepts whole days only (minimum 1 day); early daily checks skip until it is due. Without pg_cron, start enables sampling and prints the jobs to schedule externally. Idempotent. Inverse: ash.stop(). Check with ash.status().$$;

comment on function ash.stop() is
$$Admin: stop sampling — unschedules the pg_cron jobs created by ash.start() (or disables sampling when pg_cron is absent). Collected data is kept and remains readable. Inverse: ash.start().$$;

comment on function ash.take_sample() is
$$Admin/internal: take one wait-event sample of pg_stat_activity into the current slot (the every-second worker that ash.start() schedules). Returns the number of active backends captured. Call manually only for testing; continuous sampling belongs to ash.start().$$;

comment on function ash.rotate() is
$$Admin: rotate to the next partition slot, rolling up and truncating the oldest (checked daily by ash.start()). Readable raw retention is approximately (num_partitions - 2) * rotation_period. The current partial period may add more. The pre-truncation guard requires minute rollups only while they remain inside rollup_1m_retention_days. Failed attempts increment consecutive_rotate_failures in ash.status(); successful rotation resets it. Safe to call manually to force a due rotation.$$;

comment on function ash.rollup_minute(int) is
$$Admin: fold completed minutes of raw samples into ash.rollup_1m (the every-minute job scheduled by ash.start()); batch_limit caps catch-up minutes per call. Returns completed minute grains processed and watermark-advanced; empty minutes count even when they write no ash.rollup_1m row, while an already-caught-up call returns 0. Readers pick rollups automatically — this only needs manual calls when pg_cron is absent.$$;

comment on function ash.rollup_hour() is
$$Admin: fold completed hours of ash.rollup_1m into ash.rollup_1h. minute_counts preserves available per-minute totals and must sum to the hourly wait total; missing stored rows remain NULL slots because idle and uncovered minutes are indistinguishable (#137). Returns hours processed.$$;

comment on function ash.rollup_cleanup() is
$$Admin: delete rollup rows past retention (rollup_1m_retention_days / rollup_1h_retention_days in ash.config; the daily job scheduled by ash.start()). Rotation deliberately does not require minute rollups that this cleanup is entitled to delete. Returns a summary of rows deleted.$$;

comment on function ash.rebuild_partitions(int, text) is
$$Admin, DESTRUCTIVE: drop and recreate the sample/query-map partitions and query_map_all view with num_partitions slots (3-32). Before changing state, rejects geometry where (num_partitions - 1) * rotation_period exceeds rollup_1m_retention_days; rotation_period is whole-day only. Readable raw retention is approximately (num_partitions - 2) * rotation_period. The current partial period may add more. Requires confirm => 'yes'. DELETES ALL RAW SAMPLES (rollups are kept). Complete ash.grant_reader() bundles, including the default pg_monitor bundle, are preserved across the rebuild.$$;

comment on function ash.set_debug_logging(bool) is
$$Admin: toggle debug logging for the sampler and rollup jobs (null argument reports the current setting). Returns the resulting state.$$;

comment on function ash.uninstall(text) is
$$Admin, DESTRUCTIVE: remove pg_ash entirely — unschedules jobs and drops schema ash with all collected data. Requires confirm => 'yes'.$$;

/*
 * Helper: detect the schema that holds the pg_stat_statements view.
 * Managed services differ: RDS/Cloud SQL/Supabase/AlloyDB/Neon default to
 * public, but self-hosted installs may use `pg_stat_statements`, `extensions`,
 * `monitoring`, or another custom schema. Returns NULL when pgss is not
 * installed.
 */
create or replace function ash._pgss_schema()
returns text
language sql
stable
set search_path = pg_catalog
as $$
  select nsp.nspname::text
  from pg_extension as ext
  join pg_namespace as nsp on nsp.oid = ext.extnamespace
  where ext.extname = 'pg_stat_statements'
$$;

comment on function ash._pgss_schema() is
  'Returns the schema name of the installed pg_stat_statements extension, or NULL if not installed. Used to keep reader functions portable across managed services and custom install schemas.';

/*
 * Helper: re-apply search_path on the pgss reader functions using the
 * currently detected pgss schema. Run this after installing / moving
 * pg_stat_statements if it lives outside `public`. Safe to re-run.
 */
create or replace function ash._apply_pgss_search_path()
returns text
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_pgss_schema text := ash._pgss_schema();
  /*
   * The pgss readers are derived from the catalog, not a hand-maintained list
   * (the old list named v1.x functions that no longer exist, so the #76 shadow
   * mitigation covered nothing). Every ash.* function that must resolve
   * pg_stat_statements carries `public` in its own search_path (see the per-
   * function `set search_path = pg_catalog, ash, public` clauses); those are
   * exactly the functions whose path we rewrite so the real pgss schema is
   * listed before public. No-pgss functions have no `public` in their path and
   * are left alone. Idempotent: the rewritten path still ends in public, so a
   * re-run re-selects the same set.
   */
  v_path text;
  func_row record;
begin
  /*
   * Always keep public in the path as a fallback (matches the managed-service
   * default and preserves behavior when pgss is not yet installed). When the
   * extension lives in a non-default schema, list THAT schema BEFORE public
   * so an unqualified `pg_stat_statements` cannot be shadowed by an
   * attacker-created `public.pg_stat_statements` (security review #76).
   *
   * NOTE (#115): this ordering is now DEFENSE-IN-DEPTH only. Name resolution
   * skips search_path schemas the caller lacks USAGE on, so ordering alone
   * cannot protect a reader without USAGE on the pgss schema. The primary
   * defense is that every pgss data access is schema-qualified via the
   * catalog-derived ash._pgss_schema() (see ash._pgss_query_text and the
   * probes in ash.top / ash._samples); the rewrite here still helps any
   * caller-side unqualified references and USAGE-granted paths.
   */
  if v_pgss_schema is null
     or v_pgss_schema in ('pg_catalog', 'ash', 'public') then
    v_path := 'pg_catalog, ash, public';
  else
    v_path := format('pg_catalog, ash, %I, public', v_pgss_schema);
  end if;

  for func_row in
    select proc.proname,
           pg_catalog.pg_get_function_identity_arguments(proc.oid) as args
    from pg_catalog.pg_proc as proc
    join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.prokind = 'f'
      -- 'public' is one of the schemas in the function's own search_path
      -- (spaces stripped, comma-wrapped so 'publications' etc. can't match).
      and exists (
        select 1 from unnest(coalesce(proc.proconfig, array[]::text[])) as cfg
        where cfg like 'search_path=%'
          and (',' || replace(split_part(cfg, '=', 2), ' ', '') || ',')
              like '%,public,%'
      )
  loop
    execute format('alter function ash.%I(%s) set search_path = %s',
                   func_row.proname, func_row.args, v_path);
  end loop;

  return v_path;
end;
$$;

comment on function ash._apply_pgss_search_path() is
  'Re-applies search_path on pgss reader functions using the currently detected pg_stat_statements schema. Run after installing pg_stat_statements if it lives outside the public schema.';

-- Apply now so installs that have pgss in a non-public schema work out of the
-- box. No-op (keeps default) when pgss is absent or lives in public.
select ash._apply_pgss_search_path();

/*
 * Canonical "admin" function set: callers that must NOT be granted to
 * monitoring roles. Single source of truth for the REVOKE-from-PUBLIC /
 * GRANT-to-owner hardening block below and for grant_reader/revoke_reader
 * (which exclude these names from the reader EXECUTE bundle). Adding a new
 * admin entry point requires updating only this list.
 */
create or replace function ash._admin_funcs()
returns text[]
language sql
immutable
parallel safe
set search_path = pg_catalog
as $$
  select array[
    'start', 'stop', 'uninstall', 'rotate', 'take_sample',
    'set_debug_logging', 'rebuild_partitions', 'rollup_minute',
    'rollup_hour', 'rollup_cleanup', '_drop_all_partitions',
    '_rebuild_query_map_view', '_merge_wait_counts', '_merge_query_counts',
    '_truncate_pairs', '_int4_array_cat_agg', '_int8_array_cat_agg',
    '_register_wait', '_validate_rotation_period', '_record_rotate_failure',
    '_validate_rotation_config', '_validate_config_update',
    /*
     * The privilege helpers and their canonical exclusion-list helper are
     * administrative. Granting grant_reader/revoke_reader to a monitoring
     * role would let it hand out privileges; keeping _admin_funcs itself in
     * this set also prevents revoke_reader from stripping the schema owner's
     * EXECUTE privilege on the helper both functions initialize from.
     */
    '_admin_funcs', 'grant_reader', 'revoke_reader',
    /*
     * _apply_pgss_search_path runs ALTER FUNCTION on every reader, which
     * requires owner privilege so a non-owner call would fail anyway, but
     * list it explicitly so grant_reader doesn't hand it to monitoring
     * roles in the first place. _pgss_schema() is read-only and can stay
     * generally callable.
     */
    '_apply_pgss_search_path'
  ]::text[]
$$;

comment on function ash._admin_funcs() is
  'Canonical list of ash.* admin function names (must not be granted to monitoring roles). Single source of truth used by the REVOKE/GRANT hardening block and by grant_reader/revoke_reader.';

do $$
declare
  v_owner text := (
    select nspowner::regrole::text from pg_namespace where nspname = 'ash'
  );
  v_admin_funcs constant text[] := ash._admin_funcs();
  v_rec record;
begin
  /*
   * Admin functions: revoke from PUBLIC and grant only to the schema owner.
   * Resolve signatures dynamically via pg_proc so any future overload or
   * default-argument change is picked up automatically. prokind in ('f','a')
   * covers regular functions and aggregates (_int{4,8}_array_cat_agg).
   * Entries in _admin_funcs() that are not yet created at this point in
   * install order (e.g. grant_reader/revoke_reader, defined below) are
   * skipped here and locked down by their own DO block once created.
   */
  for v_rec in
    select proc.proname,
           pg_catalog.pg_get_function_identity_arguments(proc.oid) as args
    from pg_catalog.pg_proc as proc
    join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.prokind in ('f', 'a')
      and proc.proname::text = any(v_admin_funcs)
  loop
    execute format('revoke all on function ash.%I(%s) from public',
                   v_rec.proname, v_rec.args);
    execute format('grant execute on function ash.%I(%s) to %I',
                   v_rec.proname, v_rec.args, v_owner);
  end loop;

  /*
   * ts helpers: grant to PUBLIC (harmless read-only conversion, useful for
   * Grafana panels). ts_from_timestamptz and ts_to_timestamptz are already
   * PUBLIC by default.
   */

  /*
   * Reader/helper functions: revoke EXECUTE from PUBLIC for every non-trigger
   * function in ash.*. Signatures are resolved dynamically via pg_proc so
   * default arguments and future overloads do not cause drift. Admin
   * functions above are re-revoked here (harmless: REVOKE is idempotent).
   */
  for v_rec in
    select proc.proname,
           pg_catalog.pg_get_function_identity_arguments(proc.oid) as args
    from pg_catalog.pg_proc as proc
    join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.prokind = 'f'
  loop
    execute format('revoke execute on function ash.%I(%s) from public',
                   v_rec.proname, v_rec.args);
  end loop;

  /*
   * Re-grant EXECUTE on ts helpers to PUBLIC: these are pure, immutable
   * timestamp <-> int4 conversion utilities with no access to sample data.
   * Useful for Grafana panels and ad-hoc queries against rollup views.
   * ash.epoch() must also be public since ts_from_timestamptz inlines a call
   * to it.
   */
  execute 'grant execute on function ash.epoch() to public';
  execute
    'grant execute on function ash.ts_from_timestamptz(timestamptz) to public';
  execute 'grant execute on function ash.ts_to_timestamptz(int4) to public';

  /*
   * Reader tables/views: revoke SELECT from PUBLIC for objects holding
   * sample data, query text, and configuration. REVOKE on a partitioned
   * parent does not cascade to partitions in PostgreSQL, so sample_N and
   * query_map_N are enumerated dynamically below. Rollup tables hold
   * aggregated wait/query data and must also be restricted.
   */
  execute 'revoke select on table ash.sample from public';
  execute 'revoke select on table ash.query_map_all from public';
  execute 'revoke select on table ash.config from public';
  execute 'revoke select on table ash.wait_event_map from public';
  execute 'revoke select on table ash.rollup_1m from public';
  execute 'revoke select on table ash.rollup_1h from public';

  -- Per-slot partition/dictionary tables: sample_N and query_map_N.
  for v_rec in
    select rel.relname
    from pg_catalog.pg_class as rel
    join pg_catalog.pg_namespace as nsp on rel.relnamespace = nsp.oid
    where nsp.nspname = 'ash'
      and rel.relkind in ('r', 'p')
      and (rel.relname ~ '^query_map_[0-9]+$'
           or rel.relname ~ '^sample_[0-9]+$')
  loop
    execute format('revoke select on ash.%I from public', v_rec.relname);
  end loop;
end $$;

--------------------------------------------------------------------------------
-- STEP 7: Convenience helpers for monitoring roles
--------------------------------------------------------------------------------

/*
 * ash.grant_reader(role) / ash.revoke_reader(role)
 *
 * Convenience helpers that hand a monitoring role (Grafana, Datadog, an
 * on-call dashboard, etc.) the *minimum* privileges needed to invoke every
 * public reader function and read from the tables the readers depend on.
 * They are the inverse of the REVOKE-from-PUBLIC hardening above: instead
 * of opening up the schema globally, the operator names a specific role.
 *
 * Granted set:
 *   - USAGE on schema ash
 *   - EXECUTE on every ash.* function EXCEPT the admin set (start, stop,
 *     uninstall, rotate, take_sample, set_debug_logging, rebuild_partitions,
 *     rollup_minute, rollup_hour, rollup_cleanup, _drop_all_partitions,
 *     _rebuild_query_map_view, _merge_wait_counts, _merge_query_counts,
 *     _truncate_pairs, _int4_array_cat_agg, _int8_array_cat_agg,
 *     _register_wait, _validate_rotation_period, _record_rotate_failure,
 *     _validate_rotation_config, _validate_config_update, _admin_funcs).
 *     Defining "reader" by exclusion (rather than enumeration) keeps the
 *     helpers correct as new readers and reader-internal helpers are added.
 *   - SELECT on ash.sample (+ every sample_N partition), ash.query_map_all
 *     (+ every query_map_N partition), ash.config, ash.wait_event_map,
 *     ash.rollup_1m, ash.rollup_1h.
 *
 * Both helpers are idempotent (safe to re-run), validate the role exists
 * via pg_roles, quote_ident() the role name, and emit a RAISE NOTICE
 * summarizing what was changed. revoke_reader() is the symmetric undo.
 */
create or replace function ash.grant_reader(role name)
returns void
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_rec record;
  v_role text;
  /*
   * Canonical admin set lives in ash._admin_funcs(): a reader role must not
   * receive EXECUTE on any of these (incl. grant_reader/revoke_reader, which
   * would let the role hand out privileges).
   */
  v_admin_funcs constant text[] := ash._admin_funcs();
  v_func_count int := 0;
  v_table_count int := 0;
begin
  if role is null or length(trim(role::text)) = 0 then
    raise exception 'ash.grant_reader: role name must not be null or empty';
  end if;

  /*
   * Validate role exists. quote_ident() defends against SQL injection in
   * the dynamic GRANT statements below, but a non-existent role would
   * raise a confusing "role does not exist" from inside the loop —
   * surface a clear error up front instead.
   */
  if not exists (select 1 from pg_catalog.pg_roles where rolname = role) then
    raise exception 'ash.grant_reader: role % does not exist',
      quote_literal(role);
  end if;

  v_role := quote_ident(role);

  execute format('grant usage on schema ash to %s', v_role);

  /*
   * EXECUTE on every reader function (= every ash.* function not in the
   * admin set). Signatures are resolved dynamically via pg_proc so default
   * arguments and future overloads do not cause drift.
   */
  for v_rec in
    select proc.proname,
           pg_catalog.pg_get_function_identity_arguments(proc.oid) as args
    from pg_catalog.pg_proc as proc
    join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.prokind = 'f'
      and proc.proname::text <> all (v_admin_funcs)
  loop
    execute format('grant execute on function ash.%I(%s) to %s',
                   v_rec.proname, v_rec.args, v_role);
    v_func_count := v_func_count + 1;
  end loop;

  -- SELECT on reader tables. Partitioned-parent grants do not cascade to
  -- partitions in PostgreSQL, so sample_N and query_map_N are enumerated.
  execute format('grant select on table ash.sample to %s', v_role);
  execute format('grant select on table ash.query_map_all to %s', v_role);
  execute format('grant select on table ash.config to %s', v_role);
  execute format('grant select on table ash.wait_event_map to %s', v_role);
  execute format('grant select on table ash.rollup_1m to %s', v_role);
  execute format('grant select on table ash.rollup_1h to %s', v_role);
  v_table_count := v_table_count + 6;

  for v_rec in
    select rel.relname
    from pg_catalog.pg_class as rel
    join pg_catalog.pg_namespace as nsp on rel.relnamespace = nsp.oid
    where nsp.nspname = 'ash'
      and rel.relkind in ('r', 'p')
      and (rel.relname ~ '^query_map_[0-9]+$'
           or rel.relname ~ '^sample_[0-9]+$')
  loop
    execute format('grant select on ash.%I to %s', v_rec.relname, v_role);
    v_table_count := v_table_count + 1;
  end loop;

  raise notice
    'ash.grant_reader: granted USAGE on schema ash, EXECUTE on % reader '
    'function(s), SELECT on % table(s) to %',
    v_func_count, v_table_count, v_role;

  /*
   * query_text from top('query_id')/samples() reads other roles'
   * pg_stat_statements text, which pgss restricts to holders of
   * pg_read_all_stats (pg_monitor members have it). We deliberately do NOT
   * auto-grant pg_read_all_stats (least privilege); just tell the operator so
   * a NULL query_text is not mistaken for a bug.
   */
  if not pg_catalog.pg_has_role(role, 'pg_read_all_stats', 'MEMBER')
     and not exists (select 1 from pg_catalog.pg_roles
                     where rolname = role and rolsuper) then
    raise notice
      'ash.grant_reader: note: % lacks pg_read_all_stats (not a pg_monitor '
      'member); query_text will be NULL for it — grant pg_monitor to % if '
      'query text is needed',
      role, role;
  end if;
end;
$$;

comment on function ash.grant_reader(name) is
  'Grants the minimum privileges (USAGE on schema ash, EXECUTE on all reader functions AND the internal helpers they depend on, SELECT on reader tables incl. partitions) to a monitoring role. This is the supported way to grant reader access: reader functions are SECURITY INVOKER and call shared internal helpers (also revoked from PUBLIC), so granting EXECUTE on an individual reader function alone is not sufficient. Idempotent. Inverse: ash.revoke_reader(name). Complete reader bundles are preserved automatically by ash.rebuild_partitions(N, ''yes'').';

create or replace function ash.revoke_reader(role name)
returns void
language plpgsql
set search_path = pg_catalog, ash
as $$
declare
  v_rec record;
  v_role text;
  -- See grant_reader: ash._admin_funcs() is the single source of truth.
  v_admin_funcs constant text[] := ash._admin_funcs();
  v_func_count int := 0;
  v_table_count int := 0;
begin
  if role is null or length(trim(role::text)) = 0 then
    raise exception 'ash.revoke_reader: role name must not be null or empty';
  end if;

  if not exists (select 1 from pg_catalog.pg_roles where rolname = role) then
    raise exception 'ash.revoke_reader: role % does not exist',
      quote_literal(role);
  end if;

  /*
   * A non-superuser schema owner does not bypass ACL checks. Revoking its
   * schema/function privileges bricks sampling, readers, and grant_reader()
   * itself. Refuse every protected target before changing any ACL.
   */
  if exists (
    select
    from pg_catalog.pg_roles as target_role
    where target_role.rolname = role
      and (
        target_role.rolname = current_user
        or target_role.rolsuper
        or exists (
          select
          from pg_catalog.pg_namespace as nsp
          where nsp.nspname = 'ash'
            and nsp.nspowner = target_role.oid
        )
      )
  ) then
    raise exception
      'ash.revoke_reader: refusing protected role % '
      '(schema owner, current user, or superuser)',
      role;
  end if;

  v_role := quote_ident(role);

  for v_rec in
    select proc.proname,
           pg_catalog.pg_get_function_identity_arguments(proc.oid) as args
    from pg_catalog.pg_proc as proc
    join pg_catalog.pg_namespace as nsp on proc.pronamespace = nsp.oid
    where nsp.nspname = 'ash'
      and proc.prokind = 'f'
      and proc.proname::text <> all (v_admin_funcs)
  loop
    execute format('revoke execute on function ash.%I(%s) from %s',
                   v_rec.proname, v_rec.args, v_role);
    v_func_count := v_func_count + 1;
  end loop;

  execute format('revoke select on table ash.sample from %s', v_role);
  execute format('revoke select on table ash.query_map_all from %s', v_role);
  execute format('revoke select on table ash.config from %s', v_role);
  execute format('revoke select on table ash.wait_event_map from %s', v_role);
  execute format('revoke select on table ash.rollup_1m from %s', v_role);
  execute format('revoke select on table ash.rollup_1h from %s', v_role);
  v_table_count := v_table_count + 6;

  for v_rec in
    select rel.relname
    from pg_catalog.pg_class as rel
    join pg_catalog.pg_namespace as nsp on rel.relnamespace = nsp.oid
    where nsp.nspname = 'ash'
      and rel.relkind in ('r', 'p')
      and (rel.relname ~ '^query_map_[0-9]+$'
           or rel.relname ~ '^sample_[0-9]+$')
  loop
    execute format('revoke select on ash.%I from %s', v_rec.relname, v_role);
    v_table_count := v_table_count + 1;
  end loop;

  -- USAGE last so the in-flight statements above can still resolve ash.*
  -- by name even if the role had no other path to it. Idempotent.
  execute format('revoke usage on schema ash from %s', v_role);

  raise notice
    'ash.revoke_reader: revoked USAGE on schema ash, EXECUTE on % reader '
    'function(s), SELECT on % table(s) from %',
    v_func_count, v_table_count, v_role;
end;
$$;

comment on function ash.revoke_reader(name) is
  'Revokes the privileges granted by ash.grant_reader(): USAGE on schema ash, EXECUTE on all reader functions, SELECT on reader tables. Refuses schema-owner, current-user, and superuser targets so an installation cannot revoke its own operating privileges. Idempotent. Inverse: ash.grant_reader(name).';

-- Lock down the helpers themselves: only the schema owner may hand out
-- (or take back) privileges. PUBLIC must not be able to call them.
do $$
declare
  v_owner text := (
    select nspowner::regrole::text from pg_namespace where nspname = 'ash'
  );
begin
  execute format('revoke all on function ash.grant_reader(name) from public');
  execute format('revoke all on function ash.revoke_reader(name) from public');
  execute format('grant execute on function ash.grant_reader(name) to %I', v_owner);
  execute format('grant execute on function ash.revoke_reader(name) to %I', v_owner);
end $$;

/*
 * Re-apply the EXECUTE grants snapshotted before the drop/recreate at the
 * top of this script (#107), keeping the restore strictly least-privilege:
 *   * Admin functions (ash._admin_funcs()) are never restored. They are
 *     locked to the owner by the hardening block above and are never handed
 *     out by ash.grant_reader(); re-applying a stray manual grant on one
 *     would silently undo that hardening on every install. Excluding them
 *     here preserves the pre-#107 behaviour where DROP FUNCTION scrubbed
 *     such grants.
 *   * Each grant is restored to the exact same signature when it still
 *     exists, so a role that held only one overload of a function is not
 *     widened to its siblings. Only when the snapshotted signature is gone
 *     (a genuine cross-version signature change — the case this restore
 *     exists to cover) does it fall back to every current overload of the
 *     name.
 * This mirrors what CREATE OR REPLACE would have preserved: function names
 * that no longer exist (removed/renamed) are skipped, roles dropped
 * mid-script are skipped, and a role with only partial FUNCTION grants is
 * not widened. Roles that held the FULL pre-upgrade reader-function bundle
 * (detected in the snapshot block at the top of this script) are additionally
 * re-run through ash.grant_reader() afterwards, so they can also execute
 * helpers introduced by this version — otherwise the readers they kept would
 * fail mid-call on the first new internal helper. This classification does
 * not snapshot table ACLs, so the full-bundle replay can restore table access
 * an operator narrowed; the WARNING below lists every affected role.
 */
do $$
declare
  v_rec record;
  v_admin_funcs constant text[] := ash._admin_funcs();
  v_reader_roles text;
begin
  for v_rec in
    select distinct func_acl.grantee, func_acl.grantable, proc.proname,
           pg_catalog.pg_get_function_identity_arguments(proc.oid) as args
    from pg_temp._ash_install_func_acl as func_acl
    join pg_catalog.pg_roles as role_row on role_row.rolname = func_acl.grantee
    join pg_catalog.pg_proc as proc on proc.proname = func_acl.proname
    join pg_catalog.pg_namespace as nsp on nsp.oid = proc.pronamespace
    where nsp.nspname = 'ash'
      and proc.prokind in ('f', 'a')
      and proc.proname::text <> all (v_admin_funcs)
      and (
        -- the snapshotted overload still exists: restore exactly it
        pg_catalog.pg_get_function_identity_arguments(proc.oid) = func_acl.args
        -- the snapshotted overload is gone (signature changed): fall back
        -- to restoring every current overload of the name
        or not exists (
          select 1
          from pg_catalog.pg_proc as proc2
          join pg_catalog.pg_namespace as nsp2 on nsp2.oid = proc2.pronamespace
          where nsp2.nspname = 'ash'
            and proc2.proname = func_acl.proname
            and pg_catalog.pg_get_function_identity_arguments(proc2.oid)
                = func_acl.args
        )
      )
  loop
    execute format('grant execute on function ash.%I(%s) to %I%s',
                   v_rec.proname, v_rec.args, v_rec.grantee,
                   case when v_rec.grantable then ' with grant option'
                        else '' end);
  end loop;

  select string_agg(
           pg_catalog.quote_ident(reader_role.rolname),
           ', ' order by reader_role.rolname
         )
  into v_reader_roles
  from pg_temp._ash_install_reader_roles as reader_role
  join pg_catalog.pg_roles as role_row
    on role_row.rolname = reader_role.rolname;

  if v_reader_roles is not null then
    raise warning
      'pg_ash installer: restoring the full reader bundle for role(s) %; '
      'any operator-narrowed table privileges will be re-granted',
      v_reader_roles;
  end if;

  /*
   * Preserved reader roles: grant the full CURRENT reader closure. The
   * exact-signature loop above only replays pre-upgrade grants, so helpers
   * new in this version would stay denied for these roles. grant_reader()
   * excludes the admin set, so this never widens beyond reader access, but it
   * can restore manually revoked reader-table access because the detection
   * snapshot records function grants only.
   *
   * _admin_funcs() moved from the reader set into the admin set in #166.
   * CREATE OR REPLACE preserves its old ACL, so explicitly remove that one
   * legacy bundle grant before replaying the current bundle. Partial/manual
   * roles are untouched because they are not present in the reader snapshot.
   */
  for v_rec in
    select reader_role.rolname
    from pg_temp._ash_install_reader_roles as reader_role
    join pg_catalog.pg_roles as role_row
      on role_row.rolname = reader_role.rolname
  loop
    execute format(
      'revoke execute on function ash._admin_funcs() from %I cascade',
      v_rec.rolname
    );
    perform ash.grant_reader(v_rec.rolname);
  end loop;

  drop table pg_temp._ash_install_func_acl;
  drop table pg_temp._ash_install_reader_roles;
end $$;

/*
 * Default reader: pg_monitor.
 *
 * pg_monitor is the predefined monitoring role (PG10+); its members already
 * hold pg_read_all_stats / pg_read_all_settings / pg_stat_scan_tables and can
 * therefore read pg_stat_activity and pg_stat_statements directly — the very
 * sources pg_ash samples from. Granting them pg_ash's derived data exposes
 * nothing they could not already see, and it makes monitoring tools running
 * as pg_monitor members (Grafana, exporters) work out of the box.
 *
 * To opt out, run this after installation and after every installer re-apply
 * (including upgrades, which restore the default grant):
 *   select ash.revoke_reader('pg_monitor');
 *
 * Best-effort: this must NEVER abort the install. On a locked-down managed
 * platform the installing role may not be allowed to grant on behalf of
 * pg_monitor — warn and continue; the operator can grant_reader() manually.
 */
do $$
begin
  if exists (
       select from pg_catalog.pg_roles where rolname = 'pg_monitor'
     ) then
    /*
     * Revoke first so pg_monitor's aclitem always lands LAST on every
     * function/table, on fresh installs and re-applies alike. Without this,
     * CREATE OR REPLACE preserves proacl across a re-apply, and the mid-file
     * REVOKE-then-GRANT-to-PUBLIC on epoch/ts_* would leave pg_monitor in a
     * different aclitem position than on a fresh install — same effective
     * privileges, but a text-level proacl diff in equivalence snapshots.
     */
    perform ash.revoke_reader('pg_monitor');
    perform ash.grant_reader('pg_monitor');
  else
    -- pg_monitor is predefined on every supported PG version; this branch is
    -- purely defensive (e.g. an exotic fork without predefined roles).
    raise notice
      'pg_ash: role pg_monitor not found, skipping default reader grant';
  end if;
exception when others then
  raise warning
    'pg_ash: could not grant default reader privileges to pg_monitor '
    '(%: %); run "select ash.grant_reader(''pg_monitor'')" manually, or '
    'ignore to leave pg_monitor without access',
    sqlstate, sqlerrm;
end $$;

/*
 * Installer re-apply migration for running installations. Defining the new
 * ash.start() body is not enough: an existing pg_cron job keeps its old
 * minute-0 schedule until start() is called again.
 */
do $$
declare
  v_hourly_job record;
begin
  if ash._pg_cron_available() then
    for v_hourly_job in
      select jobname, command
      from cron.job
      where jobname = 'ash_rollup_1h'
        and database = current_database()
        and username = current_user
        and schedule = '0 * * * *'
    loop
      /*
       * Named cron.schedule() updates the caller's existing job in place and
       * is available to ordinary pg_cron job owners. cron.alter_job() is not:
       * pg_cron revokes it from PUBLIC by default. Reusing the stored command
       * also preserves custom command text; pg_cron keeps jobid/active state.
       */
      perform cron.schedule(
        v_hourly_job.jobname,
        '1 * * * *',
        v_hourly_job.command
      );
    end loop;
  end if;
end $$;

/*
 * Enforce the day-granular rotation contract last. A legacy install may
 * already contain a sub-day value that older versions accepted. The
 * actionable error must still stop that unsupported configuration. Because
 * this installer is file-transactional, the error rolls every replacement
 * back. The operator can update the pre-existing config to a whole-day value
 * and re-run the installer to atomically install the operational surface and
 * declarative CHECK.
 */
do $$
begin
  perform ash._validate_rotation_period(
    (select rotation_period from ash.config where singleton)
  );

  if not exists (
    select from pg_constraint
    where conname = 'config_rotation_period_day_check'
      and conrelid = 'ash.config'::regclass
  ) then
    -- Keep this predicate aligned with _validate_rotation_period() above.
    alter table ash.config
      add constraint config_rotation_period_day_check
      check (
        rotation_period >= interval '1 day'
        and extract(year from rotation_period) = 0
        and extract(month from rotation_period) = 0
        and extract(epoch from rotation_period) % 86400 = 0
      );
  end if;
end $$;

commit;

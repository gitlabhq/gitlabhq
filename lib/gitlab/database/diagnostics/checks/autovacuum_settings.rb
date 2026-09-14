# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Checks
        class AutovacuumSettings
          # Worker counts are only flagged below the PostgreSQL default of 3, since most
          # instances run with the default and warning on it would be noise.
          MAX_WORKERS_WARN_THRESHOLD = 3
          DEFAULT_COST_LIMIT = 200

          # A global scale factor at or above this threshold is impractical for
          # large tables: they accumulate a large amount of dead-tuple debt
          # before autovacuum even triggers.
          HIGH_SCALE_FACTOR_THRESHOLD = 0.1
          LARGE_TABLE_BYTES_THRESHOLD = 10 * 1024 * 1024 * 1024 # 10 GiB

          AUTOVACUUM_OVERRIDES_LIMIT = 50
          LARGEST_TABLES_LIMIT = 20

          # How many candidate tables to rank cheaply by pg_class.relpages (a
          # catalog-only heap-page estimate) before computing the exact
          # pg_total_relation_size for just the largest few
          LARGEST_TABLES_CANDIDATE_LIMIT = 100

          # Effective autovacuum-related GUCs to surface, read from pg_settings.
          # vacuum_cost_limit is included because autovacuum_vacuum_cost_limit may inherit it
          SETTING_NAMES = %w[
            autovacuum
            autovacuum_max_workers
            autovacuum_naptime
            autovacuum_vacuum_scale_factor
            autovacuum_vacuum_threshold
            autovacuum_analyze_scale_factor
            autovacuum_analyze_threshold
            autovacuum_vacuum_insert_scale_factor
            autovacuum_vacuum_insert_threshold
            autovacuum_vacuum_cost_delay
            autovacuum_vacuum_cost_limit
            vacuum_cost_limit
            autovacuum_work_mem
            maintenance_work_mem
            autovacuum_freeze_max_age
            autovacuum_multixact_freeze_max_age
          ].freeze

          # unit is returned alongside setting so views can render memory/time values
          # with their configured unit (e.g. "65536 kB")
          SETTINGS_SQL = <<~SQL
            SELECT name, setting, unit
            FROM pg_settings
            WHERE name IN (%{names})
          SQL

          # reloptions are 'name=value' strings. toast.* options are stored on
          # the toast relation itself, so 'toast.autovacuum%' can never match here.
          OVERRIDES_JSON_SQL = <<~SQL
            (
              SELECT jsonb_object_agg(split_part(opt, '=', 1), split_part(opt, '=', 2))
              FROM unnest(reloptions) opt
              WHERE opt LIKE 'autovacuum%'
            ) AS overrides
          SQL

          # Tables that override any autovacuum reloption. Same two-stage shape
          # as LARGEST_TABLES_SQL: rank by relpages first so the result set and
          # the pg_total_relation_size calls stay bounded on instances with many
          # overrides. Tables that set autovacuum_enabled rank first so the
          # LIMIT never cuts a disabled table out of the count.
          AUTOVACUUM_OVERRIDES_SQL = <<~SQL
            WITH candidates AS (
              SELECT c.oid, n.nspname AS schema_name, c.relname AS table_name,
                c.reltuples, c.reloptions
              FROM pg_class c
              JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE c.relkind = 'r'
                AND c.reloptions IS NOT NULL
                AND EXISTS (
                  SELECT 1 FROM unnest(c.reloptions) opt
                  WHERE opt LIKE 'autovacuum%'
                )
              ORDER BY EXISTS (
                  SELECT 1 FROM unnest(c.reloptions) opt
                  WHERE opt LIKE 'autovacuum_enabled=%'
                ) DESC,
                c.relpages DESC
              LIMIT #{AUTOVACUUM_OVERRIDES_LIMIT}
            )
            SELECT schema_name,
              table_name,
              pg_total_relation_size(oid) AS total_bytes,
              GREATEST(reltuples, 0)::bigint AS estimated_rows,
              #{OVERRIDES_JSON_SQL.chomp}
            FROM candidates
            ORDER BY total_bytes DESC
          SQL
          .freeze

          # The largest ordinary tables, used to judge the scale factor in effect per table
          LARGEST_TABLES_SQL = <<~SQL
            WITH candidates AS (
              SELECT c.oid, n.nspname AS schema_name, c.relname AS table_name,
                c.reltuples, c.reloptions
              FROM pg_class c
              JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE c.relkind = 'r'
                AND n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
              ORDER BY c.relpages DESC
              LIMIT #{LARGEST_TABLES_CANDIDATE_LIMIT}
            )
            SELECT schema_name,
              table_name,
              pg_total_relation_size(oid) AS total_bytes,
              GREATEST(reltuples, 0)::bigint AS estimated_rows,
              #{OVERRIDES_JSON_SQL.chomp}
            FROM candidates
            ORDER BY total_bytes DESC
            LIMIT #{LARGEST_TABLES_LIMIT}
          SQL
          .freeze

          def initialize(connection)
            @connection = connection
          end

          def execute
            findings = settings_findings + table_findings

            {
              settings: settings,
              table_overrides: table_overrides,
              scale_factor_risks: scale_factor_risks,
              findings: Findings.sort(findings),
              severity: Findings.worst(findings.pluck(:severity)),
              counts: Findings.counts(findings)
            }
          end

          private

          attr_reader :connection

          # Re-keyed in SETTING_NAMES order so views can render settings by simply
          # iterating the hash, without their own copy of the name list. Settings
          # absent on the running PostgreSQL version
          def settings
            @settings ||= begin
              rows = fetch_settings

              ordered = SETTING_NAMES.each_with_object({}) do |name, hash|
                hash[name] = rows[name] if rows[name]
              end

              annotate_effective_cost_limit(ordered)
              ordered
            end
          end

          def fetch_settings
            names = SETTING_NAMES.map { |name| connection.quote(name) }.join(', ')

            connection.select_all(format(SETTINGS_SQL, names: names)).each_with_object({}) do |row, rows|
              rows[row['name']] = { value: row['setting'], unit: row['unit'] }
            end
          end

          # autovacuum_vacuum_cost_limit = -1 means "inherit vacuum_cost_limit". Views
          # show the resolved limit next to the -1 sentinel so the value cell matches
          # the finding, which judges the effective limit.
          def annotate_effective_cost_limit(ordered)
            entry = ordered['autovacuum_vacuum_cost_limit']
            return unless entry && entry[:value] == '-1'

            effective = ordered.dig('vacuum_cost_limit', :value)
            entry[:effective_value] = effective if effective
          end

          def table_overrides
            @table_overrides ||= connection.select_all(AUTOVACUUM_OVERRIDES_SQL).map { |row| table_row(row) }
          end

          def table_row(row)
            overrides = Gitlab::Json::SafeParser.parse(row['overrides'] || '{}')

            {
              schema_name: row['schema_name'],
              table_name: row['table_name'],
              total_bytes: row['total_bytes'].to_i,
              estimated_rows: row['estimated_rows'].to_i,
              overrides: overrides,
              autovacuum_disabled: autovacuum_disabled?(overrides)
            }
          end

          def autovacuum_disabled?(overrides)
            Gitlab::Utils.to_boolean(overrides['autovacuum_enabled']) == false
          end

          # Large tables whose scale factor in effect (per-table override, else
          # global) is still high. Tables with autovacuum disabled are left out;
          # the disabled error already covers them.
          def scale_factor_risks
            @scale_factor_risks ||=
              if global_scale_factor_high?
                largest_tables
                  .select { |table| at_risk?(table) }
                  .map { |table| table.except(:overrides, :autovacuum_disabled) }
              else
                []
              end
          end

          def at_risk?(table)
            return false if table[:total_bytes] < LARGE_TABLE_BYTES_THRESHOLD || table[:autovacuum_disabled]

            effective_scale_factor(table) >= HIGH_SCALE_FACTOR_THRESHOLD
          end

          # A threshold override only adds a fixed row count on top of the scale
          # factor, so it cannot compensate and is ignored here.
          def effective_scale_factor(table)
            override = table[:overrides]['autovacuum_vacuum_scale_factor']

            override ? override.to_f : numeric_value('autovacuum_vacuum_scale_factor')
          end

          def global_scale_factor_high?
            scale_factor = numeric_value('autovacuum_vacuum_scale_factor')

            scale_factor && scale_factor >= HIGH_SCALE_FACTOR_THRESHOLD
          end

          def largest_tables
            connection.select_all(LARGEST_TABLES_SQL).map { |row| table_row(row) }
          end

          def settings_findings
            [
              autovacuum_disabled_finding,
              throttling_disabled_finding,
              max_workers_finding,
              cost_limit_finding,
              work_mem_finding
            ].compact
          end

          def table_findings
            [tables_disabled_finding, scale_factor_finding].compact
          end

          def tables_disabled_finding
            count = table_overrides.count { |table| table[:autovacuum_disabled] }
            return if count == 0

            {
              severity: Findings::ERROR,
              code: 'tables_autovacuum_disabled',
              message: format(ns_(
                'DatabaseDiagnostics|Autovacuum is disabled for %{count} table, so its dead tuples are ' \
                  'never reclaimed automatically.',
                'DatabaseDiagnostics|Autovacuum is disabled for %{count} tables, so their dead tuples are ' \
                  'never reclaimed automatically.',
                count), count: count)
            }
          end

          def scale_factor_finding
            count = scale_factor_risks.size
            return if count == 0

            {
              severity: Findings::WARNING,
              code: 'scale_factor_risk',
              message: format(ns_(
                'DatabaseDiagnostics|The vacuum scale factor in effect is high for %{count} large table, ' \
                  'which delays autovacuum until a large amount of dead tuples has accumulated.',
                'DatabaseDiagnostics|The vacuum scale factor in effect is high for %{count} large tables, ' \
                  'which delays autovacuum until a large amount of dead tuples has accumulated.',
                count), count: count)
            }
          end

          def autovacuum_disabled_finding
            return unless raw_value('autovacuum') == 'off'

            {
              severity: Findings::ERROR,
              code: 'autovacuum_disabled',
              setting_name: 'autovacuum',
              message: s_('DatabaseDiagnostics|Autovacuum is disabled. Dead tuples will not be reclaimed ' \
                'automatically, risking bloat and eventually transaction ID wraparound.')
            }
          end

          def throttling_disabled_finding
            return unless numeric_value('autovacuum_vacuum_cost_delay')&.zero?

            {
              severity: Findings::ERROR,
              code: 'autovacuum_throttling_disabled',
              setting_name: 'autovacuum_vacuum_cost_delay',
              message: s_('DatabaseDiagnostics|A cost delay of zero disables throttling, so autovacuum runs ' \
                'at full speed and can cause write storms and replication lag.')
            }
          end

          def max_workers_finding
            workers = numeric_value('autovacuum_max_workers')
            return unless workers && workers < MAX_WORKERS_WARN_THRESHOLD

            {
              severity: Findings::WARNING,
              code: 'autovacuum_max_workers_low',
              setting_name: 'autovacuum_max_workers',
              message: s_('DatabaseDiagnostics|Only a few autovacuum workers are configured, which may be ' \
                'too few for a large or decomposed database fleet.')
            }
          end

          def cost_limit_finding
            effective = effective_cost_limit
            return unless effective && effective <= DEFAULT_COST_LIMIT

            {
              severity: Findings::WARNING,
              code: 'autovacuum_cost_limit_low',
              setting_name: 'autovacuum_vacuum_cost_limit',
              message: s_('DatabaseDiagnostics|The cost limit is at or near the conservative default, which ' \
                'is likely too low to keep up on modern storage.')
            }
          end

          def work_mem_finding
            return unless raw_value('autovacuum_work_mem') == '-1'

            {
              severity: Findings::WARNING,
              code: 'autovacuum_work_mem_inherited',
              setting_name: 'autovacuum_work_mem',
              message: s_('DatabaseDiagnostics|The autovacuum_work_mem setting is unset and inherits ' \
                'maintenance_work_mem. Consider setting it explicitly to bound per-worker memory.')
            }
          end

          def effective_cost_limit
            limit = numeric_value('autovacuum_vacuum_cost_limit')
            return limit unless limit == -1

            numeric_value('vacuum_cost_limit')
          end

          def raw_value(name)
            settings.dig(name, :value)
          end

          def numeric_value(name)
            raw_value(name)&.to_f
          end
        end
      end
    end
  end
end

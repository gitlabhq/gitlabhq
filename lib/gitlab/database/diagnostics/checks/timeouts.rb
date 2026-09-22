# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Checks
        class Timeouts < Base
          # statement_timeout comes first because it is the only setting this check
          # judges. The other two are reported for context.
          SETTING_NAMES = %w[statement_timeout lock_timeout idle_in_transaction_session_timeout].freeze

          UNLIMITED = 0

          # See doc/administration/postgresql/tune.md: required setting for external
          # instances, matching the one-minute Puma rack timeout.
          MAXIMUM_RECOMMENDED_MS = 60_000

          # setting is the value for this session, which GitLab sets from the
          # variables block in database.yml. reset_val is what a session falls back
          # to on RESET, so it carries postgresql.conf plus any ALTER DATABASE or
          # ALTER ROLE default. The two differ on almost every instance: one covers
          # GitLab's own connections, the other covers every other session.
          SETTINGS_SQL = <<~SQL
            SELECT name, setting, unit, source, sourcefile, sourceline, reset_val
            FROM pg_settings
            WHERE name IN (%{names})
          SQL

          # Per-database and per-role defaults, which pg_settings folds into a single
          # resolved value. setconfig holds "name=value" entries, so each is unnested
          # and split here; a NULL database or role means the entry applies to all of
          # them. Rows for other databases cannot affect this one, so they are
          # excluded. strpos, not split_part, because a value may contain "=".
          OVERRIDES_SQL = <<~SQL
            SELECT d.datname AS database_name,
              r.rolname AS role_name,
              split_part(c.config, '=', 1) AS name,
              substr(c.config, strpos(c.config, '=') + 1) AS value
            FROM pg_catalog.pg_db_role_setting s
            LEFT JOIN pg_catalog.pg_database d ON d.oid = s.setdatabase
            LEFT JOIN pg_catalog.pg_roles r ON r.oid = s.setrole
            CROSS JOIN LATERAL unnest(s.setconfig) AS c(config)
            WHERE (s.setdatabase = 0 OR d.datname = current_database())
              AND split_part(c.config, '=', 1) IN (%{names})
            ORDER BY database_name NULLS FIRST, role_name NULLS FIRST, name
          SQL

          def execute
            { settings: settings, overrides: overrides }.merge(verdict(statement_timeout_findings))
          end

          private

          def statement_timeout_findings
            setting = settings['statement_timeout']
            return [] unless setting

            [session_finding(setting), cluster_default_finding(setting)].compact
          end

          def session_finding(setting)
            if setting[:value] == UNLIMITED
              {
                severity: Findings::ERROR,
                code: 'statement_timeout_unlimited',
                message: format(
                  s_('DatabaseDiagnostics|The statement_timeout value is 0 on the connection GitLab uses, so a ' \
                    'query can run with no limit. A query that does not end keeps its connection, which can use ' \
                    'up the connection pool and stop GitLab. Set statement_timeout to %{maximum} ms or less.'),
                  maximum: MAXIMUM_RECOMMENDED_MS
                )
              }
            elsif setting[:value] > MAXIMUM_RECOMMENDED_MS
              {
                severity: Findings::WARNING,
                code: 'statement_timeout_above_maximum',
                message: format(
                  s_('DatabaseDiagnostics|The statement_timeout value is %{value} ms on the connection GitLab uses, ' \
                    'more than the recommended maximum of %{maximum} ms. A higher value lets a slow query hold its ' \
                    'connection for longer.'),
                  value: setting[:value], maximum: MAXIMUM_RECOMMENDED_MS
                )
              }
            end
          end

          # Skipped when GitLab's own session is unlimited, because the session
          # finding already reports that value, and when an ALTER DATABASE or ALTER
          # ROLE entry exists, because reset_val then hides what other roles get.
          def cluster_default_finding(setting)
            return unless setting[:default_value] == UNLIMITED && setting[:value] != UNLIMITED
            return if overridden?('statement_timeout')

            {
              severity: Findings::WARNING,
              code: 'statement_timeout_unlimited_by_default',
              message: s_('DatabaseDiagnostics|The cluster default for statement_timeout is 0. GitLab sets its ' \
                'own value for each of its sessions, but any other session, for example psql, a backup or an ' \
                'external tool, can run a query with no limit. Set statement_timeout in postgresql.conf, or ' \
                'with ALTER DATABASE or ALTER ROLE.')
            }
          end

          def settings
            @settings ||= begin
              sql = format(SETTINGS_SQL, names: quoted_names(SETTING_NAMES))
              rows = connection.select_all(sql).index_by { |row| row['name'] }

              # Keyed in SETTING_NAMES order so both views render by iterating the
              # hash. A setting the running PostgreSQL does not have is skipped.
              SETTING_NAMES.each_with_object({}) do |name, ordered|
                row = rows[name]
                next unless row

                ordered[name] = {
                  value: row['setting'].to_i,
                  default_value: row['reset_val'].to_i,
                  unit: row['unit'],
                  source: row['source'],
                  source_location: source_location(row)
                }
              end
            end
          end

          def source_location(row)
            return if row['sourcefile'].blank?

            "#{row['sourcefile']}:#{row['sourceline']}"
          end

          def overridden?(name)
            overrides.any? { |override| override[:name] == name }
          end

          def overrides
            @overrides ||= begin
              sql = format(OVERRIDES_SQL, names: quoted_names(SETTING_NAMES))

              connection.select_all(sql).map do |row|
                {
                  database_name: row['database_name'],
                  role_name: row['role_name'],
                  name: row['name'],
                  value: row['value']
                }
              end
            end
          end
        end
      end
    end
  end
end

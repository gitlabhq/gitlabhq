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

          def initialize(connection)
            @connection = connection
          end

          def execute
            findings = settings_findings

            {
              settings: settings,
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

          def settings_findings
            [
              autovacuum_disabled_finding,
              throttling_disabled_finding,
              max_workers_finding,
              cost_limit_finding,
              work_mem_finding
            ].compact
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

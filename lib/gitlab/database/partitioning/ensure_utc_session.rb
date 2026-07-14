# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      # Guard shared by PartitionExporter and PartitionImporter.
      #
      # Partition export/import round-trips `timestamp with time zone` partition
      # boundaries through their textual `FOR VALUES` definition. PostgreSQL
      # renders that text in the connection's *session* TimeZone, so a non-UTC
      # session shifts the boundary to a different instant (e.g. an instant
      # stored as 2026-01-01 00:00:00+00 renders as 2025-12-31 under
      # America/Los_Angeles), silently corrupting the exported/imported range.
      #
      # GitLab runs its database sessions in UTC, but that is an implicit
      # assumption. This guard makes it explicit: it fails loudly and early
      # instead of producing wrong boundaries. See
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/601875.
      module EnsureUtcSession
        # Values PostgreSQL may report for a UTC session that are equivalent to
        # UTC for boundary-rendering purposes.
        UTC_TIMEZONES = Set.new(%w[UTC Etc/UTC GMT Etc/GMT Greenwich Universal Zulu]).freeze

        private

        # @return [void]
        # Relies on the including class exposing a private `connection` reader.
        #
        # Two TimeZone values are checked:
        #
        # - The live session zone (`SHOW TIMEZONE`). This is the value PostgreSQL
        #   uses to render a stored `timestamptz` boundary into the `FOR VALUES`
        #   text the exporter parses, so it strictly governs correctness here. A
        #   non-UTC session is what actually corrupts a boundary.
        # - The configured default (`pg_settings.reset_val`), i.e. the zone a
        #   fresh connection starts with. This does not affect rendering on this
        #   connection, but a non-UTC default is checked defensively: it forces a
        #   misconfigured cell's database default to be fixed before export/import
        #   proceeds, rather than relying on every future session resetting to UTC.
        def ensure_utc_session!
          ensure_utc_timezone!('session', connection.select_value('SHOW TIMEZONE'))
          ensure_utc_timezone!(
            'configured default',
            connection.select_value("SELECT reset_val FROM pg_settings WHERE name = 'TimeZone'")
          )
        end

        # @return [void]
        def ensure_utc_timezone!(source, timezone)
          return if UTC_TIMEZONES.include?(timezone.to_s)

          raise ArgumentError,
            "Partition export/import requires the connection's #{source} TimeZone to be UTC, got: #{timezone}"
        end
      end
    end
  end
end

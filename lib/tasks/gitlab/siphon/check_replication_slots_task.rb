# frozen_string_literal: true

module Tasks
  module Gitlab
    module Siphon
      # Checks that the Siphon logical replication slots have a producer attached, still reserve
      # their WAL, and are advancing. Read only.
      class CheckReplicationSlotsTask
        POLL_INTERVAL_SECONDS = 5
        POLL_ATTEMPTS = 5
        DISCOVERY_PATTERN = '%siphon%'
        EXPECTED_WAL_STATUS = 'reserved'
        LOST_WAL_STATUS = 'lost'

        def initialize(slot_names: nil, database: nil)
          @slot_names = slot_names.to_s.split(',').map(&:strip).reject(&:empty?)
          @database = database.presence
          @results = []
        end

        def execute
          puts "SIPHON_SLOT_NAMES is not set, checking every slot matching #{DISCOVERY_PATTERN}" if discovery?

          ::Gitlab::Database::EachDatabase.each_connection(only: @database, include_shared: false) do |conn, name|
            check_database(conn, name)
          end

          report
        end

        private

        def discovery?
          @slot_names.empty?
        end

        def timeout_seconds
          POLL_INTERVAL_SECONDS * POLL_ATTEMPTS
        end

        def check_database(connection, database_name)
          puts
          puts "=== #{database_name} ==="

          slots = fetch_slots(connection, discovery? ? nil : @slot_names)

          if slots.empty?
            puts '  no matching slots'
            return
          end

          watch(connection, database_name, slots.index_by { |slot| slot['slot_name'] })
        end

        # Every condition is re-read each round, so a producer that reconnects part way through
        # still passes. A lost slot is the exception: its WAL is gone, waiting cannot bring it back.
        def watch(connection, database_name, baseline)
          baseline.each_value { |slot| print_slot(slot) }
          puts "  polling every #{POLL_INTERVAL_SECONDS}s for up to #{timeout_seconds}s"

          pending = baseline.dup

          POLL_ATTEMPTS.times do |round|
            Kernel.sleep(POLL_INTERVAL_SECONDS)

            fetch_slots(connection, pending.keys).each do |slot|
              name = slot['slot_name']
              pending[name] = slot

              status, reason = verdict(baseline[name], slot)
              next unless status == :ok || lost?(slot)

              puts "  [#{round + 1}/#{POLL_ATTEMPTS}] #{name} advanced to #{slot['lsn']}" if status == :ok
              record(name, database_name, status, reason)
              pending.delete(name)
            end

            break if pending.empty?
          end

          pending.each { |name, slot| record(name, database_name, *verdict(baseline[name], slot)) }
        end

        def verdict(before, slot)
          return [:failed, "wal_status is #{LOST_WAL_STATUS}, the slot has to be recreated"] if lost?(slot)
          return [:failed, "still inactive after #{timeout_seconds}s, no producer connected"] unless slot['active']

          unless slot['wal_status'] == EXPECTED_WAL_STATUS
            return [:failed, "wal_status is #{slot['wal_status']}, expected #{EXPECTED_WAL_STATUS}"]
          end

          return [:ok, nil] if advanced?(before, slot)

          [:warned, "confirmed_flush_lsn did not advance in #{timeout_seconds}s, " \
            'either Siphon is stuck or the database is idle and producing no WAL']
        end

        def lost?(slot)
          slot['wal_status'] == LOST_WAL_STATUS
        end

        def advanced?(before, slot)
          return false if slot['lsn_bytes'].nil?

          before['lsn_bytes'].nil? || slot['lsn_bytes'] > before['lsn_bytes']
        end

        def print_slot(slot)
          puts "  #{slot['slot_name']}  active=#{slot['active']}  wal_status=#{slot['wal_status']}  " \
            "confirmed_flush_lsn=#{slot['lsn'] || 'none'}"
        end

        # Keyed per database, not per slot name: main, ci and sec are separate clusters and can
        # each hold a slot with the same name, so a healthy one must not hide a broken one.
        def record(name, database_name, status, reason = nil)
          @results << { name: name, database: database_name, status: status, reason: reason }
        end

        def fetch_slots(connection, names)
          filter = if names
                     "slot_name IN (#{names.map { |name| connection.quote(name) }.join(', ')})"
                   else
                     "slot_name LIKE #{connection.quote(DISCOVERY_PATTERN)}"
                   end

          sql = <<~SQL.squish
            SELECT slot_name, active, wal_status,
              confirmed_flush_lsn::text AS lsn,
              pg_catalog.pg_wal_lsn_diff(confirmed_flush_lsn, '0/0')::bigint AS lsn_bytes
            FROM pg_catalog.pg_replication_slots
            WHERE database = pg_catalog.current_database() AND #{filter}
          SQL

          # Slots only exist on the primary, and without a transaction the load balancer is free to
          # answer this from a replica, where it looks like a missing slot.
          connection.transaction { connection.select_all(sql).to_a }
        end

        def report
          unless discovery?
            missing = @slot_names - @results.pluck(:name)
            missing.each { |name| record(name, nil, :failed, 'not found in any database') }
          end

          abort "\nNo slot matching #{DISCOVERY_PATTERN} on any database. Is Siphon set up?" if @results.empty?

          puts
          puts 'Summary'

          sorted = @results.sort_by { |result| [result[:name], result[:database].to_s] }
          ok, warned, failed = sorted.group_by { |result| result[:status] }.values_at(:ok, :warned, :failed).map(&:to_a)

          ok.each { |result| puts "  OK       #{result[:name]} (#{result[:database]})" }
          warned.each { |result| warn "  WARNING  #{result[:name]} (#{result[:database]}): #{result[:reason]}" }
          failed.each { |result| warn "  FAILED   #{result[:name]}: #{result[:reason]}" }

          abort "\n#{failed.size} of #{@results.size} slots failed." if failed.any?

          puts
          puts summary_line(ok, warned)
        end

        def summary_line(ok, warned)
          return "All #{@results.size} slots are active and advancing." if warned.empty?

          "#{ok.size} of #{@results.size} slots advanced, #{warned.size} did not move during the check."
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class Capture < Base
        class << self
          def enabled?
            Gitlab::Runtime.application?
          end

          def analyze(parsed)
            return unless capturing?

            db_name = parsed.connection.pool.db_config.name.delete_suffix('_replica')
            capture_task = Gitlab::Database::Capture::Tasks[db_name]

            return unless capture_task

            # Stamped at query completion: replay derives start time as
            # timestamp - duration. Monotonic deltas are immune to clock
            # adjustments but only comparable within a single host.
            statement = {
              raw: parsed.raw,
              connection_id: connection_id(parsed.connection),
              timestamp: Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond),
              monotonic: Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond),
              duration: parsed.duration,
              binds: serializable_binds(parsed.type_casted_binds),
              returned_values: parsed.returned_values
            }.compact

            capture_task.push(statement.as_json)
          end

          private

          # The Postgres backend PID serving this connection: unique per
          # connection across client processes, and read from the local libpq
          # struct so it does not cost a server round trip per query.
          #
          # Read via the ivar, not #raw_connection: the public accessor has
          # two side effects, each lasting the rest of the connection's
          # checkout. It sets @raw_connection_dirty, which suppresses Rails'
          # transparent reconnect/retry, and it disables lazy transactions,
          # which makes later transaction blocks BEGIN eagerly even when they
          # issue no queries.
          def connection_id(connection)
            connection.instance_variable_get(:@raw_connection)&.backend_pid
          end

          def capturing?
            Gitlab::Database::Capture.enabled?
          end

          def serializable_binds(binds)
            binds.presence&.map { |bind| serializable_bind(bind) }
          end

          # Binary binds do not survive JSON: the adapter type-casts bytea to
          # { value: <raw bytes>, format: 1 } (a binary-format wire param) and
          # JSON requires valid UTF-8, so dumping raw bytes raises and would
          # cost us the statement. Re-encode binary values in the hex form the
          # text protocol uses (\x...), which the replayer can pass straight
          # through as a text-format param.
          def serializable_bind(bind)
            case bind
            when Hash
              binary_format?(bind) ? hex_encode(bind[:value].to_s) : bind
            when String
              utf8_safe?(bind) ? bind : hex_encode(bind)
            else
              bind
            end
          end

          def binary_format?(bind)
            bind[:format] == 1
          end

          def hex_encode(value)
            "\\x#{value.unpack1('H*')}"
          end

          def utf8_safe?(string)
            string.dup.force_encoding(Encoding::UTF_8).valid_encoding?
          end
        end
      end
    end
  end
end

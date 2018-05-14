module Gitlab
  module HealthChecks
    class FsShardsCheck
      extend BaseAbstractCheck
      RANDOM_STRING = SecureRandom.hex(1000).freeze
      COMMAND_TIMEOUT = '1'.freeze
      TIMEOUT_EXECUTABLE = 'timeout'.freeze

      class << self
        def readiness
          repository_storages.map do |storage_name|
            begin
              if !storage_circuitbreaker_test(storage_name)
                HealthChecks::Result.new(false, 'circuitbreaker tripped', shard: storage_name)
              elsif !storage_stat_test(storage_name)
                HealthChecks::Result.new(false, 'cannot stat storage', shard: storage_name)
              else
                with_temp_file(storage_name) do |tmp_file_path|
                  if !storage_write_test(tmp_file_path)
                    HealthChecks::Result.new(false, 'cannot write to storage', shard: storage_name)
                  elsif !storage_read_test(tmp_file_path)
                    HealthChecks::Result.new(false, 'cannot read from storage', shard: storage_name)
                  else
                    HealthChecks::Result.new(true, nil, shard: storage_name)
                  end
                end
              end
            rescue RuntimeError => ex
              message = "unexpected error #{ex} when checking storage #{storage_name}"
              Rails.logger.error(message)
              HealthChecks::Result.new(false, message, shard: storage_name)
            end
          end
        end

        def metrics
          repository_storages.flat_map do |storage_name|
            [
              storage_stat_metrics(storage_name),
              storage_write_metrics(storage_name),
              storage_read_metrics(storage_name),
              storage_circuitbreaker_metrics(storage_name)
            ].flatten
          end
        end

        private

        def operation_metrics(ok_metric, latency_metric, **labels)
          result, elapsed = yield
          [
            metric(latency_metric, elapsed, **labels),
            metric(ok_metric, result ? 1 : 0, **labels)
          ]
        rescue RuntimeError => ex
          Rails.logger.error("unexpected error #{ex} when checking #{ok_metric}")
          [metric(ok_metric, 0, **labels)]
        end

        def repository_storages
          storages_paths.keys
        end

        def storages_paths
          Gitlab.config.repositories.storages
        end

        def exec_with_timeout(cmd_args, *args, &block)
          Gitlab::Popen.popen([TIMEOUT_EXECUTABLE, COMMAND_TIMEOUT].concat(cmd_args), *args, &block)
        end

        def with_temp_file(storage_name)
          temp_file_path = Dir::Tmpname.create(%w(fs_shards_check +deleted), storage_path(storage_name)) { |path| path }
          yield temp_file_path
        ensure
          delete_test_file(temp_file_path)
        end

        def storage_path(storage_name)
          storages_paths[storage_name]&.legacy_disk_path
        end

        # All below test methods use shell commands to perform actions on storage volumes.
        # In case a storage volume have connectivity problems causing pure Ruby IO operation to wait indefinitely,
        # we can rely on shell commands to be terminated once `timeout` kills them.
        #
        # However we also fallback to pure Ruby file operations in case a specific shell command is missing
        # so we are still able to perform healthchecks and gather metrics from such system.

        def delete_test_file(tmp_path)
          _, status = exec_with_timeout(%W{ rm -f #{tmp_path} })
          status.zero?
        rescue Errno::ENOENT
          File.delete(tmp_path) rescue Errno::ENOENT
        end

        def storage_stat_test(storage_name)
          stat_path = File.join(storage_path(storage_name), '.')
          begin
            _, status = exec_with_timeout(%W{ stat #{stat_path} })
            status.zero?
          rescue Errno::ENOENT
            File.exist?(stat_path) && File::Stat.new(stat_path).readable?
          end
        end

        def storage_write_test(tmp_path)
          _, status = exec_with_timeout(%W{ tee #{tmp_path} }) do |stdin|
            stdin.write(RANDOM_STRING)
          end
          status.zero?
        rescue Errno::ENOENT
          written_bytes = File.write(tmp_path, RANDOM_STRING) rescue Errno::ENOENT
          written_bytes == RANDOM_STRING.length
        end

        def storage_read_test(tmp_path)
          _, status = exec_with_timeout(%W{ diff #{tmp_path} - }) do |stdin|
            stdin.write(RANDOM_STRING)
          end
          status.zero?
        rescue Errno::ENOENT
          file_contents = File.read(tmp_path) rescue Errno::ENOENT
          file_contents == RANDOM_STRING
        end

        def storage_circuitbreaker_test(storage_name)
          Gitlab::Git::Storage::CircuitBreaker.build(storage_name).perform { "OK" }
        rescue Gitlab::Git::Storage::Inaccessible
          nil
        end

        def storage_stat_metrics(storage_name)
          operation_metrics(:filesystem_accessible, :filesystem_access_latency_seconds, shard: storage_name) do
            with_timing { storage_stat_test(storage_name) }
          end
        end

        def storage_write_metrics(storage_name)
          operation_metrics(:filesystem_writable, :filesystem_write_latency_seconds, shard: storage_name) do
            with_temp_file(storage_name) do |tmp_file_path|
              with_timing { storage_write_test(tmp_file_path) }
            end
          end
        end

        def storage_read_metrics(storage_name)
          operation_metrics(:filesystem_readable, :filesystem_read_latency_seconds, shard: storage_name) do
            with_temp_file(storage_name) do |tmp_file_path|
              storage_write_test(tmp_file_path) # writes data used by read test
              with_timing { storage_read_test(tmp_file_path) }
            end
          end
        end

        def storage_circuitbreaker_metrics(storage_name)
          operation_metrics(:filesystem_circuitbreaker,
                            :filesystem_circuitbreaker_latency_seconds,
                            shard: storage_name) do
            with_timing { storage_circuitbreaker_test(storage_name) }
          end
        end
      end
    end
  end
end

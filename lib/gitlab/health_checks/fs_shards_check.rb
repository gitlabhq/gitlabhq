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
              if !storage_stat_test(storage_name)
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
          res = []
          repository_storages.each do |storage_name|
            res << operation_metrics(:filesystem_accessible, :filesystem_access_latency_seconds, shard: storage_name) do
              with_timing { storage_stat_test(storage_name) }
            end

            res << operation_metrics(:filesystem_writable, :filesystem_write_latency_seconds, shard: storage_name) do
              with_temp_file(storage_name) do |tmp_file_path|
                with_timing { storage_write_test(tmp_file_path) }
              end
            end

            res << operation_metrics(:filesystem_readable, :filesystem_read_latency_seconds, shard: storage_name) do
              with_temp_file(storage_name) do |tmp_file_path|
                storage_write_test(tmp_file_path) # writes data used by read test
                with_timing { storage_read_test(tmp_file_path) }
              end
            end
          end
          res.flatten
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
          @repository_storage ||= Gitlab::CurrentSettings.current_application_settings.repository_storages
        end

        def storages_paths
          @storage_paths ||= Gitlab.config.repositories.storages
        end

        def exec_with_timeout(cmd_args, *args, &block)
          Gitlab::Popen.popen([TIMEOUT_EXECUTABLE, COMMAND_TIMEOUT].concat(cmd_args), *args, &block)
        end

        def with_temp_file(storage_name)
          begin
            temp_file_path = Dir::Tmpname.create(%w(fs_shards_check +deleted), path(storage_name)) { |path| path }
            yield temp_file_path
          ensure
            delete_test_file(temp_file_path)
          end
        end

        def path(storage_name)
          storages_paths&.dig(storage_name, 'path')
        end

        def storage_stat_test(storage_name)
          stat_path = File.join(path(storage_name), '.')
          begin
            _, status = exec_with_timeout(%W{ stat #{stat_path} })
            status == 0
          rescue Errno::ENOENT
            File.exist?(stat_path) && File::Stat.new(stat_path).readable?
          end
        end

        def storage_write_test(tmp_path)
          _, status = exec_with_timeout(%W{ tee #{tmp_path} }) do |stdin|
            stdin.write(RANDOM_STRING)
          end
          status == 0
        rescue Errno::ENOENT
          written_bytes = File.write(tmp_path, RANDOM_STRING) rescue Errno::ENOENT
          written_bytes == RANDOM_STRING.length
        end

        def storage_read_test(tmp_path)
          _, status = exec_with_timeout(%W{ diff #{tmp_path} - }) do |stdin|
            stdin.write(RANDOM_STRING)
          end
          status == 0
        rescue Errno::ENOENT
          file_contents = File.read(tmp_path) rescue Errno::ENOENT
          file_contents == RANDOM_STRING
        end

        def delete_test_file(tmp_path)
          _, status = exec_with_timeout(%W{ rm -f #{tmp_path} })
          status == 0
        rescue Errno::ENOENT
          File.delete(tmp_path) rescue Errno::ENOENT
        end
      end
    end
  end
end

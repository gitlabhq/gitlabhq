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
              tmp_file_path = tmp_file_path(storage_name)

              if !storage_stat_test(storage_name)
                HealthChecks::Result.new(false, 'cannot stat storage', shard: storage_name)
              elsif !storage_write_test(tmp_file_path)
                HealthChecks::Result.new(false, 'cannot write to storage', shard: storage_name)
              elsif !storage_read_test(tmp_file_path)
                HealthChecks::Result.new(false, 'cannot read from storage', shard: storage_name)
              else
                HealthChecks::Result.new(true, nil, shard: storage_name)
              end
            rescue RuntimeError => ex
              message = "unexpected error #{ex} when checking storage #{storage_name}"
              Rails.logger.error(message)
              HealthChecks::Result.new(false, message, shard: storage_name)
            ensure
              delete_test_file(tmp_file_path)
            end
          end
        end

        def metrics
          repository_storages.flat_map do |storage_name|
            tmp_file_path = tmp_file_path(storage_name)
            [
              operation_metrics(:filesystem_accessible, :filesystem_access_latency_seconds, -> { storage_stat_test(storage_name) }, shard: storage_name),
              operation_metrics(:filesystem_writable, :filesystem_write_latency_seconds, -> { storage_write_test(tmp_file_path) }, shard: storage_name),
              operation_metrics(:filesystem_readable, :filesystem_read_latency_seconds, -> { storage_read_test(tmp_file_path) }, shard: storage_name)
            ].flatten
          end
        end

        private

        def operation_metrics(ok_metric, latency_metric, operation, **labels)
          with_timing operation do |result, elapsed|
            [
              metric(latency_metric, elapsed, **labels),
              metric(ok_metric, result ? 1 : 0, **labels)
            ]
          end
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

        def tmp_file_path(storage_name)
          Dir::Tmpname.create(%w(fs_shards_check +deleted), path(storage_name)) { |path| path }
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

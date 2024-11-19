# frozen_string_literal: true

require "google/cloud/storage_transfer"

module Gitlab
  module Backup
    module Cli
      module Targets
        class ObjectStorage
          class Google < Target
            OperationNotFoundError = Class.new(StandardError)

            attr_accessor :object_type, :backup_bucket, :client, :config, :results

            def initialize(object_type, remote_directory, config)
              @object_type = object_type
              @backup_bucket = remote_directory
              @config = config
              @client = ::Google::Cloud::StorageTransfer.storage_transfer_service
            end

            # @param [String] backup_id unique identifier for the backup
            def dump(backup_id)
              response = find_or_create_job(backup_id, "backup")
              run_request = {
                project_id: backup_job_spec(backup_id)[:project_id],
                job_name: response.name
              }
              @results = client.run_transfer_job run_request
            end

            # @param [String] backup_id unique identifier for the backup
            def restore(backup_id)
              response = find_or_create_job(backup_id, "restore")
              run_request = {
                project_id: restore_job_spec(backup_id)[:project_id],
                job_name: response.name
              }
              @results = client.run_transfer_job run_request
            end

            def job_name(operation)
              "transferJobs/#{object_type}-#{operation}"
            end

            def backup_job_spec(backup_id)
              job_spec(
                config.object_store.remote_directory,
                backup_bucket,
                operation: "backup",
                destination_path: backup_path(backup_id)
              )
            end

            def restore_job_spec(backup_id)
              job_spec(
                backup_bucket,
                config.object_store.remote_directory,
                operation: "restore",
                source_path: backup_path(backup_id)
              )
            end

            def backup_path(backup_id)
              "backups/#{backup_id}/#{object_type}/"
            end

            def find_job_spec(backup_id, operation)
              case operation
              when "backup"
                backup_job_spec(backup_id)
              when "restore"
                restore_job_spec(backup_id)
              else
                raise StandardError "Operation #{operation} not found"
              end
            end

            def job_spec(source, destination, operation:, source_path: nil, destination_path: nil)
              {
                project_id: config.object_store.connection.google_project,
                name: job_name(operation),
                transfer_spec: {
                  gcs_data_source: {
                    bucket_name: source,
                    path: source_path
                  },
                  gcs_data_sink: {
                    bucket_name: destination,
                    # NOTE: The trailing '/' is required
                    path: destination_path
                  }
                },
                status: :ENABLED
              }
            end

            def asynchronous?
              true
            end

            def wait_until_done!
              @results.wait_until_done!
            end

            private

            def find_or_create_job(backup_id, operation)
              begin
                name = job_name(operation)
                response = client.get_transfer_job(
                  job_name: name, project_id: config.object_store.connection.google_project
                )
                log.info("Existing job for #{object_type} found, using")
                job_update = find_job_spec(backup_id, operation)
                job_update.delete(:project_id)

                client.update_transfer_job(
                  job_name: name,
                  project_id: config.object_store.connection.google_project,
                  transfer_job: job_update
                )
              rescue ::Google::Cloud::NotFoundError
                log.info("Existing job for #{object_type} not found, creating one")
                response = client.create_transfer_job transfer_job: find_job_spec(backup_id, operation)
              end
              response
            end

            def log
              Gitlab::Backup::Cli::Output
            end
          end
        end
      end
    end
  end
end

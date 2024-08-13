# frozen_string_literal: true

require "google/cloud/storage_transfer"

module Gitlab
  module Backup
    module Cli
      module Targets
        class ObjectStorage
          class Google < Target
            attr_accessor :object_type, :backup_bucket, :client, :config

            def initialize(object_type, options, config)
              check_env
              @object_type = object_type
              @backup_bucket = options.remote_directory
              @config = config
              @client = ::Google::Cloud::StorageTransfer.storage_transfer_service
            end

            def dump(_, backup_id)
              response = find_or_create_job(backup_id)
              run_request = {
                project_id: job_spec(backup_id)[:project_id],
                job_name: response.name
              }
              client.run_transfer_job run_request
            end

            def job_name
              "transferJobs/#{object_type}-backup"
            end

            def job_spec(backup_id)
              {
                project_id: config.object_store.connection.google_project,
                name: job_name,
                transfer_spec: {
                  gcs_data_source: {
                    bucket_name: config.object_store.remote_directory
                  },
                  gcs_data_sink: {
                    bucket_name: backup_bucket,
                    # NOTE: The trailing '/' is required
                    path: "backups/#{backup_id}/#{object_type}/"
                  }
                },
                status: :ENABLED
              }
            end

            private

            def check_env
              # We expect service account credentials to be passed via env variables. If they are not, attempt
              # to use the local service account credentials and warn.
              return unless ENV.key?("GOOGLE_CLOUD_CREDENTIALS") || ENV.key?("GOOGLE_APPLICATION_CREDENTIALS")

              log.warning("No credentials provided.")
              log.warning("If we're in GCP, we will attempt to use the machine service account.")
              log.warning("This is not recommended.")
            end

            def find_or_create_job(backup_id)
              begin
                response = client.get_transfer_job(
                  job_name: job_name, project_id: config.object_store.connection.google_project
                )
                log.info("Existing job for #{object_type} found, using")
                job_update = job_spec(backup_id)
                job_update.delete(:project_id)

                client.update_transfer_job(
                  job_name: job_name,
                  project_id: config.object_store.connection.google_project,
                  transfer_job: job_update
                )
              rescue ::Google::Cloud::NotFoundError
                log.info("Existing job for #{object_type} not found, creating one")
                response = client.create_transfer_job transfer_job: job_spec(backup_id)
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

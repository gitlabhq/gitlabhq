# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Local < Base
            extend ::Gitlab::Utils::Override
            include Gitlab::Utils::StrongMemoize
            include Gitlab::Loggable

            def initialize(params, context)
              # `Repository#blobs_at` does not support files with the `/` prefix.
              @location = Gitlab::Utils.remove_leading_slashes(params[:local])

              super
            end

            def content
              strong_memoize(:content) { fetch_local_content }
            end

            def include_type
              :local
            end

            def metadata
              super.merge(
                location: masked_location,
                blob: masked_blob,
                raw: masked_raw,
                extra: extra_params
              )
            end

            def validate_context!
              return if context.project&.repository

              errors.push("Local file `#{masked_location}` does not have project!")
            end

            def validate_content_presence!
              if content.nil?
                log_missing_local_file if verbose_logging_enabled?(context.project)
                errors.push("Local file `#{masked_location}` does not exist!")
              elsif content.blank?
                errors.push("Local file `#{masked_location}` is empty!")
              end
            end

            private

            def extra_params
              params.except(:local)
            end

            def fetch_local_content
              BatchLoader.for([context.sha, location])
                         .batch(key: context.project) do |locations, loader, args|
                context.logger.instrument(:config_file_fetch_local_content) do
                  project = args[:key]
                  requested_paths = locations.map(&:second)

                  log_ci_config_blob_request(project, requested_paths)

                  blobs = project.repository.blobs_at(locations)
                  returned_paths = blobs.map(&:path)
                  missing_paths = requested_paths - returned_paths

                  log_ci_config_blob_response(project, returned_paths, missing_paths)

                  blobs.each do |blob|
                    loader.call([blob.commit_id, blob.path], blob.data)
                  end
                end
              rescue GRPC::InvalidArgument => e
                log_grpc_error(e)
              rescue GRPC::DeadlineExceeded
                log_and_raise_timeout_error
              end
            end

            override :expand_context_attrs
            def expand_context_attrs
              super.merge(
                project: context.project,
                sha: context.sha,
                user: context.user,
                parent_pipeline: context.parent_pipeline,
                variables: context.variables,
                component_data: context.component_data
              )
            end

            def masked_blob
              return unless valid?

              strong_memoize(:masked_blob) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_blob_url(context.project, ::File.join(context.sha, location))
                )
              end
            end

            def masked_raw
              return unless valid?

              strong_memoize(:masked_raw) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_raw_url(context.project, ::File.join(context.sha, location))
                )
              end
            end

            def log_ci_config_blob_request(project, requested_paths)
              return unless verbose_logging_enabled?(project)

              Gitlab::AppLogger.info(build_structured_payload(
                message: "CI config: Fetching blobs from Gitaly",
                project_id: project.id,
                sha: context.sha,
                extra: {
                  requested_paths: requested_paths,
                  requested_count: requested_paths.size,
                  repository_storage: project.repository_storage,
                  gitaly_storage_name: project.repository.gitaly_repository.storage_name
                }
              ))
            end

            def log_ci_config_blob_response(project, returned_paths, missing_paths)
              extra = {
                returned_paths: returned_paths,
                returned_count: returned_paths.size,
                repository_storage: project.repository_storage,
                gitaly_storage_name: project.repository.gitaly_repository.storage_name
              }

              if missing_paths.any?
                Gitlab::AppLogger.warn(build_structured_payload(
                  message: "CI config: Blobs fetched from Gitaly - missing paths detected",
                  project_id: project.id,
                  sha: context.sha,
                  extra: extra.merge(
                    missing_paths: missing_paths,
                    missing_count: missing_paths.size
                  )
                ))
              elsif verbose_logging_enabled?(project)
                Gitlab::AppLogger.info(build_structured_payload(
                  message: "CI config: Blobs fetched from Gitaly",
                  project_id: project.id,
                  sha: context.sha,
                  extra: extra
                ))
              end
            end

            def log_grpc_error(error)
              Gitlab::AppLogger.warn(build_structured_payload(
                message: "CI config: GRPC error fetching blobs",
                project_id: context.project.id,
                sha: context.sha,
                extra: {
                  location: location,
                  error_class: error.class.name,
                  error_message: error.message
                }
              ))
            end

            def log_missing_local_file
              Gitlab::AppLogger.warn(build_structured_payload(
                message: "CI config: Local file content is nil",
                project_id: context.project.id,
                sha: context.sha,
                extra: { location: location }
              ))
            end

            def verbose_logging_enabled?(project)
              Feature.enabled?(:ci_config_local_file_verbose_logging, project, type: :ops)
            end
          end
        end
      end
    end
  end
end

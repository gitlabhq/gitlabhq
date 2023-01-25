# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Local < Base
            extend ::Gitlab::Utils::Override
            include Gitlab::Utils::StrongMemoize

            def initialize(params, context)
              @location = if ::Feature.enabled?(:ci_batch_request_for_local_and_project_includes, context.project)
                            # `Repository#blobs_at` does not support files with the `/` prefix.
                            Gitlab::Utils.remove_leading_slashes(params[:local])
                          else
                            params[:local]
                          end

              super
            end

            def content
              strong_memoize(:content) { fetch_local_content }
            end

            def metadata
              super.merge(
                type: :local,
                location: masked_location,
                blob: masked_blob,
                raw: masked_raw,
                extra: {}
              )
            end

            def validate_context!
              return if context.project&.repository

              errors.push("Local file `#{masked_location}` does not have project!")
            end

            def validate_content!
              if content.nil?
                errors.push("Local file `#{masked_location}` does not exist!")
              elsif content.blank?
                errors.push("Local file `#{masked_location}` is empty!")
              end
            end

            private

            def fetch_local_content
              if ::Feature.disabled?(:ci_batch_request_for_local_and_project_includes, context.project)
                return legacy_fetch_local_content
              end

              BatchLoader.for([context.sha, location])
                         .batch(key: context.project) do |locations, loader, args|
                context.logger.instrument(:config_file_fetch_local_content) do
                  args[:key].repository.blobs_at(locations).each do |blob|
                    loader.call([blob.commit_id, blob.path], blob.data)
                  end
                end
              rescue GRPC::InvalidArgument
                # no-op
              end
            end

            # Will be removed with the FF ci_batch_request_for_local_and_project_includes
            def legacy_fetch_local_content
              context.logger.instrument(:config_file_fetch_local_content) do
                context.project.repository.blob_data_at(context.sha, location)
              end
            rescue GRPC::InvalidArgument
              errors.push("Sha #{context.sha} is not valid!")

              nil
            end

            override :expand_context_attrs
            def expand_context_attrs
              {
                project: context.project,
                sha: context.sha,
                user: context.user,
                parent_pipeline: context.parent_pipeline,
                variables: context.variables
              }
            end

            def masked_blob
              strong_memoize(:masked_blob) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_blob_url(context.project, ::File.join(context.sha, location))
                )
              end
            end

            def masked_raw
              return unless context.project

              strong_memoize(:masked_raw) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_raw_url(context.project, ::File.join(context.sha, location))
                )
              end
            end
          end
        end
      end
    end
  end
end

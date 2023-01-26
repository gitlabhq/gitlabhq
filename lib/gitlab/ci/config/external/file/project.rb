# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Project < Base
            extend ::Gitlab::Utils::Override
            include Gitlab::Utils::StrongMemoize

            attr_reader :project_name, :ref_name

            def initialize(params, context)
              @location = if ::Feature.enabled?(:ci_batch_request_for_local_and_project_includes, context.project)
                            # `Repository#blobs_at` does not support files with the `/` prefix.
                            Gitlab::Utils.remove_leading_slashes(params[:file])
                          else
                            params[:file]
                          end

              @project_name = get_project_name(params[:project])
              @ref_name = params[:ref] || 'HEAD'

              super
            end

            def matching?
              super && project_name.present?
            end

            def content
              strong_memoize(:content) { fetch_local_content }
            end

            def metadata
              super.merge(
                type: :file,
                location: masked_location,
                blob: masked_blob,
                raw: masked_raw,
                extra: { project: masked_project_name, ref: masked_ref_name }
              )
            end

            def validate_context!
              if !can_access_local_content?
                errors.push("Project `#{masked_project_name}` not found or access denied! Make sure any includes in the pipeline configuration are correctly defined.")
              elsif sha.nil?
                errors.push("Project `#{masked_project_name}` reference `#{masked_ref_name}` does not exist!")
              end
            end

            def validate_content!
              if content.nil?
                errors.push("Project `#{masked_project_name}` file `#{masked_location}` does not exist!")
              elsif content.blank?
                errors.push("Project `#{masked_project_name}` file `#{masked_location}` is empty!")
              end
            end

            private

            def project
              strong_memoize(:project) do
                ::Project.find_by_full_path(project_name)
              end
            end

            def can_access_local_content?
              strong_memoize(:can_access_local_content) do
                context.logger.instrument(:config_file_project_validate_access) do
                  Ability.allowed?(context.user, :download_code, project)
                end
              end
            end

            def fetch_local_content
              if ::Feature.disabled?(:ci_batch_request_for_local_and_project_includes, context.project)
                return legacy_fetch_local_content
              end

              return unless can_access_local_content?
              return unless sha

              BatchLoader.for([sha, location])
                         .batch(key: project) do |locations, loader, args|
                context.logger.instrument(:config_file_fetch_project_content) do
                  args[:key].repository.blobs_at(locations).each do |blob|
                    loader.call([blob.commit_id, blob.path], blob.data)
                  end
                end
              rescue GRPC::NotFound, GRPC::Internal
                # no-op
              end
            end

            def legacy_fetch_local_content
              return unless can_access_local_content?
              return unless sha

              context.logger.instrument(:config_file_fetch_project_content) do
                project.repository.blob_data_at(sha, location)
              end
            rescue GRPC::NotFound, GRPC::Internal
              nil
            end

            def sha
              return unless project

              strong_memoize(:sha) do
                project.commit(ref_name).try(:sha)
              end
            end

            override :expand_context_attrs
            def expand_context_attrs
              {
                project: project,
                sha: sha,
                user: context.user,
                parent_pipeline: context.parent_pipeline,
                variables: context.variables
              }
            end

            def masked_project_name
              strong_memoize(:masked_project_name) do
                context.mask_variables_from(project_name)
              end
            end

            def masked_ref_name
              strong_memoize(:masked_ref_name) do
                context.mask_variables_from(ref_name)
              end
            end

            def masked_blob
              return unless project

              strong_memoize(:masked_blob) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_blob_url(project, ::File.join(sha, location))
                )
              end
            end

            def masked_raw
              return unless project

              strong_memoize(:masked_raw) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_raw_url(project, ::File.join(sha, location))
                )
              end
            end

            # TODO: To be removed after we deprecate usage of array in `project` keyword.
            # https://gitlab.com/gitlab-org/gitlab/-/issues/365975
            def get_project_name(project_name)
              if project_name.is_a?(Array)
                project_name.first
              else
                project_name
              end
            end
          end
        end
      end
    end
  end
end

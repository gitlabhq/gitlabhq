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
              # `Repository#blobs_at` does not support files with the `/` prefix.
              @location = Gitlab::Utils.remove_leading_slashes(params[:file])

              # We are using the same downcase in the `project` method.
              @project_name = get_project_name(params[:project]).to_s.downcase
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

            def preload_context
              #
              # calling these methods lazily loads them via BatchLoader
              #
              project
              can_access_local_content?
              sha
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
              # Although we use `where_full_path_in`, this BatchLoader does not reduce the number of queries to 1.
              # That's because we use it in the `can_access_local_content?` and `sha` BatchLoaders
              # as the `for` parameter. And this loads the project immediately.
              BatchLoader.for(project_name)
                         .batch do |project_names, loader|
                ::Project.where_full_path_in(project_names.uniq).each do |project|
                  # We are using the same downcase in the `initialize` method.
                  loader.call(project.full_path.downcase, project)
                end
              end
            end

            def can_access_local_content?
              return if project.nil?

              # We are force-loading the project with the `itself` method
              # because the `project` variable can be a `BatchLoader` object and we should not
              # pass a `BatchLoader` object in the `for` method to prevent unwanted behaviors.
              BatchLoader.for(project.itself)
                         .batch(key: context.user) do |projects, loader, args|
                projects.uniq.each do |project|
                  context.logger.instrument(:config_file_project_validate_access) do
                    loader.call(project, project_access_allowed?(args[:key], project))
                  end
                end
              end
            end

            def project_access_allowed?(user, project)
              Ability.allowed?(user, :download_code, project)
            end

            def sha
              return if project.nil?

              # with `itself`, we are force-loading the project
              BatchLoader.for([project.itself, ref_name])
                         .batch do |project_ref_pairs, loader|
                project_ref_pairs.uniq.each do |project, ref_name|
                  loader.call([project, ref_name], project.commit(ref_name).try(:sha))
                end
              end
            end

            def fetch_local_content
              BatchLoader.for([sha.to_s, location])
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

            override :expand_context_attrs
            def expand_context_attrs
              {
                project: project,
                sha: sha.to_s, # we need to use `.to_s` to load the value from the BatchLoader
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
              return unless valid?

              strong_memoize(:masked_blob) do
                context.mask_variables_from(
                  Gitlab::Routing.url_helpers.project_blob_url(project, ::File.join(sha, location))
                )
              end
            end

            def masked_raw
              return unless valid?

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

Gitlab::Ci::Config::External::File::Project.prepend_mod

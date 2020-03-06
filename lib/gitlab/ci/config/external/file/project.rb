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
              @location = params[:file]
              @project_name = params[:project]
              @ref_name = params[:ref] || 'HEAD'

              super
            end

            def matching?
              super && project_name.present?
            end

            def content
              strong_memoize(:content) { fetch_local_content }
            end

            private

            def validate_content!
              if !can_access_local_content?
                errors.push("Project `#{project_name}` not found or access denied!")
              elsif sha.nil?
                errors.push("Project `#{project_name}` reference `#{ref_name}` does not exist!")
              elsif content.nil?
                errors.push("Project `#{project_name}` file `#{location}` does not exist!")
              elsif content.blank?
                errors.push("Project `#{project_name}` file `#{location}` is empty!")
              end
            end

            def project
              strong_memoize(:project) do
                ::Project.find_by_full_path(project_name)
              end
            end

            def can_access_local_content?
              Ability.allowed?(context.user, :download_code, project)
            end

            def fetch_local_content
              return unless can_access_local_content?
              return unless sha

              project.repository.blob_data_at(sha, location)
            rescue GRPC::NotFound, GRPC::Internal
              nil
            end

            def sha
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
                parent_pipeline: context.parent_pipeline
              }
            end
          end
        end
      end
    end
  end
end

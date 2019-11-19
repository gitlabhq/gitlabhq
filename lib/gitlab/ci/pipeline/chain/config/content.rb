# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content < Chain::Base
            include Chain::Helpers

            def perform!
              return if @command.config_content

              if content = content_from_repo
                @command.config_content = content
                @pipeline.config_source = :repository_source
                # TODO: we should persist ci_config_path
                # @pipeline.config_path = ci_config_path
              elsif content = content_from_auto_devops
                @command.config_content = content
                @pipeline.config_source = :auto_devops_source
              end

              unless @command.config_content
                return error("Missing #{ci_config_path} file")
              end
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end

            private

            def content_from_repo
              return unless project
              return unless @pipeline.sha
              return unless ci_config_path

              project.repository.gitlab_ci_yml_for(@pipeline.sha, ci_config_path)
            rescue GRPC::NotFound, GRPC::Internal
              nil
            end

            def content_from_auto_devops
              return unless project&.auto_devops_enabled?

              Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content
            end

            def ci_config_path
              project.ci_config_path.presence || '.gitlab-ci.yml'
            end
          end
        end
      end
    end
  end
end

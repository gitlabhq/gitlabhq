# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Repository < Source
        def content
          strong_memoize(:content) do
            next unless file_in_repository?

            YAML.dump('include' => [{ 'local' => ci_config_path }])
          end
        end

        def internal_include_prepended?
          true
        end

        def source
          :repository_source
        end

        private

        def file_in_repository?
          return unless project
          return unless sha

          project.repository.gitlab_ci_yml_for(sha, ci_config_path).present?
        rescue GRPC::NotFound, GRPC::Internal
          nil
        end
      end
    end
  end
end

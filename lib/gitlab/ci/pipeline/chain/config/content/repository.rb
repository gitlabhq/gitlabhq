# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class Repository < Source
              def content
                strong_memoize(:content) do
                  next unless file_in_repository?

                  YAML.dump('include' => [{ 'local' => ci_config_path }])
                end
              end

              def source
                :repository_source
              end

              private

              def file_in_repository?
                return unless project
                return unless @pipeline.sha

                project.repository.gitlab_ci_yml_for(@pipeline.sha, ci_config_path).present?
              rescue GRPC::NotFound, GRPC::Internal
                nil
              end
            end
          end
        end
      end
    end
  end
end

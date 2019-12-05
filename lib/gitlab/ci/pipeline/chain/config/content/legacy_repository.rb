# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class LegacyRepository < Source
              def content
                strong_memoize(:content) do
                  next unless project
                  next unless @pipeline.sha
                  next unless ci_config_path

                  project.repository.gitlab_ci_yml_for(@pipeline.sha, ci_config_path)
                rescue GRPC::NotFound, GRPC::Internal
                  nil
                end
              end

              def source
                :repository_source
              end
            end
          end
        end
      end
    end
  end
end

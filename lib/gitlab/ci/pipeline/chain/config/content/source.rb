# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class Source
              include Gitlab::Utils::StrongMemoize

              DEFAULT_YAML_FILE = '.gitlab-ci.yml'

              def initialize(pipeline, command)
                @pipeline = pipeline
                @command = command
              end

              def exists?
                strong_memoize(:exists) do
                  content.present?
                end
              end

              def content
                raise NotImplementedError
              end

              def source
                raise NotImplementedError
              end

              def project
                @project ||= @pipeline.project
              end

              def ci_config_path
                @ci_config_path ||= project.ci_config_path.presence || DEFAULT_YAML_FILE
              end
            end
          end
        end
      end
    end
  end
end

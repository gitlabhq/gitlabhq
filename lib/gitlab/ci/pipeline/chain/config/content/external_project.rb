# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content
            class ExternalProject < Source
              def content
                strong_memoize(:content) do
                  next unless external_project_path?

                  path_file, path_project = ci_config_path.split('@', 2)
                  YAML.dump('include' => [{ 'project' => path_project, 'file' => path_file }])
                end
              end

              def source
                :external_project_source
              end

              private

              # Example: path/to/.gitlab-ci.yml@another-group/another-project
              def external_project_path?
                ci_config_path =~ /\A.+(yml|yaml)@.+\z/
              end
            end
          end
        end
      end
    end
  end
end

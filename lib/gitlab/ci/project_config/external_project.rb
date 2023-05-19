# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class ExternalProject < Source
        def content
          strong_memoize(:content) do
            next unless external_project_path?

            path_file, path_project, ref = extract_location_tokens

            config_location = { 'project' => path_project, 'file' => path_file }
            config_location['ref'] = ref if ref.present?

            YAML.dump('include' => [config_location])
          end
        end

        def internal_include_prepended?
          true
        end

        def source
          :external_project_source
        end

        private

        # Example: path/to/.gitlab-ci.yml@another-group/another-project
        def external_project_path?
          ci_config_path =~ /\A.+(yml|yaml)@.+\z/
        end

        # Example: path/to/.gitlab-ci.yml@another-group/another-project:refname
        def extract_location_tokens
          path_file, path_project = ci_config_path.split('@', 2)

          if path_project.include? ":"
            project, ref = path_project.split(':', 2)
            [path_file, project, ref]
          else
            [path_file, path_project]
          end
        end
      end
    end
  end
end

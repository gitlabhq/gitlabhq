# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class ProjectSetting < Source
        extend ::Gitlab::Utils::Override

        def content
          case source
          when :repository_source
            ci_yaml_include({ 'local' => ci_config_path })
          when :external_project_source
            path_file, path_project, ref = extract_location_tokens

            config_location = { 'project' => path_project, 'file' => path_file }
            config_location['ref'] = ref if ref.present?

            ci_yaml_include(config_location)
          when :remote_source
            ci_yaml_include({ 'remote' => ci_config_path })
          end
        end
        strong_memoize_attr :content

        def internal_include_prepended?
          true
        end

        def source
          if remote_config_path?
            :remote_source
          elsif external_project_path?
            :external_project_source
          elsif file_in_repository?
            :repository_source
          end
        end
        strong_memoize_attr :source

        override :url
        def url
          return unless source == :repository_source

          File.join(Settings.build_ci_server_fqdn, project.full_path, '//', ci_config_path)
        end

        private

        def file_in_repository?
          return unless project
          return unless sha

          project.repository.blob_at(sha, ci_config_path).present?
        rescue GRPC::NotFound, GRPC::Internal
          nil
        end

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

        def remote_config_path?
          URI::DEFAULT_PARSER.make_regexp(%w[http https]).match?(ci_config_path)
        end

        def ci_yaml_include(config)
          YAML.dump('include' => [config])
        end
      end
    end
  end
end

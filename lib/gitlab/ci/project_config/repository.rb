# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Repository < Source
        extend ::Gitlab::Utils::Override

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

        override :url
        def url
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
      end
    end
  end
end

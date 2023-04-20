# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize

        LATEST_VERSION_KEYWORD = '~latest'

        def self.match?(address)
          address.include?('@') && address.start_with?(Settings.gitlab_ci['component_fqdn'])
        end

        attr_reader :host

        def initialize(address:, content_filename:)
          @full_path, @version = address.to_s.split('@', 2)
          @content_filename = content_filename
          @host = Settings.gitlab_ci['component_fqdn']
        end

        def fetch_content!(current_user:)
          return unless project
          return unless sha

          raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(current_user, :download_code, project)

          project.repository.blob_data_at(sha, project_file_path)
        end

        def project
          find_project_by_component_path(instance_path)
        end
        strong_memoize_attr :project

        def project_file_path
          return unless project

          component_dir = instance_path.delete_prefix(project.full_path)
          File.join(component_dir, @content_filename).delete_prefix('/')
        end

        def sha
          return unless project
          return latest_version_sha if version == LATEST_VERSION_KEYWORD

          project.commit(version)&.id
        end
        strong_memoize_attr :sha

        private

        attr_reader :version, :path

        def instance_path
          @full_path.delete_prefix(host)
        end

        # Given a path like "my-org/sub-group/the-project/path/to/component"
        # find the project "my-org/sub-group/the-project" by looking at all possible paths.
        def find_project_by_component_path(path)
          possible_paths = [path]

          while index = path.rindex('/') # find index of last `/` in a path
            possible_paths << (path = path[0..index - 1])
          end

          # remove shortest path as it is group
          possible_paths.pop

          ::Project.where_full_path_in(possible_paths).take # rubocop: disable CodeReuse/ActiveRecord
        end

        def latest_version_sha
          return unless catalog_resource = project&.catalog_resource

          catalog_resource.latest_version&.sha
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize
        include ::Gitlab::LoopHelpers

        LATEST_VERSION_KEYWORD = '~latest'

        def self.match?(address)
          address.include?('@') && address.start_with?(Settings.gitlab_ci['component_fqdn'])
        end

        attr_reader :host

        def initialize(address:)
          @full_path, @version = address.to_s.split('@', 2)
          @host = Settings.gitlab_ci['component_fqdn']
        end

        def fetch_content!(current_user:)
          return unless project
          return unless sha

          raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(current_user, :download_code, project)

          component_project = ::Ci::Catalog::ComponentsProject.new(project, sha)
          component_project.fetch_component(component_name)
        end

        def project
          find_project_by_component_path(instance_path)
        end
        strong_memoize_attr :project

        def sha
          return unless project
          return latest_version_sha if version == LATEST_VERSION_KEYWORD

          project.commit(version)&.id
        end
        strong_memoize_attr :sha

        private

        attr_reader :version, :component_name

        def find_project_by_component_path(path)
          if Feature.enabled?(:ci_redirect_component_project, Feature.current_request)
            project_full_path = extract_project_path(path)

            Project.find_by_full_path(project_full_path, follow_redirects: true).tap do |project|
              next unless project

              @component_name = extract_component_name(project_full_path)
            end
          else
            legacy_finder(path).tap do |project|
              next unless project

              @component_name = extract_component_name(project.full_path)
            end
          end
        end

        def legacy_finder(path)
          return if path.start_with?('/') # exit early if path starts with `/` or it will loop forever.

          possible_paths = [path]

          index = nil

          loop_until(limit: 20) do
            index = path.rindex('/') # find index of last `/` in a path
            break unless index

            possible_paths << (path = path[0..index - 1])
          end

          # remove shortest path as it is group
          possible_paths.pop

          ::Project.where_full_path_in(possible_paths).take # rubocop: disable CodeReuse/ActiveRecord
        end

        # Given a path like "my-org/sub-group/the-project/the-component"
        # we expect that the last `/` is the separator between the project full path and the
        # component name.
        def extract_project_path(path)
          return if path.start_with?('/') # invalid project full path.

          index = path.rindex('/') # find index of last `/` in the path
          return unless index

          path[0..index - 1]
        end

        def instance_path
          @full_path.delete_prefix(host)
        end

        def extract_component_name(project_path)
          instance_path.delete_prefix(project_path).delete_prefix('/')
        end

        def latest_version_sha
          if project.catalog_resource
            project.catalog_resource.versions.latest&.sha
          else
            project.releases.latest&.sha
          end
        end
      end
    end
  end
end

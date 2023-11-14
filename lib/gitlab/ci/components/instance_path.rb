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

        attr_reader :version

        # Given a path like "my-org/sub-group/the-project/path/to/component"
        # find the project "my-org/sub-group/the-project" by looking at all possible paths.
        def find_project_by_component_path(path)
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

        def instance_path
          @full_path.delete_prefix(host)
        end

        def component_name
          instance_path.delete_prefix(project.full_path).delete_prefix('/')
        end
        strong_memoize_attr :component_name

        def latest_version_sha
          project.releases.latest&.sha
        end
      end
    end
  end
end

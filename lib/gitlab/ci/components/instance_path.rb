# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize
        include ::Gitlab::LoopHelpers

        attr_reader :component_name

        LATEST_VERSION_KEYWORD = '~latest'

        def self.match?(address)
          address.include?('@') && address.start_with?(fqdn_prefix)
        end

        def self.fqdn_prefix
          "#{Gitlab.config.gitlab_ci.server_fqdn}/"
        end

        def initialize(address:)
          @full_path, @version = address.to_s.split('@', 2)
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

          release_with_tag = project.releases.find_by_tag(version)

          return release_with_tag.sha if release_with_tag.present?

          project.commit(version)&.id
        end
        strong_memoize_attr :sha

        private

        attr_reader :version

        def find_project_by_component_path(path)
          project_full_path = extract_project_path(path)

          Project.find_by_full_path(project_full_path, follow_redirects: true).tap do |project|
            next unless project

            @component_name = extract_component_name(project_full_path)
          end
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
          @full_path.delete_prefix(self.class.fqdn_prefix)
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

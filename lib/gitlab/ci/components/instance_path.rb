# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize
        include ::Gitlab::LoopHelpers

        attr_reader :component_name

        SHORTHAND_SEMVER_PATTERN = /^\d+(\.\d+)?$/
        LATEST = '~latest'

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

          find_version_sha(version)
        end
        strong_memoize_attr :sha

        def invalid_usage_for_latest?
          @version == LATEST && project && project.catalog_resource.nil?
        end

        private

        attr_reader :version

        def find_version_sha(version)
          return find_latest_sha if version == LATEST

          sha_by_shorthand_semver(version) || sha_by_released_tag(version) || sha_by_ref(version)
        end

        def find_latest_sha
          return unless project.catalog_resource

          project.catalog_resource.versions.latest&.sha
        end

        def sha_by_shorthand_semver(version)
          return unless version.match?(SHORTHAND_SEMVER_PATTERN)
          return unless project.catalog_resource

          major, minor = version.split(".")
          project.catalog_resource.versions.latest(major, minor)&.sha
        end

        def sha_by_released_tag(version)
          project.releases.find_by_tag(version)&.sha
        end

        def sha_by_ref(version)
          project.commit(version)&.id
        end

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
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize
        include ::Gitlab::LoopHelpers

        attr_reader :reference

        SHORTHAND_SEMVER_PATTERN = /^\d+(\.\d+)?$/
        LATEST = '~latest'

        def self.match?(address)
          address.include?('@') && address.start_with?(fqdn_prefix)
        end

        def self.fqdn_prefix
          "#{Gitlab.config.gitlab.server_fqdn}/"
        end

        def initialize(address:)
          @full_path, @reference = address.to_s.split('@', 2)
        end

        def fetch_content!(current_user:)
          return unless project
          return unless sha

          raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(current_user, :download_code, project)

          return fetch_component_content if ::Feature.disabled?(:ci_optimize_component_fetching, project)

          Rails.cache.fetch("ci_component_content:#{project_full_path}:#{sha}:#{component_name}", expires_in: 1.day) do
            fetch_component_content
          end
        end

        def project
          Project.find_by_full_path(project_full_path, follow_redirects: true)
        end
        strong_memoize_attr :project

        def sha
          return unless project

          if ::Feature.enabled?(:ci_optimize_component_fetching, project)
            # First, we try finding the sha from the catalog.
            # Otherwise, from the repository.
            find_catalog_version&.sha || sha_by_released_tag || sha_by_ref
          else
            legacy_find_version_sha
          end
        end
        strong_memoize_attr :sha

        def matched_version
          find_catalog_version&.semver&.to_s
        end
        strong_memoize_attr :matched_version

        def component_name
          instance_path.delete_prefix(project_full_path).delete_prefix('/')
        end
        strong_memoize_attr :component_name

        def invalid_usage_for_latest?
          reference == LATEST && project && project.catalog_resource.nil?
        end

        def invalid_usage_for_partial_semver?
          reference.match?(SHORTHAND_SEMVER_PATTERN) && project && project.catalog_resource.nil?
        end

        private

        def fetch_component_content
          component_project = ::Ci::Catalog::ComponentsProject.new(project, sha)
          component_project.fetch_component(component_name)
        end

        def legacy_find_version_sha
          return legacy_find_latest_sha if reference == LATEST

          legacy_sha_by_shorthand_semver || sha_by_released_tag || sha_by_ref
        end

        def find_catalog_version
          return unless project.catalog_resource

          if reference == LATEST
            catalog_resource_version_latest
          elsif reference.match?(SHORTHAND_SEMVER_PATTERN)
            catalog_resource_version_by_short_semver
          else
            project.catalog_resource.versions.by_name(reference).first
          end
        end
        strong_memoize_attr :find_catalog_version

        def legacy_find_latest_sha
          return unless project.catalog_resource

          catalog_resource_version_latest&.sha
        end

        def legacy_sha_by_shorthand_semver
          return unless reference.match?(SHORTHAND_SEMVER_PATTERN)
          return unless project.catalog_resource

          catalog_resource_version_by_short_semver&.sha
        end

        def catalog_resource_version_latest
          project.catalog_resource.versions.latest
        end
        strong_memoize_attr :catalog_resource_version_latest

        def catalog_resource_version_by_short_semver
          major, minor = reference.split(".")
          project.catalog_resource.versions.latest(major, minor)
        end
        strong_memoize_attr :catalog_resource_version_by_short_semver

        def sha_by_released_tag
          project.releases.find_by_tag(reference)&.sha
        end

        def sha_by_ref
          project.commit(reference)&.id
        end

        def instance_path
          @full_path.delete_prefix(self.class.fqdn_prefix)
        end
        strong_memoize_attr :instance_path

        def project_full_path
          extract_project_path(instance_path)
        end
        strong_memoize_attr :project_full_path

        # Given a path like "my-org/sub-group/the-project/the-component"
        # we expect that the last `/` is the separator between the project full path and the
        # component name.
        def extract_project_path(path)
          return if path.start_with?('/') # invalid project full path.

          index = path.rindex('/') # find index of last `/` in the path
          return unless index

          path[0..index - 1]
        end
      end
    end
  end
end

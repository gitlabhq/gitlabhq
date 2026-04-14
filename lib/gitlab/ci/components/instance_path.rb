# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize
        include ::Gitlab::LoopHelpers

        attr_reader :reference, :logger

        SHORTHAND_SEMVER_PATTERN = /^\d+(\.\d+)?$/
        LATEST = '~latest'

        def self.match?(address)
          address.include?('@') && address.start_with?(fqdn_prefix)
        end

        def self.fqdn_prefix
          "#{Gitlab.config.gitlab.server_fqdn}/"
        end

        def initialize(address:, logger: nil)
          @full_path, @reference = address.to_s.split('@', 2)
          @logger = logger
        end

        def fetch_content!(current_user:)
          return unless project
          return unless sha

          raise Gitlab::Access::AccessDeniedError unless access_allowed?(current_user)

          instrument(:config_component_fetch_content) do
            fetch_component_content
          end
        end

        def project
          instrument(:config_component_find_project) do
            next unless project_full_path

            if ci_optimize_component_instance_path_enabled?
              Gitlab::SafeRequestStore.fetch(cache_key('project', project_full_path.downcase)) do
                Project.find_by_full_path(project_full_path, follow_redirects: true)
              end
            else
              Project.find_by_full_path(project_full_path, follow_redirects: true)
            end
          end
        end
        strong_memoize_attr :project

        def sha
          return unless project

          instrument(:config_component_find_sha) do
            if ci_optimize_component_instance_path_enabled?
              Gitlab::SafeRequestStore.fetch(cache_key('sha', project.id, reference)) do
                find_catalog_version&.sha || sha_by_released_tag || sha_by_ref
              end
            else
              legacy_find_version_sha
            end
          end
        end
        strong_memoize_attr :sha

        def matched_version
          instrument(:config_component_matched_version) do
            find_catalog_version&.semver&.to_s
          end
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
          return fetch_component_content_uncached if ::Feature.disabled?(:ci_optimize_component_fetching, project)

          Rails.cache.fetch("ci_component_content:#{project_full_path}:#{sha}:#{component_name}",
            expires_in: 1.day) do
            fetch_component_content_uncached
          end
        end

        def fetch_component_content_uncached
          component_project = ::Ci::Catalog::ComponentsProject.new(project, sha)
          component_project.fetch_component(component_name)
        end

        def access_allowed?(current_user)
          instrument(:config_component_check_access) do
            if ci_optimize_component_instance_path_enabled?
              Gitlab::SafeRequestStore.fetch(cache_key('access_allowed', project.id, current_user&.id)) do
                Ability.allowed?(current_user, :download_code, project)
              end
            else
              Ability.allowed?(current_user, :download_code, project)
            end
          end
        end

        def cache_key(*parts)
          [self.class.name, *parts]
        end

        def legacy_find_version_sha
          return legacy_find_latest_sha if reference == LATEST

          legacy_sha_by_shorthand_semver || sha_by_released_tag || sha_by_ref
        end

        def find_catalog_version
          instrument(:config_component_find_catalog_version) do
            next unless project&.catalog_resource

            if ci_optimize_component_instance_path_enabled?
              Gitlab::SafeRequestStore.fetch(cache_key('catalog_version', project.id, reference)) do
                fetch_catalog_version
              end
            else
              fetch_catalog_version
            end
          end
        end
        strong_memoize_attr :find_catalog_version

        def fetch_catalog_version
          if reference == LATEST
            catalog_resource_version_latest
          elsif reference.match?(SHORTHAND_SEMVER_PATTERN)
            catalog_resource_version_by_short_semver
          else
            project.catalog_resource.versions.by_name(reference).first
          end
        end

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

        def instrument(operation, &block)
          return yield unless logger

          logger.instrument(operation, &block)
        end

        def ci_optimize_component_instance_path_enabled?
          ::Feature.enabled?(:ci_optimize_component_instance_path, Feature.current_request)
        end
        strong_memoize_attr :ci_optimize_component_instance_path_enabled?
      end
    end
  end
end

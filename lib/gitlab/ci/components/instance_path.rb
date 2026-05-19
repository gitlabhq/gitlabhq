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

            Gitlab::SafeRequestStore.fetch(cache_key('project', project_full_path.downcase)) do
              Project.find_by_full_path(project_full_path, follow_redirects: true)
            end
          end
        end
        strong_memoize_attr :project

        def sha
          return unless project

          instrument(:config_component_find_sha) do
            Gitlab::SafeRequestStore.fetch(cache_key('sha', project.id, reference)) do
              find_catalog_version&.sha || sha_by_released_tag || sha_by_ref
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
          component_data = try_cached_template_path(simple_template_path)

          return component_data if component_data.present?

          component_data = try_cached_template_path(complex_template_path)

          return component_data if component_data.present?

          fetch_from_gitaly
        end

        def content_fetcher
          ::Gitlab::Ci::Config::External::CachedContentFetcher.new(
            project: project,
            cache_enabled: cache_enabled?
          )
        end
        strong_memoize_attr :content_fetcher

        def try_cached_template_path(template_path)
          cache_key = component_cache_key_for(sha, template_path)
          content = content_fetcher.read_cache(cache_key)
          return unless content

          ::Ci::Catalog::ComponentsProject::ComponentData.new(
            content: content,
            path: template_path
          )
        end

        def fetch_from_gitaly
          simple_sha_path = [sha, simple_template_path]
          complex_sha_path = [sha, complex_template_path]

          items = [
            [simple_sha_path, component_cache_key_for(sha, simple_template_path)],
            [complex_sha_path, component_cache_key_for(sha, complex_template_path)]
          ]

          content_by_sha_path = content_fetcher.fetch_batch(items)

          [simple_sha_path, complex_sha_path].each do |sha_path|
            content = content_by_sha_path[sha_path]

            if content.present?
              return ::Ci::Catalog::ComponentsProject::ComponentData.new(
                content: content,
                path: sha_path[1]
              )
            end
          end

          ::Ci::Catalog::ComponentsProject::ComponentData.new
        end

        def simple_template_path
          File.join('templates', "#{component_name}.yml")
        end

        def complex_template_path
          File.join('templates', component_name, 'template.yml')
        end

        def component_cache_key_for(sha, path)
          "ci_component_content:v1:#{project.id}:#{sha}:#{path}"
        end

        def cache_enabled?
          ::Feature.enabled?(:ci_cache_component_includes, project)
        end

        def access_allowed?(current_user)
          instrument(:config_component_check_access) do
            Gitlab::SafeRequestStore.fetch(cache_key('access_allowed', project.id, current_user&.id)) do
              Ability.allowed?(current_user, :download_code, project)
            end
          end
        end

        def cache_key(*parts)
          [self.class.name, *parts]
        end

        def find_catalog_version
          instrument(:config_component_find_catalog_version) do
            next unless project&.catalog_resource

            Gitlab::SafeRequestStore.fetch(cache_key('catalog_version', project.id, reference)) do
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
      end
    end
  end
end

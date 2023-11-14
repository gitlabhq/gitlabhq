# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job that:
    # * pickup container repositories with delete_scheduled status.
    # * check if there are tags linked to it.
    # * if there are tags, reset the status to nil.
    class ResetStatusOnContainerRepositories < BatchedMigrationJob
      DELETE_SCHEDULED_STATUS = 0
      DUMMY_TAGS = %w[tag].freeze
      MIGRATOR = 'ResetStatusOnContainerRepositories'

      scope_to ->(relation) { relation.where(status: DELETE_SCHEDULED_STATUS) }
      operation_name :reset_status_on_container_repositories
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          reset_status_if_tags(sub_batch)
        end
      end

      private

      def reset_status_if_tags(container_repositories)
        container_repositories_with_tags = container_repositories.select { |cr| cr.becomes(ContainerRepository).tags? } # rubocop:disable Cop/AvoidBecomes

        ContainerRepository.where(id: container_repositories_with_tags.map(&:id))
                           .update_all(status: nil)
      end

      # rubocop:disable Style/Documentation
      module Routable
        extend ActiveSupport::Concern

        included do
          has_one :route,
            as: :source,
            class_name: '::Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories::Route'
        end

        def full_path
          route&.path || build_full_path
        end

        def build_full_path
          if parent && path
            "#{parent.full_path}/#{path}"
          else
            path
          end
        end
      end

      class Route < ::ApplicationRecord
        self.table_name = 'routes'
      end

      class Namespace < ::ApplicationRecord
        include ::Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories::Routable
        include ::Namespaces::Traversal::Recursive
        include ::Namespaces::Traversal::Linear
        include ::Gitlab::Utils::StrongMemoize

        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled

        belongs_to :parent,
          class_name: '::Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories::Namespace'

        def self.polymorphic_name
          'Namespace'
        end
      end

      class Project < ::ApplicationRecord
        include ::Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories::Routable

        self.table_name = 'projects'

        belongs_to :namespace,
          class_name: '::Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories::Namespace'

        alias_method :parent, :namespace
        alias_attribute :parent_id, :namespace_id

        delegate :root_ancestor, to: :namespace, allow_nil: true
      end

      class ContainerRepository < ::ApplicationRecord
        self.table_name = 'container_repositories'

        belongs_to :project,
          class_name: '::Gitlab::BackgroundMigration::ResetStatusOnContainerRepositories::Project'

        def tags?
          result = ContainerRegistry.tags_for(path).any?
          ::Gitlab::BackgroundMigration::Logger.info(
            migrator: MIGRATOR,
            has_tags: result,
            container_repository_id: id,
            container_repository_path: path
          )
          result
        end

        def path
          @path ||= [project.full_path, name].select(&:present?).join('/').downcase
        end
      end

      class ContainerRegistry
        class << self
          def tags_for(path)
            response = ContainerRegistryClient.repository_tags(path, page_size: 1)
            return DUMMY_TAGS unless response

            response['tags'] || []
          rescue StandardError # rubocop:todo BackgroundMigration/AvoidSilentRescueExceptions -- https://gitlab.com/gitlab-org/gitlab/-/issues/431592
            DUMMY_TAGS
          end
        end
      end

      class ContainerRegistryClient
        def self.repository_tags(path, page_size:)
          registry_config = ::Gitlab.config.registry

          return { 'tags' => DUMMY_TAGS } unless registry_config.enabled && registry_config.api_url.present?

          pull_token = ::Auth::ContainerRegistryAuthenticationService.pull_access_token(path)
          client = ::ContainerRegistry::Client.new(registry_config.api_url, token: pull_token)
          client.repository_tags(path, page_size: page_size)
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end

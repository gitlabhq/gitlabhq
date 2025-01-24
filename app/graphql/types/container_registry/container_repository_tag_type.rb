# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryTagType < BaseObject
      graphql_name 'ContainerRepositoryTag'

      description 'A tag from a container repository'

      authorize :read_container_image

      expose_permissions Types::PermissionTypes::ContainerRepositoryTag

      field :created_at, Types::TimeType, null: true, description: 'Timestamp when the tag was created.'
      field :digest, GraphQL::Types::String, null: true, description: 'Digest of the tag.'
      field :location, GraphQL::Types::String, null: false, description: 'URL of the tag.'
      field :media_type, GraphQL::Types::String, null: true, description: 'Media type of the tag.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the tag.'
      field :path, GraphQL::Types::String, null: false, description: 'Path of the tag.'
      field :published_at, Types::TimeType, null: true, description: 'Timestamp when the tag was published.'
      field :referrers, [Types::ContainerRegistry::ContainerRepositoryReferrerType], null: true,
        description: 'Referrers for the tag.'
      field :revision, GraphQL::Types::String, null: true, description: 'Revision of the tag.'
      field :short_revision, GraphQL::Types::String, null: true, description: 'Short revision of the tag.'
      field :total_size, GraphQL::Types::BigInt, null: true, description: 'Size of the tag.'

      field :protection,
        Types::ContainerRegistry::Protection::AccessLevelType,
        null: true,
        experiment: { milestone: '17.9' },
        description: 'Minimum GitLab access level required to push and delete container image tags. ' \
          'If multiple protection rules match an image tag, the highest access levels are applied'

      def protection
        return unless Feature.enabled?(:container_registry_protected_tags, project)

        highest_matching_rule
      end

      private

      def project
        object.repository.project
      end

      def highest_matching_rule
        result = ::ContainerRegistry::Protection::TagRule.new

        project.container_registry_protection_tag_rules.each do |rule|
          next unless Gitlab::UntrustedRegexp.new(rule.tag_name_pattern).match?(object.name)

          set_max_access_level(result, rule)
        end

        result
      end

      def set_max_access_level(result, rule)
        %i[push delete].each do |action|
          attribute = :"minimum_access_level_for_#{action}"

          result[attribute] = [
            # minimum_access_level_for_push_before_type_cast will return the
            # enum's numeric value so we can correctly use .max on it.
            result.method(:"#{attribute}_before_type_cast").call.to_i,
            rule.method(:"#{attribute}_before_type_cast").call
          ].max
        end
      end
    end
  end
end

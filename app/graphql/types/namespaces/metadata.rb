# frozen_string_literal: true

module Types
  module Namespaces
    module Metadata
      include ::Types::BaseInterface
      include ::IssuablesHelper
      include ActionView::Helpers::NumberHelper

      graphql_name 'NamespaceMetadata'

      TYPE_MAPPINGS = {
        ::Group => ::Types::Namespaces::Metadata::GroupNamespaceMetadataType,
        ::Namespaces::ProjectNamespace => ::Types::Namespaces::Metadata::ProjectNamespaceMetadataType,
        ::Namespaces::UserNamespace => ::Types::Namespaces::Metadata::UserNamespaceMetadataType
      }.freeze

      field :time_tracking_limit_to_hours,
        GraphQL::Types::Boolean,
        null: true,
        resolver_method: :time_tracking_limit_to_hours?,
        description: 'Time tracking limit to hours setting.',
        experiment: { milestone: '18.6' }

      field :initial_sort,
        GraphQL::Types::String,
        null: true,
        description: 'User preference for initial sort order.',
        fallback_value: nil,
        experiment: { milestone: '18.6' }

      field :is_issue_repositioning_disabled,
        GraphQL::Types::Boolean,
        resolver_method: :issue_repositioning_disabled?,
        description: 'Whether issue repositioning is disabled for the namespace.',
        experiment: { milestone: '18.6' }

      field :show_new_work_item,
        GraphQL::Types::Boolean,
        resolver_method: :show_new_work_item?,
        description: 'Whether to show the new work item link.',
        experiment: { milestone: '18.6' }

      field :max_attachment_size,
        GraphQL::Types::String,
        null: true,
        description: 'Maximum allowed attachment size (humanized).',
        fallback_value: nil,
        experiment: { milestone: '18.6' }

      field :group_id,
        GraphQL::Types::String,
        null: true,
        description: 'ID of the group. Returns null for user namespaces.',
        fallback_value: nil,
        experiment: { milestone: '18.6' }

      def self.type_mappings
        TYPE_MAPPINGS
      end

      def self.resolve_type(object, _context)
        type_mappings[object.class] || raise("Unknown GraphQL type for namespace type #{object.class}")
      end

      orphan_types(*type_mappings.values)

      def time_tracking_limit_to_hours?
        Gitlab::CurrentSettings.time_tracking_limit_to_hours
      end

      def initial_sort
        current_user&.user_preference&.issues_sort
      end

      def max_attachment_size
        number_to_human_size(Gitlab::CurrentSettings.max_attachment_size.megabytes)
      end
    end
  end
end

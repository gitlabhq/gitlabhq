# frozen_string_literal: true

module Types
  module WorkItems
    class TypeType < BaseObject
      graphql_name 'WorkItemType'

      authorize :read_work_item_type

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      field :icon_name, GraphQL::Types::String,
        null: true,
        description: 'Icon name of the work item type.'
      field :id, ::Types::GlobalIDType[::WorkItems::Type],
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Global ID of the work item type.'
      field :name, GraphQL::Types::String,
        null: false,
        scopes: [:api, :read_api, :ai_workflows],
        description: 'Name of the work item type.'
      field :widget_definitions, [::Types::WorkItems::WidgetDefinitionInterface],
        null: true,
        description: 'Available widgets for the work item type.',
        method: :widgets,
        experiment: { milestone: '16.7' }

      field :supported_conversion_types, [::Types::WorkItems::TypeType],
        null: true,
        description: 'Supported conversion types for the work item type.',
        experiment: { milestone: '17.8' }

      field :unavailable_widgets_on_conversion, [::Types::WorkItems::WidgetDefinitionInterface],
        null: true,
        description: 'Widgets that will be lost when converting from source work item type to target work item type.' do
          argument :target, ::Types::GlobalIDType[::WorkItems::Type],
            required: true,
            description: 'Target work item type to convert to.'
        end

      field :supports_roadmap_view, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type supports roadmap view.',
        method: :supports_roadmap_view?,
        experiment: { milestone: '18.8' }

      field :use_issue_view, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type uses the issue view instead of work item view.',
        method: :use_legacy_view?,
        experiment: { milestone: '18.8' }

      field :can_promote_to_objective, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type can be promoted to an objective.',
        method: :can_promote_to_objective?,
        experiment: { milestone: '18.8' }

      field :show_project_selector, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type should show the project selector.',
        method: :show_project_selector?,
        experiment: { milestone: '18.8' }

      field :supports_move_action, GraphQL::Types::Boolean, # rubocop:disable GraphQL/ExtractType -- no need for extraction
        null: true,
        description: 'Indicates whether the work item type can be moved or not.',
        method: :supports_move_action?,
        experiment: { milestone: '18.8' }

      field :is_service_desk, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type is for service desk.',
        method: :service_desk?,
        experiment: { milestone: '18.8' }

      field :is_incident_management, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type is for incident management.',
        method: :incident_management?,
        experiment: { milestone: '18.8' }

      field :is_configurable, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type is configurable.',
        method: :configurable?,
        experiment: { milestone: '18.8' }

      field :can_user_create_items, GraphQL::Types::Boolean, # rubocop:disable GraphQL/ExtractType -- no need for extraction
        null: true,
        description: 'Indicates whether the work item type is creatable by the API.',
        method: :creatable?,
        experiment: { milestone: '18.8' }

      field :visible_in_settings, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type should be visible in the settings page.',
        method: :visible_in_settings?,
        experiment: { milestone: '18.8' }

      field :archived, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type is archived.',
        method: :archived?,
        experiment: { milestone: '18.8' }

      field :is_filterable, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type should be filterable.',
        method: :filterable?,
        experiment: { milestone: '18.8' }

      field :is_group_work_item_type, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates whether the work item type belongs only to a group.',
        method: :only_for_group?,
        experiment: { milestone: '18.8' }

      field :enabled, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates whether the work item type is enabled.',
        method: :enabled?,
        experiment: { milestone: '18.9' }

      def widgets
        object.widget_definitions(context[:resource_parent])
      end

      def widget_definitions
        object.widgets(context[:resource_parent])
      end

      def supported_conversion_types
        object.supported_conversion_types(context[:resource_parent], current_user)
      end

      def unavailable_widgets_on_conversion(target:)
        source_type = object
        target_type = GitlabSchema.find_by_gid(target).sync

        return [] unless source_type && target_type

        source_type.unavailable_widgets_on_conversion(target_type, context[:resource_parent])
      end
    end
  end
end

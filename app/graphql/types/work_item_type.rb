# frozen_string_literal: true

module Types
  class WorkItemType < BaseObject
    graphql_name 'WorkItem'

    include ::IssuablesHelper

    implements Types::TodoableInterface
    connection_type_class Types::CountableConnectionType

    authorize :read_work_item

    def self.authorization_scopes
      super + [:ai_workflows]
    end

    present_using WorkItemPresenter
    expose_permissions Types::PermissionTypes::WorkItem

    field :author, Types::UserType, null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'User that created the work item.',
      experiment: { milestone: '15.9' }
    field :closed_at, Types::TimeType, null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Timestamp of when the work item was closed.'
    field :confidential, GraphQL::Types::Boolean, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Indicates the work item is confidential.'
    field :created_at, Types::TimeType, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Timestamp of when the work item was created.'
    field :description, GraphQL::Types::String, null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Description of the work item.'
    field :id, Types::GlobalIDType[::WorkItem], null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Global ID of the work item.'
    field :iid, GraphQL::Types::String, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Internal ID of the work item.'
    field :imported, GraphQL::Types::Boolean, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      method: :imported?,
      description: 'Indicates whether the work item was imported.'
    field :lock_version,
      GraphQL::Types::Int,
      null: false,
      description: 'Lock version of the work item. Incremented each time the work item is updated.'
    field :namespace, Types::NamespaceType, null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Namespace the work item belongs to.',
      skip_type_authorization: [:read_namespace],
      experiment: { milestone: '15.10' }
    field :project, Types::ProjectType, null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Project the work item belongs to.',
      skip_type_authorization: [:read_project],
      experiment: { milestone: '15.3' }
    field :state, WorkItemStateEnum, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'State of the work item.'
    field :title, GraphQL::Types::String, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Title of the work item.'
    field :updated_at, Types::TimeType, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Timestamp of when the work item was last updated.'

    field :create_note_email, GraphQL::Types::String,
      null: true,
      description: 'User specific email address for the work item.'
    field :user_discussions_count, GraphQL::Types::Int, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Number of user discussions in the work item.',
      resolver: Resolvers::UserDiscussionsCountResolver

    field :reference, GraphQL::Types::String, null: false,
      description: 'Internal reference of the work item. Returned in shortened format by default.',
      method: :to_reference do
      argument :full, GraphQL::Types::Boolean, required: false, default_value: false,
        description: 'Boolean option specifying whether the reference should be returned in full.'
    end

    field :widgets,
      [Types::WorkItems::WidgetInterface],
      null: true,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Collection of widgets that belong to the work item.' do
      argument :except_types, [::Types::WorkItems::WidgetTypeEnum],
        required: false,
        default_value: nil,
        description: 'Except widgets of the given types.'
      argument :only_types, [::Types::WorkItems::WidgetTypeEnum],
        required: false,
        default_value: nil,
        description: 'Only widgets of the given types.'

      validates mutually_exclusive: %i[except_types only_types]
    end

    field :work_item_type, Types::WorkItems::TypeType, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Type assigned to the work item.'

    field :archived, GraphQL::Types::Boolean, null: false,
      scopes: [:api, :read_api, :ai_workflows],
      description: 'Whether the work item belongs to an archived project. Always false for group level work items.',
      experiment: { milestone: '16.5' }

    field :comment_templates_paths, [Types::WorkItems::CommentTemplatePathType], null: false,
      description: 'Paths of the comment templates.'
    field :duplicated_to_work_item_url, GraphQL::Types::String, null: true,
      description: 'URL of the work item that the work item is marked as a duplicate of.'
    field :moved_to_work_item_url, GraphQL::Types::String, null: true,
      description: 'URL of the work item that the work item was moved to.'
    field :show_plan_upgrade_promotion, GraphQL::Types::Boolean, null: false,
      description: 'Whether to show the promotional message for the work item.',
      experiment: { milestone: '17.11' }

    field :hidden, GraphQL::Types::Boolean, null: true,
      method: :hidden?,
      description: 'Indicates the work item is hidden because the author has been banned.'

    markdown_field :title_html, null: true
    markdown_field :description_html, null: true

    def work_item_type
      context.scoped_set!(:resource_parent, object.resource_parent)

      object.work_item_type
    end

    def comment_templates_paths
      new_comment_template_paths(object.namespace.group_namespace? ? object.namespace : object.project.group,
        object.project)
    end

    def create_note_email
      object.creatable_note_email_address(context[:current_user])
    end

    def archived
      return false if object.project.blank?

      object.project.archived?
    end

    def show_plan_upgrade_promotion
      # It should be true for namespaces in free plan.
      # As we don't have a direct way to check that. We can check if the licensed feature for epics is enabled,
      # which is a premium and ultimate feature.
      !object.namespace.licensed_feature_available?(:epics)
    end
  end
end

Types::WorkItemType.prepend_mod_with('Types::WorkItemType')

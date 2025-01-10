# frozen_string_literal: true

module Types
  class WorkItemType < BaseObject
    graphql_name 'WorkItem'

    implements Types::TodoableInterface
    connection_type_class Types::CountableConnectionType

    authorize :read_work_item

    present_using WorkItemPresenter

    field :author, Types::UserType, null: true,
      description: 'User that created the work item.',
      experiment: { milestone: '15.9' }
    field :closed_at, Types::TimeType, null: true,
      description: 'Timestamp of when the work item was closed.'
    field :confidential, GraphQL::Types::Boolean, null: false,
      description: 'Indicates the work item is confidential.'
    field :created_at, Types::TimeType, null: false,
      description: 'Timestamp of when the work item was created.'
    field :description, GraphQL::Types::String, null: true,
      description: 'Description of the work item.'
    field :id, Types::GlobalIDType[::WorkItem], null: false,
      description: 'Global ID of the work item.'
    field :iid, GraphQL::Types::String, null: false,
      description: 'Internal ID of the work item.'
    field :lock_version,
      GraphQL::Types::Int,
      null: false,
      description: 'Lock version of the work item. Incremented each time the work item is updated.'
    field :namespace, Types::NamespaceType, null: true,
      description: 'Namespace the work item belongs to.',
      experiment: { milestone: '15.10' }
    field :project, Types::ProjectType, null: true,
      description: 'Project the work item belongs to.',
      experiment: { milestone: '15.3' }
    field :state, WorkItemStateEnum, null: false,
      description: 'State of the work item.'
    field :title, GraphQL::Types::String, null: false,
      description: 'Title of the work item.'
    field :updated_at, Types::TimeType, null: false,
      description: 'Timestamp of when the work item was last updated.'

    field :create_note_email, GraphQL::Types::String,
      null: true,
      description: 'User specific email address for the work item.'

    field :reference, GraphQL::Types::String, null: false,
      description: 'Internal reference of the work item. Returned in shortened format by default.',
      method: :to_reference do
      argument :full, GraphQL::Types::Boolean, required: false, default_value: false,
        description: 'Boolean option specifying whether the reference should be returned in full.'
    end

    field :widgets,
      [Types::WorkItems::WidgetInterface],
      null: true,
      description: 'Collection of widgets that belong to the work item.'
    field :work_item_type, Types::WorkItems::TypeType, null: false,
      description: 'Type assigned to the work item.'

    field :archived, GraphQL::Types::Boolean, null: false,
      description: 'Whether the work item belongs to an archived project. Always false for group level work items.',
      experiment: { milestone: '16.5' }

    field :duplicated_to_work_item_url, GraphQL::Types::String, null: true,
      description: 'URL of the work item that the work item is marked as a duplicate of.'
    field :moved_to_work_item_url, GraphQL::Types::String, null: true,
      description: 'URL of the work item that the work item was moved to.'

    markdown_field :title_html, null: true
    markdown_field :description_html, null: true

    expose_permissions Types::PermissionTypes::WorkItem

    def work_item_type
      context.scoped_set!(:resource_parent, object.resource_parent)

      object.work_item_type
    end

    def create_note_email
      object.creatable_note_email_address(context[:current_user])
    end

    def archived
      return false if object.project.blank?

      object.project.archived?
    end
  end
end

Types::WorkItemType.prepend_mod_with('Types::WorkItemType')

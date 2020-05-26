# frozen_string_literal: true

module Types
  class MilestoneType < BaseObject
    graphql_name 'Milestone'
    description 'Represents a milestone.'

    present_using MilestonePresenter

    authorize :read_milestone

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the milestone'

    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Title of the milestone'

    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the milestone'

    field :state, Types::MilestoneStateEnum, null: false,
          description: 'State of the milestone'

    field :web_path, GraphQL::STRING_TYPE, null: false, method: :milestone_path,
          description: 'Web path of the milestone'

    field :due_date, Types::TimeType, null: true,
          description: 'Timestamp of the milestone due date'

    field :start_date, Types::TimeType, null: true,
          description: 'Timestamp of the milestone start date'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of milestone creation'

    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of last milestone update'

    field :project_milestone, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates if milestone is at project level',
          method: :project_milestone?

    field :group_milestone, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates if milestone is at group level',
          method: :group_milestone?

    field :subgroup_milestone, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates if milestone is at subgroup level',
          method: :subgroup_milestone?
  end
end

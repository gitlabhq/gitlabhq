# frozen_string_literal: true

module Types
  class MilestoneType < BaseObject
    graphql_name 'Milestone'
    description 'Represents a milestone'

    present_using MilestonePresenter

    authorize :read_milestone

    alias_method :milestone, :object

    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the milestone.'

    field :iid, GraphQL::Types::ID, null: false, # rubocop:disable Graphql/IDType -- Legacy argument using ID type kept for backwards compatibility
      description: "Internal ID of the milestone."

    field :title, GraphQL::Types::String, null: false,
      description: 'Title of the milestone.'

    field :description, GraphQL::Types::String, null: true,
      description: 'Description of the milestone.'

    field :state, Types::MilestoneStateEnum, null: false,
      description: 'State of the milestone.'

    field :expired, GraphQL::Types::Boolean, null: false,
      description: 'Expired state of the milestone (a milestone is expired when the due date is past the current ' \
        'date). Defaults to `false` when due date has not been set.'

    field :upcoming, GraphQL::Types::Boolean, null: false,
      description: 'Upcoming state of the milestone (a milestone is upcoming when the start date is in the future). ' \
        'Defaults to `false` when start date has not been set.'

    field :web_path, GraphQL::Types::String, null: false, method: :milestone_path,
      description: 'Web path of the milestone.'

    field :due_date, Types::TimeType, null: true,
      description: 'Timestamp of the milestone due date.'

    field :start_date, Types::TimeType, null: true,
      description: 'Timestamp of the milestone start date.'

    field :created_at, Types::TimeType, null: false,
      description: 'Timestamp of milestone creation.'

    field :updated_at, Types::TimeType, null: false,
      description: 'Timestamp of last milestone update.'

    field :project, Types::ProjectType, null: true, description: 'Project of the milestone.'

    field :project_milestone, GraphQL::Types::Boolean, null: false,
      description: 'Indicates if milestone is at project level.',
      method: :project_milestone?

    field :group, Types::GroupType, null: true, description: 'Group of the milestone.'

    field :group_milestone, GraphQL::Types::Boolean, null: false,
      description: 'Indicates if milestone is at group level.',
      method: :group_milestone?

    field :subgroup_milestone, GraphQL::Types::Boolean, null: false,
      description: 'Indicates if milestone is at subgroup level.',
      method: :subgroup_milestone?

    field :stats, Types::MilestoneStatsType, null: true,
      description: 'Milestone statistics.'

    field :releases, ::Types::ReleaseType.connection_type,
      null: true,
      description: 'Releases associated with this milestone.'

    def stats
      milestone
    end
  end
end

Types::MilestoneType.prepend_mod_with('Types::MilestoneType')

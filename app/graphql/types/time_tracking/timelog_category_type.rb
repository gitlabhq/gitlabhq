# frozen_string_literal: true

module Types
  module TimeTracking
    class TimelogCategoryType < BaseObject
      graphql_name 'TimeTrackingTimelogCategory'

      authorize :read_timelog_category

      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'Internal ID of the timelog category.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the category.'

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the category.'

      field :color,
        Types::ColorType,
        null: true,
        description: 'Color assigned to the category.'

      field :billable,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether the category is billable or not.'

      field :billing_rate,
        GraphQL::Types::Float,
        null: true,
        description: 'Billing rate for the category.'

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'When the category was created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'When the category was last updated.'
    end
  end
end

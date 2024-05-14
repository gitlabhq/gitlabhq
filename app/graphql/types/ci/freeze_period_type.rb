# frozen_string_literal: true

module Types
  module Ci
    class FreezePeriodType < BaseObject
      graphql_name 'CiFreezePeriod'
      description 'Represents a deployment freeze window of a project'

      authorize :read_freeze_period

      present_using ::Ci::FreezePeriodPresenter

      field :status, Types::Ci::FreezePeriodStatusEnum,
        description: 'Freeze period status.',
        null: false

      field :start_cron, GraphQL::Types::String,
        description: 'Start of the freeze period in cron format.',
        null: false,
        method: :freeze_start

      field :end_cron, GraphQL::Types::String,
        description: 'End of the freeze period in cron format.',
        null: false,
        method: :freeze_end

      field :cron_timezone, GraphQL::Types::String,
        description: 'Time zone for the cron fields, defaults to UTC if not provided.',
        null: true

      field :start_time, Types::TimeType,
        description: 'Timestamp (UTC) of when the current/next active period starts.',
        null: true

      field :end_time, Types::TimeType,
        description: 'Timestamp (UTC) of when the current/next active period ends.',
        null: true,
        method: :time_end_from_now
    end
  end
end

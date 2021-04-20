# frozen_string_literal: true

module Resolvers
  class TimelogResolver < BaseResolver
    include LooksAhead

    type ::Types::TimelogType.connection_type, null: false

    argument :start_date, Types::TimeType,
              required: false,
              description: 'List time logs within a date range where the logged date is equal to or after startDate.'

    argument :end_date, Types::TimeType,
              required: false,
              description: 'List time logs within a date range where the logged date is equal to or before endDate.'

    argument :start_time, Types::TimeType,
              required: false,
              description: 'List time-logs within a time range where the logged time is equal to or after startTime.'

    argument :end_time, Types::TimeType,
              required: false,
              description: 'List time-logs within a time range where the logged time is equal to or before endTime.'

    def resolve_with_lookahead(**args)
      return Timelog.none unless timelogs_available_for_user?

      validate_params_presence!(args)
      transformed_args = transform_args(args)
      validate_time_difference!(transformed_args)

      find_timelogs(transformed_args)
    end

    private

    def preloads
      {
        note: [:note]
      }
    end

    def find_timelogs(args)
      apply_lookahead(group.timelogs(args[:start_time], args[:end_time]))
    end

    def timelogs_available_for_user?
      group&.user_can_access_group_timelogs?(context[:current_user])
    end

    def validate_params_presence!(args)
      message = case time_params_count(args)
                when 0
                  'Start and End arguments must be present'
                when 1
                  'Both Start and End arguments must be present'
                when 2
                  validate_duplicated_args(args)
                when 3 || 4
                  'Only Time or Date arguments must be present'
                end

      raise_argument_error(message) if message
    end

    def validate_time_difference!(args)
      message = if args[:end_time] < args[:start_time]
                  'Start argument must be before End argument'
                elsif args[:end_time] - args[:start_time] > 60.days
                  'The time range period cannot contain more than 60 days'
                end

      raise_argument_error(message) if message
    end

    def transform_args(args)
      return args if args.keys == [:start_time, :end_time]

      time_args = args.except(:start_date, :end_date)

      if time_args.empty?
        time_args[:start_time] = args[:start_date].beginning_of_day
        time_args[:end_time] = args[:end_date].end_of_day
      elsif time_args.key?(:start_time)
        time_args[:end_time] = args[:end_date].end_of_day
      elsif time_args.key?(:end_time)
        time_args[:start_time] = args[:start_date].beginning_of_day
      end

      time_args
    end

    def time_params_count(args)
      [:start_time, :end_time, :start_date, :end_date].count { |param| args.key?(param) }
    end

    def validate_duplicated_args(args)
      if args.key?(:start_time) && args.key?(:start_date) ||
        args.key?(:end_time) && args.key?(:end_date)
        'Both Start and End arguments must be present'
      end
    end

    def raise_argument_error(message)
      raise Gitlab::Graphql::Errors::ArgumentError, message
    end

    def group
      @group ||= object.respond_to?(:sync) ? object.sync : object
    end
  end
end

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
      build_timelogs

      if args.any?
        validate_args!(args)
        build_parsed_args(args)
        validate_time_difference!
        apply_time_filter
      end

      apply_lookahead(timelogs)
    end

    private

    attr_reader :parsed_args, :timelogs

    def preloads
      {
        note: [:note]
      }
    end

    def validate_args!(args)
      if args[:start_time] && args[:start_date]
        raise_argument_error('Provide either a start date or time, but not both')
      elsif args[:end_time] && args[:end_date]
        raise_argument_error('Provide either an end date or time, but not both')
      end
    end

    def build_parsed_args(args)
      if times_provided?(args)
        @parsed_args = args
      else
        @parsed_args = args.except(:start_date, :end_date)

        @parsed_args[:start_time] = args[:start_date].beginning_of_day if args[:start_date]
        @parsed_args[:end_time] = args[:end_date].end_of_day if args[:end_date]
      end
    end

    def times_provided?(args)
      args[:start_time] && args[:end_time]
    end

    def validate_time_difference!
      return unless end_time_before_start_time?

      raise_argument_error('Start argument must be before End argument')
    end

    def end_time_before_start_time?
      times_provided?(parsed_args) && parsed_args[:end_time] < parsed_args[:start_time]
    end

    def build_timelogs
      @timelogs = Timelog.in_group(object)
    end

    def apply_time_filter
      @timelogs = timelogs.at_or_after(parsed_args[:start_time]) if parsed_args[:start_time]
      @timelogs = timelogs.at_or_before(parsed_args[:end_time]) if parsed_args[:end_time]
    end

    def raise_argument_error(message)
      raise Gitlab::Graphql::Errors::ArgumentError, message
    end
  end
end

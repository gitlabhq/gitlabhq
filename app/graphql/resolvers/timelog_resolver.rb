# frozen_string_literal: true

module Resolvers
  class TimelogResolver < BaseResolver
    include LooksAhead
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type ::Types::TimelogType.connection_type, null: false

    argument :start_date, Types::TimeType,
      required: false,
      description: 'List timelogs within a date range where the logged date is equal to or after startDate.'

    argument :end_date, Types::TimeType,
      required: false,
      description: 'List timelogs within a date range where the logged date is equal to or before endDate.'

    argument :start_time, Types::TimeType,
      required: false,
      description: 'List timelogs within a time range where the logged time is equal to or after startTime.'

    argument :end_time, Types::TimeType,
      required: false,
      description: 'List timelogs within a time range where the logged time is equal to or before endTime.'

    argument :project_id, ::Types::GlobalIDType[::Project],
      required: false,
      description: 'List timelogs for a project.'

    argument :group_id, ::Types::GlobalIDType[::Group],
      required: false,
      description: 'List timelogs for a group.'

    argument :username, GraphQL::Types::String,
      required: false,
      description: 'List timelogs for a user.'

    argument :sort, Types::TimeTracking::TimelogSortEnum,
      description: 'List timelogs in a particular order.',
      required: false,
      default_value: :spent_at_asc

    def resolve_with_lookahead(**args)
      validate_args!(object, args)

      args = parse_datetime_args(args)

      timelogs = Timelogs::TimelogsFinder.new(object, finder_params(args)).execute

      apply_lookahead(timelogs)
    rescue ArgumentError => e
      raise_argument_error(e.message)
    rescue ActiveRecord::RecordNotFound
      raise_resource_not_available_error!
    end

    private

    def finder_params(args)
      {
        username: args[:username],
        start_time: args[:start_time],
        end_time: args[:end_time],
        group_id: args[:group_id]&.model_id,
        project_id: args[:project_id]&.model_id,
        sort: args[:sort]
      }
    end

    def preloads
      {
        note: [:note]
      }
    end

    def validate_args!(object, args)
      unless has_parent?(object, args) || for_current_user?(args) || admin_user?
        raise_argument_error('Non-admin users must provide a group_id, project_id, or current username')
      end

      if args[:start_time] && args[:start_date]
        raise_argument_error('Provide either a start date or time, but not both')
      elsif args[:end_time] && args[:end_date]
        raise_argument_error('Provide either an end date or time, but not both')
      end
    end

    def has_parent?(object, args)
      object || args[:group_id] || args[:project_id]
    end

    def for_current_user?(args)
      args[:username].present? && args[:username] == current_user&.username
    end

    def admin_user?
      current_user&.can_read_all_resources?
    end

    def parse_datetime_args(args)
      if times_provided?(args)
        args
      else
        parsed_args = args.except(:start_date, :end_date)

        parsed_args[:start_time] = args[:start_date].beginning_of_day if args[:start_date]
        parsed_args[:end_time] = args[:end_date].end_of_day if args[:end_date]

        parsed_args
      end
    end

    def times_provided?(args)
      args[:start_time] && args[:end_time]
    end

    def raise_argument_error(message)
      raise Gitlab::Graphql::Errors::ArgumentError, message
    end
  end
end

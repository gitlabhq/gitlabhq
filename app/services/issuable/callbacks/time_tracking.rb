# frozen_string_literal: true

module Issuable
  module Callbacks
    class TimeTracking < Base
      ALLOWED_PARAMS = %i[time_estimate spend_time timelog].freeze

      def after_initialize
        if excluded_in_new_type?
          params.delete(:time_estimate)
          params.delete(:spend_time)
          params.delete(:timelog)
        end

        return unless has_permission?(:"admin_#{issuable.to_ability_name}")

        # below 2 parse_*_data methods, parse the data coming in from `time_tracking_widget` argument, in
        # work item update mutation.
        parse_timelog_data if params.key?(:timelog) && !params[:spend_time]
        parse_time_estimate_data if params.key?(:time_estimate) && params[:time_estimate].is_a?(String)

        # we still need to set the data here, in case when we had no data coming in from the `time_tracking_widget`
        # argument, but data was still set through updating the description and using quick actions.
        issuable.time_estimate = params[:time_estimate] if params.has_key?(:time_estimate)
        issuable.spend_time = params[:spend_time] if params[:spend_time].present?
      end

      private

      def parse_timelog_data
        time_spent = params.dig(:timelog, :time_spent)
        parsed_time_spent = if time_spent == ":reset"
                              :reset
                            else
                              Gitlab::TimeTrackingFormatter.parse(time_spent)
                            end

        raise_error(invalid_time_spent_format('Time spent')) if parsed_time_spent.nil?

        params[:spend_time] = { duration: parsed_time_spent, user_id: current_user.id }.merge(params[:timelog])
      end

      def parse_time_estimate_data
        params[:time_estimate] = begin
          Integer(params[:time_estimate] || '')
        rescue ArgumentError
          parsed_time_estimate = Gitlab::TimeTrackingFormatter.parse(params[:time_estimate])
          raise_error(invalid_time_spent_format('Time estimate')) if parsed_time_estimate.nil?
          parsed_time_estimate
        end
      end

      def invalid_time_spent_format(argument_name)
        format(_("%{argument_name} must be formatted correctly. For example: 1h 30m."), argument_name: argument_name)
      end
    end
  end
end

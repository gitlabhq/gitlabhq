# frozen_string_literal: true

module Resolvers
  module WebHooks
    class EventsResolver < BaseResolver
      include ::LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :read_web_hook

      type Types::WebHooks::EventType.connection_type, null: true

      when_single do
        argument :id, Types::GlobalIDType[::WebHookLog],
          required: true,
          description: 'ID of the webhook event.'
      end

      argument :timestamp_range, Types::TimestampRangeInputType,
        required: false,
        description: 'Filter for webhook events within a range of timestamps. ' \
          'Defaults to events within the last seven days.'

      validates mutually_exclusive: [:id, :timestamp_range]

      def ready?(**args)
        timestamp_range = args[:timestamp_range]

        if timestamp_range && timestamp_range[:start] && WebHookLog.max_recent_days_ago > timestamp_range[:start]
          raise Gitlab::Graphql::Errors::ArgumentError,
            "`timestamp range` must be within the last #{WebHookLog::MAX_RECENT_DAYS} days"
        end

        super
      end

      def resolve(**args)
        ::WebHooks::WebHookLogsFinder.new(object, context[:current_user], web_hook_log_finder_params(args)).execute
      end

      private

      def web_hook_log_finder_params(args)
        params = args.except(:timestamp_range)

        if args[:timestamp_range]
          params.merge!(start_time: args[:timestamp_range][:start], end_time: args[:timestamp_range][:end])
        end

        params[:id] = args[:id].model_id if args[:id]

        params
      end
    end
  end
end

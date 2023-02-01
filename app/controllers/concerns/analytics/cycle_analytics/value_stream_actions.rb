# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module ValueStreamActions
      extend ActiveSupport::Concern

      included do
        before_action :authorize
      end

      def index
        # FOSS users can only see the default value stream
        value_streams = [Analytics::CycleAnalytics::ValueStream.build_default_value_stream(namespace)]

        render json: Analytics::CycleAnalytics::ValueStreamSerializer.new.represent(value_streams)
      end

      private

      def namespace
        raise NotImplementedError
      end

      def authorize
        authorize_read_cycle_analytics!
      end
    end
  end
end

Analytics::CycleAnalytics::ValueStreamActions.prepend_mod_with('Analytics::CycleAnalytics::ValueStreamActions')

# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module ValueStreamActions
      extend ActiveSupport::Concern

      included do
        before_action :authorize
        # Defining the before action here, because in the EE module we cannot define a before_action.
        # Reason: this is a module which is being included into a controller. This module is extended in EE.
        before_action :authorize_modification, only: %i[create destroy update] # rubocop:disable Rails/LexicallyScopedActionFilter
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

      def authorize_modification
        # no-op, overridden in EE
      end
    end
  end
end

Analytics::CycleAnalytics::ValueStreamActions.prepend_mod_with('Analytics::CycleAnalytics::ValueStreamActions')

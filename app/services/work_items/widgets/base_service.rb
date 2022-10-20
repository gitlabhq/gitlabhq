# frozen_string_literal: true

module WorkItems
  module Widgets
    class BaseService < ::BaseService
      WidgetError = Class.new(StandardError)

      attr_reader :widget, :work_item, :current_user, :service_params

      def initialize(widget:, current_user:, service_params: {})
        @widget = widget
        @work_item = widget.work_item
        @current_user = current_user
        @service_params = service_params
      end

      private

      def has_permission?(permission)
        can?(current_user, permission, widget.work_item)
      end
    end
  end
end

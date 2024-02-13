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

      def new_type_excludes_widget?
        return false unless service_params[:work_item_type]

        service_params[:work_item_type].widgets(work_item.resource_parent).exclude?(@widget.class)
      end

      def has_permission?(permission)
        can?(current_user, permission, widget.work_item)
      end

      def service_response!(result)
        return result unless result[:status] == :error

        raise WidgetError, result[:message]
      end
    end
  end
end

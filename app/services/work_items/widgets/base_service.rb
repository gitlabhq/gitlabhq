# frozen_string_literal: true

module WorkItems
  module Widgets
    class BaseService < ::BaseService
      WidgetError = Class.new(StandardError)

      attr_reader :widget, :work_item, :current_user

      def initialize(widget:, current_user:)
        @widget = widget
        @work_item = widget.work_item
        @current_user = current_user
      end

      private

      def has_permission?(permission)
        can?(current_user, permission, widget.work_item)
      end
    end
  end
end

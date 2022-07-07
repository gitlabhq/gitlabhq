# frozen_string_literal: true

module WorkItems
  module Widgets
    class BaseService < ::BaseService
      WidgetError = Class.new(StandardError)

      attr_reader :widget, :current_user

      def initialize(widget:, current_user:)
        @widget = widget
        @current_user = current_user
      end
    end
  end
end

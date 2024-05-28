# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Base < Issuable::Callbacks::Base
      alias_method :work_item, :issuable

      def raise_error(message)
        raise ::WorkItems::Widgets::BaseService::WidgetError, message
      end
    end
  end
end

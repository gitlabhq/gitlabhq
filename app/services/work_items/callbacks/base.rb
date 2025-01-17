# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Base < Issuable::Callbacks::Base
      alias_method :work_item, :issuable

      def raise_error(message)
        raise Error, message
      end

      def log_error(message)
        ::Gitlab::AppLogger.error message
      end
    end
  end
end

# frozen_string_literal: true

module Packages
  module Destructible
    extend ActiveSupport::Concern

    class_methods do
      def next_pending_destruction(order_by:)
        set = pending_destruction.limit(1).lock('FOR UPDATE SKIP LOCKED')
        set = set.order(order_by) if order_by
        set.take
      end
    end
  end
end

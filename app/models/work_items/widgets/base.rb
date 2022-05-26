# frozen_string_literal: true

module WorkItems
  module Widgets
    class Base
      def self.type
        name.demodulize.underscore.to_sym
      end

      def type
        self.class.type
      end

      def initialize(work_item)
        @work_item = work_item
      end

      attr_reader :work_item
    end
  end
end

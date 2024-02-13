# frozen_string_literal: true

module WorkItems
  module Widgets
    class Base
      def self.type
        name.demodulize.underscore.to_sym
      end

      def self.api_symbol
        "#{type}_widget".to_sym
      end

      def self.quick_action_commands
        []
      end

      def self.process_quick_action_param(param_name, value)
        { param_name => value }
      end

      def self.callback_class
        WorkItems::Callbacks.const_get(name.demodulize, false)
      rescue NameError
        begin
          Issuable::Callbacks.const_get(name.demodulize, false)
        rescue NameError
          nil
        end
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

WorkItems::Widgets::Base.prepend_mod
WorkItems::Widgets::Base.prepend_mod_with('WorkItems::Widgets::Base::ClassMethods')

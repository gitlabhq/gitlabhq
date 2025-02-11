# frozen_string_literal: true

module WorkItems
  module Widgets
    class Base
      include Gitlab::Utils::StrongMemoize

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

      def self.sync_data_callback_class
        ::WorkItems::DataSync::Widgets.const_get(name.demodulize, false)
      rescue NameError
        nil
      end

      def self.sorting_keys
        {}
      end

      def sync_data_callback_class
        self.class.sync_data_callback_class
      end
      strong_memoize_attr :sync_data_callback_class

      def type
        self.class.type
      end

      def initialize(work_item, widget_definition: nil)
        @work_item = work_item
        @widget_definition = widget_definition
      end

      attr_reader :work_item, :widget_definition

      delegate :widget_options, to: :widget_definition
    end
  end
end

WorkItems::Widgets::Base.prepend_mod
WorkItems::Widgets::Base.prepend_mod_with('WorkItems::Widgets::Base::ClassMethods')

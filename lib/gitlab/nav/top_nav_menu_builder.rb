# frozen_string_literal: true

module Gitlab
  module Nav
    class TopNavMenuBuilder
      def initialize
        @primary = []
        @secondary = []
      end

      def add_primary_menu_item(**args)
        add_menu_item(dest: @primary, **args)
      end

      def add_secondary_menu_item(**args)
        add_menu_item(dest: @secondary, **args)
      end

      def build
        {
          primary: @primary,
          secondary: @secondary
        }
      end

      private

      def add_menu_item(dest:, **args)
        item = ::Gitlab::Nav::TopNavMenuItem.build(**args)

        dest.push(item)
      end
    end
  end
end

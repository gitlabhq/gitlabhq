# frozen_string_literal: true

module Gitlab
  module Nav
    class TopNavMenuBuilder
      def initialize
        @primary = []
        @secondary = []
        @last_header_added = nil
      end

      def add_primary_menu_item(header: nil, **args)
        if header && (header != @last_header_added)
          add_menu_header(dest: @primary, title: header)
          @last_header_added = header
        end

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

      def add_menu_header(dest:, **args)
        header = ::Gitlab::Nav::TopNavMenuHeader.build(**args)

        dest.push(header)
      end
    end
  end
end

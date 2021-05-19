# frozen_string_literal: true

module Gitlab
  module Nav
    class TopNavViewModelBuilder
      def initialize
        @menu_builder = ::Gitlab::Nav::TopNavMenuBuilder.new
        @views = {}
      end

      delegate :add_primary_menu_item, :add_secondary_menu_item, to: :@menu_builder

      def add_view(name, props)
        @views[name] = props
      end

      def build
        menu = @menu_builder.build

        menu.merge({
          views: @views,
          activeTitle: _('Menu')
        })
      end
    end
  end
end

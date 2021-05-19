# frozen_string_literal: true

module Analytics
  module NavbarHelper
    class NavbarSubItem
      attr_reader :title, :path, :link, :link_to_options

      def initialize(title:, path:, link:, link_to_options: {})
        @title = title
        @path = path
        @link = link
        @link_to_options = link_to_options.merge(title: title)
      end
    end

    def group_analytics_navbar_links(group, current_user)
      []
    end

    private

    def navbar_sub_item(args)
      NavbarSubItem.new(**args)
    end
  end
end

Analytics::NavbarHelper.prepend_mod_with('Analytics::NavbarHelper')

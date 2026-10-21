# frozen_string_literal: true

module Types
  module Users
    class SidebarNavigationModeEnum < BaseEnum
      graphql_name 'SidebarNavigationMode'
      description 'Values for the navigation mode of the left sidebar'

      DESCRIPTIONS = {
        compact: 'Show only pinned items.',
        all_categories: 'Show pinned items and all navigation categories.'
      }.freeze

      ::UserPreference.sidebar_navigation_modes.each_key do |mode|
        value mode.upcase, value: mode, description: DESCRIPTIONS.fetch(mode.to_sym)
      end
    end
  end
end

# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class UsageQuotasMenu < ::Sidebars::Menu
        include ::Sidebars::Concerns::RenderIfLoggedIn

        override :link
        def link
          profile_usage_quotas_path
        end

        override :title
        def title
          s_('UsageQuota|Usage Quotas')
        end

        override :sprite_icon
        def sprite_icon
          'quota'
        end

        override :active_routes
        def active_routes
          { controller: :usage_quotas }
        end
      end
    end
  end
end

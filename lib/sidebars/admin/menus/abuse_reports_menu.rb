# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class AbuseReportsMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_abuse_reports_path
        end

        override :title
        def title
          s_('Admin|Abuse reports')
        end

        override :sprite_icon
        def sprite_icon
          'slight-frown'
        end

        override :has_pill?
        def has_pill?
          true
        end

        override :pill_count
        def pill_count
          @pill_count ||= AbuseReport.count(:all)
        end

        override :active_routes
        def active_routes
          { controller: :abuse_reports }
        end
      end
    end
  end
end

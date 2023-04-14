# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class LabelsMenu < ::Sidebars::Admin::BaseMenu
        override :link
        def link
          admin_labels_path
        end

        override :title
        def title
          s_('Admin|Labels')
        end

        override :sprite_icon
        def sprite_icon
          'labels'
        end

        override :active_routes
        def active_routes
          { controller: :labels }
        end
      end
    end
  end
end

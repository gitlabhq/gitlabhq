# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class ScopeMenu < ::Sidebars::Menu
        override :link
        def link
          project_path(context.project)
        end

        override :title
        def title
          context.project.name
        end
      end
    end
  end
end

# frozen_string_literal: true

module Sidebars
  module Projects
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        set_scope_menu(Sidebars::Projects::Menus::ScopeMenu.new(context))

        add_menu(Sidebars::Projects::Menus::ProjectOverviewMenu.new(context))
        add_menu(Sidebars::Projects::Menus::LearnGitlabMenu.new(context))
        add_menu(Sidebars::Projects::Menus::RepositoryMenu.new(context))
      end

      override :render_raw_menus_partial
      def render_raw_menus_partial
        'layouts/nav/sidebar/project_menus'
      end

      override :aria_label
      def aria_label
        _('Project navigation')
      end
    end
  end
end

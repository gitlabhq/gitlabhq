# frozen_string_literal: true

module Sidebars
  module UserSettings
    module Menus
      class CommentTemplatesMenu < ::Sidebars::Menu
        include ::UsersHelper

        override :link
        def link
          profile_comment_templates_path
        end

        override :title
        def title
          _('Comment Templates')
        end

        override :sprite_icon
        def sprite_icon
          'comment-lines'
        end

        override :render?
        def render?
          !!context.current_user
        end

        override :active_routes
        def active_routes
          { controller: :comment_templates }
        end

        private

        def current_user
          context.current_user
        end
      end
    end
  end
end

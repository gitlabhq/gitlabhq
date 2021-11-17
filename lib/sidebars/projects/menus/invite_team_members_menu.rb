# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class InviteTeamMembersMenu < ::Sidebars::Menu
        override :title
        def title
          s_('InviteMember|Invite members')
        end

        override :render?
        def render?
          can?(context.current_user, :admin_project_member, context.project) && all_valid_members.size <= 1
        end

        override :menu_partial
        def menu_partial
          'projects/invite_members_side_nav_link'
        end

        override :menu_partial_options
        def menu_partial_options
          {
            project: context.project,
            title: title,
            sidebar_menu: self
          }
        end

        override :extra_nav_link_html_options
        def extra_nav_link_html_options
          {
            'data-test-id': 'side-nav-invite-members'
          }
        end

        private

        def all_valid_members
          MembersFinder.new(context.project, context.current_user)
                       .execute(include_relations: [:inherited, :direct, :invited_groups])
        end
      end
    end
  end
end

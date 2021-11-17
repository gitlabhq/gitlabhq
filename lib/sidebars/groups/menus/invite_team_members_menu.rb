# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class InviteTeamMembersMenu < ::Sidebars::Menu
        override :title
        def title
          s_('InviteMember|Invite members')
        end

        override :render?
        def render?
          can?(context.current_user, :admin_group_member, context.group) && all_valid_members.size <= 1
        end

        override :menu_partial
        def menu_partial
          'groups/invite_members_side_nav_link'
        end

        override :menu_partial_options
        def menu_partial_options
          {
            group: context.group,
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
          GroupMembersFinder.new(context.group, context.current_user).execute
        end
      end
    end
  end
end

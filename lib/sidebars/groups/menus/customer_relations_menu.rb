# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class CustomerRelationsMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(contacts_menu_item) if can_read_contact?

          true
        end

        override :title
        def title
          _('Customer relations')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end

        override :render?
        def render?
          context.group.crm_group?
        end

        override :serialize_as_menu_item_args
        def serialize_as_menu_item_args
          nil
        end

        private

        def contacts_menu_item
          ::Sidebars::MenuItem.new(
            title: context.is_super_sidebar ? _('Customer relations') : _('Contacts'),
            link: group_crm_contacts_path(context.group),
            super_sidebar_parent: ::Sidebars::Groups::SuperSidebarMenus::PlanMenu,
            active_routes: { controller: %w[groups/crm/contacts groups/crm/organizations] },
            item_id: :crm_contacts
          )
        end

        def can_read_contact?
          can?(context.current_user, :read_crm_contact, context.group)
        end
      end
    end
  end
end

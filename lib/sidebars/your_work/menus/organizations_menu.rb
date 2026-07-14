# frozen_string_literal: true

module Sidebars
  module YourWork
    module Menus
      class OrganizationsMenu < ::Sidebars::Menu
        override :link
        def link
          organizations_path
        end

        override :title
        def title
          _('Organizations')
        end

        override :sprite_icon
        def sprite_icon
          'organization'
        end

        override :render?
        def render?
          return false unless context.current_user
          return false unless Feature.enabled?(:ui_for_organizations, context.current_user)

          return context.current_user.has_active_non_default_organization? if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- use Gitlab.com? for now to keep simple. May refactor to SaaS feature in the future

          true
        end

        override :active_routes
        def active_routes
          { controller: 'organizations/organizations', actions: %w[index new] }
        end
      end
    end
  end
end

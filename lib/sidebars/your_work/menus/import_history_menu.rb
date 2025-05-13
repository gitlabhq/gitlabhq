# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- disabling this to match current structure of other sidebar menu items (.rubocop_todo/gitlab/bounded_contexts.yml)
module Sidebars
  module YourWork
    module Menus
      class ImportHistoryMenu < ::Sidebars::Menu
        override :link
        def link
          history_import_bulk_imports_path
        end

        override :title
        def title
          _('Import history')
        end

        override :sprite_icon
        def sprite_icon
          'import'
        end

        override :render?
        def render?
          !!context.current_user && (
            Gitlab::CurrentSettings.bulk_import_enabled? ||
            Feature.enabled?(:override_bulk_import_disabled, context.current_user, type: :ops)
          )
        end

        override :active_routes
        def active_routes
          { controller: ['import/bulk_imports', 'import/history'], path: 'import/github#details' }
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts

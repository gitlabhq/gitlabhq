# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Show < Base
          include Page::Component::Wiki
          include Page::Component::WikiSidebar
          include Page::Component::LazyLoader

          # No-op in CE; overridden by EE::Page::Component::DapEmptyState when prepended
          def close_dap_panel_if_exists; end
        end
      end
    end
  end
end

QA::Page::Project::Wiki::Show.prepend_mod_with('Page::Project::Wiki::Show', namespace: QA)

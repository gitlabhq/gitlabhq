# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Secure
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_audit_events
              open_secure_submenu('Audit events')
            end

            def go_to_security_configuration
              open_secure_submenu('Security configuration')
            end

            private

            def open_secure_submenu(sub_menu)
              open_submenu('Secure', '#secure', sub_menu)
            end
          end
        end
      end
    end
  end
end

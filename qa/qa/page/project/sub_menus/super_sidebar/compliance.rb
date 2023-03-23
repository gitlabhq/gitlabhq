# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Compliance
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_audit_events
              open_compliance_submenu('Audit events')
            end

            def go_to_security_configuration
              open_compliance_submenu('Security configuration')
            end

            private

            def open_compliance_submenu(sub_menu)
              open_submenu("Security and Compliance", "#security-and-compliance", sub_menu)
            end
          end
        end
      end
    end
  end
end

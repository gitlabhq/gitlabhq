# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Secure
          extend QA::Page::PageConcern

          def go_to_security_configuration
            open_secure_submenu('Security configuration')
          end

          private

          def open_secure_submenu(sub_menu)
            open_submenu('Secure', sub_menu)
          end
        end
      end
    end
  end
end

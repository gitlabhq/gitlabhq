# frozen_string_literal: true

module QA
  module Page
    module Component
      module WebIDE
        module Alert
          def self.prepended(page)
            page.module_eval do
              view 'app/assets/javascripts/ide/components/error_message.vue' do
                element :flash_alert
              end
            end
          end

          def has_no_alert?(message = nil)
            return has_no_element?(:flash_alert) if message.nil?

            within_element(:flash_alert) do
              has_no_text?(message)
            end
          end
        end
      end
    end
  end
end

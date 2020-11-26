# frozen_string_literal: true

module QA
  module Page
    module Registration
      class Welcome < Page::Base
        view 'app/views/registrations/welcome/show.html.haml' do
          element :get_started_button
        end

        def click_get_started_button_if_available
          click_element :get_started_button if has_element?(:get_started_button)
        end
      end
    end
  end
end

QA::Page::Registration::Welcome.prepend_if_ee('QA::EE::Page::Registration::Welcome')

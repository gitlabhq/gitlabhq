# frozen_string_literal: true

module QA
  module Page
    module Registration
      class Welcome < Page::Base
        view 'app/views/registrations/welcome/show.html.haml' do
          element :get_started_button
        end

        def click_get_started_button_if_available
          if has_element?(:get_started_button)
            Support::Retrier.retry_until do
              click_element :get_started_button
              has_no_element?(:get_started_button)
            end
          end
        end
      end
    end
  end
end

QA::Page::Registration::Welcome.prepend_mod_with('Page::Registration::Welcome', namespace: QA)

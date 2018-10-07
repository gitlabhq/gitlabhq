# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Epic
          class Edit < QA::Page::Base
            include QA::Page::Component::Issuable::Common

            def set_title(title)
              fill_element :title_input, title
            end

            def set_description(description)
              fill_element :description_textarea, description
            end

            def save_changes
              click_element :save_button
            end

            def delete_epic
              page.accept_alert("Epic will be removed! Are you sure?") do
                click_element :delete_button
              end
            end
          end
        end
      end
    end
  end
end

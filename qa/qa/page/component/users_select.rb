# frozen_string_literal: true

module QA
  module Page
    module Component
      module UsersSelect
        def select_user(element, username)
          find("#{element_selector_css(element)} input").set(username)
          find('.ajax-users-dropdown .user-username', text: "@#{username}").click
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module SAMLIdp
      module Page
        class Login < Page::Base
          def login
            fill_in 'username', with: 'user1'
            fill_in 'password', with: 'user1pass'
            click_on 'Login'
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Vendor
    module Slack
      module Page
        class OAuth < Vendor::Page::Base
          def submit_oauth
            click_button('Allow')
          end
        end
      end
    end
  end
end

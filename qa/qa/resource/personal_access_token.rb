# frozen_string_literal: true

module QA
  module Resource
    ##
    # Create a personal access token that can be used by the api
    #
    class PersonalAccessToken < Base
      attr_accessor :name

      attribute :access_token do
        Page::Profile::PersonalAccessTokens.perform(&:created_access_token)
      end

      def fabricate!
        Page::Main::Menu.perform(&:click_settings_link)
        Page::Profile::Menu.perform(&:click_access_tokens)

        Page::Profile::PersonalAccessTokens.perform do |token_page|
          token_page.fill_token_name(name || 'api-test-token')
          token_page.check_api
          token_page.click_create_token_button
        end
      end
    end
  end
end

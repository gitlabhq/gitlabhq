module QA
  module Factory
    module Resource
      ##
      # Create a personal access token that can be used by the api
      #
      class PersonalAccessToken < Factory::Base
        attr_accessor :name

        product :access_token do
          Page::Profile::PersonalAccessTokens.act { created_access_token }
        end

        def fabricate!
          Page::Menu::Main.act { go_to_profile_settings }
          Page::Menu::Profile.act { click_access_tokens }

          Page::Profile::PersonalAccessTokens.perform do |page|
            page.fill_token_name(name || 'api-test-token')
            page.check_api
            page.create_token
          end
        end
      end
    end
  end
end

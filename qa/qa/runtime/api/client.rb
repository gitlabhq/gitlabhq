require 'airborne'

module QA
  module Runtime
    module API
      class Client
        attr_reader :address

        def initialize(address = :gitlab, personal_access_token: nil)
          @address = address
          @personal_access_token = personal_access_token
        end

        def personal_access_token
          @personal_access_token ||= get_personal_access_token
        end

        def get_personal_access_token
          # you can set the environment variable PERSONAL_ACCESS_TOKEN
          # to use a specific access token rather than create one from the UI
          if Runtime::Env.personal_access_token
            Runtime::Env.personal_access_token
          else
            create_personal_access_token
          end
        end

        private

        def create_personal_access_token
          Runtime::Browser.visit(@address, Page::Main::Login) do
            Page::Main::Login.act { sign_in_using_credentials }
            Factory::Resource::PersonalAccessToken.fabricate!.access_token
          end
        end
      end
    end
  end
end

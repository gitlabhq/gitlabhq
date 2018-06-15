require 'airborne'

module QA
  module Runtime
    module API
      class Client
        attr_reader :address

        def initialize(address = :gitlab, personal_access_token: nil, new_session: true)
          @address = address
          @personal_access_token = personal_access_token
          @new_session = new_session
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
            Runtime::Env.personal_access_token = create_personal_access_token
          end
        end

        private

        def create_personal_access_token
          if @new_session
            Runtime::Browser.visit(@address, Page::Main::Login) { do_create_personal_access_token }
          else
            do_create_personal_access_token
          end
        end

        def do_create_personal_access_token
          Page::Main::Login.act { sign_in_using_credentials }
          Factory::Resource::PersonalAccessToken.fabricate!.access_token
        end
      end
    end
  end
end

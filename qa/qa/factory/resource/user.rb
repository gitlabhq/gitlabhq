require 'securerandom'

module QA
  module Factory
    module Resource
      class User < Factory::Base
        attr_accessor :name, :username, :email, :password

        def initialize
          @name = "name-#{SecureRandom.hex(8)}"
          @username = "username-#{SecureRandom.hex(8)}"
          @email = "mail#{SecureRandom.hex(8)}@mail.com"
          @password = 'password'
        end

        product :name do |factory|
          factory.name
        end

        def fabricate!
          Runtime::Browser.visit(:gitlab, Page::Main::Login)

          Page::Main::Login.perform do |page|
            page.sign_up_with_new_user(name, username, email, password)
          end
        end
      end
    end
  end
end

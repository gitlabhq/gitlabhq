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

        product(:name) { |factory| factory.name }

        product(:username) { |factory| factory.username }

        product(:email) { |factory| factory.email }

        product(:password) { |factory| factory.password }

        def fabricate!
          Page::Menu::Main.act { sign_out }
          Page::Main::Login.act { switch_to_register_tab }
          Page::Main::SignUp.perform do |page|
            page.sign_up!(name: name, username: username, email: email, password: password)
          end
        end
      end
    end
  end
end

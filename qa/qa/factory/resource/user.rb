require 'securerandom'

module QA
  module Factory
    module Resource
      class User < Factory::Base
        attr_reader :unique_id
        attr_writer :username, :password, :name, :email

        def initialize
          @unique_id = SecureRandom.hex(8)
        end

        def username
          @username ||= "qa-user-#{unique_id}"
        end

        def password
          @password ||= 'password'
        end

        def name
          @name ||= username
        end

        def email
          @email ||= "#{username}@example.com"
        end

        def credentials_given?
          defined?(@username) && defined?(@password)
        end

        product(:name) { |factory| factory.name }
        product(:username) { |factory| factory.username }
        product(:email) { |factory| factory.email }
        product(:password) { |factory| factory.password }

        def fabricate!
          Page::Menu::Main.perform { |main| main.sign_out }

          if credentials_given?
            Page::Main::Login.perform do |login|
              login.sign_in_using_credentials(self)
            end
          else
            Page::Main::Login.perform do |login|
              login.switch_to_register_tab
            end
            Page::Main::SignUp.perform do |signup|
              signup.sign_up!(self)
            end
          end
        end
      end
    end
  end
end

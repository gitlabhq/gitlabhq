require 'securerandom'

module QA
  module Factory
    module Resource
      class User < Factory::Base
        attr_reader :unique_id

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

        attribute :name
        attribute :username
        attribute :email
        attribute :password

        def fabricate!
          # Don't try to log-out if we're not logged-in
          if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
            Page::Main::Menu.perform { |main| main.sign_out }
          end

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

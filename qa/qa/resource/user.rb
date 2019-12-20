# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class User < Base
      attr_reader :unique_id
      attr_writer :username, :password
      attr_accessor :admin, :provider, :extern_uid

      attribute :id
      attribute :name
      attribute :email

      def initialize
        @admin = false
        @unique_id = SecureRandom.hex(8)
      end

      def admin?
        api_resource&.dig(:is_admin) || false
      end

      def username
        @username || "qa-user-#{unique_id}"
      end

      def password
        @password || 'password'
      end

      def name
        @name ||= api_resource&.dig(:name) || "QA User #{unique_id}"
      end

      def email
        @email ||= "#{username}@example.com"
      end

      def public_email
        @public_email ||= begin
          api_public_email = api_resource&.dig(:public_email)

          api_public_email && api_public_email != '' ? api_public_email : Runtime::User.default_email
        end
      end

      def credentials_given?
        defined?(@username) && defined?(@password)
      end

      def fabricate!
        # Don't try to log-out if we're not logged-in
        if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }
          Page::Main::Menu.perform { |main| main.sign_out }
        end

        if credentials_given?
          Page::Main::Login.perform do |login|
            login.sign_in_using_credentials(user: self)
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

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def api_delete
        super

        QA::Runtime::Logger.debug("Deleted user '#{username}'")
      end

      def api_delete_path
        "/users/#{id}"
      end

      def api_get_path
        "/users/#{fetch_id(username)}"
      end

      def api_post_path
        '/users'
      end

      def api_post_body
        {
          admin: admin,
          email: email,
          password: password,
          username: username,
          name: name,
          skip_confirmation: true
        }.merge(ldap_post_body)
      end

      def self.fabricate_or_use(username = nil, password = nil)
        if Runtime::Env.signup_disabled?
          self.fabricate_via_api! do |user|
            user.username = username
            user.password = password
          end
        else
          self.fabricate!
        end
      end

      private

      def ldap_post_body
        return {} unless extern_uid && provider

        {
            extern_uid: extern_uid,
            provider: provider
        }
      end

      def fetch_id(username)
        users = parse_body(api_get_from("/users?username=#{username}"))

        unless users.size == 1 && users.first[:username] == username
          raise ResourceNotFoundError, "Expected one user with username #{username} but found: `#{users}`."
        end

        users.first[:id]
      end
    end
  end
end

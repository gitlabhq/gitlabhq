# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class User < Base
      InvalidUserError = Class.new(RuntimeError)

      attr_reader :unique_id
      attr_writer :username, :password
      attr_accessor :admin, :provider, :extern_uid, :expect_fabrication_success, :hard_delete_on_api_removal

      attribute :id
      attribute :name
      attribute :first_name
      attribute :last_name
      attribute :email

      def initialize
        @admin = false
        @hard_delete_on_api_removal = false
        @unique_id = SecureRandom.hex(8)
        @expect_fabrication_success = true
      end

      def self.default
        Resource::User.init do |user|
          user.username = Runtime::User.ldap_user? ? Runtime::User.ldap_username : Runtime::User.username
          user.password = Runtime::User.ldap_user? ? Runtime::User.ldap_password : Runtime::User.password
        end
      end

      def admin?
        api_resource&.dig(:is_admin) || false
      end

      def username
        @username || "qa-user-#{unique_id}"
      end
      alias_method :ldap_username, :username

      def password
        @password || 'password'
      end
      alias_method :ldap_password, :password

      def name
        @name ||= api_resource&.dig(:name) || "QA User #{unique_id}"
      end

      def first_name
        name.split(' ').first
      end

      def last_name
        name.split(' ').drop(1).join(' ')
      end

      def email
        @email ||= begin
          api_email = api_resource&.dig(:email)
          api_email && !api_email.empty? ? api_email : "#{username}@example.com"
        end
      end

      def public_email
        @public_email ||= begin
          api_public_email = api_resource&.dig(:public_email)

          api_public_email && !api_public_email.empty? ? api_public_email : Runtime::User.default_email
        end
      end

      def credentials_given?
        defined?(@username) && defined?(@password)
      end

      def fabricate!
        # Don't try to log-out if we're not logged-in
        Page::Main::Menu.perform(&:sign_out) if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }

        if credentials_given?
          Page::Main::Login.perform do |login|
            login.sign_in_using_credentials(user: self)
          end
        else
          Flow::SignUp.sign_up!(self)
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
        "/users/#{id}?hard_delete=#{hard_delete_on_api_removal}"
      rescue NoValueError
        "/users/#{fetch_id(username)}?hard_delete=#{hard_delete_on_api_removal}"
      end

      def api_get_path
        return "/user" if fetching_own_data?

        "/users/#{fetch_id(username)}"
      end

      def api_post_path
        '/users'
      end

      def api_block_path
        "/users/#{id}/block"
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
          fabricate_via_api! do |user|
            user.username = username
            user.password = password
          end
        else
          fabricate! do |user|
            user.username = username if username
            user.password = password if password
          end
        end
      end

      def block!
        response = post(Runtime::API::Request.new(api_client, api_block_path).url, nil)
        return if response.code == HTTP_STATUS_CREATED

        raise ResourceUpdateFailedError, "Failed to block user. Request returned (#{response.code}): `#{response}`."
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

      def fetching_own_data?
        api_user&.username == username || Runtime::User.username == username
      end
    end
  end
end

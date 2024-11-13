# frozen_string_literal: true

# rubocop:disable Cop/UserAdmin -- does not apply to test resource
module QA
  module Resource
    class User < Base
      InvalidUserError = Class.new(RuntimeError)

      attr_reader :unique_id
      attr_writer :username, :password
      attr_accessor :admin,
        :provider,
        :extern_uid,
        :expect_fabrication_success,
        :hard_delete_on_api_removal,
        :access_level,
        :email_domain

      attributes :id,
        :name,
        :first_name,
        :last_name,
        :email

      class << self
        # TODO: remove as these methods can end up using same user which isn't fully compatible with parallel execution
        def default
          Resource::User.init do |user|
            user.username = Runtime::User.ldap_user? ? Runtime::User.ldap_username : Runtime::User.username
            user.password = Runtime::User.ldap_user? ? Runtime::User.ldap_password : Runtime::User.password
          end
        end

        def fabricate_or_use(username = nil, password = nil)
          if Runtime::Env.signup_disabled? && !Runtime::Env.personal_access_tokens_disabled?
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
      end

      def initialize
        @admin = false
        @hard_delete_on_api_removal = false
        @unique_id = SecureRandom.hex(8)
        @expect_fabrication_success = true
        @email_domain = 'example.com'
        @personal_access_tokens = []
      end

      def admin?
        api_resource&.dig(:is_admin) || false
      end

      def username
        @username || "qa-user-#{unique_id}"
      end
      alias_method :ldap_username, :username

      def password
        @password ||= "Pa$$w0rd"
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
          api_email && !api_email.empty? ? api_email : "#{username}@#{email_domain}"
        end
      end

      def commit_email
        @commit_email ||= begin
          api_commit_email = api_resource&.dig(:commit_email)

          api_commit_email && !api_commit_email.empty? ? api_commit_email : Runtime::User.default_email
        end
      end

      def credentials_given?
        defined?(@username) && defined?(@password)
      end

      def has_user?(user)
        Flow::Login.while_signed_in_as_admin do
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_users_overview)
          Page::Admin::Overview::Users::Index.perform do |index|
            index.choose_search_user(user.username)
            index.click_search
            index.has_username?(user.username)
          end
        end
      end

      def fabricate!
        # Don't try to log-out if we're not logged-in
        Page::Main::Menu.perform(&:sign_out) if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }

        if credentials_given? || has_user?(self)
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

      def exists?
        api_get
      rescue ResourceNotFoundError
        false
      end

      # TODO: implement separate delete method that only admin user can perform
      # User resource can't delete itslef if it is using it's own pat
      def api_delete_path
        "/users/#{id}?hard_delete=#{hard_delete_on_api_removal}"
      rescue NoValueError
        "/users/#{fetch_id(username)}?hard_delete=#{hard_delete_on_api_removal}"
      end

      def api_get_path
        "/users/#{id}"
      rescue NoValueError
        # if id is not yet known, attempt to find the id based on username
        "/users/#{fetch_id(username)}"
      end

      def api_post_path
        "/users"
      end

      def api_put_path
        "/users/#{id}"
      end

      def api_approve_path
        "/users/#{id}/approve"
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

      def approve!
        response = post(Runtime::API::Request.new(api_client, api_approve_path).url, nil)
        return if response.code == 201

        raise ResourceUpdateFailedError, "Failed to approve user. Request returned (#{response.code}): `#{response}`"
      end

      def block!(user_id)
        raise "Only admin can block other users" unless admin?

        response = post(Runtime::API::Request.new(api_client, "/users/#{user_id}/block").url, nil)
        return if response.code == HTTP_STATUS_CREATED

        raise ResourceUpdateFailedError, "Failed to block user. Request returned (#{response.code}): `#{response}`."
      end

      def set_public_email
        response = put(Runtime::API::Request.new(api_client, api_put_path).url, { public_email: email })
        return if response.code == HTTP_STATUS_OK

        raise(
          ResourceUpdateFailedError,
          "Failed to set public email. Request returned (#{response.code}): `#{response}`."
        )
      end

      # Get all users
      #
      # @param [Integer] per_page
      # @return [Array<Hash>]
      def users(per_page: 100)
        raise("This method can be called only on the Admin user!") unless admin?

        resp = get(Runtime::API::Request.new(api_client, '/users', per_page: per_page.to_s))
        raise ResourceQueryError unless resp.code == Support::API::HTTP_STATUS_OK

        parse_body(resp)
      end

      # Create new personal access token for user
      #
      # @return [QA::Resource::PersonalAccessToken]
      def create_personal_access_token!(use_for_api_client: true)
        pat = Resource::PersonalAccessToken.fabricate! do |resource|
          resource.username = username
          resource.password = password
          resource.user_id = id if @id # if user id is not yet known, force token creation via UI by not setting user_id
          resource.api_client = api_client if admin? # if user is admin, use it's own api client for creation
        end

        @personal_access_tokens << pat
        self.api_client = Runtime::API::Client.new(personal_access_token: pat.token) if use_for_api_client
        pat
      end

      # Get specific personal access token for user
      #
      # @param [Boolean] revoked
      # @param [Boolean] active
      # @return [QA::Resource::PersonalAccessToken]
      def personal_access_token(revoked: false, active: true)
        @personal_access_tokens.find { |pat| pat.revoked == revoked && pat.active == active }
      end

      # Get specific personal access tokens for user
      #
      # @param [Boolean] revoked
      # @param [Boolean] active
      # @return [Array<QA::Resource::PersonalAccessToken>]
      def personal_access_tokens(revoked: false, active: true)
        @personal_access_tokens.select { |pat| pat.revoked == revoked && pat.active == active }
      end

      # Add personal access token to user
      #
      # @param [QA::Resource::PersonalAccessToken] pat
      # @return [void]
      def add_personal_access_token(pat)
        return if @personal_access_tokens.any? { |p| p.id == pat.id }
        raise "Attempting to add token not belonging to this user" if pat.user_id != id

        @personal_access_tokens << pat
      end

      # Users can only be created by admin, use global admin api client if not explicitly set
      # Still revert to user_api_client in order to perform get operation for fetching existing user
      #
      # @return [QA::Runtime::API::Client]
      def api_client
        @api_client ||= Runtime::UserStore.admin_api_client || Runtime::UserStore.user_api_client
      end

      protected

      # Compare users by username and password
      #
      # @return [Array]
      def comparable
        [username, password]
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
# rubocop:enable Cop/UserAdmin

QA::Resource::User.prepend_mod_with("Resource::User", namespace: QA)

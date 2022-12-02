# frozen_string_literal: true

module QA
  module Runtime
    module API
      class Client
        attr_reader :address, :user

        AuthorizationError = Class.new(RuntimeError)

        def initialize(address = :gitlab, personal_access_token: nil, is_new_session: true, user: nil)
          @address = address
          @personal_access_token = personal_access_token
          @is_new_session = is_new_session
          @user = user
        end

        # Personal access token
        #
        # It is possible to set the environment variable GITLAB_QA_ACCESS_TOKEN
        # to use a specific access token rather than create one from the UI
        # unless a specific user has been passed
        #
        # @return [String]
        def personal_access_token
          @personal_access_token ||= if user.nil?
                                       Runtime::Env.personal_access_token ||= create_personal_access_token
                                     else
                                       create_personal_access_token
                                     end

          Runtime::Env.admin_personal_access_token = @personal_access_token if user&.admin? # rubocop:disable Cop/UserAdmin

          @personal_access_token
        end

        def self.as_admin
          @admin_client ||=
            if Runtime::Env.admin_personal_access_token
              Runtime::API::Client.new(
                :gitlab,
                personal_access_token: Runtime::Env.admin_personal_access_token
              )
            else
              # To return an API client that has admin access, we need a user with admin access to confirm that
              # the API client user has admin access.
              client = nil
              Flow::Login.while_signed_in_as_admin do
                admin_token = Resource::PersonalAccessToken.fabricate! do |pat|
                  pat.user = Runtime::User.admin
                end.token

                client = Runtime::API::Client.new(:gitlab, personal_access_token: admin_token)

                user = QA::Resource::User.init do |user|
                  user.username = QA::Runtime::User.admin_username
                  user.password = QA::Runtime::User.admin_password
                  user.api_client = client
                end.reload!

                unless user.admin? # rubocop: disable Cop/UserAdmin
                  raise AuthorizationError, "User '#{user.username}' is not an administrator."
                end
              end

              client
            end
        end

        private

        # Create PAT
        #
        # Use api if admin personal access token is present and skip any UI actions otherwise perform creation via UI
        #
        # @return [String]
        def create_personal_access_token
          if Runtime::Env.admin_personal_access_token
            Resource::PersonalAccessToken.fabricate_via_api! do |pat|
              pat.user = user
            end.token
          else
            signed_in_initially = Page::Main::Menu.perform(&:signed_in?)

            Page::Main::Menu.perform(&:sign_out) if @is_new_session && signed_in_initially

            token = Resource::PersonalAccessToken.fabricate! do |pat|
              pat.user = user
            end.token

            # If this is a new session, that tests that follow could fail if they
            # try to sign in without starting a new session.
            # Also, if the browser wasn't already signed in, leaving it
            # signed in could cause tests to fail when they try to sign
            # in again. For example, that would happen if a test has a
            # before(:context) block that fabricates via the API, and
            # it's the first test to run so it creates an access token
            #
            # Sign out so the tests can successfully sign in
            Page::Main::Menu.perform(&:sign_out) if @is_new_session || !signed_in_initially

            token
          end
        end
      end
    end
  end
end

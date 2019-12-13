# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :ldap_tls, :ldap_no_tls do
    describe 'LDAP Group sync' do
      include Support::Api

      before(:all) do
        # Create the sandbox group as the LDAP user. Without this the admin user
        # would own the sandbox group and then in subsequent tests the LDAP user
        # would not have enough permission to push etc.
        Resource::Sandbox.fabricate_via_api!

        # Create an admin personal access token and use it for the remaining API calls
        @original_personal_access_token = Runtime::Env.personal_access_token

        Page::Main::Menu.perform do |menu|
          menu.sign_out if menu.has_personal_area?
        end

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_admin_credentials)

        Runtime::Env.personal_access_token = Resource::PersonalAccessToken.fabricate!.access_token
        Page::Main::Menu.perform(&:sign_out)
      end

      after(:all) do
        # Restore the original personal access token so that subsequent tests
        # don't perform API calls as an admin user while logged in as a non-root
        # LDAP user
        Runtime::Env.personal_access_token = @original_personal_access_token
      end

      context 'using group cn method' do
        let(:ldap_users) do
          [
              {
                  name: 'ENG User 1',
                  username: 'enguser1',
                  email: 'enguser1@example.org',
                  provider: 'ldapmain',
                  extern_uid: 'uid=enguser1,ou=people,ou=global groups,dc=example,dc=org'
              },
              {
                  name: 'ENG User 2',
                  username: 'enguser2',
                  email: 'enguser2@example.org',
                  provider: 'ldapmain',
                  extern_uid: 'uid=enguser2,ou=people,ou=global groups,dc=example,dc=org'
              },
              {
                  name: 'ENG User 3',
                  username: 'enguser3',
                  email: 'enguser3@example.org',
                  provider: 'ldapmain',
                  extern_uid: 'uid=enguser3,ou=people,ou=global groups,dc=example,dc=org'
              }
          ]
        end
        let(:owner_user) { 'enguser1' }
        let(:sync_users) { ['ENG User 2', 'ENG User 3'] }

        before do
          create_users_via_api(ldap_users)
          group = create_group_and_add_user_via_api(owner_user, 'Synched-engineering-group')
          signin_and_visit_group_as_user(owner_user, group)

          EE::Page::Group::Menu.perform(&:go_to_ldap_sync_settings)

          EE::Page::Group::Settings::LDAPSync.perform do |page|
            page.set_sync_method('LDAP Group cn')
            page.set_group_cn('Engineering')
            page.click_add_sync_button
          end

          EE::Page::Group::Menu.perform(&:click_group_members_item)
        end

        it 'has LDAP users synced' do
          verify_users_synced(sync_users)
        end
      end

      context 'user filter method' do
        let(:ldap_users) do
          [
              {
                  name: 'HR User 1',
                  username: 'hruser1',
                  email: 'hruser1@example.org',
                  provider: 'ldapmain',
                  extern_uid: 'uid=hruser1,ou=people,ou=global groups,dc=example,dc=org'
              },
              {
                  name: 'HR User 2',
                  username: 'hruser2',
                  email: 'hruser2@example.org',
                  provider: 'ldapmain',
                  extern_uid: 'uid=hruser2,ou=people,ou=global groups,dc=example,dc=org'
              },
              {
                  name: 'HR User 3',
                  username: 'hruser3',
                  email: 'hruser3@example.org',
                  provider: 'ldapmain',
                  extern_uid: 'uid=hruser3,ou=people,ou=global groups,dc=example,dc=org'
              }
          ]
        end
        let(:owner_user) { 'hruser1' }
        let(:sync_users) { ['HR User 2', 'HR User 3'] }

        before do
          create_users_via_api(ldap_users)
          group = create_group_and_add_user_via_api(owner_user, 'Synched-human-resources-group')
          signin_and_visit_group_as_user(owner_user, group)

          EE::Page::Group::Menu.perform(&:go_to_ldap_sync_settings)

          EE::Page::Group::Settings::LDAPSync.perform do |page|
            page.set_user_filter('(&(objectClass=person)(cn=HR*))')
            page.click_add_sync_button
          end

          EE::Page::Group::Menu.perform(&:click_group_members_item)
        end

        it 'has LDAP users synced' do
          verify_users_synced(sync_users)
        end
      end

      def create_users_via_api(users)
        users.each do |user|
          Resource::User.fabricate_via_api! do |resource|
            resource.username = user[:username]
            resource.name = user[:name]
            resource.email = user[:email]
            resource.extern_uid = user[:extern_uid]
            resource.provider = user[:provider]
          end
        end
      end

      def add_user_to_group_via_api(user, group)
        api_client = Runtime::API::Client.new(:gitlab)
        response = get Runtime::API::Request.new(api_client, "/users?username=#{user}").url
        post Runtime::API::Request.new(api_client, group.api_members_path).url, { user_id: parse_body(response).first[:id], access_level: '50' }
      end

      def create_group_and_add_user_via_api(user_name, group_name)
        group = Resource::Group.fabricate_via_api! do |resource|
          resource.path = "#{group_name}-#{SecureRandom.hex(4)}"
        end

        add_user_to_group_via_api(user_name, group)

        group
      end

      def signin_and_visit_group_as_user(user_name, group)
        user = Struct.new(:ldap_username, :ldap_password).new(user_name, 'password')

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform do |login_page|
          login_page.sign_in_using_ldap_credentials(user)
        end

        group.visit!
      end

      def verify_users_synced(expected_users)
        EE::Page::Group::Members.perform do |page|
          page.click_sync_now
          users_synchronised = page.retry_until(reload: true) do
            expected_users.map { |user| page.has_content?(user) }.all?
          end
          expect(users_synchronised).to be_truthy
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :group_saml do
    describe 'Group SAML SSO' do
      include Support::Api

      before(:all) do
        @group = Resource::Sandbox.fabricate!
      end

      before do
        unless Page::Main::Menu.perform(&:has_personal_area?)

          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform(&:sign_in_using_credentials)

        end

        @group.visit!
      end

      it 'User logs in to group with SAML SSO' do
        EE::Page::Group::Menu.perform(&:go_to_saml_sso_group_settings)

        EE::Page::Group::Settings::SamlSSO.perform do |page|
          page.set_id_provider_sso_url(QA::EE::Runtime::Saml.idp_sso_url)
          page.set_cert_fingerprint(QA::EE::Runtime::Saml.idp_certificate_fingerprint)
          page.click_save_changes

          page.click_user_login_url_link
        end

        EE::Page::Group::SamlSSOSignIn.perform(&:click_signin)

        login_to_idp_if_required_and_expect_success

        EE::Page::Group::Menu.perform(&:go_to_saml_sso_group_settings)

        EE::Page::Group::Settings::SamlSSO.perform(&:click_user_login_url_link)

        EE::Page::Group::SamlSSOSignIn.perform(&:click_signin)

        expect(page).to have_content("Already signed in with SAML for #{Runtime::Env.sandbox_name}")
      end

      it 'Lets group admin test settings' do
        EE::Page::Group::Menu.perform(&:go_to_saml_sso_group_settings)

        EE::Page::Group::Settings::SamlSSO.perform do |page|
          page.set_id_provider_sso_url(QA::EE::Runtime::Saml.idp_sso_url)
          page.set_cert_fingerprint(QA::EE::Runtime::Saml.idp_certificate_fingerprint)
          page.click_save_changes

          page.click_test_button
        end

        login_to_idp_if_required_and_expect_success

        expect(page).to have_content("Test SAML SSO")
      end

      context 'Enforced SSO' do
        before do
          Runtime::Feature.enable("enforced_sso")
          Runtime::Feature.enable("enforced_sso_requires_session")
        end

        it 'user clones and pushes to project within a group using Git HTTP' do
          branch_name = "new_branch"

          user = Resource::User.new.tap do |user|
            user.name = 'SAML Developer'
            user.username = 'saml_dev'
          end

          create_user_via_api(user)

          add_user_to_group_via_api(user.username, @group, '30')

          EE::Page::Group::Menu.perform(&:go_to_saml_sso_group_settings)

          EE::Page::Group::Settings::SamlSSO.perform do |page|
            page.enforce_sso
            page.set_id_provider_sso_url(QA::EE::Runtime::Saml.idp_sso_url)
            page.set_cert_fingerprint(QA::EE::Runtime::Saml.idp_certificate_fingerprint)

            page.click_save_changes
          end

          @project = Resource::Project.fabricate! do |project|
            project.name = 'project-in-saml-enforced-group'
            project.description = 'project in SAML enforced gorup for git clone test'
            project.group = @group
            project.initialize_with_readme = true
          end

          @project.visit!

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = @project
            push.branch_name = branch_name
            push.user = user
          end
        end
      end
      after(:all) do
        remove_group(@group)
      end
    end

    def login_to_idp_if_required_and_expect_success
      Vendor::SAMLIdp::Page::Login.perform { |login_page| login_page.login_if_required }
      expect(page).to have_content("SAML for #{Runtime::Env.sandbox_name} was added to your connected accounts")
                        .or have_content("Already signed in with SAML for #{Runtime::Env.sandbox_name}")
    end

    def remove_group(group)
      api_client = Runtime::API::Client.new(:gitlab)
      delete Runtime::API::Request.new(api_client, "/groups/#{group.path}").url
    end

    def create_user_via_api(user)
      Resource::User.fabricate_via_api! do |resource|
        resource.username = user.username
        resource.name = user.name
        resource.email = user.email
        resource.password = user.password
      end
    end

    def add_user_to_group_via_api(username, group, access_level)
      api_client = Runtime::API::Client.new(:gitlab)
      response = get Runtime::API::Request.new(api_client, "/users?username=#{username}").url
      post Runtime::API::Request.new(api_client, group.api_members_path).url, { user_id: parse_body(response).first[:id], access_level: access_level }
    end
  end
end

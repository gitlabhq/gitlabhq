# frozen_string_literal: true

module QA
  context :manage, :orchestrated, :group_saml do
    describe 'Group SAML SSO' do
      it 'User logs in to group with SAML SSO' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.act { sign_in_using_credentials }

        Factory::Resource::Sandbox.fabricate!

        EE::Page::Group::Menu.act { go_to_saml_sso_group_settings }

        EE::Page::Group::Settings::SamlSSO.act do
          set_id_provider_sso_url("https://#{QA::Runtime::Env.simple_saml_hostname || 'localhost'}:8443/simplesaml/saml2/idp/SSOService.php")
          set_cert_fingerprint('119b9e027959cdb7c662cfd075d9e2ef384e445f')
          click_save_changes
          click_user_login_url_link
        end

        EE::Page::Group::SamlSSOSignIn.act { click_signin }

        Vendor::SAMLIdp::Page::Login.act { login }

        expect(page).to have_content("SAML for #{Runtime::Env.sandbox_name} was added to your connected accounts")

        EE::Page::Group::Menu.act { go_to_saml_sso_group_settings }

        EE::Page::Group::Settings::SamlSSO.act { click_user_login_url_link }

        EE::Page::Group::SamlSSOSignIn.act { click_signin }

        expect(page).to have_content("Signed in with SAML for #{Runtime::Env.sandbox_name}")
      end
    end
  end
end

require 'spec_helper'

feature 'SAML provider settings' do
  include CookieHelper

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:callback_path) { "/groups/#{group.path}/-/saml/callback" }

  before do
    set_beta_cookie
    stub_config_setting(url: 'https://localhost')
    stub_saml_config
    group.add_owner(user)
  end

  def set_beta_cookie
    set_cookie('enable_group_saml', 'true')
  end

  def submit
    click_button('Save changes')
  end

  def stub_saml_config
    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
  end

  describe 'settings' do
    before do
      sign_in(user)
    end

    it 'displays required information to user' do
      visit group_saml_providers_path(group)

      within '.saml-settings' do
        expect(find_field('Assertion consumer service URL').value).to eq group.build_saml_provider.assertion_consumer_service_url
        expect(find_field('Identifier').value).to eq "https://localhost/groups/#{group.full_path}"
      end
    end

    it 'allows creation of new provider' do
      visit group_saml_providers_path(group)

      fill_in 'Identity provider single sign on URL', with: 'https://localhost:9999/adfs/ls'
      fill_in 'Certificate fingerprint', with: 'aa:bb:cc:dd:ee:ff:11:22:33:44:55:66:77:88:99:0a:1b:2c:3d:00'

      expect { submit }.to change(SamlProvider, :count).by(1)
    end

    it 'shows errors if fields missing' do
      visit group_saml_providers_path(group)

      submit

      expect(find('#error_explanation')).to have_text("Certificate fingerprint can't be blank")
    end

    context 'with existing SAML provider' do
      let!(:saml_provider) { create(:saml_provider, group: group) }

      it 'allows provider to be disabled' do
        visit group_saml_providers_path(group)

        find('input#saml_provider_enabled').click

        expect { submit }.to change { saml_provider.reload.enabled }.to false
      end

      it 'displays user login URL' do
        visit group_saml_providers_path(group)

        login_url = find('label', text: 'GitLab single sign on URL').find('~* a').text

        expect(login_url).to end_with "/groups/#{group.full_path}/-/saml/sso"
      end
    end
  end

  describe '#sso' do
    context 'with no SAML provider configured' do
      it 'acts as if the group was not found' do
        visit sso_group_saml_providers_path(group)

        expect(current_path).to eq(new_user_session_path)
      end

      context 'as owner' do
        before do
          sign_in(user)
        end

        it 'redirects to settings page with warning' do
          visit sso_group_saml_providers_path(group)

          expect(current_path).to eq group_saml_providers_path(group)
          expect(page).to have_content 'SAML sign on has not been configured for this group'
        end
      end
    end

    context 'with existing SAML provider' do
      let!(:saml_provider) { create(:saml_provider, group: group) }

      before do
        allow_any_instance_of(OmniAuth::Strategies::GroupSaml).to receive(:callback_url) { callback_path }
      end

      context 'when not signed in' do
        it "doesn't show sso page" do
          visit sso_group_saml_providers_path(group)

          expect(current_path).to eq(new_user_session_path)
        end
      end

      context 'when signed in' do
        before do
          sign_in(user)

          visit sso_group_saml_providers_path(group)
        end

        it 'Sign in button redirects to auth flow and back to group' do
          click_link 'Sign in with Single Sign-On'

          expect(current_path).to eq callback_path
        end
      end

      context 'for a private group' do
        let(:group) { create(:group, :private) }

        context 'when not signed in' do
          it "doesn't show sso page" do
            visit sso_group_saml_providers_path(group)

            expect(current_path).to eq(new_user_session_path)
          end
        end

        context 'when signed in' do
          before do
            sign_in(user)

            visit sso_group_saml_providers_path(group)
          end

          it 'displays sign in button' do
            expect(current_path).to eq sso_group_saml_providers_path(group)

            within '.login-box' do
              expect(page).to have_link 'Sign in with Single Sign-On'
            end
          end

          it "doesn't leak group information" do
            expect(page).not_to have_selector('.group-avatar')
            expect(page).not_to have_selector('.nav-sidebar')
          end
        end
      end
    end
  end
end

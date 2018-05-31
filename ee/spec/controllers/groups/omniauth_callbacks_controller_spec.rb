require 'spec_helper'

describe Groups::OmniauthCallbacksController do
  include LoginHelpers
  include ForgeryProtection

  let(:uid) { 'my-uid' }
  let(:user) { create(:user) }
  let(:provider) { :group_saml }
  let(:group) { create(:group, :private) }
  let!(:saml_provider) { create(:saml_provider, group: group) }

  before do
    stub_licensed_features(group_saml: true)
  end

  def linked_accounts
    Identity.where(user: user, extern_uid: uid, provider: provider)
  end

  context "when request hasn't been validated by omniauth middleware" do
    it "prevents authentication" do
      sign_in(user)

      expect do
        post provider, group_id: group
      end.to raise_error(AbstractController::ActionNotFound)
    end
  end

  context "valid credentials" do
    before do
      mock_auth_hash(provider, uid, user.email)
      stub_omniauth_provider(provider, context: request)
    end

    context "when signed in" do
      before do
        sign_in(user)
      end

      context "and identity already linked" do
        let(:user) { create(:omniauth_user, extern_uid: uid, provider: provider, saml_provider: saml_provider) }

        it "redirects to RelayState" do
          post provider, group_id: group, RelayState: '/explore'

          expect(response).to redirect_to('/explore')
        end

        it "displays a flash message verifying group sign in" do
          post provider, group_id: group

          expect(flash[:notice]).to start_with "Signed in with SAML"
        end

        it 'uses existing linked identity' do
          expect { post provider, group_id: group }.not_to change(linked_accounts, :count)
        end

        it 'skips authenticity token based forgery protection' do
          with_forgery_protection do
            post provider, group_id: group

            expect(response).not_to be_client_error
            expect(response).not_to be_server_error
          end
        end
      end

      context 'oauth already linked to another account' do
        before do
          create(:omniauth_user, extern_uid: uid, provider: provider, saml_provider: saml_provider)
        end

        it 'displays warning to user' do
          post provider, group_id: group

          expect(flash[:notice]).to match(/has already been taken*/)
        end
      end

      context "and identity hasn't been linked" do
        it "links the identity" do
          post provider, group_id: group

          expect(group).to be_member(user)
        end

        it "redirects to RelayState" do
          post provider, group_id: group, RelayState: '/explore'

          expect(response).to redirect_to('/explore')
        end

        it "displays a flash indicating the account has been linked" do
          post provider, group_id: group

          expect(flash[:notice]).to match(/SAML for .* was added/)
        end
      end
    end

    context "when not signed in" do
      it "redirects to sign in page" do
        post provider, group_id: group

        expect(response).to redirect_to(new_user_session_path)
      end

      it "informs users that they need to sign in to the GitLab instance first" do
        post provider, group_id: group

        expect(flash[:notice]).to start_with("You must be signed in")
      end
    end
  end

  describe "#failure" do
    include RoutesHelpers

    def fake_error_callback_route
      fake_routes do
        post '/groups/:group_id/-/saml/callback', to: 'groups/omniauth_callbacks#failure'
      end
    end

    def stub_certificate_error
      strategy = OmniAuth::Strategies::GroupSaml.new(nil)
      exception = OneLogin::RubySaml::ValidationError.new("Fingerprint mismatch")
      stub_omniauth_failure(strategy, :invalid_ticket, exception)
    end

    before do
      fake_error_callback_route
      stub_certificate_error
      set_devise_mapping(context: @request)
    end

    context "not signed in" do
      it "doesn't disclose group existence" do
        expect do
          post :failure, group_id: group
        end.to raise_error(ActionController::RoutingError)
      end

      context "group doesn't exist" do
        it "doesn't disclose group non-existence" do
          expect do
            post :failure, group_id: 'not-a-group'
          end.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context "with access" do
      before do
        sign_in(user)
      end

      it "has descriptive error flash" do
        post :failure, group_id: group

        expect(flash[:alert]).to start_with("Unable to sign you in to the group with SAML due to")
        expect(flash[:alert]).to include("Fingerprint mismatch")
      end

      it "redirects back go the SSO page" do
        post :failure, group_id: group

        expect(response).to redirect_to(sso_group_saml_providers_path)
      end
    end

    context "with access to SAML settings for the group" do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it "redirects to the settings page" do
        post :failure, group_id: group

        expect(response).to redirect_to(group_saml_providers_path)
      end
    end
  end
end

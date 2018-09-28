require "spec_helper"

describe AuthHelper do
  describe "button_based_providers" do
    it 'returns all enabled providers from devise' do
      allow(helper).to receive(:auth_providers) { [:twitter, :github] }
      expect(helper.button_based_providers).to include(*[:twitter, :github])
    end

    it 'does not return ldap provider' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapmain] }
      expect(helper.button_based_providers).to include(:twitter)
    end

    it 'returns empty array' do
      allow(helper).to receive(:auth_providers) { [] }
      expect(helper.button_based_providers).to eq([])
    end
  end

  describe "providers_for_base_controller" do
    it 'returns all enabled providers from devise' do
      allow(helper).to receive(:auth_providers) { [:twitter, :github] }
      expect(helper.providers_for_base_controller).to include(*[:twitter, :github])
    end

    it 'excludes ldap providers' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapmain] }
      expect(helper.providers_for_base_controller).not_to include(:ldapmain)
    end
  end

  describe "form_based_providers" do
    it 'includes LDAP providers' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapmain] }
      expect(helper.form_based_providers).to eq %i(ldapmain)
    end

    it 'includes crowd provider' do
      allow(helper).to receive(:auth_providers) { [:twitter, :crowd] }
      expect(helper.form_based_providers).to eq %i(crowd)
    end
  end

  describe 'enabled_button_based_providers' do
    before do
      allow(helper).to receive(:auth_providers) { [:twitter, :github] }
    end

    context 'all providers are enabled to sign in' do
      it 'returns all the enabled providers from settings' do
        expect(helper.enabled_button_based_providers).to include('twitter', 'github')
      end
    end

    context 'GitHub OAuth sign in is disabled from application setting' do
      it "doesn't return github as provider" do
        stub_application_setting(
          disabled_oauth_sign_in_sources: ['github']
        )

        expect(helper.enabled_button_based_providers).to include('twitter')
        expect(helper.enabled_button_based_providers).not_to include('github')
      end
    end
  end

  describe 'button_based_providers_enabled?' do
    before do
      allow(helper).to receive(:auth_providers) { [:twitter, :github] }
    end

    context 'button based providers enabled' do
      it 'returns true' do
        expect(helper.button_based_providers_enabled?).to be true
      end
    end

    context 'all the button based providers are disabled via application_setting' do
      it 'returns false' do
        stub_application_setting(
          disabled_oauth_sign_in_sources: %w(github twitter)
        )

        expect(helper.button_based_providers_enabled?).to be false
      end
    end
  end

  describe 'unlink_allowed?' do
    [:saml, :cas3].each do |provider|
      it "returns true if the provider is #{provider}" do
        expect(helper.unlink_allowed?(provider)).to be false
      end
    end

    [:twitter, :facebook, :google_oauth2, :gitlab, :github, :bitbucket, :crowd, :auth0, :authentiq].each do |provider|
      it "returns false if the provider is #{provider}" do
        expect(helper.unlink_allowed?(provider)).to be true
      end
    end
  end
end

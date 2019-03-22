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

  describe 'form_based_auth_provider_has_active_class?' do
    it 'selects main LDAP server' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapprimary, :ldapsecondary, :kerberos] }
      expect(helper.form_based_auth_provider_has_active_class?(:twitter)).to be(false)
      expect(helper.form_based_auth_provider_has_active_class?(:ldapprimary)).to be(true)
      expect(helper.form_based_auth_provider_has_active_class?(:ldapsecondary)).to be(false)
      expect(helper.form_based_auth_provider_has_active_class?(:kerberos)).to be(false)
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

  describe '#link_provider_allowed?' do
    let(:policy) { instance_double('IdentityProviderPolicy') }
    let(:current_user) { instance_double('User') }
    let(:provider) { double }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(IdentityProviderPolicy).to receive(:new).with(current_user, provider).and_return(policy)
    end

    it 'delegates to identity provider policy' do
      allow(policy).to receive(:can?).with(:link).and_return('policy_link_result')

      expect(helper.link_provider_allowed?(provider)).to eq 'policy_link_result'
    end
  end

  describe '#unlink_provider_allowed?' do
    let(:policy) { instance_double('IdentityProviderPolicy') }
    let(:current_user) { instance_double('User') }
    let(:provider) { double }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(IdentityProviderPolicy).to receive(:new).with(current_user, provider).and_return(policy)
    end

    it 'delegates to identity provider policy' do
      allow(policy).to receive(:can?).with(:unlink).and_return('policy_unlink_result')

      expect(helper.unlink_provider_allowed?(provider)).to eq 'policy_unlink_result'
    end
  end
end

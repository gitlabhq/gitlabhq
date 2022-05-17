# frozen_string_literal: true

require "spec_helper"

RSpec.describe AuthHelper do
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

  describe 'any_form_based_providers_enabled?' do
    before do
      allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
    end

    it 'detects form-based providers' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapmain] }
      expect(helper.any_form_based_providers_enabled?).to be(true)
    end

    it 'ignores ldap providers when ldap web sign in is disabled' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapmain] }
      allow(helper).to receive(:ldap_sign_in_enabled?).and_return(false)
      expect(helper.any_form_based_providers_enabled?).to be(false)
    end
  end

  describe 'enabled_button_based_providers' do
    before do
      allow(helper).to receive(:auth_providers) { [:twitter, :github, :google_oauth2, :openid_connect] }
    end

    context 'all providers are enabled to sign in' do
      it 'returns all the enabled providers from settings in expected order' do
        expect(helper.enabled_button_based_providers).to match(%w[google_oauth2 github twitter openid_connect])
      end

      it 'puts google and github in the beginning' do
        expect(helper.enabled_button_based_providers.first).to eq('google_oauth2')
        expect(helper.enabled_button_based_providers.second).to eq('github')
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

  describe 'popular_enabled_button_based_providers' do
    it 'returns the intersection set of popular & enabled providers', :aggregate_failures do
      allow(helper).to receive(:enabled_button_based_providers) { %w(twitter github google_oauth2) }

      expect(helper.popular_enabled_button_based_providers).to eq(%w(github google_oauth2))

      allow(helper).to receive(:enabled_button_based_providers) { %w(google_oauth2 bitbucket) }

      expect(helper.popular_enabled_button_based_providers).to eq(%w(google_oauth2))

      allow(helper).to receive(:enabled_button_based_providers) { %w(bitbucket) }

      expect(helper.popular_enabled_button_based_providers).to be_empty
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

  describe '#provider_has_icon?' do
    it 'returns true for defined providers' do
      expect(helper.provider_has_icon?(described_class::PROVIDERS_WITH_ICONS.sample)).to eq true
    end

    it 'returns false for undefined providers' do
      expect(helper.provider_has_icon?('test')).to be_falsey
    end

    context 'when provider is defined by config' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:icon_for).with('test').and_return('icon')
      end

      it 'returns true' do
        expect(helper.provider_has_icon?('test')).to be_truthy
      end
    end

    context 'when provider is not defined by config' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:icon_for).with('test').and_return(nil)
      end

      it 'returns true' do
        expect(helper.provider_has_icon?('test')).to be_falsey
      end
    end
  end

  describe '#allow_admin_mode_password_authentication_for_web?' do
    let(:user) { create(:user) }

    subject { helper.allow_admin_mode_password_authentication_for_web? }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it { is_expected.to be(true) }

    context 'when password authentication for web is disabled' do
      before do
        stub_application_setting(password_authentication_enabled_for_web: false)
      end

      it { is_expected.to be(false) }
    end

    context 'when current_user is an ldap user' do
      before do
        allow(user).to receive(:ldap_user?).and_return(true)
      end

      it { is_expected.to be(false) }
    end

    context 'when user got password automatically set' do
      before do
        user.update_attribute(:password_automatically_set, true)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#auth_active?' do
    let(:user) { create(:user) }

    def auth_active?
      helper.auth_active?(provider)
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'for atlassian_oauth2 provider' do
      let_it_be(:provider) { :atlassian_oauth2 }

      it 'returns true when present' do
        create(:atlassian_identity, user: user)

        expect(auth_active?).to be true
      end

      it 'returns false when not present' do
        expect(auth_active?).to be false
      end
    end

    context 'for other omniauth providers' do
      let_it_be(:provider) { 'google_oauth2' }

      it 'returns true when present' do
        create(:identity, provider: provider, user: user)

        expect(auth_active?).to be true
      end

      it 'returns false when not present' do
        expect(auth_active?).to be false
      end
    end
  end

  describe '#google_tag_manager_enabled?' do
    let(:is_gitlab_com) { true }
    let(:user) { nil }

    before do
      allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject(:google_tag_manager_enabled) { helper.google_tag_manager_enabled? }

    context 'when not on gitlab.com' do
      let(:is_gitlab_com) { false }

      it { is_expected.to eq(false) }
    end

    context 'regular and nonce versions' do
      using RSpec::Parameterized::TableSyntax

      where(:gtm_nonce_enabled, :gtm_key) do
        false | 'google_tag_manager_id'
        true  | 'google_tag_manager_nonce_id'
      end

      with_them do
        before do
          stub_feature_flags(gtm_nonce: gtm_nonce_enabled)
          stub_config(extra: { gtm_key => 'key' })
        end

        context 'on gitlab.com and a key set without a current user' do
          it { is_expected.to be_truthy }
        end

        context 'when no key is set' do
          before do
            stub_config(extra: {})
          end

          it { is_expected.to eq(false) }
        end
      end
    end
  end

  describe '#google_tag_manager_id' do
    subject(:google_tag_manager_id) { helper.google_tag_manager_id }

    before do
      stub_config(extra: { 'google_tag_manager_nonce_id': 'nonce', 'google_tag_manager_id': 'gtm' })
    end

    context 'when google tag manager is disabled' do
      before do
        allow(helper).to receive(:google_tag_manager_enabled?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when google tag manager is enabled' do
      before do
        allow(helper).to receive(:google_tag_manager_enabled?).and_return(true)
      end

      context 'when nonce feature flag is enabled' do
        it { is_expected.to eq('nonce') }
      end

      context 'when nonce feature flag is disabled' do
        before do
          stub_feature_flags(gtm_nonce: false)
        end

        it { is_expected.to eq('gtm') }
      end
    end
  end

  describe '#auth_app_owner_text' do
    shared_examples 'generates text with the correct info' do
      it 'includes the name of the application owner' do
        auth_app_owner_text = helper.auth_app_owner_text(owner)

        expect(auth_app_owner_text).to include(owner.name)
        expect(auth_app_owner_text).to include(path_to_owner)
      end
    end

    context 'when owner is a user' do
      let_it_be(:owner) { create(:user) }

      let(:path_to_owner) { user_path(owner) }

      it_behaves_like 'generates text with the correct info'
    end

    context 'when owner is a group' do
      let_it_be(:owner) { create(:group) }

      let(:path_to_owner) { user_path(owner) }

      it_behaves_like 'generates text with the correct info'
    end

    context 'when the user is missing' do
      it 'returns nil' do
        expect(helper.auth_app_owner_text(nil)).to be(nil)
      end
    end
  end

  describe '#auth_strategy_class' do
    subject(:auth_strategy_class) { helper.auth_strategy_class(name) }

    context 'when configuration specifies no provider' do
      let(:name) { 'does_not_exist' }

      before do
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([])
      end

      it 'returns false' do
        expect(auth_strategy_class).to be_falsey
      end
    end

    context 'when configuration specifies a provider with args but without strategy_class' do
      let(:name) { 'google_oauth2' }
      let(:provider) do
        Struct.new(:name, :args).new(
          name,
          'app_id' => 'YOUR_APP_ID'
        )
      end

      before do
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
      end

      it 'returns false' do
        expect(auth_strategy_class).to be_falsey
      end
    end

    context 'when configuration specifies a provider with args and strategy_class' do
      let(:name) { 'provider1' }
      let(:strategy) { 'OmniAuth::Strategies::LDAP' }
      let(:provider) do
        Struct.new(:name, :args).new(
          name,
          'strategy_class' => strategy
        )
      end

      before do
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
      end

      it 'returns the class' do
        expect(auth_strategy_class).to eq(strategy)
      end
    end

    context 'when configuration specifies another provider with args and another strategy_class' do
      let(:name) { 'provider1' }
      let(:strategy) { 'OmniAuth::Strategies::LDAP' }
      let(:provider) do
        Struct.new(:name, :args).new(
          'another_name',
          'strategy_class' => strategy
        )
      end

      before do
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([provider])
      end

      it 'returns false' do
        expect(auth_strategy_class).to be_falsey
      end
    end
  end

  describe '#saml_providers' do
    subject(:saml_providers) { helper.saml_providers }

    let(:saml_strategy) { 'OmniAuth::Strategies::SAML' }

    let(:saml_provider_1_name) { 'saml_provider_1' }
    let(:saml_provider_1) do
      Struct.new(:name, :args).new(
        saml_provider_1_name,
        'strategy_class' => saml_strategy
      )
    end

    let(:saml_provider_2_name) { 'saml_provider_2' }
    let(:saml_provider_2) do
      Struct.new(:name, :args).new(
        saml_provider_2_name,
        'strategy_class' => saml_strategy
      )
    end

    let(:ldap_provider_name) { 'ldap_provider' }
    let(:ldap_strategy) { 'OmniAuth::Strategies::LDAP' }
    let(:ldap_provider) do
      Struct.new(:name, :args).new(
        ldap_provider_name,
        'strategy_class' => ldap_strategy
      )
    end

    let(:google_oauth2_provider_name) { 'google_oauth2' }
    let(:google_oauth2_provider) do
      Struct.new(:name, :args).new(
        google_oauth2_provider_name,
        'app_id' => 'YOUR_APP_ID'
      )
    end

    context 'when SAML is enabled without specifying a strategy class' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
      end

      it 'returns the saml provider' do
        expect(saml_providers).to match_array([:saml])
      end
    end

    context 'when configuration specifies no provider' do
      before do
        allow(Devise).to receive(:omniauth_providers).and_return([])
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([])
      end

      it 'returns an empty list' do
        expect(saml_providers).to be_empty
      end
    end

    context 'when configuration specifies a provider with a SAML strategy_class' do
      before do
        allow(Devise).to receive(:omniauth_providers).and_return([saml_provider_1_name])
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([saml_provider_1])
      end

      it 'returns the provider' do
        expect(saml_providers).to match_array([saml_provider_1_name])
      end
    end

    context 'when configuration specifies two providers with a SAML strategy_class' do
      before do
        allow(Devise).to receive(:omniauth_providers).and_return([saml_provider_1_name, saml_provider_2_name])
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([saml_provider_1, saml_provider_2])
      end

      it 'returns the provider' do
        expect(saml_providers).to match_array([saml_provider_1_name, saml_provider_2_name])
      end
    end

    context 'when configuration specifies a provider with a non-SAML strategy_class' do
      before do
        allow(Devise).to receive(:omniauth_providers).and_return([ldap_provider_name])
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([ldap_provider])
      end

      it 'returns an empty list' do
        expect(saml_providers).to be_empty
      end
    end

    context 'when configuration specifies four providers but only two with SAML strategy_class' do
      before do
        allow(Devise).to receive(:omniauth_providers).and_return([saml_provider_1_name, ldap_provider_name, saml_provider_2_name, google_oauth2_provider_name])
        allow(Gitlab.config.omniauth).to receive(:providers).and_return([saml_provider_1, ldap_provider, saml_provider_2, google_oauth2_provider])
      end

      it 'returns the provider' do
        expect(saml_providers).to match_array([saml_provider_1_name, saml_provider_2_name])
      end
    end
  end
end

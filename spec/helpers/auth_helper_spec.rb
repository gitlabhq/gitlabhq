# frozen_string_literal: true

require "spec_helper"

RSpec.describe AuthHelper, feature_category: :system_access do
  include LoginHelpers

  describe "#enabled_button_based_providers_for_signup" do
    [[true, %w[github gitlab]],
      [false, []],
      [['github'], ['github']],
      [[], []]].each do |(allow_single_sign_on, result)|
      context "when allow_single_sign_on is #{allow_single_sign_on}" do
        before do
          allow(helper).to receive(:enabled_button_based_providers) { %w[github gitlab] }
          stub_omniauth_config(allow_single_sign_on: allow_single_sign_on)
        end

        it "returns #{result}" do
          expect(helper.enabled_button_based_providers_for_signup).to eq(result)
        end
      end
    end
  end

  describe "#signup_button_based_providers_enabled?" do
    [[true, true, true],
      [true, ['github'], true],
      [false, true, false],
      [true, false, false],
      [true, [], false]].each do |(omniauth_enable, allow_single_sign_on, result)|
      context "when omniauth is #{omniauth_enable} and allow_single_sign_on is #{allow_single_sign_on}" do
        before do
          allow(Gitlab::Auth).to receive(:omniauth_enabled?).and_return(omniauth_enable)
          stub_omniauth_config(allow_single_sign_on: allow_single_sign_on)
        end

        it "returns #{result}" do
          expect(helper.signup_button_based_providers_enabled?).to eq(result)
        end
      end
    end
  end

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
      expect(helper.form_based_providers).to eq %i[ldapmain]
    end

    it 'includes crowd provider' do
      allow(helper).to receive(:auth_providers) { [:twitter, :crowd] }
      expect(helper.form_based_providers).to eq %i[crowd]
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
      allow(helper).to receive(:enabled_button_based_providers) { %w[twitter github google_oauth2] }

      expect(helper.popular_enabled_button_based_providers).to eq(%w[github google_oauth2])

      allow(helper).to receive(:enabled_button_based_providers) { %w[google_oauth2 bitbucket] }

      expect(helper.popular_enabled_button_based_providers).to eq(%w[google_oauth2])

      allow(helper).to receive(:enabled_button_based_providers) { %w[bitbucket] }

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
          disabled_oauth_sign_in_sources: %w[github twitter]
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
        expect(helper.auth_app_owner_text(nil)).to be('An administrator added this OAuth application ')
      end
    end
  end

  describe '#saml_providers' do
    subject(:saml_providers) { helper.saml_providers }

    let(:saml_strategy) { 'OmniAuth::Strategies::SAML' }

    let(:saml_provider_1_name) { 'saml' }
    let(:saml_provider_1) do
      Struct.new(:name, :args).new(
        saml_provider_1_name,
        {}
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
        stub_omniauth_config(providers: [saml_provider_1])
      end

      it 'returns the saml provider' do
        expect(saml_providers).to match_array([:saml])
      end
    end

    context 'when configuration specifies no provider' do
      before do
        stub_omniauth_config(providers: [])
      end

      it 'returns an empty list' do
        expect(saml_providers).to be_empty
      end
    end

    context 'when configuration specifies a provider with a SAML strategy_class' do
      before do
        stub_omniauth_config(providers: [saml_provider_1])
      end

      it 'returns the provider' do
        expect(saml_providers).to match_array([saml_provider_1_name.to_sym])
      end
    end

    context 'when configuration specifies two providers with a SAML strategy_class' do
      before do
        stub_omniauth_config(providers: [saml_provider_1, saml_provider_2])
      end

      it 'returns the provider' do
        expect(saml_providers).to match_array([saml_provider_1_name.to_sym, saml_provider_2_name.to_sym])
      end
    end

    context 'when configuration specifies a provider with a non-SAML strategy_class' do
      before do
        stub_omniauth_config(providers: [ldap_provider])
      end

      it 'returns an empty list' do
        expect(saml_providers).to be_empty
      end
    end

    context 'when configuration specifies four providers but only two with SAML strategy_class' do
      before do
        stub_omniauth_config(providers: [saml_provider_1, ldap_provider, saml_provider_2, google_oauth2_provider])
      end

      it 'returns the provider' do
        expect(saml_providers).to match_array([saml_provider_1_name.to_sym, saml_provider_2_name.to_sym])
      end
    end
  end

  describe '#oidc_providers' do
    subject(:oidc_providers) { helper.oidc_providers }

    let(:oidc_strategy) { 'OmniAuth::Strategies::OpenIDConnect' }

    let(:oidc_provider_1_name) { 'openid_connect' }
    let(:oidc_provider_1) do
      Struct.new(:name, :args).new(
        oidc_provider_1_name,
        {}
      )
    end

    let(:oidc_provider_2_name) { 'openid_connect2' }
    let(:oidc_provider_2) do
      Struct.new(:name, :args).new(
        oidc_provider_2_name,
        'strategy_class' => oidc_strategy
      )
    end

    let(:oidc_provider_3_name) { 'openid_connect3' }
    let(:oidc_provider_3) do
      Struct.new(:name, :args).new(
        oidc_provider_3_name,
        'strategy_class' => oidc_strategy
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

    context 'when a default openid_connect provider is configured' do
      before do
        stub_omniauth_config(providers: [oidc_provider_1])
      end

      it 'returns the provider' do
        expect(oidc_providers).to match_array([:openid_connect])
      end
    end

    context 'when the configuration specifies no provider' do
      before do
        stub_omniauth_config(providers: [])
      end

      it 'returns an empty list' do
        expect(oidc_providers).to be_empty
      end
    end

    context 'when the configuration specifies a provider with an OIDC strategy_class' do
      before do
        stub_omniauth_config(providers: [oidc_provider_2])
      end

      it 'returns the provider' do
        expect(oidc_providers).to match_array([oidc_provider_2_name.to_sym])
      end
    end

    context 'when the configuration specifies 1 default oidc provider and 1 with an OIDC strategy_class' do
      before do
        stub_omniauth_config(providers: [oidc_provider_1, oidc_provider_2])
      end

      it 'returns the providers' do
        expect(oidc_providers).to match_array([oidc_provider_1_name.to_sym, oidc_provider_2_name.to_sym])
      end
    end

    context 'when the configuration specifies two providers with an OIDC strategy_class' do
      before do
        stub_omniauth_config(providers: [oidc_provider_2, oidc_provider_3])
      end

      it 'returns the providers' do
        expect(oidc_providers).to match_array([oidc_provider_2_name.to_sym, oidc_provider_3_name.to_sym])
      end
    end

    context 'when the configuration specifies a non-OIDC provider' do
      before do
        stub_omniauth_config(providers: [ldap_provider])
      end

      it 'returns an empty list' do
        expect(oidc_providers).to be_empty
      end
    end

    context 'when the configuration specifies 2 non-oidc, 1 default oidc provider and 2 with an OIDC strategy_class' do
      before do
        stub_omniauth_config(
          providers: [oidc_provider_1, ldap_provider, oidc_provider_2, google_oauth2_provider, oidc_provider_3]
        )
      end

      it 'returns the providers' do
        expect(oidc_providers).to match_array(
          [oidc_provider_1_name.to_sym, oidc_provider_2_name.to_sym, oidc_provider_3_name.to_sym]
        )
      end
    end
  end

  describe '#delete_otp_authenticator_data' do
    context 'when password is required' do
      it 'returns data to delete the OTP authenticator' do
        expect(helper.delete_otp_authenticator_data(true)).to match(a_hash_including({
          button_text: _('Delete one-time password authenticator'),
          message: _('Are you sure you want to delete this one-time password authenticator? ' \
            'Enter your password to continue.'),
          path: destroy_otp_profile_two_factor_auth_path,
          password_required: 'true'
        }))
      end
    end

    context 'when password is not required' do
      it 'returns data to delete the OTP authenticator' do
        expect(helper.delete_otp_authenticator_data(false)).to match(a_hash_including({
          button_text: _('Delete one-time password authenticator'),
          message: _('Are you sure you want to delete this one-time password authenticator?'),
          path: destroy_otp_profile_two_factor_auth_path,
          password_required: 'false'
        }))
      end
    end
  end

  describe '#delete_webauthn_device_data' do
    let(:path) { 'test/path' }

    context 'when password is required' do
      it 'returns data to delete a WebAuthn device' do
        expect(helper.delete_webauthn_device_data(true, path)).to match(a_hash_including({
          button_text: _('Delete WebAuthn device'),
          icon: 'remove',
          message: _('Are you sure you want to delete this WebAuthn device? ' \
            'Enter your password to continue.'),
          path: path,
          password_required: 'true'
        }))
      end
    end

    context 'when password is not required' do
      it 'returns data to delete a WebAuthn device' do
        expect(helper.delete_webauthn_device_data(false, path)).to match(a_hash_including({
          button_text: _('Delete WebAuthn device'),
          icon: 'remove',
          message: _('Are you sure you want to delete this WebAuthn device?'),
          path: path,
          password_required: 'false'
        }))
      end
    end
  end

  describe '#disable_two_factor_authentication_data' do
    context 'when password is required' do
      it 'returns data to disable two-factor authentication' do
        expect(helper.disable_two_factor_authentication_data(true)).to match(a_hash_including({
          button_text: _('Disable two-factor authentication'),
          message: _('Are you sure you want to invalidate your one-time password authenticator and WebAuthn devices? ' \
            'Enter your password to continue. This action cannot be undone.'),
          path: profile_two_factor_auth_path,
          password_required: 'true'
        }))
      end
    end

    context 'when password is not required' do
      it 'returns data to disable two-factor authentication' do
        expect(helper.disable_two_factor_authentication_data(false)).to match(a_hash_including({
          button_text: _('Disable two-factor authentication'),
          message: _('Are you sure you want to invalidate your one-time password authenticator and WebAuthn devices?'),
          path: profile_two_factor_auth_path,
          password_required: 'false'
        }))
      end
    end
  end

  describe '#codes_two_factor_authentication_data' do
    context 'when password is required' do
      it 'returns data to delete the OTP authenticator' do
        expect(helper.codes_two_factor_authentication_data(true)).to match(a_hash_including({
          button_text: _('Regenerate recovery codes'),
          message: _('Are you sure you want to regenerate recovery codes? ' \
            'Enter your password to continue.'),
          method: 'post',
          path: codes_profile_two_factor_auth_path,
          password_required: 'true',
          variant: 'default'
        }))
      end
    end

    context 'when password is not required' do
      it 'returns data to delete the OTP authenticator' do
        expect(helper.codes_two_factor_authentication_data(false)).to match(a_hash_including({
          button_text: _('Regenerate recovery codes'),
          message: _('Are you sure you want to regenerate recovery codes?'),
          method: 'post',
          path: codes_profile_two_factor_auth_path,
          password_required: 'false',
          variant: 'default'
        }))
      end
    end
  end

  describe '#certificate_fingerprint_algorithm' do
    let_it_be(:sha1_fingerprint_upper) { "DD:80:B1:FA:A9:A7:8D:9D:41:7E:09:10:D8:6F:7D:0A:7E:58:4C:C4" }
    let_it_be(:sha1_fingerprint_lower) { "dd:80:b1:fa:a9:a7:8d:9d:41:7e:09:10:d8:6f:7d:0a:7e:58:4c:c4" }
    let_it_be(:sha256_fingerprint_upper) do
      "73:2D:28:C2:D2:D0:34:9F:F8:9A:9C:74:23:BF:0A:CB:66:75:78:9B:01:4D:1F:7D:60:8F:AD:47:A2:30:D7:4A"
    end

    let_it_be(:sha256_fingerprint_mixed) do
      "73:2d:28:c2:d2:d0:34:9F:F8:9a:9c:74:23:BF:0a:cb:66:75:78:9b:01:4D:1F:7D:60:8f:ad:47:a2:30:d7:4a"
    end

    it 'detects SHA1 fingerprint with upper case characters' do
      expect(helper.certificate_fingerprint_algorithm(sha1_fingerprint_upper))
        .to eq('http://www.w3.org/2000/09/xmldsig#sha1')
    end

    it 'detects SHA1 fingerprint with lower case characters' do
      expect(helper.certificate_fingerprint_algorithm(sha1_fingerprint_lower))
        .to eq('http://www.w3.org/2000/09/xmldsig#sha1')
    end

    it 'detects SHA256 fingerprint with upper case characters' do
      expect(helper.certificate_fingerprint_algorithm(sha256_fingerprint_upper))
        .to eq('http://www.w3.org/2001/04/xmlenc#sha256')
    end

    it 'detects SHA256 fingerprint with mixed case characters' do
      expect(helper.certificate_fingerprint_algorithm(sha256_fingerprint_mixed))
        .to eq('http://www.w3.org/2001/04/xmlenc#sha256')
    end
  end

  describe '#step_up_auth_params' do
    using RSpec::Parameterized::TableSyntax

    let(:current_user) { instance_double('User', flipper_id: '1') }

    let(:oidc_setting_with_step_up_auth) do
      GitlabSettings::Options.new(
        name: "openid_connect",
        step_up_auth: {
          admin_mode: {
            params: {
              claims: { acr_values: 'gold' },
              prompt: 'login'
            }
          }
        }
      )
    end

    let(:oidc_setting_without_step_up_auth_params) do
      GitlabSettings::Options.new(name: "openid_connect",
        step_up_auth: { admin_mode: { id_token: { required: { acr: 'gold' } } } })
    end

    let(:oidc_setting_without_step_up_auth) do
      GitlabSettings::Options.new(name: "openid_connect")
    end

    subject { helper.step_up_auth_params(provider_name, scope) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      stub_omniauth_setting(enabled: true, providers: omniauth_setting_providers)
    end

    # rubocop:disable Layout/LineLength -- Ensure one-line table syntax for better readability
    where(:omniauth_setting_providers, :provider_name, :scope, :expected_result) do
      [ref(:oidc_setting_with_step_up_auth)]           | 'openid_connect'        | :admin_mode  | { step_up_auth_scope: :admin_mode, 'claims' => '{"acr_values":"gold"}', 'prompt' => 'login' }
      [ref(:oidc_setting_with_step_up_auth)]           | 'openid_connect'        | 'admin_mode' | { step_up_auth_scope: 'admin_mode', 'claims' => '{"acr_values":"gold"}', 'prompt' => 'login' }
      [ref(:oidc_setting_with_step_up_auth)]           | 'openid_connect'        | nil          | {}
      [ref(:oidc_setting_with_step_up_auth)]           | 'missing_provider_name' | :admin_mode  | {}
      [ref(:oidc_setting_with_step_up_auth)]           | nil                     | nil          | {}

      []                                               | 'openid_connect'        | :admin_mode  | {}
      [ref(:oidc_setting_without_step_up_auth)]        | 'openid_connect'        | :admin_mode  | {}
      [ref(:oidc_setting_without_step_up_auth_params)] | 'openid_connect'        | :admin_mode  | { step_up_auth_scope: :admin_mode }
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it { is_expected.to eq expected_result }

      context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
        end

        it { is_expected.to eq({}) }
      end
    end
  end

  def omniauth_providers_with_step_up_auth_config(step_up_auth_scope)
    auth_providers.map { |provider| Gitlab::Auth::OAuth::Provider.config_for(provider) }
                  .select { |provider_config| provider_config.dig("step_up_auth", step_up_auth_scope.to_s).present? }
  end

  def step_up_auth_params(provider_name, scope)
    return {} if Feature.disabled?(:omniauth_step_up_auth_for_admin_mode, current_user)

    provider_config_for_scope = Gitlab::Auth::OAuth::Provider.config_for(provider_name)&.dig('step_up_auth', scope)
    return {} if provider_config_for_scope&.dig('enabled').blank?

    provider_config_for_scope&.dig('params')&.transform_values { |v| v.is_a?(Hash) ? v.to_json : v }
  end
end

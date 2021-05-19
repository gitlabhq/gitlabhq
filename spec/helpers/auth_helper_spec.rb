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
      stub_config(extra: { google_tag_manager_id: 'key' })
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject(:google_tag_manager_enabled?) { helper.google_tag_manager_enabled? }

    context 'on gitlab.com and a key set without a current user' do
      it { is_expected.to be_truthy }
    end

    context 'when not on gitlab.com' do
      let(:is_gitlab_com) { false }

      it { is_expected.to be_falsey }
    end

    context 'when current user is set' do
      let(:user) { instance_double('User') }

      it { is_expected.to be_falsey }
    end

    context 'when no key is set' do
      before do
        stub_config(extra: {})
      end

      it { is_expected.to be_falsey }
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
end

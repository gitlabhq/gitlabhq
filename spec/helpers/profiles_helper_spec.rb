# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProfilesHelper, feature_category: :user_profile do
  include SafeFormatHelper

  describe '#commit_email_select_options' do
    it 'returns an array with private commit email along with all the verified emails' do
      user = create(:user)
      create(:email, user: user)
      confirmed_email1 = create(:email, :confirmed, user: user)
      confirmed_email2 = create(:email, :confirmed, user: user)

      private_email = user.private_commit_email

      emails = [
        [s_('Use primary email (%{email})') % { email: user.email }, ''],
        [safe_format(s_("Profiles|Use a private email - %{email}"), email: private_email), Gitlab::PrivateCommitEmail::TOKEN],
        user.email,
        confirmed_email1.email,
        confirmed_email2.email
      ]

      expect(helper.commit_email_select_options(user)).to match_array(emails)
    end
  end

  describe '#email_provider_label' do
    it "returns nil for users without external email" do
      user = create(:user)
      allow(helper).to receive(:current_user).and_return(user)

      expect(helper.attribute_provider_label(:email)).to be_nil
    end

    it "returns omniauth provider label for users with external attributes" do
      stub_omniauth_setting(sync_profile_from_provider: [example_omniauth_provider])
      stub_omniauth_setting(sync_profile_attributes: true)
      stub_auth0_omniauth_provider
      auth0_user = create(:omniauth_user, provider: example_omniauth_provider)
      auth0_user.create_user_synced_attributes_metadata(provider: example_omniauth_provider, name_synced: true, email_synced: true, location_synced: true)
      allow(helper).to receive(:current_user).and_return(auth0_user)

      expect(helper.attribute_provider_label(:email)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:name)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:location)).to eq(example_omniauth_provider_label)
    end

    it "returns the correct omniauth provider label for users with some external attributes" do
      stub_omniauth_setting(sync_profile_from_provider: [example_omniauth_provider])
      stub_omniauth_setting(sync_profile_attributes: true)
      stub_auth0_omniauth_provider
      auth0_user = create(:omniauth_user, provider: example_omniauth_provider)
      auth0_user.create_user_synced_attributes_metadata(provider: example_omniauth_provider, name_synced: false, email_synced: true, location_synced: false)
      allow(helper).to receive(:current_user).and_return(auth0_user)

      expect(helper.attribute_provider_label(:name)).to be_nil
      expect(helper.attribute_provider_label(:email)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:location)).to be_nil
    end

    it "returns 'LDAP' for users with external email but no email provider" do
      ldap_user = create(:omniauth_user)
      ldap_user.create_user_synced_attributes_metadata(email_synced: true)
      allow(helper).to receive(:current_user).and_return(ldap_user)

      expect(helper.attribute_provider_label(:email)).to eq('LDAP')
    end
  end

  describe "#ssh_key_expiration_tooltip" do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(Key).to receive(:enforce_ssh_key_expiration_feature_available?).and_return(false)
    end

    error_message = 'Key type is forbidden. Must be DSA, ECDSA, or ED25519'

    where(:error, :expired, :result) do
      false | false | nil
      true  | false | error_message
      true  | true  | error_message
    end

    with_them do
      let_it_be(:key) do
        build(:personal_key)
      end

      it do
        key.expires_at = expired ? 2.days.ago : 2.days.from_now
        key.errors.add(:base, error_message) if error

        expect(helper.ssh_key_expiration_tooltip(key)).to eq(result)
      end
    end
  end

  describe "#ssh_key_expires_field_description" do
    subject { helper.ssh_key_expires_field_description }

    it { is_expected.to eq(s_('Profiles|Optional but recommended. If set, key becomes invalid on the specified date.')) }
  end

  describe '#prevent_delete_account?' do
    it 'returns false' do
      expect(helper.prevent_delete_account?).to eq false
    end
  end

  describe '#user_profile_data' do
    let(:time) { 3.hours.ago }
    let(:timezone) { 'Europe/London' }
    let(:user) do
      build_stubbed(:user, status: UserStatus.new(
        message: 'Some message',
        emoji: 'basketball',
        availability: 'busy',
        clear_status_at: time
      ), timezone: timezone)
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns user profile data' do
      data = helper.user_profile_data(user)

      expect(data[:profile_path]).to be_a(String)
      expect(data[:profile_avatar_path]).to be_a(String)
      expect(data[:avatar_url]).to be_http_url
      expect(data[:has_avatar]).to be_a(String)
      expect(data[:gravatar_enabled]).to be_a(String)
      expect(Gitlab::Json.parse(data[:gravatar_link])).to match(hash_including('hostname' => Gitlab.config.gravatar.host, 'url' => a_valid_url))
      expect(data[:brand_profile_image_guidelines]).to be_a(String)
      expect(data[:cropper_css_path]).to eq(ActionController::Base.helpers.stylesheet_path('lazy_bundles/cropper.css'))
      expect(data[:user_path]).to be_a(String)
      expect(data[:current_emoji]).to eq('basketball')
      expect(data[:current_message]).to eq('Some message')
      expect(data[:current_availability]).to eq('busy')
      expect(data[:current_clear_status_after]).to eq(time.to_fs(:iso8601))
      expect(data[:default_emoji]).to eq(UserStatus::DEFAULT_EMOJI)
      expect(data[:timezones]).to eq(helper.timezone_data_with_unique_identifiers.to_json)
      expect(data[:user_timezone]).to eq(timezone)
    end
  end

  def stub_auth0_omniauth_provider
    provider = OpenStruct.new(
      'name' => example_omniauth_provider,
      'label' => example_omniauth_provider_label
    )

    stub_omniauth_setting(providers: [provider])
  end

  def example_omniauth_provider
    "auth0"
  end

  def example_omniauth_provider_label
    "Auth0"
  end
end

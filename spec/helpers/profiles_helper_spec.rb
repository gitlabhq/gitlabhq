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
      auth0_user.create_user_synced_attributes_metadata(provider: example_omniauth_provider, name_synced: true, email_synced: true, location_synced: true, organization_synced: true, job_title_synced: true)
      allow(helper).to receive(:current_user).and_return(auth0_user)

      expect(helper.attribute_provider_label(:email)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:name)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:location)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:organization)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:job_title)).to eq(example_omniauth_provider_label)
    end

    it "returns the correct omniauth provider label for users with some external attributes" do
      stub_omniauth_setting(sync_profile_from_provider: [example_omniauth_provider])
      stub_omniauth_setting(sync_profile_attributes: true)
      stub_auth0_omniauth_provider
      auth0_user = create(:omniauth_user, provider: example_omniauth_provider)
      auth0_user.create_user_synced_attributes_metadata(provider: example_omniauth_provider, name_synced: false, email_synced: true, location_synced: false, organization_synced: false, job_title_synced: false)
      allow(helper).to receive(:current_user).and_return(auth0_user)

      expect(helper.attribute_provider_label(:name)).to be_nil
      expect(helper.attribute_provider_label(:email)).to eq(example_omniauth_provider_label)
      expect(helper.attribute_provider_label(:location)).to be_nil
      expect(helper.attribute_provider_label(:organization)).to be_nil
      expect(helper.attribute_provider_label(:job_title)).to be_nil
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
      build_stubbed(
        :user,
        status: UserStatus.new(
          message: 'Some message',
          emoji: 'basketball',
          availability: 'busy',
          clear_status_at: time
        ),
        timezone: timezone,
        pronouns: 'they/them',
        pronunciation: 'test-user',
        job_title: 'Developer',
        user_detail_organization: 'GitLab',
        location: 'Remote',
        website_url: 'https://example.com',
        bio: 'Test bio')
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

    it 'includes all user profile fields' do
      data = helper.user_profile_data(user)

      expect(data[:id]).to eq(user.id)
      expect(data[:name]).to eq(user.name)
      expect(data[:pronouns]).to eq('they/them')
      expect(data[:pronunciation]).to eq('test-user')
      expect(data[:website_url]).to eq('https://example.com')
      expect(data[:location]).to eq('Remote')
      expect(data[:job_title]).to eq('Developer')
      expect(data[:organization]).to eq('GitLab')
      expect(data[:bio]).to eq('Test bio')
      expect(data[:include_private_contributions]).to eq(user.include_private_contributions?.to_s)
      expect(data[:achievements_enabled]).to eq(user.achievements_enabled.to_s)
      expect(data[:private_profile]).to eq(user.private_profile?.to_s)
    end
  end

  describe '#delete_account_modal_data' do
    it 'returns the correct data hash for the delete account modal' do
      user = build_stubbed(:user, username: 'johndoe')
      allow(user).to receive(:confirm_deletion_with_password?).and_return(true)
      allow(helper).to receive_messages(current_user: user, user_registration_path: '/users')
      allow(Gitlab::CurrentSettings).to receive(:delay_user_account_self_deletion).and_return(true)

      result = helper.delete_account_modal_data

      expect(result).to eq(
        action_url: '/users',
        confirm_with_password: 'true',
        username: 'johndoe',
        delay_user_account_self_deletion: 'true'
      )
    end
  end

  describe '#email_profile_data' do
    include Devise::Test::ControllerHelpers

    let(:user) { build_stubbed(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns email profile data' do
      data = helper.email_profile_data(user)

      expect(data[:email]).to eq(user.email)
      expect(data[:public_email]).to eq(user.public_email)
      expect(data[:commit_email]).to eq(user.commit_email)
      expect(data[:public_email_options]).to be_a(String)
      expect(Gitlab::Json.parse(data[:public_email_options])).to be_an(Array)
      expect(data[:commit_email_options]).to be_a(String)
      expect(Gitlab::Json.parse(data[:commit_email_options])).to be_an(Array)
      expect(data[:email_help_text]).to be_present
      expect(data[:managing_group_name]).to be_nil.or(be_a(String))
      expect(data[:provider_label]).to be_nil.or(be_a(String))
      expect(data[:is_email_readonly]).to eq(user.read_only_attribute?(:email))
      expect(data[:email_change_disabled]).to eq(user.respond_to?(:managing_group) && user.managing_group.present?)
      expect(data[:needs_password_confirmation]).to eq(
        (!user.password_automatically_set? && user.allow_password_authentication_for_web?).to_s
      )
      expect(data[:password_automatically_set]).to eq(user.password_automatically_set?.to_s)
      expect(data[:allow_password_authentication_for_web]).to eq(user.allow_password_authentication_for_web?.to_s)
    end

    it 'returns empty email for temp oauth email' do
      allow(user).to receive(:temp_oauth_email?).and_return(true)

      data = helper.email_profile_data(user)

      expect(data[:email]).to eq('')
    end

    context 'when help text contains resend confirmation link' do
      let(:user_with_unconfirmed_email) { build_stubbed(:user, unconfirmed_email: 'test@example.com') }

      it 'removes the confirmation link paragraph from email help text' do
        help_text_with_link = 'Some text <p><a href="/users/user_confirmation">Resend confirmation e-mail</a></p> more text'
        allow(helper).to receive(:user_email_help_text).and_return(help_text_with_link)

        data = helper.email_profile_data(user_with_unconfirmed_email)

        expect(data[:email_help_text]).to eq('Some text  more text')
        expect(data[:email_help_text]).not_to include('Resend confirmation')
        expect(data[:email_help_text]).not_to include('user_confirmation')
      end

      it 'preserves other links in help text' do
        help_text = 'Text <p><a href="/users/user_confirmation">Resend</a></p> and <p><a href="/other">Other link</a></p>'
        allow(helper).to receive(:user_email_help_text).and_return(help_text)

        data = helper.email_profile_data(user_with_unconfirmed_email)

        expect(data[:email_help_text]).to include('Other link')
        expect(data[:email_help_text]).not_to include('Resend')
      end

      it 'returns original text when no links present' do
        help_text_without_link = 'Simple text without links'
        allow(helper).to receive(:user_email_help_text).and_return(help_text_without_link)

        data = helper.email_profile_data(user_with_unconfirmed_email)

        expect(data[:email_help_text]).to eq(help_text_without_link)
      end
    end
  end

  describe '#email_resend_confirmation_link' do
    context 'when user has no unconfirmed email' do
      it 'returns nil' do
        user = build_stubbed(:user, unconfirmed_email: nil)

        expect(helper.email_resend_confirmation_link(user)).to be_nil
      end
    end

    context 'when user has unconfirmed email' do
      it 'returns confirmation path with encoded email' do
        user = build_stubbed(:user, unconfirmed_email: 'new@example.com')

        result = helper.email_resend_confirmation_link(user)

        expect(result).to include('confirmation')
        expect(result).to include('new%40example.com')
      end
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

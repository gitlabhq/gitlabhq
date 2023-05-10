# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProfilesHelper do
  describe '#commit_email_select_options' do
    it 'returns an array with private commit email along with all the verified emails' do
      user = create(:user)
      create(:email, user: user)
      confirmed_email1 = create(:email, :confirmed, user: user)
      confirmed_email2 = create(:email, :confirmed, user: user)

      private_email = user.private_commit_email

      emails = [
        [s_('Use primary email (%{email})') % { email: user.email }, ''],
        [s_("Profiles|Use a private email - %{email}").html_safe % { email: private_email }, Gitlab::PrivateCommitEmail::TOKEN],
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

  describe '#middle_dot_divider_classes' do
    using RSpec::Parameterized::TableSyntax

    where(:stacking, :breakpoint, :expected) do
      nil  | nil | %w(gl-mb-3 gl-display-inline-block middle-dot-divider)
      true | nil | %w(gl-mb-3 middle-dot-divider-sm gl-display-block gl-sm-display-inline-block)
      nil  | :sm | %w(gl-mb-3 gl-display-inline-block middle-dot-divider-sm)
    end

    with_them do
      it 'returns CSS classes needed to render the middle dot divider' do
        expect(helper.middle_dot_divider_classes(stacking, breakpoint)).to eq expected
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

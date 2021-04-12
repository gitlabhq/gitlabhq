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
        ["Use a private email - #{private_email}", Gitlab::PrivateCommitEmail::TOKEN],
        user.email,
        confirmed_email1.email,
        confirmed_email2.email
      ]

      expect(helper.commit_email_select_options(user)).to match_array(emails)
    end
  end

  describe '#selected_commit_email' do
    let(:user) { create(:user) }

    it 'returns main email when commit email attribute is nil' do
      expect(helper.selected_commit_email(user)).to eq(user.email)
    end

    it 'returns DB stored commit_email' do
      user.update!(commit_email: Gitlab::PrivateCommitEmail::TOKEN)

      expect(helper.selected_commit_email(user)).to eq(Gitlab::PrivateCommitEmail::TOKEN)
    end
  end

  describe '#email_provider_label' do
    it "returns nil for users without external email" do
      user = create(:user)
      allow(helper).to receive(:current_user).and_return(user)

      expect(helper.attribute_provider_label(:email)).to be_nil
    end

    it "returns omniauth provider label for users with external attributes" do
      stub_omniauth_setting(sync_profile_from_provider: ['cas3'])
      stub_omniauth_setting(sync_profile_attributes: true)
      stub_cas_omniauth_provider
      cas_user = create(:omniauth_user, provider: 'cas3')
      cas_user.create_user_synced_attributes_metadata(provider: 'cas3', name_synced: true, email_synced: true, location_synced: true)
      allow(helper).to receive(:current_user).and_return(cas_user)

      expect(helper.attribute_provider_label(:email)).to eq('CAS')
      expect(helper.attribute_provider_label(:name)).to eq('CAS')
      expect(helper.attribute_provider_label(:location)).to eq('CAS')
    end

    it "returns the correct omniauth provider label for users with some external attributes" do
      stub_omniauth_setting(sync_profile_from_provider: ['cas3'])
      stub_omniauth_setting(sync_profile_attributes: true)
      stub_cas_omniauth_provider
      cas_user = create(:omniauth_user, provider: 'cas3')
      cas_user.create_user_synced_attributes_metadata(provider: 'cas3', name_synced: false, email_synced: true, location_synced: false)
      allow(helper).to receive(:current_user).and_return(cas_user)

      expect(helper.attribute_provider_label(:name)).to be_nil
      expect(helper.attribute_provider_label(:email)).to eq('CAS')
      expect(helper.attribute_provider_label(:location)).to be_nil
    end

    it "returns 'LDAP' for users with external email but no email provider" do
      ldap_user = create(:omniauth_user)
      ldap_user.create_user_synced_attributes_metadata(email_synced: true)
      allow(helper).to receive(:current_user).and_return(ldap_user)

      expect(helper.attribute_provider_label(:email)).to eq('LDAP')
    end
  end

  describe "#user_status_set_to_busy?" do
    using RSpec::Parameterized::TableSyntax

    where(:availability, :result) do
      "busy"    | true
      "not_set" | false
      ""        | false
      nil       | false
    end

    with_them do
      it { expect(helper.user_status_set_to_busy?(OpenStruct.new(availability: availability))).to eq(result) }
    end
  end

  describe "#show_status_emoji?" do
    using RSpec::Parameterized::TableSyntax

    where(:message, :emoji, :result) do
      "Some message" | UserStatus::DEFAULT_EMOJI | true
      "Some message" | ""                        | true
      ""             | "basketball"              | true
      ""             | "basketball"              | true
      ""             | UserStatus::DEFAULT_EMOJI | false
      ""             | UserStatus::DEFAULT_EMOJI | false
    end

    with_them do
      it { expect(helper.show_status_emoji?(OpenStruct.new(message: message, emoji: emoji))).to eq(result) }
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
      false | true  | 'Key usable beyond expiration date.'
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
    before do
      allow(Key).to receive(:enforce_ssh_key_expiration_feature_available?).and_return(false)
    end

    it 'returns the description' do
      expect(helper.ssh_key_expires_field_description).to eq('Key can still be used after expiration.')
    end
  end

  def stub_cas_omniauth_provider
    provider = OpenStruct.new(
      'name' => 'cas3',
      'label' => 'CAS'
    )

    stub_omniauth_setting(providers: [provider])
  end
end

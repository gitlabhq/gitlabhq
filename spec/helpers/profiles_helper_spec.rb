require 'rails_helper'

describe ProfilesHelper do
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

  def stub_cas_omniauth_provider
    provider = OpenStruct.new(
      'name' => 'cas3',
      'label' => 'CAS'
    )

    stub_omniauth_setting(providers: [provider])
  end
end

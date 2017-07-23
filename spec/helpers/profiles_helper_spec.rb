require 'rails_helper'

describe ProfilesHelper do
  describe '#email_provider_label' do
    it "returns nil for users without external email" do
      user = create(:user)
      allow(helper).to receive(:current_user).and_return(user)

      expect(helper.email_provider_label).to be_nil
    end

    it "returns omniauth provider label for users with external email" do
      stub_cas_omniauth_provider
      cas_user = create(:omniauth_user, provider: 'cas3', external_email: true, email_provider: 'cas3')
      allow(helper).to receive(:current_user).and_return(cas_user)

      expect(helper.email_provider_label).to eq('CAS')
    end

    it "returns 'LDAP' for users with external email but no email provider" do
      ldap_user = create(:omniauth_user, external_email: true)
      allow(helper).to receive(:current_user).and_return(ldap_user)

      expect(helper.email_provider_label).to eq('LDAP')
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

require "spec_helper"

describe OauthHelper do
  describe "additional_providers" do
    it 'returns all enabled providers' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :github] }
      expect(helper.additional_providers).to include(*[:twitter, :github])
    end

    it 'does not return ldap provider' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :ldapmain] }
      expect(helper.additional_providers).to include(:twitter)
    end

    it 'returns empty array' do
      allow(helper).to receive(:enabled_oauth_providers) { [] }
      expect(helper.additional_providers).to eq([])
    end
  end

  describe "kerberos_enabled?" do
    it 'returns true' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :github, :kerberos] }
      expect(helper).to be_kerberos_enabled
    end

    it 'returns false' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :ldapmain] }
      expect(helper).not_to be_kerberos_enabled
    end
  end
end

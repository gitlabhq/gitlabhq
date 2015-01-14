require "spec_helper"

describe OauthHelper do
  describe "additional_providers" do
    it 'returns all enabled providers' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :github] }
      helper.additional_providers.should include(*[:twitter, :github])
    end

    it 'does not return ldap provider' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :ldapmain] }
      helper.additional_providers.should include(:twitter)
    end

    it 'returns empty array' do
      allow(helper).to receive(:enabled_oauth_providers) { [] }
      helper.additional_providers.should == []
    end
  end

  describe "kerberos_enabled?" do
    it 'returns true' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :github, :kerberos] }
      helper.kerberos_enabled?.should be_true
    end

    it 'returns false' do
      allow(helper).to receive(:enabled_oauth_providers) { [:twitter, :ldapmain] }
      helper.kerberos_enabled?.should be_false
    end
  end
end
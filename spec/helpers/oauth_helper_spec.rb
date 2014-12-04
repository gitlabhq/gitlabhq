require "spec_helper"

describe OauthHelper do
  describe "additional_providers" do
    it 'returns appropriate values' do
      [
        [[:twitter, :github], [:twitter, :github]], 
        [[:ldap_main], []],
        [[:twitter, :ldap_main], [:twitter]],
        [[], []],
      ].each do |couple|
        allow(helper).to receive(:enabled_oauth_providers) { couple.first }
        additional_providers.should include(*couple.last)
      end
    end
  end
end
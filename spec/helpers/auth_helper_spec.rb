require "spec_helper"

describe AuthHelper do
  describe "button_based_providers" do
    let(:settings) { ApplicationSetting.create_from_defaults }

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

    it 'returns all the enabled providers from settings' do
      allow(helper).to receive(:auth_providers) { [:twitter, :github] }
      expect(helper.enabled_button_based_providers).to include(*['twitter', 'github'])
    end

    it 'should not return github as provider because it\'s disabled from settings' do
      settings.update_attribute(
        :disabled_oauth_sign_in_sources,
        ['github']
      )

      allow(helper).to receive(:auth_providers) { [:twitter, :github] }
      allow(helper).to receive(:current_application_settings) {  settings }

      expect(helper.enabled_button_based_providers).to include('twitter')
      expect(helper.enabled_button_based_providers).to_not include('github')
    end
  end
end

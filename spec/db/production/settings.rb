require 'spec_helper'
require 'rainbow/ext/string'

describe 'seed production settings', lib: true do
  include StubENV

  context 'GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN is set in the environment' do
    before do
      stub_env('GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN', '013456789')
    end

    it 'writes the token to the database' do
      load(File.join(__dir__, '../../../db/fixtures/production/010_settings.rb'))
      expect(ApplicationSetting.current.runners_registration_token).to eq('013456789')
    end
  end
end

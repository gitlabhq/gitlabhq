require 'spec_helper'
require Rails.root.join('config', 'object_store_settings.rb')

describe ObjectStoreSettings do
  describe '.parse' do
    it 'should set correct default values' do
      settings = described_class.parse(nil)

      expect(settings['enabled']).to be false
      expect(settings['direct_upload']).to be false
      expect(settings['background_upload']).to be true
      expect(settings['remote_directory']).to be nil
    end

    it 'respects original values' do
      original_settings = Settingslogic.new({
        'enabled' => true,
        'remote_directory' => 'artifacts'
      })

      settings = described_class.parse(original_settings)

      expect(settings['enabled']).to be true
      expect(settings['direct_upload']).to be false
      expect(settings['background_upload']).to be true
      expect(settings['remote_directory']).to eq 'artifacts'
    end
  end
end

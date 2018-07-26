require 'rails_helper'

describe Gitlab::Kubernetes::Helm::GetCommand do
  let(:application) { build(:clusters_applications_prometheus) }

  subject(:get_command) { described_class.new(application.name) }

  describe '#config_map?' do
    it 'returns true' do
      expect(get_command.config_map?).to be true
    end
  end

  describe '#config_map_name' do
    it 'returns the ConfigMap name' do
      expect(get_command.config_map_name).to eq("values-content-configuration-#{application.name}")
    end
  end
end

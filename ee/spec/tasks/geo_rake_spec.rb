require 'rake_helper'

describe 'geo rake tasks', :geo do
  include ::EE::GeoHelpers

  before do
    Rake.application.rake_require 'tasks/geo'
    stub_licensed_features(geo: true)
  end

  describe 'set_primary_node task' do
    before do
      stub_config_setting(protocol: 'https')
    end

    it 'creates a GeoNode' do
      expect(GeoNode.count).to eq(0)

      run_rake_task('geo:set_primary_node')

      expect(GeoNode.count).to eq(1)

      node = GeoNode.first

      expect(node.uri.scheme).to eq('https')
      expect(node.primary).to be_truthy
    end
  end

  describe 'set_secondary_as_primary task' do
    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(current_node)
    end

    it 'removes primary and sets secondary as primary' do
      run_rake_task('geo:set_secondary_as_primary')

      expect(current_node.primary?).to be_truthy
      expect(GeoNode.count).to eq(1)
    end
  end

  describe 'update_primary_node_url task' do
    let(:primary_node) { create(:geo_node, :primary, url: 'https://secondary.geo.example.com') }

    before do
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
      stub_current_geo_node(primary_node)
    end

    it 'updates Geo primary node URL' do
      run_rake_task('geo:update_primary_node_url')

      expect(primary_node.reload.url).to eq 'https://primary.geo.example.com/'
    end
  end

  describe 'status task' do
    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }
    let!(:geo_event_log) { create(:geo_event_log) }

    before do
      expect(Gitlab::Geo).to receive(:license_allows?).and_return(true).at_least(:once)
      expect(GeoNodeStatus).to receive(:current_node_status).and_call_original

      stub_current_geo_node(current_node)
    end

    it 'runs with no error' do
      expect { run_rake_task('geo:status') }.to output(/Sync settings: Full/).to_stdout
    end
  end
end

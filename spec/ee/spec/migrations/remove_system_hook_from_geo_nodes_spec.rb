require "spec_helper"
require Rails.root.join("db", "post_migrate", "20170811082658_remove_system_hook_from_geo_nodes.rb")

describe RemoveSystemHookFromGeoNodes, :migration do
  let(:geo_nodes) { table(:geo_nodes) }

  before do
    allow_any_instance_of(WebHookService).to receive(:execute)

    create(:system_hook)
    geo_nodes.create! attributes_for(:geo_node, :primary)
    geo_nodes.create! attributes_for(:geo_node, system_hook_id: create(:system_hook).id)
  end

  it 'destroy all system hooks for secondary nodes' do
    expect do
      migrate!
    end.to change { SystemHook.count }.by(-1)
  end
end

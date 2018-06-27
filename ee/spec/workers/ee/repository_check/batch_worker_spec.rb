require 'spec_helper'

describe EE::RepositoryCheck::BatchWorker do
  include ::EE::GeoHelpers

  let(:shard_name) { 'default' }
  subject(:worker) { RepositoryCheck::BatchWorker.new }

  before do
    Gitlab::ShardHealthCache.update([shard_name])
  end

  context 'Geo primary' do
    set(:primary) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(primary)
    end

    it 'loads project ids from main database' do
      projects = create_list(:project, 3, created_at: 1.week.ago, repository_storage: shard_name)

      expect(worker.perform(shard_name)).to match_array(projects.map(&:id))
    end
  end

  context 'Geo secondary' do
    set(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'loads project ids from tracking database' do
      project_registries = create_list(:geo_project_registry, 3, :synced)
      update_project_registry_shard(project_registries, shard_name)

      expect(worker.perform(shard_name)).to match_array(project_registries.map(&:project_id))
    end

    it 'loads project ids that were checked more than a month ago from tracking database' do
      project_registries = create_list(:geo_project_registry, 3, :synced,
                                       last_repository_check_failed: false,
                                       last_repository_check_at: 42.days.ago)
      update_project_registry_shard(project_registries, shard_name)

      expect(worker.perform(shard_name)).to match_array(project_registries.map(&:project_id))
    end
  end

  def update_project_registry_shard(project_registries, shard_name)
    project_registries.each do |registry|
      Project.find(registry.project_id).update_column(:repository_storage, shard_name)
    end
  end
end

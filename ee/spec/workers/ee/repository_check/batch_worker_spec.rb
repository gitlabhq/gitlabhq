require 'spec_helper'

describe EE::RepositoryCheck::BatchWorker do
  include ::EE::GeoHelpers

  subject(:worker) { RepositoryCheck::BatchWorker.new }

  context 'Geo primary' do
    set(:primary) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(primary)
    end

    it 'loads project ids from main database' do
      projects = create_list(:project, 3, created_at: 1.week.ago)

      expect(worker.perform).to eq(projects.map(&:id))
    end
  end

  context 'Geo secondary' do
    set(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'loads project ids from tracking database' do
      project_registries = create_list(:geo_project_registry, 3, :synced)

      expect(worker.perform).to eq(project_registries.map(&:project_id))
    end

    it 'loads project ids that were checked more than a month ago from tracking database' do
      project_registries = create_list(:geo_project_registry, 3, :synced,
                                       last_repository_check_failed: false,
                                       last_repository_check_at: 42.days.ago)

      expect(worker.perform).to eq(project_registries.map(&:project_id))
    end
  end
end

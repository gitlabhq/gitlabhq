require 'spec_helper'

describe EE::RepositoryCheck::SingleRepositoryWorker do
  include ::EE::GeoHelpers

  set(:project) { create(:project) }

  subject(:worker) { RepositoryCheck::SingleRepositoryWorker.new }

  context 'Geo primary' do
    set(:primary) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(primary)
    end

    it 'saves results to main database' do
      expect do
        worker.perform(project.id)
      end.to change { project.reload.last_repository_check_at }

      expect(project.last_repository_check_failed).to be_falsy
    end
  end

  context 'Geo secondary' do
    set(:project_registry) { create(:geo_project_registry, project: project) }
    set(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'saves results to Geo registry' do
      expect do
        worker.perform(project.id)
      end.to change { project_registry.reload.last_repository_check_at }

      expect(project_registry.last_repository_check_failed).to be_falsy
    end

    it 'creates Geo registry when not yet exists' do
      project_registry.destroy!

      worker.perform(project.id)

      expect(Geo::ProjectRegistry.find_by!(project: project.id).last_repository_check_failed).to be_falsy
    end
  end
end

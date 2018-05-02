require 'spec_helper'

describe EE::RepositoryCheck::SingleRepositoryWorker do
  set(:project) { create(:project) }
  set(:project_registry) { create(:geo_project_registry, project: project) }
  set(:secondary) { create(:geo_node) }

  subject(:worker) { RepositoryCheck::SingleRepositoryWorker.new }

  it 'saves results to Geo registry' do
    expect do
      worker.perform(project.id)
    end.to change { project_registry.reload.last_repository_check_at }
  end
end

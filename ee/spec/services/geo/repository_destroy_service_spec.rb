require 'spec_helper'

describe Geo::RepositoryDestroyService do
  include ::EE::GeoHelpers

  set(:secondary) { create(:geo_node) }
  let(:project) { create(:project_empty_repo) }

  subject(:service) { described_class.new(project.id, project.name, project.disk_path, project.repository_storage) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#async_execute' do
    it 'starts the worker' do
      expect(GeoRepositoryDestroyWorker).to receive(:perform_async)

      subject.async_execute
    end
  end

  describe '#execute' do
    it 'delegates project removal to Projects::DestroyService' do
      expect_any_instance_of(EE::Projects::DestroyService).to receive(:geo_replicate)

      service.execute
    end

    context 'legacy storage project' do
      let(:project) { create(:project_empty_repo, :legacy_storage) }

      it 'removes the repository from disk' do
        project.delete

        expect(project.gitlab_shell.exists?(project.repository_storage, "#{project.disk_path}.git")).to be_truthy

        service.execute

        expect(project.gitlab_shell.exists?(project.repository_storage, "#{project.disk_path}.git")).to be_falsey
      end

      it 'cleans up deleted repositories' do
        project.delete

        expect(::GitlabShellWorker).to receive(:perform_in)
          .with(5.minutes, :remove_repository, project.repository_storage, "#{project.disk_path}+#{project.id}+deleted")
          .and_return(true)

        service.execute
      end
    end

    context 'hashed storage project' do
      it 'removes the repository from disk' do
        project.delete

        expect(project.gitlab_shell.exists?(project.repository_storage, "#{project.disk_path}.git")).to be_truthy

        service.execute

        expect(project.gitlab_shell.exists?(project.repository_storage, "#{project.disk_path}.git")).to be_falsey
      end

      it 'cleans up deleted repositories' do
        project.delete

        expect(::GitlabShellWorker).to receive(:perform_in)
          .with(5.minutes, :remove_repository, project.repository_storage, "#{project.disk_path}+#{project.id}+deleted")
          .and_return(true)

        service.execute
      end
    end
  end
end

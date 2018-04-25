require 'spec_helper'

describe Geo::RenameRepositoryService do
  let(:project) { create(:project, :repository, :legacy_storage) }
  let(:old_path) { project.full_path }
  let(:new_path) { "#{old_path}+renamed" }

  subject(:service) { described_class.new(project.id, old_path, new_path) }

  describe '#execute' do
    before do
      TestEnv.clean_test_path
    end

    context 'project backed by legacy storage' do
      it 'moves the project repositories' do
        expect_any_instance_of(Geo::MoveRepositoryService).to receive(:execute)
          .once.and_return(true)

        service.execute
      end

      it 'raises an error when project repository can not be moved' do
        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, old_path, new_path)
          .and_return(false)

        expect { service.execute }.to raise_error(Geo::RepositoryCannotBeRenamed, "Repository #{old_path} could not be renamed to #{new_path}")
      end

      it 'raises an error when wiki repository can not be moved' do
        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, old_path, new_path)
          .and_return(true)

        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, "#{old_path}.wiki", "#{new_path}.wiki")
          .and_return(false)

        expect { service.execute }.to raise_error(Geo::RepositoryCannotBeRenamed, "Repository #{old_path} could not be renamed to #{new_path}")
      end
    end

    it 'does not move project backed by hashed storage' do
      project_hashed_storage = create(:project)
      service = described_class.new(project_hashed_storage.id, project_hashed_storage.full_path, new_path)

      expect_any_instance_of(Geo::MoveRepositoryService).not_to receive(:execute)

      service.execute
    end
  end

  describe '#async_execute' do
    it 'starts the worker' do
      expect(Geo::RenameRepositoryWorker).to receive(:perform_async)

      service.async_execute
    end

    it 'returns job id' do
      allow(Geo::RenameRepositoryWorker).to receive(:perform_async).and_return('foo')

      expect(service.async_execute).to eq('foo')
    end
  end
end

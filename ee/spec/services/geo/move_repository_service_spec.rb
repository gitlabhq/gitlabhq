require 'spec_helper'

describe Geo::MoveRepositoryService, :geo do
  describe '#execute' do
    let(:project) { create(:project, :repository, :wiki_repo, :legacy_storage) }
    let(:old_path) { project.full_path }
    let(:new_path) { "#{project.full_path}+renamed" }

    subject(:service) { described_class.new(project, old_path, new_path) }

    it 'renames the project repositories' do
      old_disk_path = project.repository.path_to_repo
      old_wiki_disk_path = project.wiki.repository.path_to_repo
      full_new_path = File.join(project.repository_storage_path, new_path)

      expect(File.directory?(old_disk_path)).to be_truthy
      expect(File.directory?(old_wiki_disk_path)).to be_truthy
      expect(service.execute).to eq(true)
      expect(File.directory?(old_disk_path)).to be_falsey
      expect(File.directory?(old_wiki_disk_path)).to be_falsey
      expect(File.directory?("#{full_new_path}.git")).to be_truthy
      expect(File.directory?("#{full_new_path}.wiki.git")).to be_truthy
    end

    it 'returns false when project repository can not be renamed' do
      allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
        .with(project.repository_storage_path, old_path, new_path)
        .and_return(false)

      expect(service).to receive(:log_error).with('Repository cannot be moved')

      expect(service.execute).to eq false
    end

    it 'returns false when wiki repository can not be renamed' do
      allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
        .with(project.repository_storage_path, old_path, new_path)
        .and_return(true)

      allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
        .with(project.repository_storage_path, "#{old_path}.wiki", "#{new_path}.wiki")
        .and_return(false)

      expect(service).to receive(:log_error).with('Wiki repository cannot be moved')

      expect(service.execute).to eq false
    end

    context 'wiki disabled' do
      let(:project) { create(:project, :repository, :wiki_disabled, :legacy_storage) }

      it 'tries to move wiki even if it is not enabled without reporting error' do
        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage_path, old_path, new_path)
          .and_return(true)

        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage_path, "#{old_path}.wiki", "#{new_path}.wiki")
          .and_return(false)

        expect(service).not_to receive(:log_error)

        expect(service.execute).to eq(true)
      end
    end
  end
end

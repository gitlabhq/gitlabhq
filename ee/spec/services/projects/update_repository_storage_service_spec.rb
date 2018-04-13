require 'spec_helper'

describe Projects::UpdateRepositoryStorageService do
  include StubConfiguration

  subject { described_class.new(project) }

  describe "#execute" do
    let(:time) { Time.now }

    before do
      FileUtils.mkdir('tmp/tests/storage_a')
      FileUtils.mkdir('tmp/tests/storage_b')

      storages = {
        'a' => { 'path' => 'tmp/tests/storage_a' },
        'b' => { 'path' => 'tmp/tests/storage_b' }
      }
      stub_storage_settings(storages)

      allow(Time).to receive(:now).and_return(time)
    end

    after do
      FileUtils.rm_rf('tmp/tests/storage_a')
      FileUtils.rm_rf('tmp/tests/storage_b')
    end

    context 'without wiki', :disable_gitaly do
      let(:project) { create(:project, :repository, repository_storage: 'a', repository_read_only: true, wiki_enabled: false) }

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read only' do
          expect_any_instance_of(Gitlab::Git::Repository).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(true)
          expect(GitlabShellWorker).to receive(:perform_async)
            .with(:mv_repository, 'a', project.disk_path,
              "#{project.disk_path}+#{project.id}+moved+#{time.to_i}")

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('b')
        end
      end

      context 'when the move fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          expect_any_instance_of(Gitlab::Git::Repository).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(false)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('a')
        end
      end
    end

    context 'with wiki', :disable_gitaly do
      let(:project) { create(:project, :repository, repository_storage: 'a', repository_read_only: true, wiki_enabled: true) }
      let(:repository_double) { double(:repository) }
      let(:wiki_repository_double) { double(:repository) }

      before do
        project.create_wiki

        # Default stub for non-specified params
        allow(Gitlab::Git::Repository).to receive(:new).and_call_original

        relative_path = project.repository.raw.relative_path
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('b', relative_path, "project-#{project.id}")
          .and_return(repository_double)

        wiki_relative_path = project.wiki.repository.raw.relative_path
        allow(Gitlab::Git::Repository).to receive(:new)
          .with('b', wiki_relative_path, "wiki-#{project.id}")
          .and_return(wiki_repository_double)
      end

      context 'when the move succeeds' do
        it 'moves the repository and its wiki to the new storage and unmarks the repository as read only' do
          expect(repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(true)
          expect(GitlabShellWorker).to receive(:perform_async)
            .with(:mv_repository, "a", project.disk_path,
              "#{project.disk_path}+#{project.id}+moved+#{time.to_i}")

          expect(wiki_repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.wiki.repository.raw).and_return(true)
          expect(GitlabShellWorker).to receive(:perform_async)
            .with(:mv_repository, "a", project.wiki.disk_path,
              "#{project.disk_path}+#{project.id}+moved+#{time.to_i}.wiki")

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('b')
        end
      end

      context 'when the move of the wiki fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          expect(repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.repository.raw).and_return(true)
          expect(wiki_repository_double).to receive(:fetch_repository_as_mirror)
            .with(project.wiki.repository.raw).and_return(false)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('a')
        end
      end
    end
  end
end

shared_examples 'geo base sync execution' do
  describe '#execute' do
    let(:project) { build('project')}

    context 'when can acquire exclusive lease' do
      before do
        exclusive_lease = double(:exclusive_lease, try_obtain: 12345)
        expect(subject).to receive(:exclusive_lease).and_return(exclusive_lease)
      end

      it 'executes the synchronization' do
        expect(subject).to receive(:sync_repository)

        subject.execute
      end
    end

    context 'when exclusive lease is not acquired' do
      before do
        exclusive_lease = double(:exclusive_lease, try_obtain: nil)
        expect(subject).to receive(:exclusive_lease).and_return(exclusive_lease)
      end

      it 'is does not execute synchronization' do
        expect(subject).not_to receive(:sync_repository)

        subject.execute
      end
    end
  end
end

shared_examples 'cleans temporary repositories' do
  context 'there is a leftover repository' do
    let(:temp_repo_path) { "@geo-temporary/#{repository.disk_path}" }

    it 'removes leftover repository' do
      gitlab_shell = instance_double('Gitlab::Shell')

      allow(subject).to receive(:gitlab_shell).and_return(gitlab_shell)
      allow(subject).to receive(:fetch_geo_mirror)

      expect(gitlab_shell).to receive(:exists?).and_return(true)
      expect(gitlab_shell).to receive(:remove_repository).with(project.repository_storage_path, temp_repo_path)

      subject.execute
    end
  end
end

shared_examples 'sync retries use the snapshot RPC' do
  let(:retry_count) { Geo::BaseSyncService::RETRY_BEFORE_REDOWNLOAD }

  context 'snapshot synchronization method' do
    before do
      allow(subject).to receive(:build_temporary_repository) { repository }
    end

    def receive_create_from_snapshot
      receive(:create_from_snapshot).with(primary.snapshot_url(repository), match(/^GL-Geo/))
    end

    it 'does not attempt to snapshot for initial sync' do
      expect(repository).not_to receive_create_from_snapshot
      expect(subject).to receive(:fetch_geo_mirror).with(repository)

      subject.execute
    end

    it 'does not attempt to snapshot for ordinary retries' do
      create(:geo_project_registry, project: project, repository_retry_count: retry_count - 1, wiki_retry_count: retry_count - 1)

      expect(repository).not_to receive_create_from_snapshot
      expect(subject).to receive(:fetch_geo_mirror).with(repository)

      subject.execute
    end

    context 'registry is ready to be snapshotted' do
      let!(:registry) { create(:geo_project_registry, project: project, repository_retry_count: retry_count + 1, wiki_retry_count: retry_count + 1) }

      it 'attempts to snapshot + fetch' do
        expect(repository).to receive_create_from_snapshot
        expect(subject).to receive(:fetch_geo_mirror).with(repository)

        subject.execute
      end

      it 'attempts to fetch if snapshotting raises an exception' do
        expect(repository).to receive_create_from_snapshot.and_raise(ArgumentError)
        expect(subject).to receive(:fetch_geo_mirror).with(repository)

        subject.execute
      end

      it 'does not attempt to snapshot if the feature flag is disabled' do
        stub_feature_flags(geo_redownload_with_snapshot: false)

        expect(repository).not_to receive_create_from_snapshot
        expect(subject).to receive(:fetch_geo_mirror).with(repository)

        subject.execute
      end
    end
  end
end

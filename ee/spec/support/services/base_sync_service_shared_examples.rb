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

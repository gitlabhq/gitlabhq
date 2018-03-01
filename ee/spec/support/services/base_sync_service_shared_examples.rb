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

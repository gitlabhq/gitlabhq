require 'spec_helper'

describe ClearNamespaceSharedRunnersMinutesService do
  describe '#execute' do
    subject { described_class.new(namespace).execute }

    context 'when project has namespace_statistics' do
      let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }

      it 'clears counters' do
        subject

        expect(namespace.namespace_statistics.reload.shared_runners_seconds).to eq(0)
      end

      it 'resets timer' do
        subject

        expect(namespace.namespace_statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.now)
      end

      it 'successfully clears minutes' do
        expect(subject).to be_truthy
      end
    end

    context 'when project does not have namespace_statistics' do
      let(:namespace) { create(:namespace) }

      it 'successfully clears minutes' do
        expect(subject).to be_truthy
      end
    end
  end
end

require 'spec_helper'

describe Geo::ProjectHousekeepingService do
  subject { described_class.new(project) }
  set(:project) { create(:project, :repository) }
  let(:registry) { subject.registry }

  before do
    registry.reset_syncs_since_gc
  end

  after do
    registry.reset_syncs_since_gc
  end

  describe '#execute' do
    it 'enqueues a sidekiq job' do
      expect(subject).to receive(:try_obtain_lease).and_return(:the_uuid)
      expect(subject).to receive(:lease_key).and_return(:the_lease_key)
      expect(subject).to receive(:task).and_return(:incremental_repack)
      expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :incremental_repack, :the_lease_key, :the_uuid).and_call_original

      Sidekiq::Testing.fake! do
        expect { subject.execute }.to change(GitGarbageCollectWorker.jobs, :size).by(1)
      end
    end

    it 'yields the block if given' do
      expect do |block|
        subject.execute(&block)
      end.to yield_with_no_args
    end

    it 'resets counter when syncs_since_gc > gc_period' do
      expect(subject).to receive(:try_obtain_lease).and_return(:the_uuid)
      allow(subject).to receive(:gc_period).and_return(1)
      registry.increment_syncs_since_gc

      Sidekiq::Testing.inline! do
        expect { subject.execute }.to change { registry.syncs_since_gc }.to(0)
      end
    end

    context 'when no lease can be obtained' do
      before do
        expect(subject).to receive(:try_obtain_lease).and_return(false)
      end

      it 'does not enqueue a job' do
        expect(GitGarbageCollectWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_falsey
      end

      it 'does not reset syncs_since_gc' do
        expect { subject.execute }.not_to change { registry.syncs_since_gc }
      end

      it 'does not yield' do
        expect { |block| subject.execute(&block) }.not_to yield_with_no_args
      end
    end

    context 'task type' do
      it 'goes through all three housekeeping tasks, executing only the highest task when there is overlap' do
        allow(subject).to receive(:try_obtain_lease).and_return(:the_uuid)
        allow(subject).to receive(:lease_key).and_return(:the_lease_key)

        # At push 200
        expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :gc, :the_lease_key, :the_uuid)
          .exactly(1).times
        # At push 50, 100, 150
        expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :full_repack, :the_lease_key, :the_uuid)
          .exactly(3).times
        # At push 10, 20, ... (except those above)
        expect(GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :incremental_repack, :the_lease_key, :the_uuid)
          .exactly(16).times

        201.times do
          subject.increment!
          subject.execute if subject.needed?
        end

        expect(registry.syncs_since_gc).to eq(1)
      end
    end
  end

  describe '#needed?' do
    it 'when the count is low enough' do
      expect(subject.needed?).to eq(false)
    end

    it 'when the count is high enough' do
      allow(registry).to receive(:syncs_since_gc).and_return(10)
      expect(subject.needed?).to eq(true)
    end
  end

  describe '#increment!' do
    it 'increments the syncs_since_gc counter' do
      expect { subject.increment! }.to change { registry.syncs_since_gc }.by(1)
    end
  end

  describe '#registry' do
    it 'returns a Geo::ProjectRegistry linked to current project' do
      expect(registry).to be_a(Geo::ProjectRegistry)
      expect(registry.project_id).to eq(project.id)
    end
  end
end

require 'spec_helper'

describe Admin::RunnersFinder do
  describe '#execute' do
    context 'with empty params' do
      it 'returns all runners' do
        runner1 = create :ci_runner, active: true
        runner2 = create :ci_runner, active: false

        expect(described_class.new(params: {}).execute).to match_array [runner1, runner2]
      end
    end

    context 'filter by search term' do
      it 'calls Ci::Runner.search' do
        expect(Ci::Runner).to receive(:search).with('term').and_call_original

        described_class.new(params: { search: 'term' }).execute
      end
    end

    context 'filter by status' do
      it 'calls the corresponding scope on Ci::Runner' do
        expect(Ci::Runner).to receive(:paused).and_call_original

        described_class.new(params: { status_status: 'paused' }).execute
      end
    end

    context 'sort' do
      context 'without sort param' do
        it 'sorts by id' do
          runner1 = create :ci_runner
          runner2 = create :ci_runner
          runner3 = create :ci_runner

          expect(described_class.new(params: {}).execute).to eq [runner3, runner2, runner1]
        end
      end

      context 'with sort param' do
        it 'sorts by specified attribute' do
          runner1 = create :ci_runner, contacted_at: 1.minute.ago
          runner2 = create :ci_runner, contacted_at: 3.minutes.ago
          runner3 = create :ci_runner, contacted_at: 2.minutes.ago

          expect(described_class.new(params: { sort: 'contacted_asc' }).execute).to eq [runner2, runner3, runner1]
        end
      end
    end

    context 'paginate' do
      it 'returns the runners for the specified page' do
        stub_const('Admin::RunnersFinder::NUMBER_OF_RUNNERS_PER_PAGE', 1)
        runner1 = create :ci_runner
        runner2 = create :ci_runner

        expect(described_class.new(params: { page: 1 }).execute).to eq [runner2]
        expect(described_class.new(params: { page: 2 }).execute).to eq [runner1]
      end
    end
  end
end

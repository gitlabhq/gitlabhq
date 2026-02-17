# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::BackgroundMigrationsHelper, feature_category: :database do
  describe '#batched_migration_status_badge_variant' do
    using RSpec::Parameterized::TableSyntax

    where(:status_name, :variant) do
      :active   | :info
      :paused   | :warning
      :failed   | :danger
      :finished | :success
    end

    subject { helper.batched_migration_status_badge_variant(migration) }

    with_them do
      let(:migration) { build(:batched_background_migration, status_name) }

      it { is_expected.to eq(variant) }
    end
  end

  describe '#batched_migration_progress' do
    subject { helper.batched_migration_progress(migration, completed_rows) }

    let(:migration) { build(:batched_background_migration, :active, total_tuple_count: 100) }
    let(:completed_rows) { 25 }

    it 'returns completion percentage' do
      expect(subject).to eq(25)
    end

    context 'when migration is finished' do
      let(:migration) { build(:batched_background_migration, :finished, total_tuple_count: nil) }

      it 'returns 100 percent' do
        expect(subject).to eq(100)
      end
    end

    context 'when total_tuple_count is nil' do
      let(:migration) { build(:batched_background_migration, :active, total_tuple_count: nil) }

      it 'returns nil' do
        expect(subject).to eq(nil)
      end

      context 'when there are no completed rows' do
        let(:completed_rows) { 0 }

        it 'returns 0 percent' do
          expect(subject).to eq(0)
        end
      end
    end

    context 'when completed rows are greater than total count' do
      let(:completed_rows) { 150 }

      it 'returns 99 percent' do
        expect(subject).to eq(99)
      end
    end
  end

  describe '#batched_migration_progress_with_estimate' do
    subject { helper.batched_migration_progress_with_estimate(migration, completed_rows) }

    let(:migration) { build(:batched_background_migration, :active, total_tuple_count: 100) }
    let(:completed_rows) { 25 }

    it 'returns formatted progress percentage' do
      expect(subject).to eq('25.00%')
    end

    context 'when migration has estimated_time_remaining' do
      before do
        allow(migration).to receive(:estimated_time_remaining).and_return('2 minutes')
      end

      it 'returns progress with estimated time remaining' do
        expect(subject).to eq('25.00% (estimated time remaining: 2 minutes)')
      end
    end

    context 'when migration is finished' do
      let(:migration) { build(:batched_background_migration, :finished, total_tuple_count: nil) }

      it 'returns 100 percent' do
        expect(subject).to eq('100.00%')
      end
    end

    context 'when progress is nil' do
      let(:migration) { build(:batched_background_migration, :active, total_tuple_count: nil) }
      let(:completed_rows) { 10 }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end

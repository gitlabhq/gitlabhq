# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::BackgroundMigrationsHelper do
  describe '#batched_migration_status_badge_class_name' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :class_name) do
      :active   | 'badge-info'
      :paused   | 'badge-warning'
      :failed   | 'badge-danger'
      :finished | 'badge-success'
    end

    subject { helper.batched_migration_status_badge_class_name(migration) }

    with_them do
      let(:migration) { build(:batched_background_migration, status: status) }

      it { is_expected.to eq(class_name) }
    end
  end

  describe '#batched_migration_progress' do
    subject { helper.batched_migration_progress(migration, completed_rows) }

    let(:migration) { build(:batched_background_migration, status: :active, total_tuple_count: 100) }
    let(:completed_rows) { 25 }

    it 'returns completion percentage' do
      expect(subject).to eq(25)
    end

    context 'when migration is finished' do
      let(:migration) { build(:batched_background_migration, status: :finished, total_tuple_count: nil) }

      it 'returns 100 percent' do
        expect(subject).to eq(100)
      end
    end

    context 'when total_tuple_count is nil' do
      let(:migration) { build(:batched_background_migration, status: :active, total_tuple_count: nil) }

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
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationsFinder do
  let!(:migration_1) { create(:batched_background_migration, created_at: Time.now - 2) }
  let!(:migration_2) { create(:batched_background_migration, created_at: Time.now - 1) }
  let!(:migration_3) { create(:batched_background_migration, created_at: Time.now - 3) }

  let(:finder) { described_class.new(connection: connection) }

  describe '#execute' do
    let(:connection) { ApplicationRecord.connection }

    subject { finder.execute }

    it 'returns migrations order by created_at (DESC)' do
      is_expected.to eq([migration_2, migration_1, migration_3])
    end

    it 'limits the number of returned migrations' do
      stub_const('Database::BatchedBackgroundMigrationsFinder::RETURNED_MIGRATIONS', 2)

      is_expected.to eq([migration_2, migration_1])
    end
  end
end

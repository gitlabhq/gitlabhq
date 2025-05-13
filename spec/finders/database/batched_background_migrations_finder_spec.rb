# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationsFinder do
  include Database::MultipleDatabasesHelpers

  let!(:migration_1) { create(:batched_background_migration, created_at: Time.now - 2) }
  let!(:migration_2) { create(:batched_background_migration, created_at: Time.now - 1) }
  let!(:migration_3) { create(:batched_background_migration, created_at: Time.now - 3) }

  let(:params) { { database: 'main' } }

  let(:finder) { described_class.new(params: params) }

  describe '#execute' do
    subject(:execute) { finder.execute }

    it 'returns migrations order by created_at (DESC)' do
      is_expected.to eq([migration_2, migration_1, migration_3])
    end

    it 'limits the number of returned migrations' do
      stub_const('Database::BatchedBackgroundMigrationsFinder::RETURNED_MIGRATIONS', 2)

      is_expected.to eq([migration_2, migration_1])
    end

    context 'when database is not main' do
      using RSpec::Parameterized::TableSyntax
      let_it_be(:gitlab_ci) { create(:batched_background_migration, gitlab_schema: :gitlab_ci) }
      let_it_be(:gitlab_sec) { create(:batched_background_migration, gitlab_schema: :gitlab_sec) }

      let(:params) { { database: database } }

      where(:database, :expected_migrations) do
        :ci        | [ref(:gitlab_ci)]
        :sec       | [ref(:gitlab_sec)]
      end

      with_them do
        it 'uses correct connection if database is setup' do
          skip_if_multiple_databases_not_setup(database)

          expect(execute).to eq(expected_migrations)
        end

        it 'performs a no-op if database is not setup' do
          skip_if_multiple_databases_are_setup(database)

          expect(execute).to eq([])
        end
      end
    end

    describe 'filtering by job class' do
      let!(:my_migration) { create(:batched_background_migration, job_class_name: "MyJob") }

      let(:params) { { database: 'main', job_class_name: "MyJob" } }

      it 'returns filtered results' do
        is_expected.to eq([my_migration])
      end
    end

    context 'when database is not set' do
      let(:params) { {} }

      it 'raises ArgumentError' do
        expect { execute }.to raise_error(ArgumentError)
      end
    end
  end
end

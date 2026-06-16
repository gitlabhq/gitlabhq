# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundOperationsCellLocalFinder, feature_category: :database do
  include Database::MultipleDatabasesHelpers

  let!(:operation_1) { create(:background_operation_worker_cell_local, created_at: 2.minutes.ago) }
  let!(:operation_2) { create(:background_operation_worker_cell_local, created_at: 1.minute.ago) }
  let!(:operation_3) { create(:background_operation_worker_cell_local, created_at: 3.minutes.ago) }

  let(:params) { { database: 'main' } }

  let(:finder) { described_class.new(params: params) }

  describe '#execute' do
    subject(:execute) { finder.execute }

    it 'returns cell-local operations ordered by created_at (DESC)' do
      is_expected.to eq([operation_2, operation_1, operation_3])
    end

    it 'limits the number of returned operations' do
      stub_const("#{described_class}::RETURNED_OPERATIONS", 2)

      is_expected.to eq([operation_2, operation_1])
    end

    it 'does not include org-scoped workers' do
      org_operation = create(:background_operation_worker)

      expect(execute).not_to include(org_operation)
    end

    context 'when database is not main' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:gitlab_ci) { create(:background_operation_worker_cell_local, gitlab_schema: :gitlab_ci) }
      let_it_be(:gitlab_sec) { create(:background_operation_worker_cell_local, gitlab_schema: :gitlab_sec) }

      let(:params) { { database: database } }

      where(:database, :expected_operations) do
        :ci  | [ref(:gitlab_ci)]
        :sec | [ref(:gitlab_sec)]
      end

      with_them do
        it 'uses correct connection if database is setup' do
          skip_if_multiple_databases_not_setup(database)

          expect(execute).to eq(expected_operations)
        end

        it 'performs a no-op if database is not setup' do
          skip_if_multiple_databases_are_setup(database)

          expect(execute).to eq([])
        end
      end
    end

    describe 'filtering by job class' do
      let!(:my_operation) { create(:background_operation_worker_cell_local, job_class_name: 'MyJob') }

      let(:params) { { database: 'main', job_class_name: 'MyJob' } }

      it 'returns filtered results' do
        is_expected.to eq([my_operation])
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

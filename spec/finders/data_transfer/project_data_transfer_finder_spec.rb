# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DataTransfer::ProjectDataTransferFinder, feature_category: :source_code_management do
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:user) { project_1.first_owner }
  let(:from_date) { Date.new(2022, 2, 1) }
  let(:to_date) { Date.new(2023, 1, 1) }

  describe '#execute' do
    let(:subject) { described_class.new(project: project_1, from: from_date, to: to_date, user: user) }

    before do
      create(:project_data_transfer, project: project_1, date: '2022-01-01')
      create(:project_data_transfer, project: project_1, date: '2022-02-01')
      create(:project_data_transfer, project: project_1, date: '2022-03-01')
      create(:project_data_transfer, project: project_2, date: '2022-01-01')
    end

    it 'returns the correct number of egress' do
      expect(subject.execute.size).to eq(2)
    end

    it 'returns the correct values' do
      first_result = subject.execute.first
      expect(first_result.attributes).to include(
        {
          'project_id' => project_1.id,
          'date' => from_date,
          'repository_egress' => 1,
          'artifacts_egress' => 2,
          'packages_egress' => 3,
          'registry_egress' => 4,
          'total_egress' => 10
        }
      )
    end

    context 'when there are no results for specified dates' do
      let(:from_date) { Date.new(2021, 1, 1) }
      let(:to_date) { Date.new(2021, 1, 1) }

      it 'returns nothing' do
        expect(subject.execute).to be_empty
      end
    end

    context 'when there are no results for specified project' do
      let_it_be(:project_3) { create(:project, :repository) }
      let(:subject) { described_class.new(project: project_3, from: from_date, to: to_date, user: user) }

      it 'returns nothing' do
        expect(subject.execute).to be_empty
      end
    end

    context 'when dates are not provided' do
      let(:from_date) { nil }
      let(:to_date) { nil }

      it 'return all values for a project', :aggregate_failures do
        results = subject.execute
        expect(results.size).to eq(3)
        results.each do |result|
          expect(result.project).to eq(project_1)
        end
      end
    end

    context 'when user does not have permissions' do
      let(:user) { build(:user) }

      it 'returns nothing' do
        expect(subject.execute).to be_empty
      end
    end
  end
end

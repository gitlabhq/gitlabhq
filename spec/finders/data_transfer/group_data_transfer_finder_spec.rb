# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DataTransfer::GroupDataTransferFinder, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace_1) { create(:group, owners: user) }
  let_it_be(:project_1) { create(:project, group: namespace_1) }
  let_it_be(:project_2) { create(:project, group: namespace_1) }
  let(:from_date) { Date.new(2022, 2, 1) }
  let(:to_date) { Date.new(2023, 1, 1) }

  describe '#execute' do
    let(:subject) { described_class.new(group: namespace_1, from: from_date, to: to_date, user: user) }

    before do
      create(:project_data_transfer, project: project_1, date: '2022-01-01')
      create(:project_data_transfer, project: project_1, date: '2022-02-01')
      create(:project_data_transfer, project: project_2, date: '2022-02-01')
    end

    it 'returns the correct number of egress' do
      expect(subject.execute.to_a.size).to eq(1)
    end

    it 'returns the correct values grouped by date' do
      first_result = subject.execute.first
      expect(first_result.attributes).to include(
        {
          'namespace_id' => namespace_1.id,
          'date' => from_date,
          'repository_egress' => 2,
          'artifacts_egress' => 4,
          'packages_egress' => 6,
          'registry_egress' => 8,
          'total_egress' => 20
        }
      )
    end

    context 'when there are no results for specified namespace' do
      let_it_be(:namespace_2) { create(:group) }
      let(:subject) { described_class.new(group: namespace_2, from: from_date, to: to_date, user: user) }

      it 'returns nothing' do
        expect(subject.execute).to be_empty
      end
    end

    context 'when there are no results for specified dates' do
      let(:from_date) { Date.new(2021, 1, 1) }
      let(:to_date) { Date.new(2021, 1, 1) }

      it 'returns nothing' do
        expect(subject.execute).to be_empty
      end
    end

    context 'when dates are not provided' do
      let(:from_date) { nil }
      let(:to_date) { nil }

      it 'return all values for a namespace', :aggregate_failures do
        results = subject.execute
        expect(results.to_a.size).to eq(2)
        results.each do |result|
          expect(result.namespace).to eq(namespace_1)
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

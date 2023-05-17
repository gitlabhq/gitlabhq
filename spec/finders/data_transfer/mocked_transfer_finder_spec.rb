# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DataTransfer::MockedTransferFinder, feature_category: :source_code_management do
  describe '#execute' do
    subject(:execute) { described_class.new.execute }

    it 'returns mock data' do
      expect(execute.first).to include(
        date: '2023-01-01',
        repository_egress: be_a(Integer),
        artifacts_egress: be_a(Integer),
        packages_egress: be_a(Integer),
        registry_egress: be_a(Integer),
        total_egress: be_a(Integer)
      )

      expect(execute.size).to eq(12)
    end
  end
end

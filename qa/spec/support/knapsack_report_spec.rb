# frozen_string_literal: true

RSpec.describe QA::Support::KnapsackReport do
  subject(:knapsack_report) { described_class.new('instance') }

  describe '#create_for_selective' do
    let(:qa_tests) do
      <<~CMD
        qa/specs/features/api/3_create
        qa/specs/features/browser_ui/3_create/
        qa/specs/features/ee/api/3_create/
        qa/specs/features/ee/browser_ui/3_create/
      CMD
    end

    let(:fixtures_path) { 'spec/fixtures/knapsack_report' }
    let(:expected_output) { JSON.parse(File.read(File.join(fixtures_path, 'instance-selective-parallel.json'))) }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read)
                       .with('knapsack/instance.json')
                       .and_return(File.read(File.join(fixtures_path, 'instance.json')))
    end

    it 'creates a filtered file based on qa_tests' do
      expect(File).to receive(:write).with('knapsack/instance-selective-parallel.json', expected_output.to_json)

      knapsack_report.create_for_selective(qa_tests)
    end
  end
end

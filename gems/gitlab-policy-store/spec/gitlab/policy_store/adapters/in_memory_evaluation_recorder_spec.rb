# frozen_string_literal: true

RSpec.describe Gitlab::PolicyStore::Adapters::InMemoryEvaluationRecorder do
  subject(:recorder) { described_class.new }

  let(:organization_id) { 1 }
  let(:policy_id) { 42 }

  it_behaves_like 'an evaluation recorder'

  describe '#record' do
    it 'returns a copy that does not share mutable state with the input' do
      details = { 'reason' => 'original' }
      evaluation = recorder.record(
        organization_id: organization_id,
        policy_id: policy_id,
        policy_version: 1,
        trigger_type: 'deployment_requested',
        mode: 'audit',
        verdict: 'deny',
        evaluated_at: Time.now.utc,
        violations: [{ details: details }]
      )

      details['reason'] = 'mutated'

      expect(evaluation.violations.first.details).to eq('reason' => 'original')
    end
  end
end

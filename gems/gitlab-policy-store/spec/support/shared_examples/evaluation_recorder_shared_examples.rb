# frozen_string_literal: true

RSpec.shared_examples 'an evaluation recorder' do
  let(:evaluated_at) { Time.now.utc.round }

  def attributes
    {
      organization_id: organization_id,
      policy_id: policy_id,
      policy_version: 3,
      trigger_type: 'deployment_requested',
      mode: 'enforce',
      verdict: 'deny',
      evaluated_at: evaluated_at,
      project_id: 11,
      environment_id: 12,
      user_id: 13,
      violations: [
        { details: { 'rule_index' => 0, 'reason' => 'environment tier is production' } },
        { details: { 'rule_index' => 1 } }
      ]
    }
  end

  def minimal_attributes
    {
      organization_id: organization_id,
      policy_id: policy_id,
      policy_version: 1,
      trigger_type: 'deployment_requested',
      mode: 'audit',
      verdict: 'allow',
      evaluated_at: evaluated_at
    }
  end

  describe '#record' do
    it 'persists the evaluation and returns a Gitlab::PolicyStore::Evaluation' do
      evaluation = recorder.record(attributes)

      expect(evaluation).to be_a(Gitlab::PolicyStore::Evaluation)
      expect(evaluation).to have_attributes(
        id: be_truthy,
        organization_id: organization_id,
        policy_id: policy_id,
        policy_version: 3,
        trigger_type: 'deployment_requested',
        mode: 'enforce',
        verdict: 'deny',
        evaluated_at: evaluated_at,
        project_id: 11,
        environment_id: 12,
        user_id: 13
      )
    end

    it 'persists the violations and returns them as Gitlab::PolicyStore::Violation' do
      violations = recorder.record(attributes).violations

      expect(violations).to all(be_a(Gitlab::PolicyStore::Violation))
      expect(violations.map(&:id)).to all(be_truthy)
      expect(violations.map(&:details)).to eq(
        [
          { 'rule_index' => 0, 'reason' => 'environment tier is production' },
          { 'rule_index' => 1 }
        ])
    end

    it 'returns deeply immutable value objects' do
      evaluation = recorder.record(attributes)

      expect(evaluation).to be_frozen
      expect { evaluation.violations << nil }.to raise_error(FrozenError)
      expect { evaluation.violations.first.details['reason'] = 'mutated' }.to raise_error(FrozenError)
    end

    it 'applies default values for optional attributes' do
      evaluation = recorder.record(minimal_attributes)

      expect(evaluation).to have_attributes(
        project_id: nil,
        environment_id: nil,
        user_id: nil,
        violations: []
      )
    end

    it 'accepts string keys for attributes' do
      evaluation = recorder.record(minimal_attributes.transform_keys(&:to_s))

      expect(evaluation).to have_attributes(
        organization_id: organization_id,
        policy_id: policy_id,
        verdict: 'allow'
      )
    end

    it 'accepts symbols for enum attributes' do
      evaluation = recorder.record(minimal_attributes.merge(trigger_type: :deployment_promoted, verdict: :allow))

      expect(evaluation).to have_attributes(trigger_type: 'deployment_promoted', verdict: 'allow')
    end

    Gitlab::PolicyStore::Ports::EvaluationRecorder::REQUIRED_ATTRIBUTES.each do |required|
      it "rejects a missing #{required}" do
        expect { recorder.record(minimal_attributes.except(required)) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /Missing required attributes: #{required}/)
      end
    end

    it 'rejects unknown attributes' do
      expect { recorder.record(minimal_attributes.merge(duration_ms: 5)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /Unknown attributes: duration_ms/)
    end

    { trigger_type: 'merge_request_created', mode: 'dry_run', verdict: 'abstain' }.each do |attribute, value|
      it "rejects an unknown #{attribute}" do
        expect { recorder.record(minimal_attributes.merge(attribute => value)) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /#{attribute} must be one of/)
      end
    end

    it 'rejects a non-positive policy_version' do
      expect { recorder.record(minimal_attributes.merge(policy_version: 0)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /policy_version must be a positive integer/)
    end

    it 'rejects violations that are not an array of hashes' do
      expect { recorder.record(minimal_attributes.merge(violations: 'broken')) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /violations must be an array/)

      expect { recorder.record(minimal_attributes.merge(violations: ['broken'])) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /violations must be an array/)
    end

    it 'rejects violation entries with unknown attributes' do
      expect { recorder.record(minimal_attributes.merge(violations: [{ severity: 'high' }])) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /Unknown violation attributes: severity/)
    end
  end
end

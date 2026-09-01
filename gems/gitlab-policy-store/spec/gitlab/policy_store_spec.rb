# frozen_string_literal: true

RSpec.describe Gitlab::PolicyStore do
  let(:repository) { instance_double(Gitlab::PolicyStore::Ports::PolicyRepository) }
  let(:evaluation_recorder) { instance_double(Gitlab::PolicyStore::Ports::EvaluationRecorder) }

  after do
    described_class.reset_configuration!
  end

  describe 'default configuration' do
    it 'uses the in-memory adapters' do
      expect(described_class.configuration.repository)
        .to be_a(Gitlab::PolicyStore::Adapters::InMemoryPolicyRepository)
      expect(described_class.configuration.evaluation_recorder)
        .to be_a(Gitlab::PolicyStore::Adapters::InMemoryEvaluationRecorder)
    end
  end

  describe '.reset_configuration!' do
    it 'restores the default configuration' do
      described_class.configure { |config| config.repository = repository }

      described_class.reset_configuration!

      expect(described_class.configuration.repository)
        .to be_a(Gitlab::PolicyStore::Adapters::InMemoryPolicyRepository)
    end

    it 'discards policies held by the in-memory adapter' do
      policy = described_class.create(
        organization_id: 1,
        namespace_id: 10,
        name: 'policy',
        trigger_type: 'deployment_requested'
      )

      described_class.reset_configuration!

      expect { described_class.find(policy.id) }.to raise_error(Gitlab::PolicyStore::NotFound)
    end
  end

  context 'with an injected repository' do
    before do
      allow(described_class).to receive(:configuration)
        .and_return(Gitlab::PolicyStore::Configuration.new(repository, evaluation_recorder))
    end

    describe '#create' do
      it 'delegates to the configured repository' do
        attributes = { name: 'policy' }
        policy = instance_double(Gitlab::PolicyStore::Policy)
        allow(repository).to receive(:create).with(attributes).and_return(policy)

        expect(described_class.create(attributes)).to eq(policy)
      end
    end

    describe '#update' do
      it 'delegates to the configured repository' do
        attributes = { name: 'renamed' }
        policy = instance_double(Gitlab::PolicyStore::Policy)
        allow(repository).to receive(:update).with(1, attributes).and_return(policy)

        expect(described_class.update(1, attributes)).to eq(policy)
      end
    end

    describe '#find' do
      it 'delegates to the configured repository' do
        policy = instance_double(Gitlab::PolicyStore::Policy)
        allow(repository).to receive(:find).with(1).and_return(policy)

        expect(described_class.find(1)).to eq(policy)
      end
    end

    describe '#delete' do
      it 'delegates to the configured repository' do
        allow(repository).to receive(:delete).with(1).and_return(nil)

        expect(described_class.delete(1)).to be_nil
      end
    end

    describe '#record_evaluation' do
      it 'delegates to the configured evaluation recorder' do
        attributes = { policy_id: 1, verdict: 'deny' }
        evaluation = instance_double(Gitlab::PolicyStore::Evaluation)
        allow(evaluation_recorder).to receive(:record).with(attributes).and_return(evaluation)

        expect(described_class.record_evaluation(attributes)).to eq(evaluation)
      end
    end

    describe '#list' do
      it 'delegates to the configured repository, defaulting trigger_type, ids, offset and per_page' do
        unfiltered = instance_double(Gitlab::PolicyStore::Page)
        filtered = instance_double(Gitlab::PolicyStore::Page)
        allow(repository).to receive(:list).with(
          organization_id: 5, trigger_type: nil, ids: nil, offset: 0,
          per_page: Gitlab::PolicyStore::Ports::PolicyRepository::DEFAULT_PER_PAGE
        ).and_return(unfiltered)
        allow(repository).to receive(:list)
          .with(organization_id: 5, trigger_type: 'deployment_requested', ids: [1, 2], offset: 20, per_page: 10)
          .and_return(filtered)

        expect(described_class.list(organization_id: 5)).to eq(unfiltered)
        expect(
          described_class.list(
            organization_id: 5, trigger_type: 'deployment_requested', ids: [1, 2], offset: 20, per_page: 10
          )
        ).to eq(filtered)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Gitlab::PolicyStore do
  let(:repository) { instance_double(Gitlab::PolicyStore::Ports::PolicyRepository) }

  after do
    described_class.reset_configuration!
  end

  describe 'default configuration' do
    it 'uses the in-memory adapter' do
      expect(described_class.configuration.repository)
        .to be_a(Gitlab::PolicyStore::Adapters::InMemoryPolicyRepository)
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
        .and_return(Gitlab::PolicyStore::Configuration.new(repository))
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

    describe '#list' do
      it 'delegates to the configured repository, defaulting trigger_type to nil' do
        unfiltered = [instance_double(Gitlab::PolicyStore::Policy)]
        filtered = [instance_double(Gitlab::PolicyStore::Policy)]
        allow(repository).to receive(:list).with(organization_id: 5, trigger_type: nil).and_return(unfiltered)
        allow(repository).to receive(:list)
          .with(organization_id: 5, trigger_type: 'deployment_requested').and_return(filtered)

        expect(described_class.list(organization_id: 5)).to eq(unfiltered)
        expect(described_class.list(organization_id: 5, trigger_type: 'deployment_requested')).to eq(filtered)
      end
    end
  end
end

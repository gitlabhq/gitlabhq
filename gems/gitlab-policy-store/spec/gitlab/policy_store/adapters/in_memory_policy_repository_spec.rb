# frozen_string_literal: true

RSpec.describe Gitlab::PolicyStore::Adapters::InMemoryPolicyRepository do
  subject(:repository) { described_class.new }

  let(:organization_id) { 1 }

  it_behaves_like 'a policy repository'

  describe 'validation messages' do
    let(:valid_attributes) do
      { organization_id: organization_id, name: 'Limits policy', trigger_type: 'merge_request' }
    end

    it 'names the attribute and the limit on create' do
      expect { repository.create(valid_attributes.merge(name: 'a' * 256)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, 'name exceeds maximum length of 255 characters')
    end

    it 'names the attribute and the limit on update' do
      created = repository.create(valid_attributes)

      expect { repository.update(created.id, description: 'a' * 4097) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, 'description exceeds maximum length of 4096 characters')
    end

    it 'lists every missing required attribute at once' do
      expect { repository.create({}) }
        .to raise_error(Gitlab::PolicyStore::ValidationError,
          'Missing required attributes: organization_id, name, trigger_type')
    end
  end

  describe '#create' do
    it 'rejects an over-limit name before the scope reaches the transpiler' do
      expect(Gitlab::PolicyStore::ScopeTranspiler).not_to receive(:new)

      limits = Gitlab::PolicyStore::Ports::PolicyRepository::TEXT_LIMITS
      over_limit_name_attributes = {
        organization_id: organization_id,
        name: 'n' * (limits[:name] + 1),
        trigger_type: 'deployment_requested',
        policy_scope: { 'projects' => { 'including' => [{ 'id' => 1 }] } },
        scope_rego: nil
      }

      expect { repository.create(over_limit_name_attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name exceeds maximum length/)
    end
  end

  describe '#update' do
    it 'rejects an over-limit name before the scope reaches the transpiler' do
      created = repository.create(
        organization_id: organization_id,
        name: 'Renameable',
        trigger_type: 'deployment_requested',
        policy_scope: { 'projects' => { 'including' => [{ 'id' => 1 }] } }
      )

      expect(Gitlab::PolicyStore::ScopeTranspiler).not_to receive(:new)

      limits = Gitlab::PolicyStore::Ports::PolicyRepository::TEXT_LIMITS

      expect { repository.update(created.id, name: 'n' * (limits[:name] + 1)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name exceeds maximum length/)
    end
  end
end

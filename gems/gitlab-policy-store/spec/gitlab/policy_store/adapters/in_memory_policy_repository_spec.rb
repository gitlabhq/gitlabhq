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
end

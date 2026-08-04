# frozen_string_literal: true

# Contract shared by every Gitlab::PolicyStore::Ports::PolicyRepository
# implementation. Any adapter (in-memory today, a remote client later) must
# satisfy it, which is what guarantees they are interchangeable behind the
# facade.
#
# Requires the including context to define:
#   - `repository`        the adapter under test
#   - `organization_id`   a valid organization id
RSpec.shared_examples 'a policy repository' do
  let(:non_existing_id) { -1 }
  let(:other_organization_id) { organization_id + 1 }

  let(:attributes) do
    {
      organization_id: organization_id,
      name: 'My approval policy',
      trigger_id: 'merge_request',
      rules: { 'rules' => [{ 'type' => 'scan_finding' }] },
      actions: [{ 'type' => 'require_approval' }],
      policy_scope: { 'compliance_frameworks' => [] },
      scope_rego: 'package gitlab.policy.scope',
      mode: 'audit',
      lifecycle_state: 'active'
    }
  end

  let(:minimal_attributes) do
    {
      organization_id: organization_id,
      name: 'Minimal policy',
      trigger_id: 'merge_request'
    }
  end

  describe '#create' do
    it 'persists the policy and returns a Gitlab::PolicyStore::Policy', :aggregate_failures do
      policy = repository.create(attributes)

      expect(policy).to be_a(Gitlab::PolicyStore::Policy)
      expect(policy).to have_attributes(
        id: be_truthy,
        organization_id: organization_id,
        name: 'My approval policy',
        trigger_id: 'merge_request',
        rules: { 'rules' => [{ 'type' => 'scan_finding' }] },
        actions: [{ 'type' => 'require_approval' }],
        scope_rego: 'package gitlab.policy.scope',
        mode: 'audit',
        lifecycle_state: 'active'
      )
    end

    it 'applies default values for optional attributes' do
      policy = repository.create(minimal_attributes)

      expect(policy).to have_attributes(
        version: 1,
        rules: {},
        actions: [],
        mode: 'enforce',
        lifecycle_state: 'active'
      )
    end

    it 'accepts string keys for attributes', :aggregate_failures do
      string_key_attributes = {
        'organization_id' => organization_id,
        'name' => 'String key policy',
        'trigger_id' => 'merge_request'
      }

      policy = repository.create(string_key_attributes)

      expect(policy).to be_a(Gitlab::PolicyStore::Policy)
      expect(policy.name).to eq('String key policy')
      expect(policy.organization_id).to eq(organization_id)
    end

    it 'raises ValidationError when organization_id is missing' do
      invalid_attributes = attributes.merge(organization_id: nil)

      expect { repository.create(invalid_attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /organization_id/)
    end

    it 'raises ValidationError when name is missing' do
      invalid_attributes = attributes.merge(name: nil)

      expect { repository.create(invalid_attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name/)
    end

    it 'raises ValidationError when trigger_id is missing' do
      invalid_attributes = attributes.merge(trigger_id: nil)

      expect { repository.create(invalid_attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /trigger_id/)
    end

    it 'raises ValidationError when name is an empty string' do
      invalid_attributes = attributes.merge(name: '')

      expect { repository.create(invalid_attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name/)
    end
  end

  describe '#find' do
    it 'returns the previously created policy' do
      created = repository.create(attributes)

      expect(repository.find(created.id)).to eq(created)
    end

    it 'raises Gitlab::PolicyStore::NotFound when the policy does not exist' do
      expect { repository.find(non_existing_id) }.to raise_error(Gitlab::PolicyStore::NotFound)
    end
  end

  describe '#delete' do
    it 'removes the policy from the repository' do
      created = repository.create(attributes)

      repository.delete(created.id)

      expect { repository.find(created.id) }.to raise_error(Gitlab::PolicyStore::NotFound)
    end

    it 'returns nil on success' do
      created = repository.create(attributes)

      expect(repository.delete(created.id)).to be_nil
    end

    it 'raises Gitlab::PolicyStore::NotFound when the policy does not exist' do
      expect { repository.delete(non_existing_id) }.to raise_error(Gitlab::PolicyStore::NotFound)
    end
  end

  describe '#list' do
    it 'returns the policies for the organization' do
      created = repository.create(attributes)

      expect(repository.list(organization_id: organization_id)).to contain_exactly(created)
    end

    it 'returns an empty array when no policies exist for the organization' do
      expect(repository.list(organization_id: organization_id)).to be_empty
    end

    it 'excludes policies from other organizations' do
      other_org_attributes = attributes.merge(organization_id: other_organization_id)
      repository.create(other_org_attributes)
      our_policy = repository.create(attributes)

      expect(repository.list(organization_id: organization_id)).to contain_exactly(our_policy)
    end

    it 'does not include deleted policies' do
      created = repository.create(attributes)
      repository.delete(created.id)

      expect(repository.list(organization_id: organization_id)).to be_empty
    end
  end
end

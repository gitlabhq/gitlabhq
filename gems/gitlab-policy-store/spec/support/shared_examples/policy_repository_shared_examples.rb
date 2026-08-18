# frozen_string_literal: true

require_relative 'policy_repository_scope_shared_examples'

RSpec.shared_examples 'a policy repository' do
  port = Gitlab::PolicyStore::Ports::PolicyRepository

  let(:other_organization_id) { organization_id + 1 }
  let(:namespace_id) { 1 }
  let(:trigger_type) { 'deployment_requested' }
  let(:other_trigger_type) { 'deployment_promoted' }

  def non_existing_id
    -1
  end

  def attributes
    {
      organization_id: organization_id,
      namespace_id: namespace_id,
      name: 'My approval policy',
      description: 'Requires approval for scan findings',
      trigger_type: trigger_type,
      rules: [{ 'type' => 'scan_finding' }],
      actions: [{ 'type' => 'require_approval' }],
      policy_scope: { 'compliance_frameworks' => [{ 'id' => 5 }] },
      scope_rego: 'package gitlab.scope',
      mode: 'audit',
      lifecycle_state: 'active'
    }
  end

  def minimal_attributes
    {
      organization_id: organization_id,
      name: 'Minimal policy',
      trigger_type: trigger_type
    }
  end

  it_behaves_like 'a policy repository reconciling scope forms'

  describe '#create' do
    it 'persists the policy and returns a Gitlab::PolicyStore::Policy', :aggregate_failures do
      policy = repository.create(attributes)

      expect(policy).to be_a(Gitlab::PolicyStore::Policy)
      expect(policy).to have_attributes(
        id: be_truthy,
        organization_id: organization_id,
        namespace_id: namespace_id,
        name: 'My approval policy',
        description: 'Requires approval for scan findings',
        trigger_type: trigger_type,
        rules: [{ 'type' => 'scan_finding' }],
        actions: [{ 'type' => 'require_approval' }],
        scope_rego: 'package gitlab.scope',
        mode: 'audit',
        lifecycle_state: 'active'
      )
    end

    it 'applies default values for optional attributes' do
      policy = repository.create(minimal_attributes)

      expect(policy).to have_attributes(
        version: 1,
        namespace_id: nil,
        description: nil,
        rules: [],
        actions: [],
        mode: 'enforce',
        lifecycle_state: 'active'
      )
    end

    it 'accepts string keys for attributes', :aggregate_failures do
      string_key_attributes = {
        'organization_id' => organization_id,
        'namespace_id' => namespace_id,
        'name' => 'String key policy',
        'trigger_type' => trigger_type
      }

      policy = repository.create(string_key_attributes)

      expect(policy).to be_a(Gitlab::PolicyStore::Policy)
      expect(policy.name).to eq('String key policy')
      expect(policy.organization_id).to eq(organization_id)
      expect(policy.namespace_id).to eq(namespace_id)
    end

    it 'stores symbol-keyed json attributes with string keys, matching what jsonb returns' do
      symbol_keyed = attributes.merge(
        rules: [{ type: :scan_finding }],
        actions: [{ type: :require_approval }],
        policy_scope: { compliance_frameworks: [{ id: 5 }] },
        scope_rego: nil
      )

      expect(repository.create(symbol_keyed)).to have_attributes(
        rules: [{ 'type' => 'scan_finding' }],
        actions: [{ 'type' => 'require_approval' }],
        policy_scope: { 'compliance_frameworks' => [{ 'id' => 5 }] }
      )
    end

    it 'stores symbol values on text attributes as strings, matching what a text column returns' do
      symbol_valued = attributes.merge(
        trigger_type: :deployment_requested,
        mode: :audit,
        lifecycle_state: :active
      )

      expect(repository.create(symbol_valued)).to have_attributes(
        trigger_type: 'deployment_requested',
        mode: 'audit',
        lifecycle_state: 'active'
      )
    end

    (port::REQUIRED_ATTRIBUTES + port::NON_NULLABLE_ATTRIBUTES).each do |attribute|
      it "raises ValidationError when #{attribute} is nil" do
        expect { repository.create(attributes.merge(attribute => nil)) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /#{attribute}/i)
      end
    end

    it 'accepts a policy with no namespace_id' do
      organization_owned = attributes.merge(namespace_id: nil)

      expect(repository.create(organization_owned)).to have_attributes(
        namespace_id: nil,
        organization_id: organization_id
      )
    end

    it 'raises ValidationError when name is only whitespace' do
      invalid_attributes = attributes.merge(name: "  \t\n ")

      expect { repository.create(invalid_attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name/i)
    end

    port::TEXT_LIMITS.each do |attribute, limit|
      it "raises ValidationError when #{attribute} exceeds #{limit} characters" do
        expect { repository.create(attributes.merge(attribute => 'a' * (limit + 1))) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /#{attribute.to_s.tr('_', '.')}/i)
      end
    end

    it 'accepts a scope_rego at exactly the limit' do
      limit = Gitlab::PolicyStore::Ports::PolicyRepository::TEXT_LIMITS[:scope_rego]
      at_limit = attributes.merge(scope_rego: 'p' * limit)

      expect(repository.create(at_limit).scope_rego.length).to eq(limit)
    end

    it 'raises ValidationError when a policy_scope compiles past the scope_rego limit' do
      limit = Gitlab::PolicyStore::Ports::PolicyRepository::TEXT_LIMITS[:scope_rego]
      # One project id per allowed character overshoots the limit, since each id writes at
      # least one character plus a separator.
      too_many_projects = { 'projects' => { 'including' => (1..limit).map { |id| { 'id' => id } } } }

      expect { repository.create(attributes.merge(policy_scope: too_many_projects, scope_rego: nil)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /scope_rego exceeds maximum length of #{limit}/)
    end

    it 'allows nil description without raising ValidationError' do
      valid_attributes = minimal_attributes.merge(description: nil)

      expect { repository.create(valid_attributes) }.not_to raise_error
    end

    it 'rejects a name the organization already uses' do
      repository.create(attributes)

      expect { repository.create(attributes) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /taken/i)
    end

    it 'rejects a name another policy in the organization uses, whoever owns it' do
      repository.create(attributes)

      expect { repository.create(attributes.merge(namespace_id: nil)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /taken/i)
    end

    it 'accepts a name another organization already uses, because the name is scoped to one' do
      repository.create(attributes)

      expect(repository.create(attributes.merge(organization_id: other_organization_id, namespace_id: nil)))
        .to have_attributes(name: attributes[:name], organization_id: other_organization_id)
    end

    it 'rejects an attribute that is neither creatable nor a known immutable one' do
      expect { repository.create(attributes.merge(nmae: 'Misspelled')) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /nmae/)
    end

    it 'ignores immutable attributes rather than rejecting them, so a policy can be copied',
      :aggregate_failures do
      created = repository.create(attributes)

      copy = repository.create(created.to_h.merge(organization_id: other_organization_id, namespace_id: nil))

      expect(copy).to have_attributes(
        name: created.name,
        organization_id: other_organization_id,
        version: 1
      )
      expect(copy.id).not_to eq(created.id)
    end

    it 'starts every policy at version 1, whatever version the caller supplies' do
      expect(repository.create(attributes.merge(version: 99))).to have_attributes(version: 1)
    end
  end

  describe '#update' do
    it 'applies the changes and bumps the version by one', :aggregate_failures do
      created = repository.create(attributes)

      updated = repository.update(created.id, name: 'Renamed policy', mode: 'enforce')

      expect(updated).to be_a(Gitlab::PolicyStore::Policy)
      expect(updated).to have_attributes(
        id: created.id,
        name: 'Renamed policy',
        mode: 'enforce',
        version: created.version + 1
      )
    end

    it 'applies changes to every part of the policy payload' do
      created = repository.create(attributes)

      updated = repository.update(created.id,
        description: 'Rewritten',
        trigger_type: other_trigger_type,
        rules: [{ 'type' => 'license_finding' }],
        actions: [{ 'type' => 'send_bot_message' }],
        mode: 'warn',
        lifecycle_state: 'disabled')

      expect(updated).to have_attributes(
        description: 'Rewritten',
        trigger_type: other_trigger_type,
        rules: [{ 'type' => 'license_finding' }],
        actions: [{ 'type' => 'send_bot_message' }],
        mode: 'warn',
        lifecycle_state: 'disabled'
      )
    end

    it 'leaves attributes the caller did not supply untouched' do
      created = repository.create(attributes)

      updated = repository.update(created.id, name: 'Renamed policy')

      expect(updated).to have_attributes(
        description: created.description,
        trigger_type: created.trigger_type,
        rules: created.rules,
        actions: created.actions
      )
    end

    it 'ignores identity and tenancy attributes that restate what is stored' do
      created = repository.create(attributes)

      updated = repository.update(created.id,
        id: created.id,
        organization_id: created.organization_id,
        namespace_id: created.namespace_id,
        name: 'Renamed policy')

      expect(updated).to have_attributes(
        id: created.id,
        version: created.version + 1,
        organization_id: organization_id,
        namespace_id: created.namespace_id,
        name: 'Renamed policy'
      )
    end

    it 'ignores a stale version, because update does not do optimistic locking' do
      created = repository.create(attributes)

      expect(repository.update(created.id, version: 99, name: 'Renamed policy'))
        .to have_attributes(version: created.version + 1)
    end

    port::IDENTITY_ATTRIBUTES.each do |attribute|
      it "rejects a change to #{attribute}, rather than reporting a move it will not make" do
        created = repository.create(attributes)
        differing = { id: non_existing_id, organization_id: other_organization_id, namespace_id: nil }.fetch(attribute)

        expect { repository.update(created.id, attribute => differing) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /cannot be changed: #{attribute}/)
      end
    end

    it 'persists the change' do
      created = repository.create(attributes)

      repository.update(created.id, name: 'Renamed policy')

      expect(repository.find(created.id).name).to eq('Renamed policy')
    end

    it 'enforces the text limits that create enforces' do
      created = repository.create(attributes)

      expect { repository.update(created.id, name: 'a' * 256) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name/i)
    end

    it 'rejects blanking a required attribute' do
      created = repository.create(attributes)

      expect { repository.update(created.id, name: nil) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /name/i)
    end

    it 'rejects blanking the trigger_type, which would drop the policy out of evaluation' do
      created = repository.create(attributes)

      expect { repository.update(created.id, trigger_type: nil) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /trigger/i)
    end

    it 'rejects a rename onto a name the organization already uses' do
      blocking_policy = repository.create(attributes)
      renamed_policy = repository.create(attributes.merge(name: 'Second policy'))

      expect { repository.update(renamed_policy.id, name: blocking_policy.name) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /taken/i)
    end

    it "accepts an update that restates the policy's own name" do
      created = repository.create(attributes)

      expect(repository.update(created.id, name: created.name, mode: 'enforce'))
        .to have_attributes(name: created.name, mode: 'enforce')
    end

    it 'accepts string keys for the changes' do
      created = repository.create(attributes)

      expect(repository.update(created.id, 'name' => 'Renamed policy')).to have_attributes(name: 'Renamed policy')
    end

    it 'rejects an attribute that is neither updatable nor a known immutable one' do
      created = repository.create(attributes)

      expect { repository.update(created.id, nmae: 'Misspelled') }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /nmae/)
    end

    it 'ignores immutable attributes rather than rejecting them, so a whole policy can be handed back' do
      created = repository.create(attributes)

      updated = repository.update(created.id, created.to_h.merge(name: 'Renamed policy'))

      expect(updated).to have_attributes(
        id: created.id,
        organization_id: created.organization_id,
        name: 'Renamed policy',
        version: created.version + 1
      )
    end

    it 'leaves the version alone when the change set touches nothing' do
      created = repository.create(attributes)

      expect(repository.update(created.id, {})).to have_attributes(version: created.version)
    end

    it 'leaves the version alone when every supplied value matches what is stored' do
      created = repository.create(attributes)

      expect(repository.update(created.id, name: created.name, mode: created.mode))
        .to have_attributes(version: created.version)
    end

    it 'leaves the version alone when a caller resends a whole policy unchanged' do
      created = repository.create(attributes)

      expect(repository.update(created.id, created.to_h)).to have_attributes(version: created.version)
    end

    port::NON_NULLABLE_ATTRIBUTES.each do |attribute|
      it "raises ValidationError when #{attribute} is set to nil" do
        created = repository.create(attributes)

        expect { repository.update(created.id, attribute => nil) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /#{attribute}/i)
      end
    end

    it 'raises Gitlab::PolicyStore::NotFound when the policy does not exist' do
      expect { repository.update(non_existing_id, name: 'Renamed policy') }
        .to raise_error(Gitlab::PolicyStore::NotFound)
    end
  end

  describe 'isolation from stored data' do
    let(:tamperable_attributes) do
      attributes.merge(
        name: +'Tamperable policy',
        trigger_type: +trigger_type,
        mode: +'audit',
        rules: [{ 'type' => +'scan_finding' }],
        actions: [{ 'type' => +'require_approval' }],
        policy_scope: { 'compliance_frameworks' => [{ 'id' => 5 }] },
        scope_rego: nil
      )
    end

    def attempt_tampering
      yield
    rescue FrozenError
      nil
    end

    def expect_tampering_not_to_reach_storage(policy, id)
      attempt_tampering { policy.name << '_tampered' }
      attempt_tampering { policy.trigger_type << '_tampered' }
      attempt_tampering { policy.mode << '_tampered' }
      attempt_tampering { policy.rules.first['type'] << '_tampered' }
      attempt_tampering { policy.actions << { 'type' => 'injected' } }
      attempt_tampering { policy.policy_scope['injected'] = true }

      stored = repository.find(id)

      expect(stored.name).to eq('Tamperable policy')
      expect(stored.trigger_type).to eq(trigger_type)
      expect(stored.mode).to eq('audit')
      expect(stored.rules).to eq([{ 'type' => 'scan_finding' }])
      expect(stored.actions).to eq([{ 'type' => 'require_approval' }])
      expect(stored.policy_scope).to eq({ 'compliance_frameworks' => [{ 'id' => 5 }] })
    end

    it 'isolates the policy create returned', :aggregate_failures do
      created = repository.create(tamperable_attributes)

      expect_tampering_not_to_reach_storage(created, created.id)
    end

    it 'isolates the policy update returned', :aggregate_failures do
      created = repository.create(tamperable_attributes)

      expect_tampering_not_to_reach_storage(repository.update(created.id, description: 'Rewritten'), created.id)
    end

    it 'isolates the policy find returned', :aggregate_failures do
      created = repository.create(tamperable_attributes)

      expect_tampering_not_to_reach_storage(repository.find(created.id), created.id)
    end

    it 'isolates the policies list returned', :aggregate_failures do
      created = repository.create(tamperable_attributes)

      expect_tampering_not_to_reach_storage(repository.list(organization_id: organization_id).first, created.id)
    end
  end

  describe '#find' do
    it 'returns the previously created policy', :aggregate_failures do
      created = repository.create(attributes)

      expect(repository.find(created.id)).to eq(created)
      expect(repository.find(created.id)).to have_attributes(
        name: 'My approval policy',
        description: 'Requires approval for scan findings',
        trigger_type: trigger_type,
        rules: [{ 'type' => 'scan_finding' }],
        mode: 'audit'
      )
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
    let(:other_trigger_attributes) do
      attributes.merge(name: 'Other trigger policy', trigger_type: other_trigger_type)
    end

    it 'returns the policies for the organization' do
      created = repository.create(attributes)

      expect(repository.list(organization_id: organization_id)).to contain_exactly(created)
    end

    it 'returns every trigger when no trigger_type is given' do
      other_trigger_policy = repository.create(other_trigger_attributes)
      default_trigger_policy = repository.create(attributes)

      expect(repository.list(organization_id: organization_id))
        .to contain_exactly(other_trigger_policy, default_trigger_policy)
    end

    it 'returns an empty array when no policies exist for the organization' do
      expect(repository.list(organization_id: organization_id)).to be_empty
    end

    it 'excludes policies from other organizations' do
      other_org_attributes = attributes.merge(organization_id: other_organization_id, namespace_id: nil)
      repository.create(other_org_attributes)
      same_organization_policy = repository.create(attributes)

      expect(repository.list(organization_id: organization_id)).to contain_exactly(same_organization_policy)
    end

    it 'includes policies owned by the organization rather than a group' do
      organization_owned = repository.create(attributes.merge(namespace_id: nil))

      expect(repository.list(organization_id: organization_id)).to contain_exactly(organization_owned)
    end

    it 'does not include deleted policies' do
      created = repository.create(attributes)
      repository.delete(created.id)

      expect(repository.list(organization_id: organization_id)).to be_empty
    end

    context 'with a trigger_type' do
      it 'returns only the policies for that trigger' do
        other_trigger_policy = repository.create(other_trigger_attributes)
        repository.create(attributes)

        expect(repository.list(organization_id: organization_id, trigger_type: other_trigger_type))
          .to contain_exactly(other_trigger_policy)
      end

      it 'returns an empty array when no policy targets it' do
        repository.create(attributes)

        expect(repository.list(organization_id: organization_id, trigger_type: other_trigger_type)).to be_empty
      end

      it 'still excludes policies from other organizations' do
        repository.create(other_trigger_attributes.merge(organization_id: other_organization_id, namespace_id: nil))
        same_organization_policy = repository.create(other_trigger_attributes)

        expect(repository.list(organization_id: organization_id, trigger_type: other_trigger_type))
          .to contain_exactly(same_organization_policy)
      end
    end
  end
end

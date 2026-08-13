# frozen_string_literal: true

RSpec.shared_examples 'a policy repository reconciling scope forms' do
  port = Gitlab::PolicyStore::Ports::PolicyRepository
  let(:authored_scope_rego) { "package gitlab.scope\n\n# hand written" }
  let(:compiled_attributes) { attributes.except(:scope_rego) }
  let(:narrower_policy_scope) { { 'compliance_frameworks' => [{ 'id' => 7 }] } }
  let(:oversized_policy_scope) { { 'compliance_frameworks' => (1..1000).map { |id| { 'id' => id } } } }

  def program_compiled_for(scope_attributes, name)
    repository.create(
      compiled_attributes.merge(scope_attributes).merge(
        name: name, organization_id: other_organization_id, namespace_id: nil
      )
    ).scope_rego
  end

  describe 'on create' do
    it 'compiles scope_rego from policy_scope when none is supplied', :aggregate_failures do
      policy = repository.create(compiled_attributes)

      expect(policy.scope_rego).to include('framework_id in {5}')
      expect(policy.scope_rego).to include('match_mode=all')
      expect(policy.scope_rego).not_to eq(program_compiled_for({ policy_scope: nil }, policy.name))
    end

    it 'preserves an authored scope_rego instead of compiling one' do
      policy = repository.create(attributes.merge(scope_rego: authored_scope_rego))

      expect(policy.scope_rego).to eq(authored_scope_rego)
    end

    it 'clears policy_scope when scope_rego is authored, so the two cannot disagree' do
      policy = repository.create(attributes.merge(scope_rego: authored_scope_rego))

      expect(policy.policy_scope).to be_nil
    end

    it 'compiles an applies-to-all scope_rego when the policy has no scope', :aggregate_failures do
      policy = repository.create(minimal_attributes)

      expect(policy.scope_rego).to include('no policy_scope: applies to all projects')
      expect(policy.scope_rego).to eq(program_compiled_for({ policy_scope: nil }, policy.name))
    end

    it 'compiles from policy_scope when scope_rego is only whitespace, rather than storing it' do
      policy = repository.create(attributes.merge(scope_rego: "\n  "))

      expect(policy.scope_rego).to eq(program_compiled_for({}, policy.name))
    end

    it 'raises ValidationError when policy_scope compiles past the scope_rego limit' do
      expect { repository.create(compiled_attributes.merge(policy_scope: oversized_policy_scope)) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /scope.rego/i)
    end

    port::SCOPE_FORM_TYPES.each do |attribute, type|
      it "raises ValidationError when #{attribute} is not a #{type.name.downcase}" do
        expect { repository.create(attributes.merge(attribute => 42)) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /#{attribute.to_s.tr('_', '.')}/i)
      end
    end
  end

  describe 'on update' do
    it 'recompiles scope_rego when policy_scope changes', :aggregate_failures do
      created = repository.create(compiled_attributes)

      updated = repository.update(created.id, policy_scope: narrower_policy_scope)

      expect(updated.scope_rego).to include('framework_id in {7}')
      expect(updated.scope_rego).to eq(program_compiled_for({ policy_scope: narrower_policy_scope }, created.name))
      expect(updated.policy_scope).to eq(narrower_policy_scope)
    end

    it 'clears policy_scope when scope_rego is authored', :aggregate_failures do
      created = repository.create(compiled_attributes)

      updated = repository.update(created.id, scope_rego: authored_scope_rego)

      expect(updated.scope_rego).to eq(authored_scope_rego)
      expect(updated.policy_scope).to be_nil
    end

    it 'keeps only the authored program when both scope forms are supplied', :aggregate_failures do
      created = repository.create(compiled_attributes)

      updated = repository.update(created.id,
        policy_scope: narrower_policy_scope, scope_rego: authored_scope_rego)

      expect(updated.scope_rego).to eq(authored_scope_rego)
      expect(updated.policy_scope).to be_nil
    end

    it 'recompiles from policy_scope when scope_rego is blanked', :aggregate_failures do
      created = repository.create(compiled_attributes)

      updated = repository.update(created.id, scope_rego: nil)

      expect(updated.policy_scope).to eq(created.policy_scope)
      expect(updated.scope_rego).to eq(created.scope_rego)
    end

    it 'treats a whitespace-only scope_rego as blanked, not as an authored program', :aggregate_failures do
      created = repository.create(compiled_attributes)

      updated = repository.update(created.id, scope_rego: "\n  ")

      expect(updated.scope_rego).to eq(program_compiled_for({}, created.name))
      expect(updated.policy_scope).to eq(created.policy_scope)
    end

    it 'applies everywhere when the policy_scope a policy was compiled from is blanked', :aggregate_failures do
      created = repository.create(compiled_attributes)

      updated = repository.update(created.id, policy_scope: nil)

      expect(updated.policy_scope).to be_nil
      expect(updated.scope_rego).to eq(program_compiled_for({ policy_scope: nil }, created.name))
    end

    it 'applies everywhere when an authored scope_rego is blanked, because nothing is left to compile',
      :aggregate_failures do
      created = repository.create(minimal_attributes.merge(scope_rego: authored_scope_rego))

      updated = repository.update(created.id, scope_rego: nil)

      expect(updated.policy_scope).to be_nil
      expect(updated.scope_rego).to eq(program_compiled_for({ policy_scope: nil }, created.name))
    end

    it 'leaves an authored scope_rego alone when a policy_scope it never had is blanked' do
      created = repository.create(minimal_attributes.merge(scope_rego: authored_scope_rego))

      expect(repository.update(created.id, policy_scope: nil).scope_rego).to eq(authored_scope_rego)
    end

    it 'recompiles a generated scope_rego on rename, because the program carries the name',
      :aggregate_failures do
      created = repository.create(compiled_attributes.merge(name: 'Original name'))

      updated = repository.update(created.id, name: 'Renamed policy')

      expect(updated.scope_rego).to include('Renamed policy')
      expect(updated.scope_rego).not_to include('Original name')
      expect(updated.scope_rego).to eq(program_compiled_for({}, 'Renamed policy'))
    end

    it 'recompiles an unscoped policy on rename, since its program also carries the name',
      :aggregate_failures do
      created = repository.create(minimal_attributes.merge(name: 'Original name'))

      updated = repository.update(created.id, name: 'Renamed policy')

      expect(updated.scope_rego).to include('Renamed policy')
      expect(updated.scope_rego).not_to include('Original name')
      expect(updated.scope_rego).to eq(program_compiled_for({ policy_scope: nil }, 'Renamed policy'))
    end

    it 'leaves an authored scope_rego alone on rename' do
      created = repository.create(attributes.merge(scope_rego: authored_scope_rego, name: 'Original name'))

      expect(repository.update(created.id, name: 'Renamed policy').scope_rego).to eq(authored_scope_rego)
    end

    it 'keeps a compiled scope when a caller resends the whole policy', :aggregate_failures do
      created = repository.create(compiled_attributes.merge(name: 'Original name'))

      updated = repository.update(created.id, created.to_h.merge(name: 'Renamed policy'))

      expect(updated.policy_scope).to eq(created.policy_scope)
      expect(updated.scope_rego).to include('Renamed policy')
      expect(updated.scope_rego).not_to include('Original name')
      expect(updated.scope_rego).to eq(program_compiled_for({}, 'Renamed policy'))
    end

    it 'leaves an authored scope a caller resent alone', :aggregate_failures do
      created = repository.create(minimal_attributes.merge(scope_rego: authored_scope_rego))

      updated = repository.update(created.id, created.to_h.merge(description: 'Rewritten'))

      expect(updated.scope_rego).to eq(authored_scope_rego)
      expect(updated.policy_scope).to be_nil
    end

    it 'raises ValidationError when a policy_scope change compiles past the scope_rego limit' do
      created = repository.create(attributes)

      expect { repository.update(created.id, policy_scope: oversized_policy_scope) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /scope.rego/i)
    end

    port::SCOPE_FORM_TYPES.each_key do |attribute|
      it "raises ValidationError rather than rewriting the scope when #{attribute} has the wrong type",
        :aggregate_failures do
        created = repository.create(compiled_attributes)

        expect { repository.update(created.id, attribute => 42) }
          .to raise_error(Gitlab::PolicyStore::ValidationError, /#{attribute.to_s.tr('_', '.')}/i)
        expect(repository.find(created.id)).to have_attributes(
          policy_scope: created.policy_scope,
          scope_rego: created.scope_rego
        )
      end
    end
  end
end

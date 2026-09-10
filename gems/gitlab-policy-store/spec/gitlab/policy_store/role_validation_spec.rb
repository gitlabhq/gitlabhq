# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RoleValidation do
  let(:repository) { Gitlab::PolicyStore::Adapters::InMemoryPolicyRepository.new }

  let(:base_attributes) do
    {
      organization_id: 1,
      name: 'Test policy',
      trigger_type: trigger_type,
      rules: [{ 'type' => 'custom', 'value' => 'package governance' }],
      actions: actions
    }
  end

  describe 'role validation on create' do
    subject(:create_policy) { repository.create(base_attributes) }

    context 'with a deployment trigger' do
      let(:trigger_type) { 'deployment_requested' }

      context 'with valid CD roles' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => ['release_manager'] } }]
        end

        it 'creates the policy successfully' do
          expect(create_policy).to be_a(Gitlab::PolicyStore::Policy)
        end
      end

      context 'with multiple CD roles' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => %w[release_manager deployment_observer] } }]
        end

        it 'creates the policy successfully' do
          expect(create_policy).to be_a(Gitlab::PolicyStore::Policy)
        end
      end

      context 'with GitLab roles' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => %w[developer maintainer] } }]
        end

        it 'raises a validation error' do
          expect { create_policy }
            .to raise_error(
              Gitlab::PolicyStore::ValidationError,
              /GitLab roles.*cannot be used with deployment triggers/
            )
        end
      end

      context 'with mixed GitLab and CD roles' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => %w[maintainer release_manager] } }]
        end

        it 'raises a validation error for the GitLab role' do
          expect { create_policy }
            .to raise_error(
              Gitlab::PolicyStore::ValidationError,
              /GitLab roles.*cannot be used with deployment triggers/
            )
        end
      end

      context 'with invalid role' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => ['unknown_role'] } }]
        end

        it 'raises a validation error' do
          expect { create_policy }
            .to raise_error(Gitlab::PolicyStore::ValidationError, /invalid roles: unknown_role/)
        end
      end
    end

    context 'with a non-deployment trigger' do
      let(:trigger_type) { 'some_other_trigger' }

      context 'with GitLab roles' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => %w[developer maintainer] } }]
        end

        it 'creates the policy successfully' do
          expect(create_policy).to be_a(Gitlab::PolicyStore::Policy)
        end
      end

      context 'with CD roles' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => ['release_manager'] } }]
        end

        it 'raises a validation error' do
          expect { create_policy }
            .to raise_error(
              Gitlab::PolicyStore::ValidationError,
              /CD roles.*can only be used with deployment triggers/
            )
        end
      end

      context 'with deployment_observer CD role' do
        let(:actions) do
          [{ 'type' => 'require_approval', 'value' => { 'roles' => ['deployment_observer'] } }]
        end

        it 'raises a validation error' do
          expect { create_policy }
            .to raise_error(
              Gitlab::PolicyStore::ValidationError,
              /CD roles.*can only be used with deployment triggers/
            )
        end
      end
    end

    context 'with no roles in require_approval action' do
      let(:trigger_type) { 'deployment_requested' }
      let(:actions) do
        [{ 'type' => 'require_approval', 'value' => {} }]
      end

      it 'creates the policy successfully' do
        expect(create_policy).to be_a(Gitlab::PolicyStore::Policy)
      end
    end

    context 'with block action (no roles)' do
      let(:trigger_type) { 'deployment_requested' }
      let(:actions) do
        [{ 'type' => 'block', 'value' => { 'blockMessage' => 'Blocked' } }]
      end

      it 'creates the policy successfully' do
        expect(create_policy).to be_a(Gitlab::PolicyStore::Policy)
      end
    end

    context 'with require_approval action where value is an empty Hash' do
      let(:trigger_type) { 'deployment_requested' }
      let(:actions) do
        [{ 'type' => 'require_approval', 'value' => {} }]
      end

      it 'creates the policy successfully when roles key is missing' do
        expect(create_policy).to be_a(Gitlab::PolicyStore::Policy)
      end
    end
  end

  describe 'role validation on update' do
    let(:trigger_type) { 'deployment_requested' }
    let(:actions) do
      [{ 'type' => 'require_approval', 'value' => { 'roles' => ['release_manager'] } }]
    end

    let!(:policy) { repository.create(base_attributes) }

    context 'when updating to valid CD roles' do
      it 'updates successfully' do
        updated = repository.update(
          policy.id,
          actions: [{ 'type' => 'require_approval', 'value' => { 'roles' => ['deployment_observer'] } }]
        )

        expect(updated.actions.first['value']['roles']).to eq(['deployment_observer'])
      end
    end

    context 'when updating to invalid roles' do
      it 'raises a validation error' do
        expect do
          repository.update(
            policy.id,
            actions: [{ 'type' => 'require_approval', 'value' => { 'roles' => ['invalid'] } }]
          )
        end.to raise_error(Gitlab::PolicyStore::ValidationError, /invalid roles/)
      end
    end

    context 'when updating to GitLab roles on a deployment trigger' do
      it 'raises a validation error' do
        expect do
          repository.update(
            policy.id,
            actions: [{ 'type' => 'require_approval', 'value' => { 'roles' => ['developer'] } }]
          )
        end.to raise_error(
          Gitlab::PolicyStore::ValidationError,
          /GitLab roles.*cannot be used with deployment triggers/
        )
      end
    end

    context 'when policy has non-deployment trigger and update tries to add CD roles' do
      let(:trigger_type) { 'some_other_trigger' }
      let(:actions) do
        [{ 'type' => 'require_approval', 'value' => { 'roles' => ['developer'] } }]
      end

      it 'rejects CD roles even when trigger_type is not in update params' do
        expect do
          repository.update(
            policy.id,
            actions: [{ 'type' => 'require_approval', 'value' => { 'roles' => ['release_manager'] } }]
          )
        end.to raise_error(Gitlab::PolicyStore::ValidationError, /CD roles.*can only be used with deployment triggers/)
      end
    end
  end
end

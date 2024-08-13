# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Terraform::State::Lock do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:state) { create(:terraform_state) }

  let(:mutation) do
    described_class.new(
      object: double,
      context: query_context,
      field: double
    )
  end

  it { expect(described_class.graphql_name).to eq('TerraformStateLock') }
  it { expect(described_class).to require_graphql_authorizations(:admin_terraform_state) }

  describe '#resolve' do
    let(:global_id) { state.to_global_id }

    subject { mutation.resolve(id: global_id) }

    context 'user does not have permission' do
      it 'raises an error', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect(state.reload).not_to be_locked
      end
    end

    context 'user has permission' do
      before do
        state.project.add_maintainer(current_user)
      end

      it 'locks the state', :aggregate_failures do
        expect(subject).to eq(errors: [])

        expect(state.reload).to be_locked
        expect(state.locked_by_user).to eq(current_user)
        expect(state.lock_xid).to be_present
        expect(state.locked_at).to be_present
      end

      context 'state is already locked' do
        let(:locked_by_user) { create(:user) }
        let(:state) { create(:terraform_state, :locked, locked_by_user: locked_by_user) }

        it 'does not modify the existing lock', :aggregate_failures do
          expect(subject).to eq(errors: ['state is already locked'])

          expect(state.reload).to be_locked
          expect(state.locked_by_user).to eq(locked_by_user)
        end
      end
    end

    context 'with invalid params' do
      let(:global_id) { current_user.to_global_id }

      it 'raises an error', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect(state.reload).not_to be_locked
      end
    end
  end
end

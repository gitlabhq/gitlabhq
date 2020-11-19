# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Terraform::State::Delete do
  let_it_be(:user) { create(:user) }
  let_it_be(:state) { create(:terraform_state) }

  let(:mutation) do
    described_class.new(
      object: double,
      context: { current_user: user },
      field: double
    )
  end

  it { expect(described_class.graphql_name).to eq('TerraformStateDelete') }
  it { expect(described_class).to require_graphql_authorizations(:admin_terraform_state) }

  describe '#resolve' do
    let(:global_id) { state.to_global_id }

    subject { mutation.resolve(id: global_id) }

    context 'user does not have permission' do
      it 'raises an error', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect { state.reload }.not_to raise_error
      end
    end

    context 'user has permission' do
      before do
        state.project.add_maintainer(user)
      end

      it 'deletes the state', :aggregate_failures do
        expect do
          expect(subject).to eq(errors: [])
        end.to change { ::Terraform::State.count }.by(-1)

        expect { state.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with invalid params' do
      let(:global_id) { user.to_global_id }

      it 'raises an error', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect { state.reload }.not_to raise_error
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Terraform::State::Delete do
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
        state.project.add_maintainer(current_user)
      end

      it 'schedules the state for deletion', :aggregate_failures do
        expect_next_instance_of(Terraform::States::TriggerDestroyService, state,
          current_user: current_user) do |service|
          expect(service).to receive(:execute).once.and_return(ServiceResponse.success)
        end

        subject
      end
    end

    context 'with invalid params' do
      let(:global_id) { current_user.to_global_id }

      it 'raises an error', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect { state.reload }.not_to raise_error
      end
    end
  end
end

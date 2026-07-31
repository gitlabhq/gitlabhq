# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Projects::Transfer, feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:target_namespace) { create(:group) }

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  specify { expect(described_class).to require_graphql_authorizations(:change_namespace) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(**params) }

    context 'when the user does not have permission' do
      let(:params) { { id: project.to_global_id, namespace_id: target_namespace.to_global_id } }

      it 'raises a resource not available error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user has change_namespace permission' do
      before_all do
        project.add_owner(current_user)
        target_namespace.add_owner(current_user)
      end

      let(:params) { { id: project.to_global_id, namespace_id: target_namespace.to_global_id } }

      context 'when the namespace_id resolves to a ProjectNamespace' do
        let(:params) { { id: project.to_global_id, namespace_id: project.project_namespace.to_global_id } }

        it 'returns an error', :aggregate_failures do
          result = resolve

          expect(result[:errors]).to contain_exactly(
            'Target namespace must be a group or user namespace, not a project namespace.'
          )
          expect(result[:project]).to eq(project)
        end
      end

      context 'when scheduling succeeds' do
        it 'schedules an async transfer and returns the project with no errors', :aggregate_failures do
          service = instance_double(::Projects::TransferService)
          allow(::Projects::TransferService).to receive(:new).with(project, current_user).and_return(service)
          allow(service).to receive(:schedule_async_transfer).with(target_namespace)
            .and_return(ServiceResponse.success)

          result = resolve

          expect(result[:errors]).to be_empty
          expect(result[:project]).to eq(project)
        end
      end

      context 'when scheduling fails' do
        it 'returns errors and the project', :aggregate_failures do
          service = instance_double(::Projects::TransferService)
          allow(::Projects::TransferService).to receive(:new).with(project, current_user).and_return(service)
          allow(service).to receive(:schedule_async_transfer).with(target_namespace)
            .and_return(ServiceResponse.error(message: 'Transfer already in progress.'))

          result = resolve

          expect(result[:errors]).to contain_exactly('Transfer already in progress.')
          expect(result[:project]).to eq(project)
        end
      end

      context 'when groups_and_projects_async_transfer feature flag is disabled' do
        before do
          stub_feature_flags(groups_and_projects_async_transfer: false)
        end

        context 'when transfer succeeds' do
          it 'returns the project and no errors', :aggregate_failures do
            service = instance_double(::Projects::TransferService)
            allow(::Projects::TransferService).to receive(:new).with(project, current_user).and_return(service)
            allow(service).to receive(:execute).with(target_namespace).and_return(true)

            result = resolve

            expect(result[:errors]).to be_empty
            expect(result[:project]).to eq(project)
          end
        end

        context 'when transfer fails with new_namespace errors' do
          it 'returns errors and the project', :aggregate_failures do
            allow(mutation).to receive(:authorized_find!).and_return(project)
            service = instance_double(::Projects::TransferService)
            allow(::Projects::TransferService).to receive(:new).with(project, current_user).and_return(service)
            allow(service).to receive(:execute).with(target_namespace) do
              project.errors.add(:new_namespace, 'Transfer not allowed.')
              false
            end

            result = resolve

            expect(result[:errors]).to contain_exactly('Transfer not allowed.')
            expect(result[:project]).to eq(project)
          end
        end

        context 'when transfer fails without specific errors' do
          it 'returns a generic error message and the project', :aggregate_failures do
            service = instance_double(::Projects::TransferService)
            allow(::Projects::TransferService).to receive(:new).with(project, current_user).and_return(service)
            allow(service).to receive(:execute).with(target_namespace).and_return(false)

            result = resolve

            expect(result[:errors]).to contain_exactly('Transfer failed')
            expect(result[:project]).to eq(project)
          end
        end
      end
    end
  end
end

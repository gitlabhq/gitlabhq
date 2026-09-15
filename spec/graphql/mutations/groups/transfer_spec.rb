# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Groups::Transfer, feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:target_group) { create(:group) }

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  specify { expect(described_class).to require_graphql_authorizations(:change_group) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(**params) }

    context 'when the user does not have permission' do
      let(:params) { { id: group.to_global_id } }

      it 'raises a resource not available error' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user has admin_group permission' do
      before_all do
        group.add_owner(current_user)
        target_group.add_owner(current_user)
      end

      context 'when target_id is supplied but resolves to nil (deleted or inaccessible group)' do
        let(:params) do
          { id: group.to_global_id, target_id: ::GlobalID.parse("gid://gitlab/Group/#{non_existing_record_id}") }
        end

        it 'raises a resource not available error' do
          expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'Target group not found.')
        end
      end

      context 'when transferring to a target group' do
        let(:params) { { id: group.to_global_id, target_id: target_group.to_global_id } }

        it 'schedules an async transfer and returns the group with no errors', :aggregate_failures do
          service = instance_double(::Groups::TransferService)
          allow(::Groups::TransferService).to receive(:new).with(group, current_user).and_return(service)
          allow(service).to receive(:schedule_async_transfer).with(target_group)
            .and_return(ServiceResponse.success)

          result = resolve

          expect(result[:errors]).to be_empty
          expect(result[:group]).to eq(group)
        end

        context 'when scheduling fails' do
          it 'returns errors and the group', :aggregate_failures do
            service = instance_double(::Groups::TransferService)
            allow(::Groups::TransferService).to receive(:new).with(group, current_user).and_return(service)
            allow(service).to receive(:schedule_async_transfer).with(target_group)
              .and_return(ServiceResponse.error(message: 'Transfer already in progress.'))

            result = resolve

            expect(result[:errors]).to contain_exactly('Transfer already in progress.')
            expect(result[:group]).to eq(group)
          end
        end
      end

      context 'when making group top-level (no target_id)' do
        let(:params) { { id: group.to_global_id } }

        it 'schedules an async transfer with nil target group', :aggregate_failures do
          service = instance_double(::Groups::TransferService)
          allow(::Groups::TransferService).to receive(:new).with(group, current_user).and_return(service)
          allow(service).to receive(:schedule_async_transfer).with(nil)
            .and_return(ServiceResponse.success)

          result = resolve

          expect(result[:errors]).to be_empty
        end
      end
    end
  end
end

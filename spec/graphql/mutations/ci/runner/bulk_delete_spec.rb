# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::BulkDelete, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:admin_user) { create(:user, :admin) }

  let(:current_ctx) { { current_user: user } }

  let(:mutation_params) do
    {}
  end

  describe '#resolve' do
    subject(:response) do
      sync(resolve(described_class, args: mutation_params, ctx: current_ctx))
    end

    context 'when user can delete runners' do
      let_it_be(:group) { create(:group) }

      let(:user) { admin_user }
      let!(:runners) do
        create_list(:ci_runner, 2, :group, groups: [group])
      end

      context 'when runner IDs are missing' do
        let(:mutation_params) { {} }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'does not return an error' do
            is_expected.to match a_hash_including(errors: [])
          end
        end
      end

      context 'with runners specified by id' do
        let!(:mutation_params) do
          { ids: runners.map(&:to_global_id) }
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'deletes runners', :aggregate_failures do
            expect { response }.to change { Ci::Runner.count }.by(-2)
            expect(response[:errors]).to be_empty
          end
        end

        it 'ignores unknown keys from service response payload', :aggregate_failures do
          expect_next_instance_of(
            ::Ci::Runners::BulkDeleteRunnersService, { runners: runners, current_user: user }
          ) do |service|
            expect(service).to receive(:execute).once.and_return(
              ServiceResponse.success(
                payload: {
                  extra_key: 'extra_value',
                  deleted_count: 10,
                  deleted_ids: (1..10).to_a,
                  errors: []
                }))
          end

          expect(response).not_to include(extra_key: 'extra_value')
        end
      end
    end

    context 'when the user cannot delete the runner' do
      let(:runner) { create(:ci_runner) }
      let!(:mutation_params) do
        { ids: [runner.to_global_id] }
      end

      context 'when user is admin and admin mode is not enabled' do
        let(:user) { admin_user }

        it 'returns error', :aggregate_failures do
          expect { response }.not_to change { Ci::Runner.count }
          expect(response[:errors]).to match_array("User does not have permission to delete any of the runners")
        end
      end
    end
  end
end

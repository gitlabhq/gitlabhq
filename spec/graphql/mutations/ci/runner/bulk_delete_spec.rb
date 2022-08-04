# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::BulkDelete do
  include GraphqlHelpers

  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }

  let(:current_ctx) { { current_user: user } }

  let(:mutation_params) do
    {}
  end

  describe '#resolve' do
    subject(:response) do
      sync(resolve(described_class, args: mutation_params, ctx: current_ctx))
    end

    context 'when the user cannot admin the runner' do
      let(:runner) { create(:ci_runner) }
      let(:mutation_params) do
        { ids: [runner.to_global_id] }
      end

      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) { response }
      end
    end

    context 'when user can delete runners' do
      let(:user) { admin_user }
      let!(:runners) do
        create_list(:ci_runner, 2, :instance)
      end

      context 'when required arguments are missing' do
        let(:mutation_params) { {} }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'does not return an error' do
            is_expected.to match a_hash_including(errors: [])
          end
        end
      end

      context 'with runners specified by id' do
        let(:mutation_params) do
          { ids: runners.map(&:to_global_id) }
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'deletes runners', :aggregate_failures do
            expect_next_instance_of(
              ::Ci::Runners::BulkDeleteRunnersService, { runners: runners }
            ) do |service|
              expect(service).to receive(:execute).once.and_call_original
            end

            expect { response }.to change { Ci::Runner.count }.by(-2)
            expect(response[:errors]).to be_empty
          end

          context 'when runner list is is above limit' do
            before do
              stub_const('::Ci::Runners::BulkDeleteRunnersService::RUNNER_LIMIT', 1)
            end

            it 'only deletes up to the defined limit', :aggregate_failures do
              expect { response }.to change { Ci::Runner.count }
                .by(-::Ci::Runners::BulkDeleteRunnersService::RUNNER_LIMIT)
              expect(response[:errors]).to be_empty
            end
          end
        end

        context 'when admin mode is disabled', :aggregate_failures do
          it 'returns error', :aggregate_failures do
            expect do
              expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
                response
              end
            end.not_to change { Ci::Runner.count }
          end
        end
      end
    end
  end
end

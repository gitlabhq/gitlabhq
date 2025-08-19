# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::BulkDelete, factory_default: :keep, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:organization) { create_default(:organization) }
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

  context 'for N+1 Query', :request_store do
    let_it_be(:user) { create(:user) }

    # destroy_all itself triggers N+1 queries, so we are patching this method to
    # ensure that the select calls (specifically authorization checks) that are being tested are not impacted by this
    before do
      allow(Ci::Runner).to receive(:id_in).and_wrap_original do |original_method, ids|
        relation = original_method.call(ids)
        allow(relation).to receive(:destroy_all).and_return(relation.to_a)
        relation
      end
    end

    def expect_constant_queries(single_runner, all_runners, ctx = current_ctx)
      control = ActiveRecord::QueryRecorder.new do
        sync(resolve(described_class, args: { ids: single_runner.map(&:to_global_id) }, ctx: ctx))
      end

      expect do
        sync(resolve(described_class, args: { ids: all_runners.map(&:to_global_id) }, ctx: ctx))
      end.not_to exceed_query_limit(control)
    end

    context 'with project runners' do
      let_it_be(:owner_project) { create(:project, owners: user) }
      let_it_be(:maintainer_project) { create(:project, maintainers: user) }
      let_it_be(:developer_project) { create(:project, developers: user) }

      context 'with single runner per project' do
        let_it_be(:owner_runner) { create(:ci_runner, :project, projects: [owner_project]) }
        let_it_be(:maintainer_runner) { create(:ci_runner, :project, projects: [maintainer_project]) }
        let_it_be(:developer_runner) { create(:ci_runner, :project, projects: [developer_project]) }

        it 'does not cause N+1 queries' do
          runners = [owner_runner, maintainer_runner, developer_runner]
          expect_constant_queries([developer_runner], runners)
        end
      end

      context 'with multiple runners per project' do
        let_it_be(:owner_runners) { create_list(:ci_runner, 3, :project, projects: [owner_project]) }
        let_it_be(:maintainer_runners) { create_list(:ci_runner, 3, :project, projects: [maintainer_project]) }
        let_it_be(:developer_runners) { create_list(:ci_runner, 3, :project, projects: [developer_project]) }

        it 'does not cause N+1 queries' do
          all_runners = owner_runners + maintainer_runners + developer_runners
          expect_constant_queries([developer_runners.first], all_runners)
        end
      end

      context 'with different project access levels' do
        let_it_be(:runners_with_diff_access_levels) do
          [
            create(:ci_runner, :project, projects: [owner_project]),
            create(:ci_runner, :project, projects: [maintainer_project]),
            create(:ci_runner, :project, projects: [developer_project])
          ]
        end

        it 'preloads runner policies efficiently across different access levels' do
          expect_constant_queries([runners_with_diff_access_levels.last], runners_with_diff_access_levels)
        end
      end
    end

    context 'with group runners' do
      let_it_be(:owner_group) { create(:group, owners: user) }
      let_it_be(:maintainer_group) { create(:group, maintainers: user) }
      let_it_be(:developer_group) { create(:group, developers: user) }

      context 'with single runner per group' do
        let_it_be(:owner_group_runner) { create(:ci_runner, :group, groups: [owner_group]) }
        let_it_be(:maintainer_group_runner) { create(:ci_runner, :group, groups: [maintainer_group]) }
        let_it_be(:developer_group_runner) { create(:ci_runner, :group, groups: [developer_group]) }

        it 'does not cause N+1 queries' do
          runners = [owner_group_runner, maintainer_group_runner, developer_group_runner]
          expect_constant_queries([owner_group_runner], runners)
        end
      end

      context 'with multiple runners per group' do
        let_it_be(:owner_group_runners) { create_list(:ci_runner, 3, :group, groups: [owner_group]) }
        let_it_be(:maintainer_group_runners) { create_list(:ci_runner, 3, :group, groups: [maintainer_group]) }

        it 'handles without N+1' do
          all_runners = owner_group_runners + maintainer_group_runners
          expect_constant_queries([owner_group_runners.first], all_runners)
        end
      end
    end

    context 'with admin user and instance runners' do
      let_it_be(:instance_runners) { create_list(:ci_runner, 5, :instance) }
      let(:admin_ctx) { { current_user: admin_user } }

      it 'does not cause N+1 queries' do
        expect_constant_queries([instance_runners.first], instance_runners, admin_ctx)
      end
    end
  end
end

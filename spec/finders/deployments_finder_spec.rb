# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentsFinder, feature_category: :deployment_management do
  subject { described_class.new(params).execute }

  describe "validation" do
    context 'when both updated_at and finished_at filters are specified' do
      let(:params) { { updated_before: 1.day.ago, finished_before: 1.day.ago } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          described_class::InefficientQueryError,
          'Both `updated_at` filter and `finished_at` filter can not be specified')
      end
    end

    context 'when finished_at filter and id sorting' do
      let(:params) { { finished_before: 1.day.ago, order_by: :id } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          described_class::InefficientQueryError,
          '`finished_at` filter requires `finished_at` sort.')
      end
    end

    context 'when running status filter and finished_at sorting' do
      let(:params) { { status: :running, order_by: :finished_at } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          described_class::InefficientQueryError,
          '`finished_at` sort requires `finished_at` filter or a filter with at least one of the finished statuses.')
      end
    end

    context 'when finished_at filter with failed status filter' do
      let(:params) { { finished_before: 1.day.ago, order_by: :finished_at, status: :failed } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          described_class::InefficientQueryError,
          '`finished_at` filter must be combined with `success` status filter.')
      end
    end

    context 'when environment filter with non-project scope' do
      let(:params) { { environment: 'production' } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          described_class::InefficientQueryError,
          '`environment` name filter must be combined with `project` scope.')
      end
    end

    context 'when status filter with mixed finished and upcoming statuses' do
      let(:params) { { status: [:success, :running] } }

      it 'raises an error' do
        expect { subject }.to raise_error(
          described_class::InefficientQueryError,
          'finished statuses and upcoming statuses must be separately queried.')
      end
    end
  end

  describe "#execute" do
    context 'when project or group is missing' do
      let(:params) { {} }

      it 'returns nothing' do
        is_expected.to eq([])
      end
    end

    context 'at project scope' do
      let_it_be(:project) { create(:project, :public, :test_repo) }

      let(:base_params) { { project: project } }

      describe 'filtering' do
        context 'when updated_at filters are specified' do
          let_it_be(:deployment_1) { create(:deployment, :success, project: project, updated_at: 48.hours.ago) }
          let_it_be(:deployment_2) { create(:deployment, :success, project: project, updated_at: 47.hours.ago) }
          let_it_be(:deployment_3) { create(:deployment, :success, project: project, updated_at: 4.days.ago) }
          let_it_be(:deployment_4) { create(:deployment, :success, project: project, updated_at: 1.hour.ago) }

          let(:params) { { **base_params, updated_before: 1.day.ago, updated_after: 3.days.ago, order_by: :updated_at } }

          it 'returns deployments with matched updated_at' do
            is_expected.to match_array([deployment_2, deployment_1])
          end
        end

        context 'when the environment name is specified' do
          let!(:environment1) { create(:environment, project: project) }
          let!(:environment2) { create(:environment, project: project) }
          let!(:deployment1) do
            create(:deployment, project: project, environment: environment1)
          end

          let!(:deployment2) do
            create(:deployment, project: project, environment: environment2)
          end

          let(:params) { { **base_params, environment: environment1.name } }

          it 'returns deployments for the given environment' do
            is_expected.to match_array([deployment1])
          end
        end

        context 'when the environment ID is specified' do
          let!(:environment1) { create(:environment, project: project) }
          let!(:environment2) { create(:environment, project: project) }
          let!(:deployment1) do
            create(:deployment, project: project, environment: environment1)
          end

          let!(:deployment2) do
            create(:deployment, project: project, environment: environment2)
          end

          let(:params) { { environment: environment1.id } }

          it 'returns deployments for the given environment' do
            is_expected.to match_array([deployment1])
          end
        end

        context 'when the deployment status is specified' do
          let!(:deployment1) { create(:deployment, :success, project: project) }
          let!(:deployment2) { create(:deployment, :failed, project: project) }
          let(:params) { { **base_params, status: 'success' } }

          it 'returns deployments for the given environment' do
            is_expected.to match_array([deployment1])
          end
        end

        context 'when using an invalid deployment status' do
          let(:params) { { **base_params, status: 'kittens' } }

          it 'raises ArgumentError' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end
      end

      describe 'ordering' do
        using RSpec::Parameterized::TableSyntax

        let(:params) { { **base_params, order_by: order_by, sort: sort } }

        let!(:deployment_1) { create(:deployment, :success, project: project, ref: 'master', created_at: 2.days.ago, updated_at: Time.now, finished_at: Time.now) }
        let!(:deployment_2) { create(:deployment, :success, project: project, ref: 'feature', created_at: 1.day.ago, updated_at: 2.hours.ago, finished_at: 2.hours.ago) }
        let!(:deployment_3) { create(:deployment, :success, project: project, ref: 'video', created_at: Time.now, updated_at: 1.hour.ago, finished_at: 1.hour.ago) }

        where(:order_by, :sort, :ordered_deployments) do
          'created_at'  | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
          'created_at'  | 'desc' | [:deployment_3, :deployment_2, :deployment_1]
          'id'          | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
          'id'          | 'desc' | [:deployment_3, :deployment_2, :deployment_1]
          'iid'         | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
          'iid'         | 'desc' | [:deployment_3, :deployment_2, :deployment_1]
          'ref'         | 'asc'  | [:deployment_1, :deployment_2, :deployment_3] # ref acts like id because of remove_deployments_api_ref_sort feature flag
          'ref'         | 'desc' | [:deployment_3, :deployment_2, :deployment_1] # ref acts like id because of remove_deployments_api_ref_sort feature flag
          'updated_at'  | 'asc'  | [:deployment_2, :deployment_3, :deployment_1]
          'updated_at'  | 'desc' | [:deployment_1, :deployment_3, :deployment_2]
          'finished_at' | 'asc'  | described_class::InefficientQueryError
          'finished_at' | 'desc' | described_class::InefficientQueryError
          'invalid'     | 'asc'  | [:deployment_1, :deployment_2, :deployment_3]
          'iid'         | 'err'  | [:deployment_1, :deployment_2, :deployment_3]
        end

        with_them do
          it 'returns the deployments ordered' do
            if ordered_deployments == described_class::InefficientQueryError
              expect { subject }.to raise_error(described_class::InefficientQueryError)
            else
              expect(subject).to eq(ordered_deployments.map { |name| public_send(name) })
            end
          end
        end
      end

      describe 'transform `created_at` sorting to `id` sorting' do
        let(:params) { { **base_params, order_by: 'created_at', sort: 'asc' } }

        it 'sorts by only one column' do
          expect(subject.order_values.size).to eq(1)
        end

        it 'sorts by `id`' do
          expect(subject.order_values.first.to_sql).to eq(Deployment.arel_table[:id].asc.to_sql)
        end
      end

      describe 'transform `iid` sorting to `id` sorting' do
        let(:params) { { **base_params, order_by: 'iid', sort: 'asc' } }

        it 'sorts by only one column' do
          expect(subject.order_values.size).to eq(1)
        end

        it 'sorts by `id`' do
          expect(subject.order_values.first.to_sql).to eq(Deployment.arel_table[:id].asc.to_sql)
        end
      end

      describe 'tie-breaker for `updated_at` sorting' do
        let(:params) { { **base_params, updated_after: 1.day.ago, order_by: 'updated_at', sort: 'asc' } }

        it 'sorts by two columns' do
          expect(subject.order_values.size).to eq(2)
        end

        it 'adds `id` sorting as the second order column' do
          order_value = subject.order_values[1]

          expect(order_value.to_sql).to eq(Deployment.arel_table[:id].asc.to_sql)
        end

        it 'uses the `id ASC` as tie-breaker when ordering' do
          updated_at = Time.now

          deployment_1 = create(:deployment, :success, project: project, updated_at: updated_at)
          deployment_2 = create(:deployment, :success, project: project, updated_at: updated_at)
          deployment_3 = create(:deployment, :success, project: project, updated_at: updated_at)

          expect(subject).to eq([deployment_1, deployment_2, deployment_3])
        end

        context 'when sort direction is desc' do
          let(:params) { { **base_params, updated_after: 1.day.ago, order_by: 'updated_at', sort: 'desc' } }

          it 'uses the `id DESC` as tie-breaker when ordering' do
            updated_at = Time.now

            deployment_1 = create(:deployment, :success, project: project, updated_at: updated_at)
            deployment_2 = create(:deployment, :success, project: project, updated_at: updated_at)
            deployment_3 = create(:deployment, :success, project: project, updated_at: updated_at)

            expect(subject).to eq([deployment_3, deployment_2, deployment_1])
          end
        end
      end

      context 'when `updated_at` is used for filtering without sorting by `updated_at`' do
        let(:params) { { **base_params, updated_before: 1.day.ago, order_by: 'id', sort: 'asc' } }

        it 'raises an error' do
          expect { subject }.to raise_error(DeploymentsFinder::InefficientQueryError)
        end
      end

      context 'when filtering by finished time' do
        let!(:deployment_1) { create(:deployment, :success, project: project, finished_at: 2.days.ago) }
        let!(:deployment_2) { create(:deployment, :success, project: project, finished_at: 4.days.ago) }
        let!(:deployment_3) { create(:deployment, :success, project: project, finished_at: 5.hours.ago) }

        context 'when filtering by finished_after and finished_before' do
          let(:params) { { **base_params, finished_after: 3.days.ago, finished_before: 1.day.ago, status: :success, order_by: :finished_at } }

          it { is_expected.to match_array([deployment_1]) }
        end

        context 'when the finished_before parameter is missing' do
          let(:params) { { **base_params, finished_after: 3.days.ago, status: :success, order_by: :finished_at } }

          it { is_expected.to match_array([deployment_1, deployment_3]) }
        end

        context 'when finished_after is missing' do
          let(:params) { { **base_params, finished_before: 3.days.ago, status: :success, order_by: :finished_at } }

          it { is_expected.to match_array([deployment_2]) }
        end
      end

      context 'with mixed deployable types' do
        let!(:deployment_1) do
          create(:deployment, :success, project: project, deployable: create(:ci_build))
        end

        let!(:deployment_2) do
          create(:deployment, :success, project: project, deployable: create(:ci_bridge))
        end

        let(:params) { { **base_params, status: 'success' } }

        it 'successfully fetches deployments' do
          is_expected.to contain_exactly(deployment_1, deployment_2)
        end
      end
    end

    context 'at group scope' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      let_it_be(:group_project_1) { create(:project, :public, :test_repo, group: group) }
      let_it_be(:group_project_2) { create(:project, :public, :test_repo, group: group) }
      let_it_be(:subgroup_project_1) { create(:project, :public, :test_repo, group: subgroup) }

      let(:base_params) { { group: group } }

      describe 'ordering' do
        using RSpec::Parameterized::TableSyntax

        let(:params) { { **base_params, order_by: order_by, sort: sort } }

        let!(:group_project_1_deployment) { create(:deployment, :success, project: group_project_1, iid: 11, ref: 'master', created_at: 2.days.ago, updated_at: Time.now, finished_at: Time.now) }
        let!(:group_project_2_deployment) { create(:deployment, :success, project: group_project_2, iid: 12, ref: 'feature', created_at: 1.day.ago, updated_at: 2.hours.ago, finished_at: 2.hours.ago) }
        let!(:subgroup_project_1_deployment) { create(:deployment, :success, project: subgroup_project_1, iid: 8, ref: 'video', created_at: Time.now, updated_at: 1.hour.ago, finished_at: 1.hour.ago) }

        where(:order_by, :sort) do
          'created_at'  | 'asc'
          'created_at'  | 'desc'
          'id'          | 'asc'
          'id'          | 'desc'
          'iid'         | 'asc'
          'iid'         | 'desc'
          'ref'         | 'asc'
          'ref'         | 'desc'
          'invalid'     | 'asc'
          'iid'         | 'err'
        end

        with_them do
          it 'returns the deployments unordered' do
            expect(subject.to_a).to contain_exactly(
              group_project_1_deployment,
              group_project_2_deployment,
              subgroup_project_1_deployment
            )
          end
        end
      end

      it 'avoids N+1 queries' do
        execute_queries = -> { described_class.new({ group: group }).execute.first }
        control = ActiveRecord::QueryRecorder.new { execute_queries }

        new_project = create(:project, :repository, group: group)
        new_env = create(:environment, project: new_project, name: "production")
        create_list(:deployment, 2, status: :success, project: new_project, environment: new_env)
        group.reload

        expect { execute_queries }.not_to exceed_query_limit(control)
      end
    end
  end
end

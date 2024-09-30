# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::AllJobsResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:instance_runner) { create(:ci_runner, :instance) }
  let_it_be(:successful_job) { create(:ci_build, :success, name: 'successful_job') }
  let_it_be(:successful_job_two) { create(:ci_build, :success, name: 'successful_job_two') }
  let_it_be(:failed_job) { create(:ci_build, :failed, name: 'failed_job') }
  let_it_be(:pending_job) { create(:ci_build, :pending, name: 'pending_job') }

  let(:args) { {} }

  describe '#resolve' do
    subject(:request) { resolve_jobs(args) }

    context 'when current user is an admin' do
      let_it_be(:current_user) { create(:admin) }

      shared_examples 'executes as admin' do
        context "with argument `statuses`" do
          using RSpec::Parameterized::TableSyntax

          where(:statuses, :expected_jobs) do
            nil                | lazy { [successful_job, successful_job_two, failed_job, pending_job] }
            %w[SUCCESS]        | lazy { [successful_job, successful_job_two] }
            %w[SUCCESS FAILED] | lazy { [successful_job, successful_job_two, failed_job] }
            %w[CANCELED]       | lazy { [] }
          end

          with_them do
            let(:args) do
              { statuses: statuses&.map { |status| Types::Ci::JobStatusEnum.coerce_isolated_input(status) } }
            end

            it { is_expected.to contain_exactly(*expected_jobs) }
          end
        end

        context "with argument `runner_types`" do
          let_it_be(:successful_job_with_instance_runner) do
            create(:ci_build, :success, name: 'successful_job_with_instance_runner', runner: instance_runner)
          end

          context 'with feature flag :admin_jobs_filter_runner_type enabled' do
            using RSpec::Parameterized::TableSyntax

            where(:runner_types, :expected_jobs) do
              nil | lazy do
                [
                  successful_job,
                  successful_job_two,
                  failed_job,
                  pending_job,
                  successful_job_with_instance_runner
                ]
              end
              %w[INSTANCE_TYPE]            | lazy { [successful_job_with_instance_runner] }
              %w[INSTANCE_TYPE GROUP_TYPE] | lazy { [successful_job_with_instance_runner] }
              %w[PROJECT_TYPE]             | lazy { [] }
            end

            with_them do
              let(:args) do
                {
                  runner_types: runner_types&.map { |type| Types::Ci::RunnerTypeEnum.coerce_isolated_input(type) }
                }
              end

              it { is_expected.to match_array(expected_jobs) }
            end
          end
        end

        context "with argument combination" do
          let_it_be(:successful_job_with_instance_runner) do
            create(
              :ci_build,
              :success,
              name: 'successful_job_with_instance_runner',
              runner: instance_runner
            )
          end

          let_it_be(:group) { create(:group) }
          let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
          let_it_be(:running_job_with_group_runner) do
            create(:ci_build, :running, name: 'running_job_with_instance_runner', runner: group_runner)
          end

          context 'with feature flag :admin_jobs_filter_runner_type enabled' do
            using RSpec::Parameterized::TableSyntax

            where(:statuses, :runner_types, :expected_jobs) do
              %w[SUCCESS]         | %w[INSTANCE_TYPE]            | lazy { [successful_job_with_instance_runner] }
              %w[CANCELED]        | %w[INSTANCE_TYPE]            | lazy { [] }
              %w[SUCCESS RUNNING] | %w[INSTANCE_TYPE GROUP_TYPE] | lazy do
                                                                     [
                                                                       successful_job_with_instance_runner,
                                                                       running_job_with_group_runner
                                                                     ]
                                                                   end
            end

            with_them do
              let(:args) do
                {
                  statuses: statuses&.map { |status| Types::Ci::JobStatusEnum.coerce_isolated_input(status) },
                  runner_types: runner_types&.map { |type| Types::Ci::RunnerTypeEnum.coerce_isolated_input(type) }
                }
              end

              it { is_expected.to contain_exactly(*expected_jobs) }
            end
          end
        end
      end

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it_behaves_like 'executes as admin'
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it_behaves_like 'executes as admin'
        end

        context 'when not in admin mode' do
          it { is_expected.to be_empty }
        end
      end
    end

    context 'with unauthorized user' do
      let_it_be(:unauth_user) { create(:user) }

      let(:current_user) { unauth_user }

      it { is_expected.to be_empty }
    end
  end

  private

  def resolve_jobs(args = {}, context = { current_user: current_user })
    resolve(described_class, args: args, ctx: context)
  end
end

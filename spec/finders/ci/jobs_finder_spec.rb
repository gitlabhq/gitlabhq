# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobsFinder, '#execute', feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:project) { create(:project, :private, public_builds: false) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:pending_job) { create(:ci_build, :pending) }
  let_it_be(:running_job) { create(:ci_build, :running) }
  let_it_be(:successful_job) { create(:ci_build, :success, pipeline: pipeline, name: 'build') }

  let(:params) { {} }

  context 'when project, pipeline, and runner are blank' do
    subject(:finder_execute) { described_class.new(current_user: current_user, params: params).execute }

    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode setting is disabled', :do_not_mock_admin_mode_setting do
        it { is_expected.to match_array([pending_job, running_job, successful_job]) }
      end

      context 'when admin mode setting is enabled' do
        context 'when in admin mode', :enable_admin_mode do
          it { is_expected.to match_array([pending_job, running_job, successful_job]) }
        end

        context 'when not in admin mode' do
          it { is_expected.to be_empty }
        end
      end
    end

    context 'with admin and admin mode enabled', :enable_admin_mode do
      let(:current_user) { admin }

      context 'with param `scope`' do
        using RSpec::Parameterized::TableSyntax

        where(:scope, :expected_jobs) do
          'pending'           | lazy { [pending_job] }
          'running'           | lazy { [running_job] }
          'finished'          | lazy { [successful_job] }
          %w[running success] | lazy { [running_job, successful_job] }
        end

        with_them do
          let(:params) { { scope: scope } }

          it { is_expected.to match_array(expected_jobs) }
        end
      end

      context 'with param `runner_type`' do
        let_it_be(:job_with_instance_runner) { create(:ci_build, :success, runner: create(:ci_runner, :instance)) }
        let_it_be(:job_with_group_runner) do
          create(:ci_build, :success, runner: create(:ci_runner, :group, groups: [project.parent]))
        end

        let_it_be(:job_with_project_runner) do
          create(:ci_build, :success, runner: create(:ci_runner, :project, projects: [project]))
        end

        context 'with feature flag :admin_jobs_filter_runner_type enabled' do
          using RSpec::Parameterized::TableSyntax

          where(:runner_type, :expected_jobs) do
            'group_type'                   | lazy { [job_with_group_runner] }
            'instance_type'                | lazy { [job_with_instance_runner] }
            'project_type'                 | lazy { [job_with_project_runner] }
            %w[instance_type project_type] | lazy { [job_with_instance_runner, job_with_project_runner] }
          end

          with_them do
            let(:params) { { runner_type: runner_type } }
            it { is_expected.to match_array(expected_jobs) }
          end
        end

        context 'with feature flag :admin_jobs_filter_runner_type disabled' do
          let(:params) { { runner_type: 'instance_type' } }
          let(:expected_jobs) do
            [
              job_with_group_runner,
              job_with_instance_runner,
              job_with_project_runner,
              pending_job,
              running_job,
              successful_job
            ]
          end

          before do
            stub_feature_flags(admin_jobs_filter_runner_type: false)
          end

          it { is_expected.to match_array(expected_jobs) }
        end
      end

      context "with params" do
        let_it_be(:job_with_running_status_and_group_runner) do
          create(:ci_build, :running, runner: create(:ci_runner, :group, groups: [project.parent]))
        end

        let_it_be(:job_with_instance_runner) { create(:ci_build, :success, runner: create(:ci_runner, :instance)) }
        let_it_be(:job_with_project_runner) do
          create(:ci_build, :success, runner: create(:ci_runner, :project, projects: [project]))
        end

        context 'with feature flag :admin_jobs_filter_runner_type enabled' do
          using RSpec::Parameterized::TableSyntax

          where(:param_runner_type, :param_scope, :expected_jobs) do
            'group_type'                   | 'running'  | lazy { [job_with_running_status_and_group_runner] }
            %w[instance_type project_type] | 'finished' | lazy { [job_with_instance_runner, job_with_project_runner] }
            %w[instance_type project_type] | 'pending'  | lazy { [] }
          end

          with_them do
            let(:params) { { runner_type: param_runner_type, scope: param_scope } }

            it { is_expected.to match_array(expected_jobs) }
          end
        end

        context 'with feature flag :admin_jobs_filter_runner_type disabled' do
          before do
            stub_feature_flags(admin_jobs_filter_runner_type: false)
          end

          using RSpec::Parameterized::TableSyntax

          where(:param_runner_type, :param_scope, :expected_jobs) do
            'group_type' | 'running' | lazy do
              [job_with_running_status_and_group_runner, running_job]
            end
            %w[instance_type project_type] | 'finished' | lazy do
              [
                job_with_instance_runner,
                job_with_project_runner,
                successful_job
              ]
            end
            %w[instance_type project_type] | 'pending' | lazy { [pending_job] }
          end

          with_them do
            let(:params) { { runner_type: param_runner_type, scope: param_scope } }

            it { is_expected.to match_array(expected_jobs) }
          end
        end
      end
    end

    context 'with user not being project member' do
      let(:current_user) { user }

      it { is_expected.to be_empty }
    end

    context 'without user' do
      let(:current_user) { nil }

      it { is_expected.to be_empty }
    end
  end

  context 'when project is present' do
    subject { described_class.new(current_user: user, project: project, params: params).execute }

    context 'with user being project maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns jobs for the specified project' do
        expect(subject).to match_array([successful_job])
      end

      context 'when artifacts are present for some jobs' do
        let_it_be(:job_with_artifacts) { create(:ci_build, :success, pipeline: pipeline, name: 'test') }
        let_it_be(:artifact) { create(:ci_job_artifact, job: job_with_artifacts) }

        context 'when with_artifacts is true' do
          let(:params) { { with_artifacts: true } }

          it 'returns only jobs with artifacts' do
            expect(subject).to match_array([job_with_artifacts])
          end
        end

        context 'when with_artifacts is false' do
          let(:params) { { with_artifacts: false } }

          it 'returns all jobs' do
            expect(subject).to match_array([successful_job, job_with_artifacts])
          end
        end

        context "with param `scope" do
          using RSpec::Parameterized::TableSyntax

          where(:param_scope, :expected_jobs) do
            'success'           | lazy { [successful_job, job_with_artifacts] }
            '[success pending]' | lazy { [successful_job, job_with_artifacts] }
            'pending'           | lazy { [] }
            nil                 | lazy { [successful_job, job_with_artifacts] }
          end

          with_them do
            let(:params) { { with_artifacts: false, scope: param_scope } }

            it { is_expected.to match_array(expected_jobs) }
          end
        end
      end
    end

    context 'with user being project guest' do
      before do
        project.add_guest(user)
      end

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end

    context 'without user' do
      let(:user) { nil }

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end
  end

  context 'when pipeline is present' do
    subject { described_class.new(current_user: user, pipeline: pipeline, params: params).execute }

    context 'with user being project maintainer' do
      before_all do
        project.add_maintainer(user)
        successful_job.update!(retried: true)
      end

      let_it_be(:job_4) { create(:ci_build, :success, pipeline: pipeline, name: 'build') }

      it 'does not return retried jobs by default' do
        expect(subject).to match_array([job_4])
      end

      context 'when include_retried is false' do
        let(:params) { { include_retried: false } }

        it 'does not return retried jobs' do
          expect(subject).to match_array([job_4])
        end
      end

      context 'when include_retried is true' do
        let(:params) { { include_retried: true } }

        it 'returns retried jobs' do
          expect(subject).to match_array([successful_job, job_4])
        end
      end
    end

    context 'without user' do
      let(:user) { nil }

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end
  end

  context 'when runner is present' do
    let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:job_4) { create(:ci_build, :success, runner: runner) }

    subject(:execute) { described_class.new(current_user: user, runner: runner, params: params).execute }

    context 'when current user is an admin' do
      let(:user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns jobs for the specified project' do
          expect(subject).to contain_exactly job_4
        end

        context 'with params' do
          using RSpec::Parameterized::TableSyntax

          where(:param_runner_type, :param_scope, :expected_jobs) do
            'project_type'  | 'success' | lazy { [job_4] }
            'instance_type' | nil       | lazy { [] }
            nil             | 'pending' | lazy { [] }
          end

          with_them do
            let(:params) { { runner_type: param_runner_type, scope: param_scope } }

            it { is_expected.to match_array(expected_jobs) }
          end
        end
      end
    end

    context 'with user being project guest' do
      let_it_be(:guest) { create(:user) }

      let(:user) { guest }

      before do
        project.add_guest(guest)
      end

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end

    context 'without user' do
      let(:user) { nil }

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end
  end
end

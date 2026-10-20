# frozen_string_literal: true

require 'spec_helper'

# NOTE: No dedicated cross-organization isolation test here. `Ci::RunnerJobsFinder` returns the
# jobs of a single runner filtered by the user's per-project access (see the cross-project
# isolation examples below), which is the effective organization boundary for this path.
RSpec.describe Ci::RunnerJobsFinder, '#execute', factory_default: :keep, feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create_default(:ci_pipeline, project: project) }
  let_it_be(:runner) { create(:ci_runner, :instance) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner) }
  let_it_be(:jobs) { create_list(:ci_build, 5, runner_manager: runner_manager, project: project) }

  let(:params) { {} }

  subject(:execute) { described_class.new(runner, user, params).execute }

  context 'when params is empty' do
    let!(:job1) { create(:ci_build, project: project) }

    it 'returns all jobs assigned to Runner' do
      is_expected.to match_array(jobs)
      is_expected.not_to include(job1)
    end
  end

  context 'when the user has guest access' do
    let(:another_project) { create(:project, guests: user) }
    let!(:job) { create(:ci_build, runner: runner, project: another_project) }

    it 'does not returns jobs the user does not have permission to see' do
      is_expected.not_to match_array(job)
    end
  end

  context 'when the user is admin', :enable_admin_mode do
    let_it_be(:user) { create(:user, :admin) }

    it { is_expected.to match_array(jobs) }
  end

  context 'when user is developer' do
    it { is_expected.to match_array(jobs) }
  end

  context 'when the user has different access levels in different projects' do
    let_it_be(:guest_project) { create(:project, guests: user) }
    let_it_be(:guest_jobs) { create_list(:ci_build, 2, runner: runner, project: guest_project) }
    let_it_be(:reporter_project) { create(:project, reporters: user) }
    let_it_be(:reporter_jobs) { create_list(:ci_build, 3, runner: runner, project: reporter_project) }

    it 'returns only the jobs the user has permission to see', :aggregate_failures do
      is_expected.to include(*reporter_jobs)
      is_expected.not_to include(*guest_jobs)
    end
  end

  context 'when the user has reporter access level or greater' do
    it 'returns jobs assigned to the Runner that the user has access to' do
      is_expected.to match_array(jobs)
    end
  end

  context 'when params contains status' do
    Ci::HasStatus::AVAILABLE_STATUSES.each do |target_status|
      context "when status is #{target_status}" do
        let(:params) { { status: target_status } }
        let(:exception_status) { (Ci::HasStatus::AVAILABLE_STATUSES - [target_status]).first }
        let!(:job) { create(:ci_build, runner: runner, project: project, status: target_status) }
        let!(:other_job) { create(:ci_build, runner: runner, project: project, status: exception_status) }

        it 'returns matched job', :aggregate_failures do
          is_expected.to include(job)
          is_expected.not_to include(other_job)
        end
      end
    end
  end

  context 'when system_id is specified' do
    let_it_be(:runner_manager2) { create(:ci_runner_machine, runner: runner) }
    let_it_be(:job2) { create(:ci_build, runner_manager: runner_manager2, project: project) }

    let(:params) { { system_id: runner_manager.system_xid } }

    it 'returns jobs from the specified system' do
      is_expected.to match_array(jobs)
    end

    context 'when specified system_id does not exist' do
      let(:params) { { system_id: 'unknown_system' } }

      it { is_expected.to be_empty }
    end
  end

  context 'when order_by and sort are specified' do
    context 'when order_by id and sort is asc' do
      let(:params) { { order_by: 'id', sort: 'asc' } }

      it 'sorts as id: :asc' do
        is_expected.to eq(jobs.sort_by(&:id))
      end
    end
  end

  context 'when order_by is specified and sort is not specified' do
    let(:params) { { order_by: 'id' } }

    it 'sorts as id: :desc' do
      is_expected.to eq(jobs.sort_by(&:id).reverse)
    end
  end

  context 'when repository is disabled' do
    let_it_be(:disabled_repo_project) { create(:project, :repository_disabled, reporters: user) }
    let_it_be(:disabled_repo_jobs) { create_list(:ci_build, 2, runner: runner, project: disabled_repo_project) }

    it 'does not return jobs from projects with disabled repository' do
      is_expected.not_to include(*disabled_repo_jobs)
    end
  end

  context 'when builds are disabled' do
    let_it_be(:disabled_builds_project) { create(:project, :builds_disabled, reporters: user) }
    let_it_be(:disabled_builds_jobs) { create_list(:ci_build, 2, runner: runner, project: disabled_builds_project) }

    it 'does not return jobs from projects with disabled builds' do
      is_expected.not_to include(*disabled_builds_jobs)
    end
  end

  context 'when both repository and builds are enabled' do
    let_it_be(:enabled_project) { create(:project, reporters: user) }
    let_it_be(:enabled_jobs) { create_list(:ci_build, 2, runner: runner, project: enabled_project) }

    it 'returns jobs from projects with enabled repository and builds' do
      is_expected.to include(*enabled_jobs)
    end
  end

  context 'with lateral authorization' do
    subject(:lateral_jobs) { described_class.new(runner, user, params).execute }

    it 'keeps permission checks correlated with each job', :aggregate_failures do
      sql = lateral_jobs.to_sql

      expect(sql).to include('CROSS JOIN LATERAL', 'OFFSET 0', 'LIMIT 1')
      expect(sql).to include('ci_project_mirrors', 'p_ci_builds')
    end

    context 'when filtering by status' do
      let(:params) { { status: 'success' } }

      it 'applies the status filter outside the authorization join', :aggregate_failures do
        _, lateral_and_outer_query = lateral_jobs.to_sql.split('CROSS JOIN LATERAL (', 2)
        lateral_query, outer_query = lateral_and_outer_query.split(') allowed_project', 2)

        expect(lateral_query).not_to include('"p_ci_builds"."status"')
        expect(outer_query).to include('"p_ci_builds"."status"')
      end
    end

    it 'returns only authorized jobs in the requested order' do
      inaccessible_project = create(:project)
      create(:ci_build, runner: runner, project: inaccessible_project)
      successful_jobs = create_list(:ci_build, 2, runner: runner, project: project, status: :success)
      create(:ci_build, runner: runner, project: project, status: :failed)
      filtered_jobs = described_class
        .new(runner, user, { status: 'success', order_by: 'id', sort: 'desc' })
        .execute

      expect(filtered_jobs.to_a).to eq(successful_jobs.reverse)
    end

    it 'preserves the full authorized count for pagination' do
      inaccessible_project = create(:project)
      create(:ci_build, runner: runner, project: inaccessible_project)

      expect(lateral_jobs.count).to eq(jobs.size)
    end

    context 'when the user is an admin', :enable_admin_mode do
      let(:user) { create(:user, :admin) }

      it 'does not add an authorization join' do
        expect(lateral_jobs.to_sql).not_to include('LATERAL')
      end
    end

    context 'when system_id is specified' do
      let(:params) { { system_id: runner_manager.system_xid } }

      it 'uses lateral authorization with the runner manager scope' do
        expect(lateral_jobs.to_sql).to include('CROSS JOIN LATERAL')
        expect(lateral_jobs).to match_array(jobs)
      end
    end

    context 'when keyset pagination is requested' do
      let(:params) { { pagination: 'keyset', order_by: 'id', sort: 'desc' } }

      it 'uses lateral authorization for keyset pagination' do
        expect(lateral_jobs.to_sql).to include('CROSS JOIN LATERAL')
        expect(lateral_jobs).to match_array(jobs)
      end
    end
  end
end

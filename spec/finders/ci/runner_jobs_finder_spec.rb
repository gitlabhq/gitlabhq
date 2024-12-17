# frozen_string_literal: true

require 'spec_helper'

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
    before_all do
      project.add_developer(user)
    end

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
end

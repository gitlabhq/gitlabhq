# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerJobsFinder do
  let(:project) { create(:project) }
  let(:runner) { create(:ci_runner, :instance) }
  let(:user) { create(:user) }
  let(:params) { {} }

  subject { described_class.new(runner, user, params).execute }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    context 'when params is empty' do
      let!(:job) { create(:ci_build, runner: runner, project: project) }
      let!(:job1) { create(:ci_build, project: project) }

      it 'returns all jobs assigned to Runner' do
        is_expected.to match_array(job)
        is_expected.not_to match_array(job1)
      end
    end

    context 'when the user has guest access' do
      it 'does not returns jobs the user does not have permission to see' do
        another_project = create(:project)
        job = create(:ci_build, runner: runner, project: another_project)

        another_project.add_guest(user)

        is_expected.not_to match_array(job)
      end
    end

    context 'when the user has permission to read all resources' do
      let(:user) { create(:user, :admin) }

      it 'returns all the jobs assigned to a runner' do
        jobs = create_list(:ci_build, 5, runner: runner, project: project)

        is_expected.to match_array(jobs)
      end
    end

    context 'when the user has different access levels in different projects' do
      it 'returns only the jobs the user has permission to see' do
        guest_project = create(:project)
        reporter_project = create(:project)

        _guest_jobs = create_list(:ci_build, 2, runner: runner, project: guest_project)
        reporter_jobs = create_list(:ci_build, 3, runner: runner, project: reporter_project)

        guest_project.add_guest(user)
        reporter_project.add_reporter(user)

        is_expected.to match_array(reporter_jobs)
      end
    end

    context 'when the user has reporter access level or greater' do
      it 'returns jobs assigned to the Runner that the user has accesss to' do
        jobs = create_list(:ci_build, 3, runner: runner, project: project)

        is_expected.to match_array(jobs)
      end
    end

    context 'when params contains status' do
      Ci::HasStatus::AVAILABLE_STATUSES.each do |target_status|
        context "when status is #{target_status}" do
          let(:params) { { status: target_status } }
          let!(:job) { create(:ci_build, runner: runner, project: project, status: target_status) }

          before do
            exception_status = Ci::HasStatus::AVAILABLE_STATUSES - [target_status]
            create(:ci_build, runner: runner, project: project, status: exception_status.first)
          end

          it 'returns matched job' do
            is_expected.to eq([job])
          end
        end
      end
    end

    context 'when order_by and sort are specified' do
      context 'when order_by id and sort is asc' do
        let(:params) { { order_by: 'id', sort: 'asc' } }
        let!(:jobs) { create_list(:ci_build, 2, runner: runner, project: project, user: create(:user)) }

        it 'sorts as id: :asc' do
          is_expected.to eq(jobs.sort_by(&:id))
        end
      end
    end

    context 'when order_by is specified and sort is not specified' do
      context 'when order_by id and sort is not specified' do
        let(:params) { { order_by: 'id' } }
        let!(:jobs) { create_list(:ci_build, 2, runner: runner, project: project, user: create(:user)) }

        it 'sorts as id: :desc' do
          is_expected.to eq(jobs.sort_by(&:id).reverse)
        end
      end
    end
  end
end

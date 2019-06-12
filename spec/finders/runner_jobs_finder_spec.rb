require 'spec_helper'

describe RunnerJobsFinder do
  let(:project) { create(:project) }
  let(:runner) { create(:ci_runner, :instance) }

  subject { described_class.new(runner, params).execute }

  describe '#execute' do
    context 'when params is empty' do
      let(:params) { {} }
      let!(:job) { create(:ci_build, runner: runner, project: project) }
      let!(:job1) { create(:ci_build, project: project) }

      it 'returns all jobs assigned to Runner' do
        is_expected.to match_array(job)
        is_expected.not_to match_array(job1)
      end
    end

    context 'when params contains status' do
      HasStatus::AVAILABLE_STATUSES.each do |target_status|
        context "when status is #{target_status}" do
          let(:params) { { status: target_status } }
          let!(:job) { create(:ci_build, runner: runner, project: project, status: target_status) }

          before do
            exception_status = HasStatus::AVAILABLE_STATUSES - [target_status]
            create(:ci_build, runner: runner, project: project, status: exception_status.first)
          end

          it 'returns matched job' do
            is_expected.to eq([job])
          end
        end
      end
    end

    context 'when order_by and sort are specified' do
      context 'when order_by created_at' do
        let(:params) { { order_by: 'created_at', sort: 'asc' } }
        let!(:jobs) { Array.new(2) { create(:ci_build, runner: runner, project: project, user: create(:user)) } }

        it 'sorts as created_at: :asc' do
          is_expected.to match_array(jobs)
        end

        context 'when sort is invalid' do
          let(:params) { { order_by: 'created_at', sort: 'invalid_sort' } }

          it 'sorts as created_at: :desc' do
            is_expected.to eq(jobs.sort_by { |p| -p.user.id })
          end
        end
      end

      context 'when order_by is invalid' do
        let(:params) { { order_by: 'invalid_column', sort: 'asc' } }
        let!(:jobs) { Array.new(2) { create(:ci_build, runner: runner, project: project, user: create(:user)) } }

        it 'sorts as id: :asc' do
          is_expected.to eq(jobs.sort_by { |p| p.id })
        end
      end

      context 'when both are nil' do
        let(:params) { { order_by: nil, sort: nil } }
        let!(:jobs) { Array.new(2) { create(:ci_build, runner: runner, project: project, user: create(:user)) } }

        it 'sorts as id: :desc' do
          is_expected.to eq(jobs.sort_by { |p| -p.id })
        end
      end
    end
  end
end

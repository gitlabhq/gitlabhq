require 'spec_helper'

describe RunnerJobsFinder do
  let(:project) { create(:project) }
  let(:runner) { create(:ci_runner, :shared) }

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
  end
end

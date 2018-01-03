require 'spec_helper'

describe PipelineSchedulesFinder do
  let(:project) { create(:project) }

  let!(:active_schedule) { create(:ci_pipeline_schedule, project: project) }
  let!(:inactive_schedule) { create(:ci_pipeline_schedule, :inactive, project: project) }

  subject { described_class.new(project).execute(params) }

  describe "#execute" do
    context 'when the scope is nil' do
      let(:params) { { scope: nil } }

      it 'selects all pipeline pipeline schedules' do
        expect(subject.count).to be(2)
        expect(subject).to include(active_schedule, inactive_schedule)
      end
    end

    context 'when the scope is active' do
      let(:params) { { scope: 'active' } }

      it 'selects only active pipelines' do
        expect(subject.count).to be(1)
        expect(subject).to include(active_schedule)
        expect(subject).not_to include(inactive_schedule)
      end
    end

    context 'when the scope is inactve' do
      let(:params) { { scope: 'inactive' } }

      it 'selects only inactive pipelines' do
        expect(subject.count).to be(1)
        expect(subject).not_to include(active_schedule)
        expect(subject).to include(inactive_schedule)
      end
    end
  end
end

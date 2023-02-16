# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedulesFinder do
  let(:project) { create(:project) }

  let!(:active_schedule) { create(:ci_pipeline_schedule, project: project) }
  let!(:inactive_schedule) { create(:ci_pipeline_schedule, :inactive, project: project) }

  subject { described_class.new(project).execute(**params) }

  describe "#execute" do
    context 'when the scope is nil' do
      let(:params) { { scope: nil } }

      it 'selects all pipeline schedules' do
        expect(subject).to contain_exactly(active_schedule, inactive_schedule)
      end
    end

    context 'when the id is nil' do
      let(:params) { { ids: nil } }

      it 'selects all pipeline schedules' do
        expect(subject).to contain_exactly(active_schedule, inactive_schedule)
      end
    end

    context 'when the id is a single pipeline schedule' do
      let(:params) { { ids: active_schedule.id } }

      it 'selects one pipeline schedule' do
        expect(subject).to contain_exactly(active_schedule)
      end
    end

    context 'when multiple ids are provided' do
      let(:params) { { ids: [active_schedule.id, inactive_schedule.id] } }

      it 'selects multiple pipeline schedules' do
        expect(subject).to contain_exactly(active_schedule, inactive_schedule)
      end
    end

    context 'when multiple ids are provided and a scope is set' do
      let(:params) { { scope: 'active', ids: [active_schedule.id, inactive_schedule.id] } }

      it 'selects one pipeline schedule' do
        expect(subject).to contain_exactly(active_schedule)
      end
    end

    context 'when the scope is active' do
      let(:params) { { scope: 'active' } }

      it 'selects only active pipelines' do
        expect(subject).to contain_exactly(active_schedule)
      end
    end

    context 'when the scope is inactve' do
      let(:params) { { scope: 'inactive' } }

      it 'selects only inactive pipelines' do
        expect(subject).to contain_exactly(inactive_schedule)
      end
    end
  end
end

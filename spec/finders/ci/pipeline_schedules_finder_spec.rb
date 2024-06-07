# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedulesFinder do
  let(:project) { create(:project) }

  describe "#execute" do
    let!(:active_schedule) { create(:ci_pipeline_schedule, project: project) }
    let!(:inactive_schedule) { create(:ci_pipeline_schedule, :inactive, project: project) }

    subject { described_class.new(project).execute(**params) }

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

  describe '#sort' do
    before do
      travel_to(Time.zone.local(2024, 3, 2, 1, 0))
    end

    let!(:pipeline1) do
      create(:ci_pipeline_schedule, description: :aab, ref: :masterb, cron: ' 0 5 * * *   ',
        created_at: Time.zone.local(2024, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 1, 2, 1, 0),
        project: project)
    end

    let!(:pipeline2) do
      create(:ci_pipeline_schedule, description: :aaa, ref: :masterz, cron: ' 0 6 * * *   ',
        created_at: Time.zone.local(2023, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 3, 2, 1, 0),
        project: project)
    end

    let!(:pipeline3) do
      create(:ci_pipeline_schedule, description: :zzz, ref: :mastera, cron: ' 0 8 * * *   ',
        created_at: Time.zone.local(2022, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 4, 2, 1, 0),
        project: project)
    end

    let!(:pipeline4) do
      create(:ci_pipeline_schedule, description: :zza, ref: :mastery, cron: ' 0 7 * * *   ',
        created_at: Time.zone.local(2021, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 2, 2, 1, 0),
        project: project)
    end

    subject { described_class.new(project, params).execute }

    context "with by id" do
      context "and sorts desc" do
        let(:params) { { sort: :id_desc } }

        it { is_expected.to eq([pipeline4, pipeline3, pipeline2, pipeline1]) }
      end

      context "and sorts asc" do
        let(:params) { { sort: :id_asc } }

        it { is_expected.to eq([pipeline1, pipeline2, pipeline3, pipeline4]) }
      end
    end

    context "with by description" do
      context "and sorts desc" do
        let(:params) { { sort: :description_desc } }

        it { is_expected.to eq([pipeline3, pipeline4, pipeline1, pipeline2]) }
      end

      context "and sorts asc" do
        let(:params) { { sort: :description_asc } }

        it { is_expected.to eq([pipeline2, pipeline1, pipeline4, pipeline3]) }
      end
    end

    context "with by ref" do
      context "and sorts desc" do
        let(:params) { { sort: :ref_desc } }

        it { is_expected.to eq([pipeline2, pipeline4, pipeline1, pipeline3]) }
      end

      context "and sorts asc" do
        let(:params) { { sort: :ref_asc } }

        it { is_expected.to eq([pipeline3, pipeline1, pipeline4, pipeline2]) }
      end
    end

    context "with by next_run_at" do
      context "and sorts desc" do
        let(:params) { { sort: :next_run_at_desc } }

        it { is_expected.to eq([pipeline3, pipeline4, pipeline2, pipeline1]) }
      end

      context "and sorts asc" do
        let(:params) { { sort: :next_run_at_asc } }

        it { is_expected.to eq([pipeline1, pipeline2, pipeline4, pipeline3]) }
      end
    end

    context "with by created_at" do
      context "and sorts desc" do
        let(:params) { { sort: :created_at_desc } }

        it { is_expected.to eq([pipeline1, pipeline2, pipeline3, pipeline4]) }
      end

      context "and sorts asc" do
        let(:params) { { sort: :created_at_asc } }

        it { is_expected.to eq([pipeline4, pipeline3, pipeline2, pipeline1]) }
      end
    end

    context "with by updated_at" do
      context "and sorts desc" do
        let(:params) { { sort: :updated_at_desc } }

        it { is_expected.to eq([pipeline3, pipeline2, pipeline4, pipeline1]) }
      end

      context "and sorts asc" do
        let(:params) { { sort: :updated_at_asc } }

        it { is_expected.to eq([pipeline1, pipeline4, pipeline2, pipeline3]) }
      end
    end
  end
end

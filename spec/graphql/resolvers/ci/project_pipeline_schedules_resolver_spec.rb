# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ProjectPipelineSchedulesResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, public_builds: false, owners: user) }

  describe 'With filters' do
    let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer) }

    before do
      pipeline_schedule.pipelines << build(:ci_pipeline, project: project)
    end

    it 'shows active pipeline schedules' do
      schedules = resolve_pipeline_schedules

      expect(schedules).to contain_exactly(pipeline_schedule)
    end

    it 'shows the inactive pipeline schedules' do
      schedules = resolve_pipeline_schedules(args:
                 { status: ::Types::Ci::PipelineScheduleStatusEnum.values['INACTIVE'].value })

      expect(schedules).to be_empty
    end
  end

  describe '#sort', time_travel_to: Time.zone.local(2024, 3, 2, 12, 0) do
    let!(:pipeline1) do
      create(:ci_pipeline_schedule, description: :aab, ref: :masterb, cron: ' 0 13 * * *   ',
        created_at: Time.zone.now, updated_at: 2.months.ago, project: project)
    end

    let!(:pipeline2) do
      create(:ci_pipeline_schedule, description: :aaa, ref: :masterz, cron: ' 0 23 * * *   ',
        created_at: 1.year.ago, updated_at: Time.zone.now, project: project)
    end

    let!(:pipeline3) do
      create(:ci_pipeline_schedule, description: :zzz, ref: :mastera, cron: ' 0 12 * * *   ',
        created_at: 2.years.ago, updated_at: 1.month.from_now, project: project)
    end

    let!(:pipeline4) do
      create(:ci_pipeline_schedule, description: :zza, ref: :mastery, cron: ' 0 1 * * *   ',
        created_at: 3.years.ago, updated_at: 1.month.ago, project: project)
    end

    context "with by id" do
      it "default sort" do
        expect(resolve_pipeline_schedules.to_a).to eq([pipeline4, pipeline3, pipeline2, pipeline1])
      end

      it "sorts desc" do
        expect(resolve_pipeline_schedules(args: { sort: :id_desc }).to_a).to eq([pipeline4, pipeline3, pipeline2,
          pipeline1])
      end

      it "sorts asc" do
        expect(resolve_pipeline_schedules(args: { sort: :id_asc }).to_a).to eq([pipeline1, pipeline2, pipeline3,
          pipeline4])
      end
    end

    context "with by description" do
      it "sorts desc" do
        expect(resolve_pipeline_schedules(args: { sort: :description_desc }).to_a).to eq([pipeline3, pipeline4,
          pipeline1, pipeline2])
      end

      it "sorts asc" do
        expect(resolve_pipeline_schedules(args: { sort: :description_asc }).to_a).to eq([pipeline2, pipeline1,
          pipeline4, pipeline3])
      end
    end

    context "with by ref" do
      it "sorts desc" do
        expect(resolve_pipeline_schedules(args: { sort: :ref_desc }).to_a).to eq([pipeline2, pipeline4, pipeline1,
          pipeline3])
      end

      it "sorts asc" do
        expect(resolve_pipeline_schedules(args: { sort: :ref_asc }).to_a).to eq([pipeline3, pipeline1, pipeline4,
          pipeline2])
      end
    end

    context "with by next_run_at" do
      it "sorts desc" do
        expect(resolve_pipeline_schedules(args: { sort: :next_run_at_desc }).to_a).to eq([pipeline3, pipeline4,
          pipeline2, pipeline1])
      end

      it "sorts asc" do
        expect(resolve_pipeline_schedules(args: { sort: :next_run_at_asc }).to_a).to eq([pipeline1, pipeline2,
          pipeline4, pipeline3])
      end
    end

    context "with by created_at" do
      it "sorts desc" do
        expect(resolve_pipeline_schedules(args: { sort: :created_at_desc }).to_a).to eq([pipeline1, pipeline2,
          pipeline3, pipeline4])
      end

      it "sorts asc" do
        expect(resolve_pipeline_schedules(args: { sort: :created_at_asc }).to_a).to eq([pipeline4, pipeline3,
          pipeline2, pipeline1])
      end
    end

    context "with by updated_at" do
      it "sorts desc" do
        expect(resolve_pipeline_schedules(args: { sort: :updated_at_desc }).to_a).to eq([pipeline3, pipeline2,
          pipeline4, pipeline1])
      end

      it "sorts asc" do
        expect(resolve_pipeline_schedules(args: { sort: :updated_at_asc }).to_a).to eq([pipeline1, pipeline4,
          pipeline2, pipeline3])
      end
    end
  end

  def resolve_pipeline_schedules(args: {})
    resolve(described_class, obj: project, ctx: { current_user: user }, args: args, arg_style: :internal)
  end
end

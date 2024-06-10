# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelineSchedulesResolver do
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

  describe '#sort' do
    before do
      travel_to(Time.zone.local(2024, 3, 2, 1, 0))
    end

    let_it_be(:pipeline1) do
      create(:ci_pipeline_schedule, description: :aab, ref: :masterb, cron: ' 0 5 * * *   ',
        created_at: Time.zone.local(2024, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 1, 2, 1, 0),
        project: project)
    end

    let_it_be(:pipeline2) do
      create(:ci_pipeline_schedule, description: :aaa, ref: :masterz, cron: ' 0 6 * * *   ',
        created_at: Time.zone.local(2023, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 3, 2, 1, 0),
        project: project)
    end

    let_it_be(:pipeline3) do
      create(:ci_pipeline_schedule, description: :zzz, ref: :mastera, cron: ' 0 8 * * *   ',
        created_at: Time.zone.local(2022, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 4, 2, 1, 0),
        project: project)
    end

    let_it_be(:pipeline4) do
      create(:ci_pipeline_schedule, description: :zza, ref: :mastery, cron: ' 0 7 * * *   ',
        created_at: Time.zone.local(2021, 3, 2, 1, 0), updated_at: Time.zone.local(2024, 2, 2, 1, 0),
        project: project)
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
      it "sorts desc", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/466308' do
        expect(resolve_pipeline_schedules(args: { sort: :next_run_at_desc }).to_a).to eq([pipeline3, pipeline4,
          pipeline2, pipeline1])
      end

      it "sorts asc", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/466309' do
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

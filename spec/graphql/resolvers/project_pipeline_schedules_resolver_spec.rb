# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelineSchedulesResolver do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, public_builds: false) }

  before do
    project.add_owner(user)
  end

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

  def resolve_pipeline_schedules(args: {})
    resolve(described_class, obj: project, ctx: { current_user: user }, args: args)
  end
end

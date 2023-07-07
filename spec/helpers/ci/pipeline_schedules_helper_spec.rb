# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineSchedulesHelper, feature_category: :continuous_integration do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:pipeline_schedule) { build_stubbed(:ci_pipeline_schedule, project: project, owner: user) }
  let_it_be(:timezones) { [{ identifier: "Pacific/Honolulu", name: "Hawaii" }] }

  let_it_be(:pipeline_schedule_variable) do
    build_stubbed(:ci_pipeline_schedule_variable, key: 'foo', value: 'foovalue', pipeline_schedule: pipeline_schedule)
  end

  describe '#js_pipeline_schedules_form_data' do
    before do
      allow(helper).to receive(:timezone_data).and_return(timezones)
    end

    it 'returns pipeline schedule form data' do
      expect(helper.js_pipeline_schedules_form_data(project, pipeline_schedule)).to include({
        full_path: project.full_path,
        daily_limit: nil,
        project_id: project.id,
        schedules_path: pipeline_schedules_path(project),
        settings_link: project_settings_ci_cd_path(project),
        timezone_data: timezones.to_json
      })
    end
  end
end

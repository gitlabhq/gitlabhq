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
      allow(helper).to receive_messages(timezone_data: timezones, current_user: user, can_view_pipeline_editor?: true)
    end

    it 'returns pipeline schedule form data' do
      expect(helper.js_pipeline_schedules_form_data(project, pipeline_schedule)).to include({
        can_view_pipeline_editor: 'true',
        daily_limit: nil,
        pipeline_editor_path: project_ci_pipeline_editor_path(project),
        project_id: project.id,
        project_path: project.full_path,
        schedules_path: pipeline_schedules_path(project),
        settings_link: project_settings_ci_cd_path(project),
        timezone_data: timezones.to_json,
        can_set_pipeline_variables: 'false'
      })
    end
  end
end

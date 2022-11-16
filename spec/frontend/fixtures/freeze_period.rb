# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Freeze Periods (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers
  include TimeZoneHelper

  let_it_be(:project) { create(:project, :repository, path: 'freeze-periods-project') }
  let_it_be(:user) { project.first_owner }

  after(:all) do
    remove_repository(project)
  end

  describe API::FreezePeriods, '(JavaScript fixtures)', type: :request do
    include ApiHelpers

    it 'api/freeze-periods/freeze_periods.json' do
      create(:ci_freeze_period, project: project, freeze_start: '5 4 * * *', freeze_end: '5 9 * 8 *', cron_timezone: 'America/New_York')
      create(:ci_freeze_period, project: project, freeze_start: '0 12 * * 1-5', freeze_end: '0 1 5 * *', cron_timezone: 'Etc/UTC')
      create(:ci_freeze_period, project: project, freeze_start: '0 12 * * 1-5', freeze_end: '0 16 * * 6', cron_timezone: 'Europe/Berlin')

      get api("/projects/#{project.id}/freeze_periods", user)

      expect(response).to be_successful
    end
  end
end

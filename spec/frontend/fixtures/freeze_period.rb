# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Freeze Periods (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers
  include TimeZoneHelper

  let_it_be(:project) { create(:project, :repository, path: 'freeze-periods-project') }
  let_it_be(:user) { project.owner }

  before(:all) do
    clean_frontend_fixtures('api/freeze-periods/')
  end

  after(:all) do
    remove_repository(project)
  end

  around do |example|
    freeze_time do
      # Mock time to sept 19 (intl. talk like a pirate day)
      Timecop.travel(2020, 9, 19)

      example.run
    end
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

  describe TimeZoneHelper, '(JavaScript fixtures)' do
    let(:response) { timezone_data.to_json }

    it 'api/freeze-periods/timezone_data.json' do
      # Looks empty but does things
      # More info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38525/diffs#note_391048415
    end
  end
end

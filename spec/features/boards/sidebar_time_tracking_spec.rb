# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar time tracking', :js do
  include BoardHelpers

  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:board)   { create(:board, project: project) }
  let_it_be(:list)    { create(:list, board: board, position: 0) }
  let!(:issue)        { create(:issue, project: project, relative_position: 1) }
  let(:card)          { find('.board:nth-child(1)').first('.board-card') }

  let(:application_settings) { {} }

  before do
    stub_feature_flags(graphql_board_lists: false)

    project.add_maintainer(user)

    sign_in(user)

    stub_application_setting(application_settings)

    visit project_board_path(project, board)
    wait_for_requests
  end

  context 'time tracking' do
    let(:compare_meter_tooltip) { find('.time-tracking .time-tracking-content .compare-meter')['title'] }

    before do
      issue.timelogs.create!(time_spent: 14400, user: user)
      issue.update!(time_estimate: 128800)

      click_card(card)
    end

    it 'shows time tracking progress bar' do
      expect(compare_meter_tooltip).to eq('Time remaining: 3d 7h 46m')
    end

    context 'when time_tracking_limit_to_hours is true' do
      let(:application_settings) { { time_tracking_limit_to_hours: true } }

      it 'shows time tracking progress bar' do
        expect(compare_meter_tooltip).to eq('Time remaining: 31h 46m')
      end
    end
  end
end

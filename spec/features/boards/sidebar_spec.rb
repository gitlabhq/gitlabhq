# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards', :js do
  include BoardHelpers

  let(:user)         { create(:user) }
  let(:project)      { create(:project, :public) }
  let!(:milestone)   { create(:milestone, project: project) }
  let!(:development) { create(:label, project: project, name: 'Development') }
  let!(:regression)  { create(:label, project: project, name: 'Regression') }
  let!(:stretch)     { create(:label, project: project, name: 'Stretch') }
  let!(:issue1)      { create(:labeled_issue, project: project, milestone: milestone, labels: [development], relative_position: 2) }
  let!(:issue2)      { create(:labeled_issue, project: project, labels: [development, stretch], relative_position: 1) }
  let(:board)        { create(:board, project: project) }
  let!(:list)        { create(:list, board: board, label: development, position: 0) }
  let(:card)         { find('.board:nth-child(2)').first('.board-card') }

  let(:application_settings) { {} }

  around do |example|
    freeze_time { example.run }
  end

  before do
    project.add_maintainer(user)

    sign_in(user)

    stub_application_setting(application_settings)

    visit project_board_path(project, board)
    wait_for_requests
  end

  it 'shows sidebar when clicking issue' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking issue' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')

    click_card(card)

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking close button' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')

    find('.gutter-toggle').click

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'shows issue details when sidebar is open' do
    click_card(card)

    page.within('.issue-boards-sidebar') do
      expect(page).to have_content(issue2.title)
      expect(page).to have_content(issue2.to_reference)
    end
  end

  context 'milestone' do
    it 'adds a milestone' do
      click_card(card)

      page.within('.milestone') do
        click_link 'Edit'

        wait_for_requests

        click_link milestone.title

        wait_for_requests

        page.within('.value') do
          expect(page).to have_content(milestone.title)
        end
      end
    end

    it 'removes a milestone' do
      click_card(card)

      page.within('.milestone') do
        click_link 'Edit'

        wait_for_requests

        click_link "No milestone"

        wait_for_requests

        page.within('.value') do
          expect(page).not_to have_content(milestone.title)
        end
      end
    end
  end

  context 'time tracking' do
    let(:compare_meter_tooltip) { find('.time-tracking .time-tracking-content .compare-meter')['title'] }

    before do
      issue2.timelogs.create(time_spent: 14400, user: user)
      issue2.update!(time_estimate: 128800)

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

  context 'due date' do
    it 'updates due date' do
      click_card(card)

      page.within('.due_date') do
        click_link 'Edit'

        click_button Date.today.day.to_s

        wait_for_requests

        expect(page).to have_content(Date.today.to_s(:medium))
      end
    end
  end

  context 'subscription' do
    it 'changes issue subscription' do
      click_card(card)
      wait_for_requests

      page.within('.subscriptions') do
        find('[data-testid="subscription-toggle"] button:not(.is-checked)').click
        wait_for_requests

        expect(page).to have_css('[data-testid="subscription-toggle"] button.is-checked')
      end
    end

    it 'has checked subscription toggle when already subscribed' do
      create(:subscription, user: user, project: project, subscribable: issue2, subscribed: true)
      visit project_board_path(project, board)
      wait_for_requests

      click_card(card)
      wait_for_requests

      page.within('.subscriptions') do
        find('[data-testid="subscription-toggle"] button.is-checked').click
        wait_for_requests

        expect(page).to have_css('[data-testid="subscription-toggle"] button:not(.is-checked)')
      end
    end
  end
end

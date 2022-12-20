# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Abuse reports', feature_category: :insider_threat do
  let_it_be(:another_user) { create(:user) }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project, author: another_user) }

  before do
    sign_in(create(:user))
  end

  it 'report abuse from an issue', :js do
    visit project_issue_path(project, issue)

    click_button 'Issue actions'
    click_link 'Report abuse to administrator'

    wait_for_requests

    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'

    expect(page).to have_content 'Thank you for your report'

    visit user_path(another_user)

    expect(page).to have_button('Already reported for abuse')
  end

  it 'report abuse from profile', :js do
    visit user_path(another_user)

    click_button 'Report abuse to administrator'

    choose "They're posting spam."
    click_button 'Next'

    wait_for_requests

    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'

    expect(page).to have_content 'Thank you for your report'

    visit user_path(another_user)

    expect(page).to have_button('Already reported for abuse')
  end
end

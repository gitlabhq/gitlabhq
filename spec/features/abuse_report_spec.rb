# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Abuse reports', :js, feature_category: :insider_threat do
  let_it_be(:abusive_user) { create(:user) }

  let_it_be(:reporter1) { create(:user) }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project, author: abusive_user) }

  before do
    sign_in(reporter1)
  end

  context 'when reporting an issue for abuse' do
    it 'allows a user to be reported for abuse from an issue', :js do
      visit project_issue_path(project, issue)

      click_button 'Issue actions'
      click_link 'Report abuse to administrator'

      wait_for_requests

      fill_and_submit_form

      expect(page).to have_content 'Thank you for your report'
    end

    it 'redirects backs to the issue when cancel button is clicked' do
      visit project_issue_path(project, issue)

      click_button 'Issue actions'
      click_link 'Report abuse to administrator'

      wait_for_requests

      click_link 'Cancel'

      expect(page).to have_current_path(project_issue_path(project, issue))
    end
  end

  context 'when reporting a user profile for abuse' do
    let_it_be(:reporter2) { create(:user) }

    it 'allows a user to be reported for abuse from their profile' do
      visit user_path(abusive_user)

      click_button 'Report abuse to administrator'

      choose "They're posting spam."
      click_button 'Next'

      wait_for_requests

      fill_and_submit_form

      expect(page).to have_content 'Thank you for your report'

      visit user_path(abusive_user)

      click_button 'Report abuse to administrator'

      choose "They're posting spam."
      click_button 'Next'

      fill_and_submit_form

      expect(page).to have_content 'You have already reported this user'
    end

    it 'allows multiple users to report a user' do
      visit user_path(abusive_user)

      click_button 'Report abuse to administrator'

      choose "They're posting spam."
      click_button 'Next'

      wait_for_requests

      fill_and_submit_form

      expect(page).to have_content 'Thank you for your report'

      gitlab_sign_out
      gitlab_sign_in(reporter2)

      visit user_path(abusive_user)

      click_button 'Report abuse to administrator'

      choose "They're posting spam."
      click_button 'Next'

      wait_for_requests

      fill_and_submit_form

      expect(page).to have_content 'Thank you for your report'
    end

    it 'redirects backs to user profile when cancel button is clicked' do
      visit user_path(abusive_user)

      click_button 'Report abuse to administrator'

      choose "They're posting spam."
      click_button 'Next'

      wait_for_requests

      click_link 'Cancel'

      expect(page).to have_current_path(user_path(abusive_user))
    end
  end

  private

  def fill_and_submit_form
    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'
  end
end

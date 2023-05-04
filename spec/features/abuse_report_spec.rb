# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Abuse reports', :js, feature_category: :insider_threat do
  let_it_be(:abusive_user) { create(:user) }

  let_it_be(:reporter1) { create(:user) }

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:issue) { create(:issue, project: project, author: abusive_user) }

  before do
    sign_in(reporter1)
    stub_feature_flags(moved_mr_sidebar: false)
  end

  describe 'report abuse to administrator' do
    context 'when reporting an issue for abuse' do
      before do
        visit project_issue_path(project, issue)

        click_button 'Issue actions'
      end

      it_behaves_like 'reports the user with an abuse category'

      it 'redirects backs to the issue when cancel button is clicked' do
        fill_and_submit_abuse_category_form

        click_link 'Cancel'

        expect(page).to have_current_path(project_issue_path(project, issue))
      end
    end

    context 'when reporting an incident for abuse' do
      let_it_be(:incident) { create(:incident, project: project, author: abusive_user) }

      before do
        visit incident_project_issues_path(project, incident)
        click_button 'Incident actions'
      end

      it_behaves_like 'reports the user with an abuse category'
    end

    context 'when reporting a user profile for abuse' do
      let_it_be(:reporter2) { create(:user) }

      before do
        visit user_path(abusive_user)
      end

      it_behaves_like 'reports the user with an abuse category'

      it 'allows the reporter to report the same user for different abuse categories' do
        visit user_path(abusive_user)

        fill_and_submit_abuse_category_form
        fill_and_submit_report_abuse_form

        expect(page).to have_content 'Thank you for your report'

        visit user_path(abusive_user)

        fill_and_submit_abuse_category_form("They're being offensive or abusive.")
        fill_and_submit_report_abuse_form

        expect(page).to have_content 'Thank you for your report'
      end

      it 'allows multiple users to report the same user' do
        fill_and_submit_abuse_category_form
        fill_and_submit_report_abuse_form

        expect(page).to have_content 'Thank you for your report'

        gitlab_sign_out
        gitlab_sign_in(reporter2)

        visit user_path(abusive_user)

        fill_and_submit_abuse_category_form
        fill_and_submit_report_abuse_form

        expect(page).to have_content 'Thank you for your report'
      end

      it 'redirects backs to user profile when cancel button is clicked' do
        fill_and_submit_abuse_category_form

        click_link 'Cancel'

        expect(page).to have_current_path(user_path(abusive_user))
      end
    end

    context 'when reporting an merge request for abuse' do
      let_it_be(:merge_request) { create(:merge_request, source_project: project, author: abusive_user) }

      before do
        visit project_merge_request_path(project, merge_request)
        find('[data-testid="merge-request-actions"]').click
      end

      it_behaves_like 'reports the user with an abuse category'
    end

    context 'when reporting a comment' do
      let_it_be(:issue) { create(:issue, project: project, author: abusive_user) }
      let_it_be(:comment) do
        create(:discussion_note_on_issue, author: abusive_user, project: project, noteable: issue, note: 'some note')
      end

      before do
        visit project_issue_path(project, issue)
        click_button 'More actions'
      end

      it_behaves_like 'reports the user with an abuse category'
    end
  end

  private

  def fill_and_submit_abuse_category_form(category = "They're posting spam.")
    click_button 'Report abuse'

    choose category
    click_button 'Next'
  end

  def fill_and_submit_report_abuse_form
    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'
  end
end

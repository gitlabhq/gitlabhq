# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Abuse reports', feature_category: :insider_threat do
  let_it_be(:abusive_user) { create(:user, username: 'abuser_mcabusive') }
  let_it_be(:reporter1) { create(:user, username: 'reporter_mcreporty') }
  let_it_be(:reporter2) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project, author: abusive_user) }

  let!(:group) do
    create(:group).tap do |g|
      g.add_owner(reporter1)
      g.add_developer(abusive_user)
    end
  end

  before do
    sign_in(reporter1)
  end

  it 'allows a user to be reported for abuse from an issue', :js do
    visit project_issue_path(project, issue)

    click_button 'Issue actions'
    click_link 'Report abuse to administrator'

    wait_for_requests

    fill_and_submit_form

    expect(page).to have_content 'Thank you for your report'
  end

  it 'allows a user to be reported for abuse from their profile', :js do
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

  it 'allows multiple users to report a user', :js do
    visit user_path(abusive_user)

    click_button 'Report abuse to administrator'

    choose "They're posting spam."
    click_button 'Next'

    wait_for_requests

    fill_and_submit_form

    expect(page).to have_content 'Thank you for your report'

    sign_out(reporter1)
    sign_in(reporter2)

    visit user_path(abusive_user)

    click_button 'Report abuse to administrator'

    choose "They're posting spam."
    click_button 'Next'

    wait_for_requests

    fill_and_submit_form

    expect(page).to have_content 'Thank you for your report'
  end

  describe 'Cancel', :js do
    context 'when ref_url is not present (e.g. visit user page then click on report abuse)' do
      it 'links the user back to where abuse report was triggered' do
        origin_url = user_path(abusive_user)

        visit origin_url

        click_button 'Report abuse to administrator'
        choose "They're posting spam."
        click_button 'Next'

        wait_for_requests

        click_link 'Cancel'

        expect(page).to have_current_path(origin_url)
      end
    end

    context 'when ref_url is present (e.g. user is reported from one of their MRs)' do
      it 'links the user back to ref_url' do
        ref_url = group_group_members_path(group)

        visit ref_url

        # visit abusive user's profile page
        page.first('.js-user-link').click

        click_button 'Report abuse to administrator'
        choose "They're posting spam."
        click_button 'Next'

        click_link 'Cancel'

        expect(page).to have_current_path(ref_url)
      end
    end
  end

  private

  def fill_and_submit_form
    fill_in 'abuse_report_message', with: 'This user sends spam'
    click_button 'Send report'
  end
end

require 'spec_helper'

feature 'Abuse reports', feature: true do
  let(:another_user) { create(:user) }

  before do
    login_as :user
  end

  scenario 'Report abuse' do
    visit user_path(another_user)

    click_link 'Report abuse'

    fill_in 'abuse_report_message', with: 'This user send spam'
    click_button 'Send report'

    expect(page).to have_content 'Thank you for your report'

    visit user_path(another_user)

    expect(page).to have_button("Already reported for abuse")
  end
end

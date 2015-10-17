class Spinach::Features::AbuseReports < Spinach::FeatureSteps
  include SharedAuthentication

  step 'I visit "Mike" user page' do
    visit user_path(user_mike)
  end

  step 'I click "Report abuse" button' do
    click_link 'Report abuse'
  end

  step 'I fill and submit abuse form' do
    fill_in 'abuse_report_message', with: 'This user send spam'
    click_button 'Send report'
  end

  step 'I should see success message' do
    page.should have_content 'Thank you for your report'
  end

  step 'user "Mike" exists' do
    user_mike
  end

  step 'I should see a red "Report abuse" button' do
    expect(find(:css, '.report_abuse')).to have_selector(:css, 'span.btn-close')
  end

  def user_mike
    @user_mike ||= create(:user, name: 'Mike')
  end
end

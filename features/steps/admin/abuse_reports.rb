class Spinach::Features::AdminAbuseReports < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I should see list of abuse reports' do
    page.should have_content("Abuse Reports")
    page.should have_content AbuseReport.first.message
    page.should have_link("Remove user")
  end

  step 'abuse reports exist' do
    create(:abuse_report)
  end
end

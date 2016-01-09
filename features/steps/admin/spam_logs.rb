class Spinach::Features::AdminSpamLogs < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I should see list of spam logs' do
    page.should have_content("Spam Logs")
    spam_log = SpamLog.first
    page.should have_content spam_log.title
    page.should have_content spam_log.description
    page.should have_link("Remove user")
    page.should have_link("Block user")
  end

  step 'spam logs exist' do
    create(:spam_log)
  end
end

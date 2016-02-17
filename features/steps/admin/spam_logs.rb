class Spinach::Features::AdminSpamLogs < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  step 'I should see list of spam logs' do
    expect(page).to have_content('Spam Logs')
    expect(page).to have_content spam_log.source_ip
    expect(page).to have_content spam_log.noteable_type
    expect(page).to have_content 'N'
    expect(page).to have_content spam_log.title
    expect(page).to have_content truncate(spam_log.description)
    expect(page).to have_link('Remove user')
    expect(page).to have_link('Block user')
  end

  step 'spam logs exist' do
    create(:spam_log)
  end

  def spam_log
    @spam_log ||= SpamLog.first
  end

  def truncate(description)
    "#{spam_log.description[0...97]}..."
  end
end

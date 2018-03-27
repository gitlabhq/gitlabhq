require 'spec_helper'

feature 'RavenJS' do
  let(:raven_path) { '/raven.bundle.js' }

  it 'should not load raven if sentry is disabled' do
    visit new_user_session_path

    expect(has_requested_raven).to eq(false)
  end

  it 'should load raven if sentry is enabled' do
    stub_application_setting(clientside_sentry_dsn: 'https://key@domain.com/id', clientside_sentry_enabled: true)

    visit new_user_session_path

    expect(has_requested_raven).to eq(true)
  end

  def has_requested_raven
    page.all('script', visible: false).one? do |elm|
      elm[:src] =~ /#{raven_path}$/
    end
  end
end

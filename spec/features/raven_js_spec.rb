require 'spec_helper'

describe 'RavenJS' do
  let(:raven_path) { '/raven.chunk.js' }

  it 'does not load raven if sentry is disabled' do
    visit new_user_session_path

    expect(has_requested_raven).to eq(false)
  end

  it 'loads raven if sentry is enabled' do
    stub_sentry_settings

    visit new_user_session_path

    expect(has_requested_raven).to eq(true)
  end

  def has_requested_raven
    page.all('script', visible: false).one? do |elm|
      elm[:src] =~ /#{raven_path}$/
    end
  end
end

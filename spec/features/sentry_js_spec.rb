# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sentry', feature_category: :observability do
  it 'does not load sentry if sentry settings are disabled' do
    allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(false)

    visit new_user_session_path

    expect(has_requested_sentry).to eq(false)
  end

  it 'loads sentry if sentry settings are enabled', :js do
    allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(true)
    allow(Gitlab::CurrentSettings).to receive(:sentry_clientside_dsn).and_return('https://mockdsn@example.com/1')

    visit new_user_session_path

    expect(has_requested_sentry).to eq(true)
    expect(evaluate_script('window._Sentry.SDK_VERSION')).to match(%r{^8\.})
  end

  def has_requested_sentry
    page.all('script', visible: false).one? do |elm|
      elm[:src] =~ %r{/sentry.*\.chunk\.js\z}
    end
  end
end

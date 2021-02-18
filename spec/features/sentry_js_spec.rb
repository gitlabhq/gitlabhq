# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sentry' do
  let(:sentry_regex_path) { '\/sentry.*\.chunk\.js' }

  it 'does not load sentry if sentry is disabled' do
    allow(Gitlab.config.sentry).to receive(:enabled).and_return(false)
    visit new_user_session_path

    expect(has_requested_sentry).to eq(false)
  end

  it 'loads sentry if sentry is enabled' do
    stub_sentry_settings

    visit new_user_session_path

    expect(has_requested_sentry).to eq(true)
  end

  def has_requested_sentry
    page.all('script', visible: false).one? do |elm|
      elm[:src] =~ /#{sentry_regex_path}$/
    end
  end
end

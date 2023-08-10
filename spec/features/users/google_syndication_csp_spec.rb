# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Google Syndication content security policy', feature_category: :purchase do
  include ContentSecurityPolicyHelpers

  let_it_be(:connect_src) { 'https://other-cdn.test' }

  let_it_be(:google_analytics_src) do
    'localhost https://cdn.cookielaw.org https://*.onetrust.com *.google-analytics.com ' \
      '*.analytics.google.com *.googletagmanager.com'
  end

  let_it_be(:allowed_src) do
    '*.google.com/pagead/landing pagead2.googlesyndication.com/pagead/landing'
  end

  let(:extra) { { google_tag_manager_nonce_id: 'google_tag_manager_nonce_id' } }

  let(:csp) do
    ActionDispatch::ContentSecurityPolicy.new do |p|
      p.connect_src(*connect_src.split)
    end
  end

  subject { response_headers['Content-Security-Policy'] }

  before do
    setup_csp_for_controller(SessionsController, csp, any_time: true)
    stub_config(extra: extra)
    visit new_user_session_path
  end

  context 'when self-hosted' do
    context 'when there is no CSP config' do
      let(:extra) { {} }
      let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

      it { is_expected.to be_blank }
    end

    context 'when connect-src CSP config exists' do
      it { is_expected.to include("connect-src #{connect_src} #{google_analytics_src}") }
      it { is_expected.not_to include(allowed_src) }
    end
  end

  context 'when SaaS', :saas do
    context 'when connect-src CSP config exists' do
      it { is_expected.to include("connect-src #{connect_src} #{google_analytics_src} #{allowed_src}") }
    end
  end
end

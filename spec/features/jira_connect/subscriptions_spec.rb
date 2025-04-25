# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscriptions Content Security Policy', feature_category: :integrations do
  include ContentSecurityPolicyHelpers

  let(:installation) { create(:jira_connect_installation) }
  let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }
  let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

  subject(:csp) { parse_csp response_headers['Content-Security-Policy'] }

  context 'when there is no global config' do
    before do
      setup_csp_for_controller(JiraConnect::SubscriptionsController)
    end

    it 'does not add CSP directives' do
      visit jira_connect_subscriptions_path(jwt: jwt)

      is_expected.to be_blank
    end
  end

  context 'when a global CSP config exists' do
    before do
      csp = ActionDispatch::ContentSecurityPolicy.new do |p|
        p.script_src :self, 'https://some-cdn.test'
        p.style_src :self, 'https://some-cdn.test'
      end

      setup_csp_for_controller(JiraConnect::SubscriptionsController, csp)
    end

    it 'appends to CSP directives' do
      visit jira_connect_subscriptions_path(jwt: jwt)

      frame_ancestors = "'self' https://*.atlassian.net https://*.jira.com".split(' ')
      script_src = "'self' https://some-cdn.test https://connect-cdn.atl-paas.net".split(' ')
      style_src = "'self' https://some-cdn.test 'unsafe-inline'".split(' ')
      expect(csp['frame-ancestors']).to include(*frame_ancestors)
      expect(csp['script-src']).to include(*script_src)
      expect(csp['style-src']).to include(*style_src)
    end
  end

  def parse_csp(csp)
    csp.split(';').reject { |dir| dir.strip.empty? }.each_with_object({}) do |dir, hash|
      parts = dir.strip.split(/\s+/)
      hash[parts.first] = parts[1..]
    end
  end
end

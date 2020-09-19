# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscriptions Content Security Policy' do
  let(:installation) { create(:jira_connect_installation) }
  let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }
  let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

  subject { response_headers['Content-Security-Policy'] }

  context 'when there is no global config' do
    before do
      expect_next_instance_of(JiraConnect::SubscriptionsController) do |controller|
        expect(controller).to receive(:current_content_security_policy)
          .and_return(ActionDispatch::ContentSecurityPolicy.new)
      end
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

      expect_next_instance_of(JiraConnect::SubscriptionsController) do |controller|
        expect(controller).to receive(:current_content_security_policy).and_return(csp)
      end
    end

    it 'appends to CSP directives' do
      visit jira_connect_subscriptions_path(jwt: jwt)

      is_expected.to include("frame-ancestors 'self' https://*.atlassian.net")
      is_expected.to include("script-src 'self' https://some-cdn.test https://connect-cdn.atl-paas.net https://unpkg.com/jquery@3.3.1/")
      is_expected.to include("style-src 'self' https://some-cdn.test 'unsafe-inline' https://unpkg.com/@atlaskit/")
    end
  end
end

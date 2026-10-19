# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira Connect app subscriptions page', :js, :with_current_organization, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation, organization: current_organization) }

  let(:query_string_hash) do
    Atlassian::Jwt.create_query_string_hash(jira_connect_subscriptions_url, 'GET', jira_connect_base_url)
  end

  let(:jwt) do
    Atlassian::Jwt.encode({ iss: installation.client_key, qsh: query_string_hash }, installation.shared_secret)
  end

  # The app reads the `AP` global that Atlassian's all.js defines inside a Jira iframe.
  # Outside Jira the script defines nothing and the app throws before mounting.
  let(:ap_stub_identifier) do
    page.driver.browser.execute_cdp(
      'Page.addScriptToEvaluateOnNewDocument',
      source: 'window.AP = { sizeToParent() {}, context: { getToken(cb) { cb("jira-jwt"); } } };'
    )['identifier']
  end

  before do
    ap_stub_identifier

    visit jira_connect_subscriptions_path(jwt: jwt)
  end

  # The script outlives Capybara's session reset, so remove it before the next spec reuses the browser.
  after do
    page.driver.browser.execute_cdp('Page.removeScriptToEvaluateOnNewDocument', identifier: ap_stub_identifier)
  end

  context 'when no groups are linked' do
    it 'renders the sign-in page' do
      within('header') do
        expect(page).to have_link(href: Gitlab.config.gitlab.url)
        expect(page).to have_css('img[alt="GitLab"]')
      end

      within_testid('jira-connect-app') do
        expect(page).to have_css('h2', text: 'GitLab for Jira Configuration')
        expect(page).to have_text('Sign in to GitLab to get started.')
        expect(page).to have_button('Sign in to GitLab')
      end
    end
  end

  context 'when a group is linked' do
    let_it_be(:group) { create(:group, name: 'Linked group') }
    let_it_be(:subscription) { create(:jira_connect_subscription, installation: installation, namespace: group) }

    it 'renders the sign-in page with the linked groups' do
      within_testid('jira-connect-app') do
        expect(page).to have_css('h2', text: 'GitLab for Jira Configuration')
        expect(page).to have_button('Sign in to link groups')

        within('table') do
          expect(page).to have_text(group.full_name)
          expect(page).to have_button('Unlink')
        end
      end
    end
  end
end

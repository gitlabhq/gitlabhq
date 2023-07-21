# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::AppDescriptorController, feature_category: :integrations do
  describe '#show' do
    let(:descriptor) do
      json_response.deep_symbolize_keys
    end

    let(:logo_url) { %r{\Ahttp://test\.host/assets/gitlab_logo-\h+\.png\z} }

    let(:common_module_properties) do
      {
        homeUrl: 'https://gitlab.com',
        logoUrl: logo_url,
        documentationUrl: 'https://docs.gitlab.com/ee/integration/jira/'
      }
    end

    it 'returns JSON app descriptor' do
      get :show

      expect(response).to have_gitlab_http_status(:ok)

      expect(descriptor).to include(
        name: Atlassian::JiraConnect.app_name,
        description: kind_of(String),
        key: Atlassian::JiraConnect.app_key,
        baseUrl: 'https://test.host/-/jira_connect',
        lifecycle: {
          installed: '/events/installed',
          uninstalled: '/events/uninstalled'
        },
        vendor: {
          name: 'GitLab',
          url: 'https://gitlab.com'
        },
        links: {
          documentation: 'http://test.host/help/integration/jira_development_panel#gitlabcom-1'
        },
        authentication: {
          type: 'jwt'
        },
        scopes: %w(READ WRITE DELETE),
        apiVersion: 1,
        apiMigrations: {
          'context-qsh': true,
          gdpr: true,
          'signed-install': true
        }
      )

      expect(descriptor[:modules]).to include(
        postInstallPage: {
          key: 'gitlab-configuration',
          name: { value: 'GitLab Configuration' },
          url: '/subscriptions',
          conditions: contain_exactly(
            a_hash_including(condition: 'user_is_admin', invert: false)
          )
        },
        jiraDevelopmentTool: {
          actions: {
            createBranch: {
              templateUrl: 'http://test.host/-/jira_connect/branches/new?issue_key={issue.key}&issue_summary={issue.summary}'
            }
          },
          key: 'gitlab-development-tool',
          application: { value: 'GitLab' },
          name: { value: 'GitLab' },
          url: 'https://gitlab.com',
          logoUrl: logo_url,
          capabilities: %w(branch commit pull_request)
        },
        jiraBuildInfoProvider: common_module_properties.merge(
          actions: {},
          name: { value: 'GitLab CI' },
          key: 'gitlab-ci'
        ),
        jiraDeploymentInfoProvider: common_module_properties.merge(
          actions: {},
          name: { value: 'GitLab Deployments' },
          key: 'gitlab-deployments'
        ),
        jiraFeatureFlagInfoProvider: common_module_properties.merge(
          actions: {},
          name: { value: 'GitLab Feature Flags' },
          key: 'gitlab-feature-flags'
        )
      )
    end
  end
end

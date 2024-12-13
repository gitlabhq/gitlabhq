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

    describe 'GET #show' do
      context 'when gitlab host is gitlab.com' do
        before do
          allow(Atlassian::JiraConnect).to receive(:gitlab_host).and_return('gitlab.com')
        end

        it 'returns application/name values as "GitLab" without including hostname' do
          get :show

          expect(descriptor[:modules][:jiraDevelopmentTool]).to include(
            application: { value: 'GitLab' },
            name: { value: 'GitLab' }
          )
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
              documentation: 'http://test.host/help/integration/jira/development_panel.md'
            },
            authentication: {
              type: 'jwt'
            },
            scopes: %w[READ WRITE DELETE],
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
                  templateUrl: "http://test.host/-/jira_connect/branches/route?issue_key={issue.key}&issue_summary={issue.summary}&jwt={jwt}&addonkey=#{Atlassian::JiraConnect.app_key}"
                },
                searchConnectedWorkspaces: {
                  templateUrl: 'http://test.host/-/jira_connect/workspaces/search'
                },
                searchRepositories: {
                  templateUrl: 'http://test.host/-/jira_connect/repositories/search'
                },
                associateRepository: {
                  templateUrl: 'http://test.host/-/jira_connect/repositories/associate'
                }
              },
              key: 'gitlab-development-tool',
              application: { value: 'GitLab' },
              name: { value: 'GitLab' },
              url: 'https://gitlab.com',
              logoUrl: logo_url,
              capabilities: %w[branch commit pull_request]
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

      context 'when gitlab host is not gitlab.com' do
        before do
          allow(Atlassian::JiraConnect).to receive(:gitlab_host).and_return('gitlab.example.com')
        end

        it 'returns application/name values as "GitLab (hostname)"' do
          get :show

          expect(descriptor[:modules][:jiraDevelopmentTool]).to include(
            application: { value: 'GitLab (gitlab.example.com)' },
            name: { value: 'GitLab (gitlab.example.com)' }
          )
        end
      end
    end
  end
end

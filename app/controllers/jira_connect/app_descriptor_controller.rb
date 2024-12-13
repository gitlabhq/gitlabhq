# frozen_string_literal: true

# This returns an app descriptor for use with Jira in development mode
# For the Atlassian Marketplace, a static copy of this JSON is uploaded to the marketplace
# https://developer.atlassian.com/cloud/jira/platform/app-descriptor/

class JiraConnect::AppDescriptorController < JiraConnect::ApplicationController
  HOME_URL = 'https://gitlab.com'
  DOC_URL = 'https://docs.gitlab.com/ee/integration/jira/'

  skip_before_action :verify_atlassian_jwt!

  def show
    render json: {
      name: Atlassian::JiraConnect.app_name,
      description: 'Integrate commits, branches and merge requests from GitLab into Jira',
      key: Atlassian::JiraConnect.app_key,
      baseUrl: jira_connect_base_url(protocol: 'https'),
      lifecycle: {
        installed: relative_to_base_path(jira_connect_events_installed_path),
        uninstalled: relative_to_base_path(jira_connect_events_uninstalled_path)
      },
      vendor: {
        name: 'GitLab',
        url: 'https://gitlab.com'
      },
      links: {
        documentation: help_page_url('integration/jira/development_panel.md')
      },
      authentication: {
        type: 'jwt'
      },
      modules: modules,
      scopes: %w[READ WRITE DELETE],
      apiVersion: 1,
      apiMigrations: {
        'context-qsh': true,
        'signed-install': true,
        gdpr: true
      }
    }
  end

  private

  def modules
    modules = {
      postInstallPage: {
        key: 'gitlab-configuration',
        name: { value: 'GitLab Configuration' },
        url: relative_to_base_path(jira_connect_subscriptions_path),
        conditions: [
          {
            condition: 'user_is_admin',
            invert: false
          }
        ]
      }
    }

    modules.merge!(development_tool_module)
    modules.merge!(build_information_module)
    modules.merge!(deployment_information_module)
    modules.merge!(feature_flag_module)

    modules
  end

  def logo_url
    view_context.image_url('gitlab_logo.png')
  end

  # See https://developer.atlassian.com/cloud/jira/software/modules/development-tool/
  def development_tool_module
    {
      jiraDevelopmentTool: {
        actions: actions,
        key: 'gitlab-development-tool',
        application: { value: Atlassian::JiraConnect.display_name },
        name: { value: Atlassian::JiraConnect.display_name },
        url: HOME_URL,
        logoUrl: logo_url,
        capabilities: %w[branch commit pull_request]
      }
    }
  end

  # See: https://developer.atlassian.com/cloud/jira/software/modules/deployment/
  def deployment_information_module
    {
      jiraDeploymentInfoProvider: common_module_properties.merge(
        actions: {}, # TODO: list deployments
        name: { value: "GitLab Deployments" },
        key: "gitlab-deployments"
      )
    }
  end

  # see: https://developer.atlassian.com/cloud/jira/software/modules/feature-flag/
  def feature_flag_module
    {
      jiraFeatureFlagInfoProvider: common_module_properties.merge(
        actions: {}, # TODO: create, link and list feature flags https://gitlab.com/gitlab-org/gitlab/-/issues/297386
        name: { value: 'GitLab Feature Flags' },
        key: 'gitlab-feature-flags'
      )
    }
  end

  # See: https://developer.atlassian.com/cloud/jira/software/modules/build/
  def build_information_module
    {
      jiraBuildInfoProvider: common_module_properties.merge(
        actions: {},
        name: { value: "GitLab CI" },
        key: "gitlab-ci"
      )
    }
  end

  def common_module_properties
    {
      homeUrl: HOME_URL,
      logoUrl: logo_url,
      documentationUrl: DOC_URL
    }
  end

  def relative_to_base_path(full_path)
    full_path.sub(/^#{jira_connect_base_path}/, '')
  end

  def create_branch_params
    "?issue_key={issue.key}&issue_summary={issue.summary}&jwt={jwt}&addonkey=#{Atlassian::JiraConnect.app_key}"
  end

  def actions
    {
      createBranch: {
        templateUrl: "#{route_jira_connect_branches_url}#{create_branch_params}"
      },
      searchConnectedWorkspaces: {
        templateUrl: search_jira_connect_workspaces_url
      },
      searchRepositories: {
        templateUrl: search_jira_connect_repositories_url
      },
      associateRepository: {
        templateUrl: associate_jira_connect_repositories_url
      }
    }
  end
end

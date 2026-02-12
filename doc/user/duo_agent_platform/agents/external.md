---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- Not available on GitLab Duo with self-hosted models

{{< /collapsible >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.
- Renamed from CLI agents in GitLab 18.6.
- Enabling in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578318) in GitLab 18.7 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_agents`. Enabled on GitLab.com.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

GitLab Duo agents work in parallel to help you create code, research results,
and perform tasks simultaneously.

You can create an agent and integrate it with an external
AI model provider to customize it to your organization's needs.
Then, in a project issue, epic, or merge request, you can mention that external agent
in a comment or discussion and ask the agent to complete a task.

The external agent:

- Reads and analyzes the surrounding context and repository code.
- Decides the appropriate action to take, while adhering to project permissions
  and keeping an audit trail.
- Runs a CI/CD pipeline and responds inside GitLab with either a ready-to-merge
  change or an inline comment.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../_index.md#prerequisites).
- Allow [flow execution](../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off).

## Security considerations

External agents integrate with third-party AI model providers and have different security characteristics than GitLab built-in agents and flows. By using external agents, you accept the following risks:

- **Prompt injection vulnerabilities**: GitLab implements third-party prompt scanning
  to lower the risk of prompt injections. This scanning is not available for external agents.
- **Third-party provider dependency**: The external AI model provider manages all
  security controls (including prompt scanning, monitoring, and alerting), not GitLab.
- **Network access**: External agents make network calls to third-party AI providers.
  Data sent to these providers is subject to their security policies and data handling practices.
- **Limited isolation**: External agents do not have the same level of network isolation
  and security restrictions that are applied to GitLab native agents and flows.

Before enabling external agents in your organization, review your security requirements
and the security documentation provided by your chosen AI model provider.

For a broader overview of security threats and mitigations in the Duo Agent Platform, see the [Duo Agent Platform security threats documentation](../security_threats.md).

## Quickstart for GitLab-managed external agents

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.8 on GitLab.com.

{{< /history >}}

The following integrations have been tested by GitLab and are available:

- [Claude Code](https://code.claude.com/docs/en/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Amazon Q](https://aws.amazon.com/q/)
- [Gemini](https://gemini.google.com/)

Managed external agents use GitLab-managed credentials and can be enabled in groups
without additional agent configuration necessary.

Required steps to enable and use managed agents:

1. Access the agent in the AI Catalog. Search for the agent name, or use the direct URL.
1. [Enable the agent in a top-level group](#enable-the-agent-in-a-top-level-group).
1. [Enable the agent in a project](#enable-in-a-project).
1. [Use the external agent](#use-an-external-agent) in issues, epics or merge requests.

### GitLab-managed external agents

The following agents are provided by GitLab and use GitLab-managed credentials:

- [Claude Agent on GitLab.com](https://gitlab.com/explore/ai-catalog/agents/2337/)
- [Codex Agent on GitLab.com](https://gitlab.com/explore/ai-catalog/agents/2334/)

#### Add GitLab-managed agents to other instances

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221986) as an experiment in GitLab 18.8.

{{< /history >}}

Administrators can add the Claude Agent and Codex Agent to their GitLab instances by using the [REST API](../../../api/admin/ai_catalog.md#seed-gitlab-managed-external-agents).

Prerequisites:

- You must be an administrator.

To seed your instance:

1. Create a [personal access token](../../../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the `api` scope.
   - On GitLab Self-Managed, select the `admin_mode` scope if [Admin Mode](../../../administration/settings/sign_in_restrictions.md#admin-mode) is enabled.
1. Call the [REST API endpoint](../../../api/admin/ai_catalog.md#seed-gitlab-managed-external-agents) and authenticate with the personal access token. If successful, the external agents become visible in the AI Catalog.
1. [Revoke the personal access token](../../../user/profile/personal_access_tokens.md#revoke-a-personal-access-token) for security.

### Amazon Q Developer Agent

The [Amazon Q Developer Agent](https://gitlab.com/explore/ai-catalog/agents/2332/) does not use
GitLab-managed credentials. To use this agent, you must provide your own credentials.
This agent is available only on GitLab.com.

To use the Amazon Q Developer Agent:

- Add the following environment variables to the CI/CD settings of your project:

  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION_NAME`
  - `AMAZON_Q_SIGV4`

### Develop with Gemini Agent

The [Develop with Gemini Agent](https://gitlab.com/explore/ai-catalog/agents/2331/) does not use the GitLab-managed credentials.
To use this agent, you must provide your own credentials.
This agent is available only on GitLab.com.

To use the Develop with Gemini Agent:

- Add the following environment variables to the CI/CD settings of your project:

  - `GOOGLE_CREDENTIALS` - Add the location of the Google credentials JSON file. For details, see [`GOOGLE_APPLICATION_CREDENTIALS` environment variable](https://docs.cloud.google.com/docs/authentication/application-default-credentials#GAC).
  - `GOOGLE_CLOUD_PROJECT`
  - `GOOGLE_CLOUD_LOCATION`

### Access credentials

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567791) in GitLab 18.4.

{{< /history >}}

External agents use GitLab-managed credentials through an AI Gateway.

When you use GitLab-managed credentials:

- Set `injectGatewayToken: true` in your external agent configuration.
- Configure the external agent to use the GitLab AI Gateway proxy endpoints.

The following environment variables are automatically injected when `injectGatewayToken` is `true`:

- `AI_FLOW_AI_GATEWAY_TOKEN`: the authentication token for AI Gateway
- `AI_FLOW_AI_GATEWAY_HEADERS`: formatted headers for API requests

GitLab-managed credentials are available for only Anthropic Claude and OpenAI Codex.

### Supported models

The following AI models are supported:

Anthropic Claude:

- `claude-3-haiku-20240307`
- `claude-haiku-4-5-20251001`
- `claude-sonnet-4-20250514`
- `claude-sonnet-4-5-20250929`

OpenAI Codex:

- `gpt-5`
- `gpt-5-codex`

## Configure CI/CD variables

Start by adding variables to your project. These variables determine
how GitLab connects to the third-party provider.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

To add or update a variable in the project settings:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **CI/CD**.
1. Expand **Variables**.
1. Select **Add variable** and complete the fields:
   - **Type**: Select **Variable (default)**.
   - **Environments**: Select **All (default)**.
   - **Visibility**: Select the desired visibility.

     For personal access token variables, select **Masked** or
     **Masked and hidden**.
   - Clear the **Protect variable** checkbox.
   - Clear the **Expand variable reference** checkbox.
   - **Description (optional)**: Enter a variable description.
   - **Key**: Enter the environment variable name of the CI/CD variable
     (for example, `GITLAB_HOST`).
   - **Value**: The value of the personal access token or host.
1. Select **Add variable**.

For more information, see how to [add CI/CD variables to a project's settings](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui).

### CI/CD variables for external agents

The following CI/CD variables are available:

| Environment variable         | Description |
|------------------------------|-------------|
| `GITLAB_TOKEN_<integration>` | Personal access token for the service account user. |
| `GITLAB_HOST`                | GitLab instance hostname (for example, `gitlab.com`). |

## Create an external agent

Now create an external agent and configure it to run in your environment.

The preferred workflow is:

1. Create the agent in the AI Catalog.
1. Enable the agent for the top-level group.
1. Add the agent to your project and specify a trigger that determines how you call the agent.

In this case, a service account is created for you.
When the agent runs, it uses a combination of the user's memberships and the service account memberships.
This combination is called a [composite identity](../composite_identity.md).

If you'd prefer, you can [create an external agent manually](#create-an-external-agent-manually).

### Create the agent in the AI Catalog

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610) in GitLab 18.6 with a flag named `ai_catalog_third_party_flows`. Enabled on GitLab.com.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218840) in GitLab 18.8.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217634) in GitLab 18.8 to require an additional [flag](../../../administration/feature_flags/_index.md) named `ai_catalog_create_third_party_flows`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Start by creating the external agent in the AI Catalog.

Prerequisites:

- You must have the Maintainer or Owner role for the project.

To create an external agent:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
1. Select **New agent**.
1. Under **Basic information**:
   1. In **Display name**, enter a name.
   1. In **Description**, enter a description.
1. Under **Visibility & access**, for **Visibility**, select **Private** or **Public**.
1. Under **Configuration**:
   1. Select **External**.
   1. Enter your external agent configuration.
      You can write your own YAML, or edit an example configuration.
1. Select **Create agent**.

The external agent appears in the AI Catalog.

### Enable the agent in a top-level group

Now enable the agent in a top-level group.

Prerequisites:

- You must have the Owner role for the group.

To enable an external agent in a top-level group:

1. On the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**, then select the **Agents** tab.
1. Select the external agent you want to enable.
1. In the upper-right corner, select **Enable in group**.
1. From the dropdown list, select the group you want to enable the external agent in.
1. Select **Enable**.

The external agent appears in the group's **Automate** > **Agents** page.

A service account is created in the group. The name of the account
follows this naming convention: `ai-<agent>-<group>`.

### Enable in a project

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- The agent must be enabled in the project's top-level group.

To enable an external agent in a project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Agents**.
1. In the upper-right corner, select **Enable agent from group**.
1. From the dropdown list, select the external agent you want to enable.
1. For **Add triggers**, select which event types trigger the external agent:
   - **Mention**: When the service account user is mentioned
     in a comment on an issue or merge request.
   - **Assign**: When the service account user is assigned
     to an issue or merge request.
   - **Assign reviewer**: When the service account user is assigned
     as a reviewer to a merge request.
1. Select **Enable**.

The external agent appears in the project's **Automate** > **Agents** list.

The top-level group's service account is added to the project.
This account is assigned the Developer role.

## Use an external agent

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.
- If you created an external agent from the AI Catalog, the agent must be enabled in your project.
- To allow the agent to push to workload branches (`workloads/*`), you might have to create [branch rules](../../project/repository/branches/branch_rules.md).

1. In your project, open an issue, merge request, or epic.
1. Mention, assign, or request a review from the service account user.
   For example:

   ```plaintext
   @service-account-username Can you help analyze this code change?
   ```

1. After the external agent has completed the task, you see a confirmation, and either a
   ready-to-merge change or an inline comment.

## Create an external agent manually

{{< history >}}

- Changed in GitLab 18.8 to require an additional [flag](../../../administration/feature_flags/_index.md) named `ai_catalog_create_third_party_flows`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

If you prefer to not follow the UI flow, you can create an external agent manually:

1. Create a configuration file in your project.
1. Create a service account.
1. Create a trigger that determines how you call the agent.
1. Use the agent.

In this case, you manually create the service account that is used to run the agent.

### Create a configuration file

If you create external agents by manually adding configuration files,
you must create a different configuration file for each external agent.

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To create a configuration file:

1. In your project, create a YAML file, for example: `.gitlab/duo/flows/claude.yaml`
1. Populate the file by using [one of the configuration file examples](external_examples.md).

### Create a service account

You must create [a service account](../../../user/profile/service_accounts.md) that has access to
the projects where you expect to use an external agent.

When the agent runs, it uses a combination of the user's memberships and the service account memberships.
This combination is called a [composite identity](../composite_identity.md).

Prerequisites:

- On GitLab.com, you must have the Owner role for the top-level group the project belongs to.
- On GitLab Self-Managed and GitLab Dedicated, you must have one of the following:
  - Administrator access to the instance.
  - The Owner role for a top-level group and
    [permission to create service accounts](../../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

To create and assign the service account:

### Create a trigger

You must now [create a trigger](../triggers/_index.md), which determines when the external agent runs.

For example, you can specify the agent to be triggered when you mention a service account
in a discussion, or when you assign the service account as a reviewer.

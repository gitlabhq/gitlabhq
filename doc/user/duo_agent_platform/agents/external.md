---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- Not available on GitLab Duo with self-hosted models

{{< /collapsible >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.
- Renamed from CLI agents in GitLab 18.6.
- Enabling in groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578318) in GitLab 18.7 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_agents`. Enabled on GitLab.com.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab Duo agents work in parallel to help you create code, research results,
and perform tasks simultaneously.

You can create an agent and integrate it with an external
AI model provider to customize it to your organization's needs. You use your own
API key to integrate with the model provider.

Then, in a project issue, epic, or merge request, you can mention that external agent
in a comment or discussion and ask the agent to complete a task.

The external agent:

- Reads and analyzes the surrounding context and repository code.
- Decides the appropriate action to take, while adhering to project permissions
  and keeping an audit trail.
- Runs a CI/CD pipeline and responds inside GitLab with either a ready-to-merge
  change or an inline comment.

The following integrations have been tested by GitLab and are available:

- [Anthropic Claude](https://docs.anthropic.com/en/docs/claude-code/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Opencode](https://opencode.ai/docs/gitlab/)
- [Amazon Q](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)
- [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)

For a click-through demo, see [GitLab Duo Agent Platform with Amazon Q](https://gitlab.navattic.com/dap-with-q).
<!-- Demo published on 2025-11-03 -->

## Prerequisites

Before you can create an agent and integrate it with an external AI model
provider, you must meet the [prerequisites](../_index.md#prerequisites).

## AI model provider credentials

To integrate your agent with an external AI model provider, you must have access credentials.
You can use either an API key for that model provider or GitLab-managed credentials.

### API keys

To integrate your agent with an external AI model provider,
you can use an API key for that model provider:

- For Anthropic Claude and Opencode, use an [Anthropic API key](https://docs.anthropic.com/en/api/admin-api/apikeys/get-api-key).
- For OpenAI Codex, use an [OpenAI API key](https://platform.openai.com/docs/api-reference/authentication).

### GitLab-managed credentials

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567791) in GitLab 18.4.

{{< /history >}}

Instead of using your own API keys for external AI model providers,
you can configure external agents to use GitLab-managed credentials through an AI gateway.
This way, you do not have to manage and rotate API keys yourself.

When you use GitLab-managed credentials:

- Set `injectGatewayToken: true` in your external agent configuration.
- Remove the API key variables (for example, `ANTHROPIC_API_KEY`) from your CI/CD variables.
- Configure the external agent to use the GitLab AI gateway proxy endpoints.

The following environment variables are automatically injected when `injectGatewayToken` is `true`:

- `AI_FLOW_AI_GATEWAY_TOKEN`: the authentication token for AI Gateway
- `AI_FLOW_AI_GATEWAY_HEADERS`: formatted headers for API requests

GitLab-managed credentials are available only for Anthropic Claude and OpenAI Codex.

#### Supported models

For GitLab-managed credentials, the following AI models are supported:

Anthropic Claude:

- `claude-3-sonnet-20240229`
- `claude-3-5-sonnet-20240620`
- `claude-3-haiku-20240307`
- `claude-3-5-haiku-20241022`
- `claude-3-5-sonnet-20241022`
- `claude-3-7-sonnet-20250219`
- `claude-sonnet-4-20250514`
- `claude-sonnet-4-5-20250929`

OpenAI Codex:

- `gpt-5`
- `gpt-5-codex`

## Create a service account

Prerequisites:

- On GitLab.com, you must have the Owner role for the top-level group the project belongs to.
- On GitLab Self-Managed and GitLab Dedicated, you must have one of the following:
  - Administrator access to the instance.
  - The Owner role for a top-level group and
    [permission to create service accounts](../../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

Each project that mentions an external agent must have a unique [group service account](../../../user/profile/service_accounts.md).
Mention the service account username when you assign tasks to the external agent.

If you create an external agent from the AI Catalog and enable it in a top-level group, a service account is automatically created with the name `ai-<agent>-<group>`. For example, if you enable an agent named `Claude code agent` in the `GitLab Duo` group, the service account name is `ai-claude-code-agent-gitlab-duo`.

{{< alert type="warning" >}}

If you use the same service account across multiple projects, that gives the external agent attached to that service account access to all of those projects.

{{< /alert >}}

To set up the service account, take the following actions. If you do not have sufficient
permissions, ask your instance administrator or top-level group Owner for help.

1. For the top-level group, [create a service account](../../../user/profile/service_accounts.md#create-a-service-account).
   Service accounts created for the instance are not supported.
1. [Create a personal access token for the service account](../../../user/profile/service_accounts.md#create-a-personal-access-token-for-a-service-account) with the following [scopes](../../../user/profile/personal_access_tokens.md#personal-access-token-scopes):
   - `write_repository`
   - `api`
   - `ai_features`
1. [Add the service account to your project](../../../user/project/members/_index.md#add-users-to-a-project)
   with the Developer role. This ensures the service account has the minimum permissions necessary.

When adding the service account to your project, you must enter the exact name
of the service account. If you enter the wrong name, the external agent does not work.

## Configure CI/CD variables

Prerequisites:

- You must have at least the Maintainer role for the project.

Add the following CI/CD variables to your project's settings:

| Integration                | Environment variable         | Description |
|----------------------------|------------------------------|-------------|
| All                        | `GITLAB_TOKEN_<integration>` | Personal access token for the service account user. |
| All                        | `GITLAB_HOST`                | GitLab instance hostname (for example, `gitlab.com`). |
| Anthropic Claude, Opencode | `ANTHROPIC_API_KEY`          | Anthropic API key (optional when `injectGatewayToken: true` is set). |
| OpenAI Codex               | `OPENAI_API_KEY`             | OpenAI API key. |
| Amazon Q                   | `AWS_SECRET_NAME`            | AWS Secret Manager secret name. |
| Amazon Q                   | `AWS_REGION_NAME`            | AWS region name. |
| Amazon Q                   | `AMAZON_Q_SIGV4`             | Amazon Q Sig V4 credentials. |
| Google Gemini CLI          | `GOOGLE_CREDENTIALS`         | JSON credentials file contents. |
| Google Gemini CLI          | `GOOGLE_CLOUD_PROJECT`       | Google Cloud project ID. |
| Google Gemini CLI          | `GOOGLE_CLOUD_LOCATION`      | Google Cloud project location. |

To add or update a variable in the project settings:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **CI/CD**.
1. Expand **Variables**.
1. Select **Add variable** and complete the fields:
   - **Type**: Select **Variable (default)**.
   - **Environments**: Select **All (default)**.
   - **Visibility**: Select the desired visibility.

     For the API key and personal access token variables, select **Masked** or
     **Masked and hidden**.
   - Clear the **Protect variable** checkbox.
   - Clear the **Expand variable reference** checkbox.
   - **Description (optional)**: Enter a variable description.
   - **Key**: Enter the environment variable name of the CI/CD variable
     (for example, `GITLAB_HOST`).
   - **Value**: The value of the API key, personal access token, or host.
1. Select **Add variable**.

For more information, see how to [add CI/CD variables to a project's settings](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui).

## Create an external agent

Create an external agent and configure it to run on your environment.

### By using the UI

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610) in GitLab 18.6 with a flag named `ai_catalog_third_party_flows`. Enabled on GitLab.com.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Prerequisites:

- You must have at least the Maintainer role for the project.

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

### By using a configuration file

If you create external agents by manually adding configuration files,
you must create a different configuration file for each external agent.

Prerequisites:

- You must have at least the Developer role for the project.

To create a configuration file:

1. In your project, create a YAML file, for example: `.gitlab/duo/flows/claude.yaml`
1. Populate the file by using [one of the configuration file examples](external_examples.md).

## Enable an external agent

If you create an external agent from the AI Catalog, to use it, you must:

1. Enable it in a top-level group.
1. Enable it in the project you want to use it in.

### Enable in a top-level group

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

### Enable in a project

Prerequisites:

- You must have at least the Maintainer role for the project.
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

## Create a trigger

You must now [create a trigger](../triggers/_index.md), which determines when the external agent runs.

For example, you can specify the agent to be triggered when you mention a service account
in a discussion, or when you assign the service account as a reviewer.

If you create an external agent from the AI Catalog, when you enable the agent in a project you also create triggers.

## Use an external agent

Prerequisites:

- You must have at least the Developer role for the project.
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

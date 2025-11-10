---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Third-party agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md): No

{{< /collapsible >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.
- Renamed from CLI agents in GitLab 18.6.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab Duo agents work in parallel to help you create code, research results,
and perform tasks simultaneously.

You can create an agent and integrate it with a third-party
AI model provider to customize it to your organization's needs. You use your own
API key to integrate with the model provider.

Then, in a project issue, epic, or merge request, you can mention that third-party agent
in a comment or discussion and ask the agent to complete a task.

The third-party agent:

- Reads and analyzes the surrounding context and repository code.
- Decides the appropriate action to take, while adhering to project permissions
  and keeping an audit trail.
- Runs a CI/CD pipeline and responds inside GitLab with either a ready-to-merge
  change or an inline comment.

The following third-party integrations have been tested by GitLab and are available:

- [Anthropic Claude](https://docs.anthropic.com/en/docs/claude-code/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Opencode](https://opencode.ai/docs/gitlab/)
- [Amazon Q](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)
- [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)

For a click-through demo, see [DAP with Amazon Q](https://gitlab.navattic.com/dap-with-q).
<!-- Demo published on 2025-11-03 -->

## Prerequisites

Before you can create an agent and integrate it with a third-party AI model
provider, you must meet the [prerequisites](../_index.md#prerequisites).

## AI model provider credentials

To integrate your agent with a third-party AI model provider, you must have access credentials.
You can use either an API key for that model provider or GitLab-managed credentials.

### API keys

To integrate your agent with a third-party AI model provider,
you can use an API key for that model provider:

- For Anthropic Claude and Opencode, use an [Anthropic API key](https://docs.anthropic.com/en/api/admin-api/apikeys/get-api-key).
- For OpenAI Codex, use an [OpenAI API key](https://platform.openai.com/docs/api-reference/authentication).

### GitLab-managed credentials

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567791) in GitLab 18.4.

{{< /history >}}

Instead of using your own API keys for third-party AI model providers,
you can configure third-party agents to use GitLab-managed credentials through an AI gateway.
This way, you do not have to manage and rotate API keys yourself.

When you use GitLab-managed credentials:

- Set `injectGatewayToken: true` in your flow configuration file.
- Remove the API key variables (for example, `ANTHROPIC_API_KEY`) from your CI/CD variables.
- Configure the third-party agent to use the GitLab AI gateway proxy endpoints.

The following environment variables are automatically injected when `injectGatewayToken` is `true`:

- `AI_FLOW_AI_GATEWAY_TOKEN`: the authentication token for AI Gateway
- `AI_FLOW_AI_GATEWAY_HEADERS`: formatted headers for API requests

GitLab-managed credentials are available only for Anthropic Claude and Codex.

## Create a service account

Prerequisites:

- On GitLab.com, you must have the Owner role for the top-level group the project belongs to.
- On GitLab Self-Managed and GitLab Dedicated, you must have one of the following:
  - Administrator access to the instance.
  - The Owner role for a top-level group and
    [permission to create service accounts](../../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts).

Each project that mentions a third-party agent must have a unique [group service account](../../../user/profile/service_accounts.md).
Mention the service account username when you assign tasks to the third-party agent.

{{< alert type="warning" >}}

If you use the same service account across multiple projects, that gives the third-party agent attached to that service account access to all of those projects.

{{< /alert >}}

To set up the service account, take the following actions. If you do not have sufficient
permissions, ask your instance administrator or top-level group Owner for help.

1. [Create a service account](../../../user/profile/service_accounts.md#create-a-service-account).
1. [Create a personal access token for the service account](../../../user/profile/service_accounts.md#create-a-personal-access-token-for-a-service-account) with the following [scopes](../../../user/profile/personal_access_tokens.md#personal-access-token-scopes):
   - `write_repository`
   - `api`
   - `ai_features`
1. [Add the service account to your project](../../../user/project/members/_index.md#add-users-to-a-project)
   with the Developer role. This ensures the service account has the minimum permissions necessary.

When adding the service account to your project, you must enter the exact name
of the service account. If you enter the wrong name, the third-party agent does not work.

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

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
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

## Create a third-party agent

Create a third-party agent and configure it to run on your environment with a flow configuration.

### By using the AI Catalog

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

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flows**.
1. Select **New flow**.
1. Under **Basic information**:
   1. In **Display name**, enter a name.
   1. In **Description**, enter a description.
1. Under **Visibility & access**:
   1. For **Visibility**, select **Private** or **Public**.
1. Under **Configuration**, enter your flow configuration.
   You can write your own configuration, or edit one of the templates below.
1. Select **Create flow**.

The third-party agent appears in the AI Catalog.

### By using a flow configuration file

If you create third-party agents by manually adding flow configuration files,
you must create a different AI flow configuration file for each third-party agent.

Prerequisites:

- You must have at least the Developer role for the project.

To create a flow configuration file:

1. In your project, create a YAML file, for example: `.gitlab/duo/flows/claude.yaml`
1. Populate the file by using [one of the flow configuration file examples](flow_examples.md).

## Enable a third-party agent

If you created a third-party agent from the AI Catalog, you must enable it in a project to use it.

Prerequisites:

- You must have at least the Maintainer role for the project.

To enable a third-party agent in a project:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**.
1. Select the **Flows** tab.
1. Select your third-party agent, then select **Enable in project or group**.
1. Under **Enable in**, select **Project**.
1. From the dropdown list, select the project you want to enable the third-party agent in.
1. Select **Enable**.

The third-party agent appears in the project's **Flows** list.

## Create a trigger

You must now [create a trigger](../triggers/_index.md), which determines when the third-party agent runs.

For example, you can specify the agent to be triggered when you mention a service account
in a discussion, or when you assign the service account as a reviewer.

## Use a third-party agent

Prerequisites:

- You must have at least the Developer role for the project.
- If you created a third-party agent from the AI Catalog, the agent must be enabled in your project.

1. In your project, open an issue, merge request, or epic.
1. Add a comment on the task you want the third-party agent to complete, mentioning the service account user.
   For example:

   ```markdown
   @service-account-username can you help analyze this code change?
   ```

1. Under your comment, the third-party agent replies **Processing the request and starting the agent...**.
1. While the third-party agent is working, the comment **Agent has started. You can view the progress here**
   is displayed. You can select **here** to see the pipeline in progress.
1. After the third-party agent has completed the task, you see a confirmation, and either a
   ready-to-merge change or an inline comment.

{{< alert type="note" >}}

To allow the agent to push to `workloads/*`, you might have to create [branch rules](../../project/repository/branches/branch_rules.md).

{{< /alert >}}

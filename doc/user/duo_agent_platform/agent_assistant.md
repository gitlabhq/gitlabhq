---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CLI agents
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment
- Add-on: GitLab Duo Enterprise
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md): Yes

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a flag](../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab Duo agents work in parallel to help you create code, research results,
and perform tasks simultaneously.

You can create a command line interface (CLI) agent and integrate it with a third-party
AI model provider to customise the CLI agent to your organization's needs. You use your own
API key to integrate with the model provider.

Then, in a project issue, epic, or merge request, you can mention that CLI agent
in a comment or discussion and ask the CLI agent to complete a task.

The CLI agent:

- Reads and analyzes the surrounding context and repository code.
- Decides the appropriate action to take, while adhering to project permissions
  and keeping an audit trail.
- Runs a CI pipeline and responds inside GitLab with either a ready-to-merge
  change or an inline comment.

The following third-party integrations have been tested by GitLab and are available:

- [Anthropic Claude](https://docs.anthropic.com/en/docs/claude-code/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Opencode AI](https://opencode.ai/docs/)

## Prerequisites

Before you can create a CLI agent and integrate it with a third-party AI model
provider, you must:

### Configure your GitLab environment

- [Turn on beta and experimental features](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- [Turn on GitLab Duo](../gitlab_duo/turn_on_off.md).
- Have GitLab Duo Enterprise with an [assigned seat](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- Have a project that belongs to a [group namespace](../namespace/_index.md) with an Ultimate subscription.
- If you are using [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md),
  your self-hosted models must be [either an Anthropic or OpenAI model](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md).

### Set up CI/CD

When completing your task, the CLI agent runs a CI/CD pipeline.

If you are on GitLab Self-Managed or GitLab Dedicated, you must
[create and register a GitLab Runner](../../tutorials/create_register_first_runner/_index.md).

### Get an AI model provider API key

To integrate your CLI agent with a third-party AI model provider, you need an API key
for that model provider:

- For Anthropic Claude and Opencode AI, use an [Anthropic API key](https://docs.anthropic.com/en/api/admin-api/apikeys/get-api-key).
- For OpenAI Codex, use an [OpenAI API key](https://platform.openai.com/docs/api-reference/authentication).

## Create a service account

There must be a unique [service account](../../user/profile/service_accounts.md)
for each project where you want to mention a CLI agent. The service account username
is the name you mention when giving the CLI agent a task.

{{< alert type="warning" >}}

If you use the same service account across multiple projects, that gives the CLI agent attached to that service account access to all of those projects.

{{< /alert >}}

Ask your instance administrator or top-level group Owner to:

1. [Create a service account](../../user/profile/service_accounts.md#create-a-service-account).
1. [Create a personal access token for the service account](../../user/profile/service_accounts.md#create-a-personal-access-token-for-a-service-account) with the following [scopes](../../user/profile/personal_access_tokens.md#personal-access-token-scopes):
   - `write_repository`
   - `api`
   - `ai_features`
1. [Add the service account to your project](../../user/profile/service_accounts.md#service-account-access-to-groups-and-projects) with the Developer role. This
ensures the service account has the minimum permissions necessary.

## Configure CI/CD variables

Prerequisites:

- You must have at least the Maintainer role in the project.

Add the following CI/CD variables to your project's settings:

- Your provider-specific API key:
  - `ANTHROPIC_API_KEY` if you are using a Claude or Opencode AI integration.
  - `OPENAI_API_KEY`if you are using an OpenAI Codex integration.
- `GITLAB_TOKEN_<provider>`: The personal access token for the service account user.
- `GITLAB_HOST`: The GitLab instance hostname. For example, `gitlab.com`.

To add or update a variable in the project settings:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
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
   - **Key**: Enter the environment variable name of the CI/CD variable.
     For example `ANTHROPIC_API_KEY`.
   - **Value**: The value of the API key, personal access token, or host.
1. Select **Add variable**.

For more information, see how to [add CI/CD variables to a project's settings](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui).

## Create a flow configuration file

Prerequisites:

- You must have at least the Developer role in the project.

To tell GitLab how to run the CLI agent for your environment, in your project,
create a flow configuration file. For example, `.gitlab/duo/flows/claude.yaml`.

You must create a different AI flow configuration file for each CLI agent.

### Example flow configuation files

#### Anthropic Claude

```yaml
image: node:22-slim
commands:
  - echo "Installing claude"
  - npm install --global @anthropic-ai/claude-code
  - echo "Installing glab"
  - export GITLAB_TOKEN=$GITLAB_TOKEN_CLAUDE
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Configuring git"
  - git config --global user.email "claudecode@gitlab.com"
  - git config --global user.name "Claude Code"
  - echo "Running claude"
  - |
    claude --allowedTools="Bash(glab:*),Bash(git:*)" --permission-mode acceptEdits --verbose --output-format stream-json --prompt "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Please use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    If you are asked to summarise an MR or issue or asked to provide more information then please post back a note to the MR/Issue so that the user can see it.
    </important>
    "
  - git checkout --branch $CI_WORKLOAD_REF origin/$CI_WORKLOAD_REF
  - echo "Checking for git changes and pushing if any exist"
  - |
    if ! git diff --quiet || ! git diff --cached --quiet || [ --not "$(git ls-files --others --exclude-standard)" ]; then
      echo "Git changes detected, adding and pushing..."
      git add .
      if git diff --cached --quiet; then
        echo "No staged changes to commit"
      else
        echo "Committing changes to branch: $CI_WORKLOAD_REF"
        git commit --message "Claude Code changes"
        echo "Pushing changes up to $CI_WORKLOAD_REF"
        git push https://gitlab-ci-token:$GITLAB_TOKEN@$GITLAB_HOST/gl-demo-ultimate-dev-ai-epic-17570/test-java-project.git $CI_WORKLOAD_REF
        echo "Changes successfully pushed"
      fi
    else
      echo "No git changes detected, skipping push"
    fi
variables:
  - ANTHROPIC_API_KEY
  - GITLAB_TOKEN_CLAUDE
  - GITLAB_HOST
```

#### OpenAI Codex

```yaml
image: node:22-slim
commands:
  - echo "Installing codex"
  - npm install --global @openai/codex
  - echo "Installing glab"
  - export GITLAB_TOKEN=$GITLAB_TOKEN_CODEX
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Configuring git"
  - git config --global user.email "codex@gitlab.com"
  - git config --global user.name "OpenAI Codex"
  - echo "Running Codex"
  - |
    codex exec --dangerously-bypass-approvals-and-sandbox "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Please use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    If you are asked to summarise an MR or issue or asked to provide more information then please post back a note to the MR/Issue so that the user can see it.
    You don't need to commit or push up changes, those will be done automatically based on the file changes you make.
    </important>
    "
  - git checkout --branch $CI_WORKLOAD_REF origin/$CI_WORKLOAD_REF
  - echo "Checking for git changes and pushing if any exist"
  - |
    if ! git diff --quiet || ! git diff --cached --quiet || [ --not --zero "$(git ls-files --others --exclude-standard)" ]; then
      echo "Git changes detected, adding and pushing..."
      git add .
      if git diff --cached --quiet; then
        echo "No staged changes to commit"
      else
        echo "Committing changes to branch: $CI_WORKLOAD_REF"
        git commit --message "Codex changes"
        echo "Pushing changes up to $CI_WORKLOAD_REF"
        git push https://gitlab-ci-token:$GITLAB_TOKEN@$GITLAB_HOST/gl-demo-ultimate-dev-ai-epic-17570/test-java-project.git $CI_WORKLOAD_REF
        echo "Changes successfully pushed"
      fi
    else
      echo "No git changes detected, skipping push"
    fi
variables:
  - OPENAI_API_KEY
  - GITLAB_TOKEN_CODEX
  - GITLAB_HOST
```

#### Opencode AI

```yaml
image: node:22-slim
commands:
  - echo "Installing opencode"
  - npm install --global opencode-ai
  - echo "Installing glab"
  - export GITLAB_TOKEN=$GITLAB_TOKEN_OPENCODE
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Configuring glab"
  - echo $GITLAB_HOST
  - echo "Creating opencode auth configuration"
  - mkdir --parents ~/.local/share/opencode
  - |
    cat > ~/.local/share/opencode/auth.json << EOF
    {
      "anthropic": {
        "type": "api",
        "key": "$ANTHROPIC_API_KEY"
      }
    }
    EOF
  - echo "Configuring git"
  - git config --global user.email "opencode@gitlab.com"
  - git config --global user.name "Opencode"
  - echo "Testing glab"
  - glab issue list
  - echo "Running Opencode"
  - |
    opencode run "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Please use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    If you are asked to summarise an MR or issue or asked to provide more information then please post back a note to the MR/Issue so that the user can see it.
    You don't need to commit or push up changes, those will be done automatically based on the file changes you make.
    </important>
    "
  - git checkout --branch $CI_WORKLOAD_REF origin/$CI_WORKLOAD_REF
  - echo "Checking for git changes and pushing if any exist"
  - |
    if ! git diff --quiet || ! git diff --cached --quiet || [ --not --zero "$(git ls-files --others --exclude-standard)" ]; then
      echo "Git changes detected, adding and pushing..."
      git add .
      if git diff --cached --quiet; then
        echo "No staged changes to commit"
      else
        echo "Committing changes to branch: $CI_WORKLOAD_REF"
        git commit --message "Codex changes"
        echo "Pushing changes up to $CI_WORKLOAD_REF"
        git push https://gitlab-ci-token:$GITLAB_TOKEN@$GITLAB_HOST/gl-demo-ultimate-dev-ai-epic-17570/test-java-project.git $CI_WORKLOAD_REF
        echo "Changes successfully pushed"
      fi
    else
      echo "No git changes detected, skipping push"
    fi
variables:
  - ANTHROPIC_API_KEY
  - GITLAB_TOKEN_OPENCODE
  - GITLAB_HOST
```

## Configure a flow trigger

Prerequisites:

- You must have at least the Maintainer role in the project.

The flow trigger links the service account, the flow configuration file, and the
action that the user takes to trigger the CLI agent.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Automate** > **Flow triggers**.
1. Select **Create flow trigger**.
1. Complete the fields:
   - **Description**: Enter a description for the flow trigger.
   - **Event types**: Select one of the following event types:
     - **Mention**.
   - **Service account user**: From the **Service account user** dropdown list,
     select the service account user.
   - **Config Path**: Enter the location of the flow configuration file.
     For example `.gitlab/duo/flows/claude.yml`.
1. Select **Create flow trigger**.

You have created the flow trigger. Check that it appears in **Automate > Flow triggers**.

You can now mention the CLI agent by its service account username in a comment to accomplish
a task. The CLI agent then tries to accomplish that task, using the flow trigger defined by the user.

### Edit a flow trigger

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Automate** > **Flow triggers**.
1. For the flow trigger you want to change, select **Edit flow trigger** ({{< icon name="pencil" >}}).
1. Make the changes and select **Save changes**.

### Delete a flow trigger

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Automate** > **Flow triggers**.
1. For the flow trigger you want to change, select **Delete flow trigger** ({{< icon name="remove" >}}).
1. On the confirmation dialog, select **OK**.

## Use the CLI agent

Prerequisites:

- You must have at least the Developer role in the project.

1. In your project, open an issue, merge request, or epic.
1. Add a comment on the task you want the CLI agent to complete, mentioning the service account user.
   For example:

   ```markdown
   @service-account-username can you help analyze this code change?
   ```

1. Under your comment, the CLI agent replies **Processing the request and starting the agent...**.
1. While the CLI agent is working, the comment **Agent has started. You can view the progress here**
   is displayed. You can select **here** to see the pipeline in progress.
1. After the CLI agent has completed the task, you see a confirmation, and either a
   ready-to-merge change or an inline comment.

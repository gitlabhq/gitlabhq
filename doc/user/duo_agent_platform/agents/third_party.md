---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Third-party agents
---

{{< details >}}

- Tier: Ultimate
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
provider, you must:

### Configure your GitLab environment

- [Turn on beta and experimental features](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- [Turn on GitLab Duo](../../gitlab_duo/turn_on_off.md).
- Have GitLab Duo Enterprise with an [assigned seat](../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- Have a project that belongs to a [group namespace](../../namespace/_index.md) with an Ultimate subscription.

### Set up CI/CD

When completing your task, the third-party agent runs a CI/CD pipeline.

If you are on GitLab Self-Managed or GitLab Dedicated, you must
[create and register a GitLab Runner](../../../tutorials/create_register_first_runner/_index.md).

### AI model provider credentials

To integrate your agent with a third-party AI model provider, you must have access credentials.
You can use either an API key for that model provider or GitLab-managed credentials.

#### API keys

To integrate your agent with a third-party AI model provider,
you can use an API key for that model provider:

- For Anthropic Claude and Opencode, use an [Anthropic API key](https://docs.anthropic.com/en/api/admin-api/apikeys/get-api-key).
- For OpenAI Codex, use an [OpenAI API key](https://platform.openai.com/docs/api-reference/authentication).

#### GitLab-managed credentials

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

Each project that mentions a third-party agent must have a unique
[group service account](../../../user/profile/service_accounts.md). Mention the service account
username when you assign tasks to the third-party agent.

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

1. On the left sidebar, select **Search or go to** > **Explore**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **AI Catalog**.
1. Select the **Flows** tab, then select **New flow**.
1. Under **Basic information**:
   1. In **Display name**, enter a name.
   1. In **Description**, enter a description.
1. Under **Visibility & access**:
   1. For **Visibility**, select **Private** or **Public**.
   1. From the **Source project** dropdown list, select a project.
1. Under **Configuration**, enter your flow configuration.
   You can write your own configuration, or edit one of the templates below.
1. Select **Create flow**.

The third-party agent appears in the AI Catalog.

### By using a flow configuration file

Prerequisites:

- You must have at least the Developer role for the project.

In your project, create a flow configuration file.
For example, `.gitlab/duo/flows/claude.yaml`.

If you create third-party agents by manually adding flow configuration files,
you must create a different AI flow configuration file for each third-party agent.

### Example flow configurations

Use the following examples to create your flow configuration.
These examples contain the following variables:

- `AI_FLOW_CONTEXT`: the JSON-serialized parent object, including:
  - In merge requests, the diff and comments (up to a limit)
  - In issues or epics, the comments (up to a limit)
- `$AI_FLOW_EVENT`: the type of flow event (for example, `mention`)
- `$AI_FLOW_INPUT`: the prompt the user enters as a comment in the merge request, issue, or epic

#### Anthropic Claude

```yaml
injectGatewayToken: true
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
  - echo "Configuring claude"
  - export ANTHROPIC_AUTH_TOKEN=$AI_FLOW_AI_GATEWAY_TOKEN
  - export ANTHROPIC_CUSTOM_HEADERS=$AI_FLOW_AI_GATEWAY_HEADERS
  - export ANTHROPIC_BASE_URL="https://cloud.gitlab.com/ai/v1/proxy/anthropic"
  - echo "Running claude"
  - |
    claude --debug --allowedTools="Bash(glab:*),Bash(git:*)" --permission-mode acceptEdits --verbose --output-format stream-json -p "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    When you check in and push code, you will need to use the access token stored in GITLAB_TOKEN and the user ClaudeCode.
    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    `glab mr create --title "<title>" --description "<desc>" --source-branch <branch> --target-branch <branch>`

    If you are asked to summarize a merge request or issue, or asked to provide more information, then please post back a note to the merge request / issue so that the user can see it.

    </important>
    "
variables:
  - GITLAB_TOKEN_CLAUDE
  - GITLAB_HOST
```

#### OpenAI Codex

```yaml
image: node:22-slim
injectGatewayToken: true
commands:
  - echo "Installing codex"
  - npm install --global @openai/codex
  - echo "Installing glab"
  - export OPENAI_API_KEY=$AI_FLOW_AI_GATEWAY_TOKEN
  - export GITLAB_TOKEN=$GITLAB_TOKEN_CODEX
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Configuring git"
  - git config --global user.email "codex@gitlab.com"
  - git config --global user.name "OpenAI Codex"
  - echo "Running Codex"
  - |
    # Parse AI_FLOW_AI_GATEWAY_HEADERS (newline-separated "Key: Value" pairs)
    header_str="{"
    first=true
    while IFS= read -r line; do
      # skip empty lines
      [ -z "$line" ] && continue
      key="${line%%:*}"
      value="${line#*: }"
      if [ "$first" = true ]; then
        first=false
      else
        header_str+=", "
      fi
      header_str+="\"$key\" = \"$value\""
    done <<< "$AI_FLOW_AI_GATEWAY_HEADERS"
    header_str+="}"

    codex exec \
      --config 'model_provider="gitlab"' \
      --config 'model_providers.gitlab.name="GitLab Managed Codex"' \
      --config 'model_providers.gitlab.base_url="https://cloud.gitlab.com/ai/v1/proxy/openai/v1"' \
      --config 'model_providers.gitlab.env_key="OPENAI_API_KEY"' \
      --config 'model_providers.gitlab.wire_api="responses"' \
      --config "model_providers.gitlab.http_headers=${header_str}" \
      --dangerously-bypass-approvals-and-sandbox "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    When you check in and push code, you will need to use the access token stored in GITLAB_TOKEN and the user Codex.
    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    glab mr create --title \"<title>\" --description \"<desc>\" --source-branch \"<branch>\" --target-branch \"<branch>\"

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    </important>
    "
variables:
  - GITLAB_TOKEN_CODEX
  - GITLAB_HOST
```

#### Opencode

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
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    When you check in and push code, you will need to use the access token stored in GITLAB_TOKEN and the user ClaudeCode.
    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    `glab mr create --title "<title>" --description "<desc>" --source-branch <branch> --target-branch <branch>`

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    </important>
    "
variables:
  - ANTHROPIC_API_KEY
  - GITLAB_TOKEN_OPENCODE
  - GITLAB_HOST
```

#### Amazon Q

Instead of hard-coding your AWS credentials, store them in the AWS Secrets Manager. Then you can reference them in your YAML file.

1. [Create an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) that does not have console access.
1. Generate an access key pair for programmatic access.
1. In the same AWS account where GitLab Runner is hosted, create a secret in AWS Secrets Manager. Use the following JSON format:

   ```json
   {
     "q-cli-access-token": {"AWS_ACCESS_KEY_ID": "AKIA...", "AWS_SECRET_ACCESS_KEY": "abc123..."}
   }
   ```

   Important: Replace the placeholder values with your actual access key ID and secret access key.

1. Grant the GitLab Runner IAM role permission to access AWS Secrets Manager.
1. Create a flow configuration file like the following.

```yaml
image: node:22-slim
commands:
  - echo "Installing glab"
  - mkdir --parents ~/.aws/amazonq
  - echo $MCP_CONFIG > ~/.aws/amazonq/mcp.json
  - export GITLAB_TOKEN=$GITLAB_TOKEN_AMAZON_Q
  - apt-get update --quiet && apt-get install --quiet --yes curl wget gpg git unzip && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Installaing Python"
  - curl --location --silent --show-error --fail "https://astral.sh/uv/install.sh" | sh
  - export PATH="$HOME/.local/bin:$PATH"
  - uv python install 3.12 --default
  - TEMP_DIR=$(mktemp -d)
  - cd "$TEMP_DIR"
  - echo "Installing AWS cli"
  - curl --proto '=https' --tlsv1.2 --silent --show-error --fail "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip"
  - unzip -qq awscliv2.zip
  - ./aws/install
  - echo "Installing jq"
  - apt-get install --yes jq
  - echo "Installing q client"
  - curl --proto '=https' --tlsv1.2 --silent --show-error --fail "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip" --output "q.zip"
  - unzip -qq q.zip
  - ./q/install.sh --force --no-confirm
  - cd -
  - rm -rf "$TEMP_DIR"
  - echo "Getting AWS access token"
  - |
    if SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --region "$AWS_REGION_NAME" --query SecretString --output text 2>/dev/null); then
        export AWS_ACCESS_KEY_ID=$(echo "$SECRET_JSON" | jq -r '."q-cli-access-token" | fromjson | ."AWS_ACCESS_KEY_ID"' )
        export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET_JSON" | jq -r '."q-cli-access-token" | fromjson | ."AWS_SECRET_ACCESS_KEY"')
        echo "Success to retrieve secret $AWS_SECRET_NAME"
    else
        echo "Failed to retrieve secret: $AWS_SECRET_NAME"
        exit 1
    fi
  - echo "Configuring git"
  - git config --global user.email "amazonq@gitlab.com"
  - git config --global user.name "AmazonQ Code"
  - git remote set-url origin https://gitlab-ci-token:$GITLAB_TOKEN_AMAZON_Q@$GITLAB_HOST/internal-test/q-words-demo.git
  - echo "Running q"
  - |
    AMAZON_Q_SIGV4=1 q chat --trust-all-tools --no-interactive --verbose "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    When you check in and push code you will need to use the access token stored in GITLAB_TOKEN and the user ClaudeCode.
    Lastly, after pushing the code, if a MR doesn't already exist, create a new MR for the branch and link it to the issue using:
    `glab mr create --title "<title>" --description "<desc>" --source-branch <branch> --target-branch <branch>`

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    </important>
    "
variables:
  - GITLAB_TOKEN_AMAZON_Q
  - GITLAB_HOST
  - AWS_SECRET_NAME
  - AWS_REGION_NAME
  - MCP_CONFIG
```

#### Google Gemini CLI

```yaml
image: node:22-slim
commands:
  - echo "Installing glab"
  - export GITLAB_TOKEN=$GITLAB_TOKEN_GEMINI
  - apt-get update --quiet && apt-get install --yes curl wget gpg git unzip && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Installing gemini client"
  - npm install --global @google/gemini-cli
  - echo $GOOGLE_CREDENTIALS > /root/credentials.json
  - echo "Configuring git"
  - git config --global user.email "gemini@gitlab.com"
  - git config --global user.name "Gemini"
  - echo "Running gemini"
  - |
    GOOGLE_GENAI_USE_VERTEXAI=true GOOGLE_APPLICATION_CREDENTIALS=/root/credentials.json gemini --yolo --debug --prompt "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    When you check in and push code you will need to use the access token stored in GITLAB_TOKEN and the user ClaudeCode.
    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    `glab mr create --title "<title>" --description "<desc>" --source-branch <branch> --target-branch <branch>`

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    </important>
    "
variables:
  - GITLAB_TOKEN_GEMINI
  - GITLAB_HOST
  - GOOGLE_CREDENTIALS
  - GOOGLE_CLOUD_PROJECT
  - GOOGLE_CLOUD_LOCATION
```

#### Cursor CLI

```yaml
image: node:22-slim
commands:
  - echo "Installing Cursor"
  - apt-get update --quiet && apt-get install --yes curl wget gnupg2 gpg git && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://cursor.com/install" | bash
  - echo "Installing glab"
  - export GITLAB_TOKEN=$GITLAB_TOKEN_CURSOR
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Configuring Git"
  - git config --global user.email "cursor@gitlab.com"
  - git config --global user.name "Cursor"
  - echo "Running Cursor"
  - |
    $HOME/.local/bin/cursor-agent -p --force --output-format stream-json "--prompt "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    When you check in and push code you will need to use the access token stored in GITLAB_TOKEN and the user Cursor.
    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    `glab mr create --title "<title>" --description "<desc>" --source-branch <branch> --target-branch <branch>`

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    </important>
    "
variables:
  - GITLAB_TOKEN_CURSOR
  - GITLAB_HOST
  - CURSOR_API_KEY
```

## Create a flow trigger

{{< history >}}

- **Assign** and **Assign reviewer** event types [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/567787) in GitLab 18.5.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role for the project.

The flow trigger links the service account, the flow configuration file, and the
action that the user takes to trigger the third-party agent.

To create a flow trigger:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flow triggers**.
1. Select **New flow trigger**.
1. In **Description**, enter a description for the flow trigger.
1. From the **Event types** dropdown list, select one or more event types:
   - **Mention**: When the service account user is mentioned
     in a comment on an issue or merge request.
   - **Assign**: When the service account user is assigned
     to an issue or merge request.
   - **Assign reviewer**: When the service account user is assigned
     as a reviewer to a merge request.
1. From the **Service account user** dropdown list,
   select the service account user.
1. For **Configuration source**, select one of the following:
   - **AI Catalog**: From the flows configured for this project,
     select a flow for the trigger to execute.
   - **Configuration path**: Enter the path to the flow configuration file
     (for example, `.gitlab/duo/flows/claude.yaml`).
1. Select **Create flow trigger**.

The flow trigger now appears in **Automate** > **Flow triggers**.

You can now mention the third-party agent by its service account username in a comment to accomplish
a task. The third-party agent then tries to accomplish that task, using the flow trigger defined by the user.

### Edit a flow trigger

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flow triggers**.
1. For the flow trigger you want to change, select **Edit flow trigger** ({{< icon name="pencil" >}}).
1. Make the changes and select **Save changes**.

### Delete a flow trigger

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Automate** > **Flow triggers**.
1. For the flow trigger you want to change, select **Delete flow trigger** ({{< icon name="remove" >}}).
1. On the confirmation dialog, select **OK**.

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

You might need to create [branch rules](../../project/repository/branches/branch_rules.md)
that allow the agent to push to `workloads/*`

{{< /alert >}}

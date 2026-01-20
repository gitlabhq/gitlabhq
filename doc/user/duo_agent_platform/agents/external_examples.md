---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External agent configuration examples
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218840) in GitLab 18.8.

{{< /history >}}

Use the following examples to create your external agent configuration.
These examples contain the following variables:

- `AI_FLOW_CONTEXT`: the JSON-serialized parent object, including:
  - In merge requests, the diff and comments (up to a limit)
  - In issues or epics, the comments (up to a limit)
- `$AI_FLOW_EVENT`: the type of trigger event (for example, `mention`)
- `$AI_FLOW_INPUT`: the prompt the user enters as a comment in the merge request, issue, or epic

## Integrated with GitLab

The following agents are integrated with GitLab and available on GitLab.com.

### Claude Code

```yaml
injectGatewayToken: true
image: node:22-slim
commands:
  - echo "Installing Claude Code"
  - npm install --global @anthropic-ai/claude-code
  - echo "Installing glab"
  - export GITLAB_TOKEN=$GITLAB_TOKEN_CLAUDE
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
  - apt-get install --yes glab
  - echo "Configuring git"
  - git config --global user.email "claudecode@gitlab.com"
  - git config --global user.name "Claude Code"
  - echo "Configuring Claude Code"
  - export ANTHROPIC_AUTH_TOKEN=$AI_FLOW_AI_GATEWAY_TOKEN
  - export ANTHROPIC_CUSTOM_HEADERS=$AI_FLOW_AI_GATEWAY_HEADERS
  - export ANTHROPIC_BASE_URL="https://cloud.gitlab.com/ai/v1/proxy/anthropic"
  - echo "Running Claude Code"
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

### OpenAI Codex

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
      --config shell_environment_policy.ignore_default_excludes=true \
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

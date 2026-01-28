---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部エージェント設定の例
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。

{{< /history >}}

外部エージェント設定を作成するには、次の例を参考にしてください。これらの例には、次の変数が含まれています:

- `AI_FLOW_CONTEXT`: JSON形式でシリアル化された親オブジェクト。次の情報が含まれます:
  - マージリクエストの場合、差分とコメント（上限あり）
  - イシューまたはエピックの場合、コメント（上限あり）
- `$AI_FLOW_EVENT`: トリガーイベントのタイプ（例: `mention`）
- `$AI_FLOW_INPUT`: マージリクエスト、イシュー、またはエピックで、ユーザーがコメントとして入力するプロンプト

## GitLabとの連携 {#integrated-with-gitlab}

次のエージェントはGitLabと連携しており、GitLab.comで利用可能です。

### Claudeコード {#claude-code}

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

### OpenAI Codex {#openai-codex}

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

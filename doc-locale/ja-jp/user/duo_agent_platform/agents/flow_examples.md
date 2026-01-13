---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フロー設定例
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- `ai_flow_triggers`[フラグ](../../../administration/feature_flags/_index.md)とともにGitLab 18.3で導入されました。デフォルトでは有効になっています。

{{< /history >}}

フロー設定を作成するには、次の例を使用してください。これらの例には、次の変数が含まれています:

- `AI_FLOW_CONTEXT`：次のものを含む、JSONシリアル化された親オブジェクト:
  - マージリクエストでは、差分とコメント（上限あり）
  - イシューまたはエピックでは、コメント（上限あり）
- `$AI_FLOW_EVENT`：フローイベントのタイプ（例：`mention`）
- `$AI_FLOW_INPUT`：マージリクエスト、イシュー、またはエピックで、ユーザーがコメントとして入力するプロンプト

## GitLabとのインテグレーション {#integrated-with-gitlab}

次のエージェントは、GitLabとインテグレーションされており、GitLab.comで利用可能です。

### Amazon Q {#amazon-q}

AWS認証情報をハードコードされた状態にする代わりに、AWSシークレットマネージャーに保存します。そうすれば、YAMLファイルでそれらを参照できます。

1. コンソールアクセス権を持たない[IAMユーザーを作成](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)します。
1. プログラムによるアクセスのためのアクセスキーペアを生成します。
1. GitLab Runnerがホストされているのと同じAWSアカウントで、AWSシークレットマネージャーにシークレットを作成します。次のJSON形式を使用します:

   ```json
   {
     "q-cli-access-token": {"AWS_ACCESS_KEY_ID": "AKIA...", "AWS_SECRET_ACCESS_KEY": "abc123..."}
   }
   ```

   重要: プレースホルダーの値を実際のアクセスキーIDとシークレットアクセスキーに置き換えます。

1. AWSシークレットマネージャーにアクセスするための権限をGitLab Runner IAMロールに付与します。
1. 次のようなフロー設定ファイルを作成します。

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
  - echo "Installing Python"
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

    When you check in and push code you will need to use the access token stored in GITLAB_TOKEN and the user AmazonQ Code.
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

### Anthropic Claude {#anthropic-claude}

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

### Google Geminiコマンドラインインターフェース {#google-gemini-cli}

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

    When you check in and push code you will need to use the access token stored in GITLAB_TOKEN and the user Gemini.
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

## 独自のキーを持ち込む {#bring-your-own-keys}

次のインテグレーションでは、GitLabからモデルで認証するために、独自のキーを持ち込む必要があります。

### Opencode {#opencode}

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

    When you check in and push code, you will need to use the access token stored in GITLAB_TOKEN and the user Opencode.
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

### Cursorコマンドラインインターフェース {#cursor-cli}

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

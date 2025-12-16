---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CLIエージェント
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: いいえ

{{< /collapsible >}}

{{< history >}}

- GitLab 18.3で`ai_flow_triggers`[フラグ](../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duoエージェントは並行して動作し、コードの作成、調査結果の検索、およびタスクの同時実行を支援します。

コマンドラインインターフェース（CLI）エージェントを作成し、サードパーティのAIモデルプロバイダーとインテグレーションして、組織のニーズに合わせてCLIエージェントをカスタマイズできます。独自のAPIキーを使用して、モデルプロバイダーとインテグレーションします。

次に、プロジェクトイシュー、エピック、またはマージリクエストで、コメントまたはディスカッションでそのCLIエージェントに言及し、CLIエージェントにタスクの完了を依頼できます。

CLIエージェント:

- 周囲のコンテキストとリポジトリコードを読み取り、分析します。
- プロジェクトの権限を遵守し、監査証跡を維持しながら、実行する適切なアクションを決定します。
- CI/CDパイプラインを実行し、すぐにマージできる変更またはインラインコメントのいずれかでGitLab内で応答します。

GitLabでテスト済みで、利用可能なサードパーティのインテグレーションを以下に示します:

- [Anthropic Claude](https://docs.anthropic.com/en/docs/claude-code/overview)
- [OpenAI Codex](https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started)
- [Opencode](https://opencode.ai/docs/gitlab/)
- [Amazon Q](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)
- [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)

## 前提要件 {#prerequisites}

CLIエージェントを作成し、サードパーティのAIモデルプロバイダーとインテグレーションする前に、以下を行う必要があります:

### GitLab環境を構成する {#configure-your-gitlab-environment}

- [ベータ](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)版および実験的な機能をオンにします。
- [GitLab Duoを有効にする](../gitlab_duo/turn_on_off.md)。
- [割り当て済みシート](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)を持つGitLab Duo Enterpriseが必要です。
- Ultimateプランのサブスクリプションがある[グループネームスペース](../namespace/_index.md)に属するプロジェクトが必要です。

### CI/CDをセットアップする {#set-up-cicd}

タスクの完了時に、CLIエージェントがCI/CDパイプラインを実行します。

GitLab Self-ManagedまたはGitLab Dedicatedを使用している場合は、[GitLab Runnerを作成して登録する](../../tutorials/create_register_first_runner/_index.md)必要があります。

### AIモデルプロバイダーの認証情報 {#ai-model-provider-credentials}

CLIエージェントをサードパーティのAIモデルプロバイダーとインテグレーションするには、アクセス認証情報が必要です。そのモデルプロバイダーのAPIキーまたはGitLabマネージド認証情報を使用できます。

#### APIキー {#api-keys}

CLIエージェントをサードパーティのAIモデルプロバイダーとインテグレーションするには、そのモデルプロバイダーのAPIキーを使用できます:

- Anthropic ClaudeとOpencodeの場合は、[Anthropic APIキー](https://docs.anthropic.com/en/api/admin-api/apikeys/get-api-key)を使用します。
- OpenAI Codexの場合は、[OpenAI APIキー](https://platform.openai.com/docs/api-reference/authentication)を使用します。

#### GitLabマネージド認証情報 {#gitlab-managed-credentials}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567791)されました。

{{< /history >}}

サードパーティのAIモデルプロバイダーに独自のAPIキーを使用する代わりに、AIゲートウェイを介してGitLabマネージド認証情報を使用するようにCLIエージェントを構成できます。これにより、APIキーを自分で管理およびローテーションする必要がなくなります。

GitLabマネージド認証情報を使用する場合:

- フロー設定ファイルで`injectGatewayToken: true`を設定します。
- CI/CD変数からAPIキー変数（たとえば、`ANTHROPIC_API_KEY`）を削除します。
- GitLab AIゲートウェイプロキシエンドポイントを使用するようにCLIエージェントを構成します。

次の環境変数は、`injectGatewayToken`が`true`の場合に自動的にインラインで挿入されます:

- `AI_FLOW_AI_GATEWAY_TOKEN`: AIゲートウェイの認証トークン
- `AI_FLOW_AI_GATEWAY_HEADERS`: APIリクエスト用にフォーマットされたヘッダー

GitLabマネージド認証情報は、Anthropic ClaudeおよびCodexでのみ使用できます。

## サービスアカウントを作成する {#create-a-service-account}

前提要件: 

- GitLab.comでは、プロジェクトが属するトップレベルグループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedでは、次のいずれかが必要です:
  - インスタンスへの管理者アクセス。
  - トップレベルグループのオーナーロールと[サービスアカウントを作成する権限](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)。

CLIエージェントに言及する各プロジェクトには、一意の[サービスアカウント](../../user/profile/service_accounts.md)が存在する必要があります。サービスアカウントのユーザー名は、CLIエージェントにタスクを与えるときに言及する名前です。

{{< alert type="warning" >}}

複数のプロジェクトで同じサービスアカウントを使用すると、そのサービスアカウントに接続されているCLIエージェントはそれらのすべてのプロジェクトにアクセスできるようになります。

{{< /alert >}}

サービスアカウントをセットアップするには、次のアクションを実行します。権限が十分にない場合は、インスタンスの管理者またはトップレベルグループのオーナーに支援を求めてください。

1. [サービスアカウントを作成](../../user/profile/service_accounts.md#create-a-service-account)します。
1. 次の[スコープ](../../user/profile/personal_access_tokens.md#personal-access-token-scopes)で、[サービスアカウントのパーソナルアクセストークンを作成する](../../user/profile/service_accounts.md#create-a-personal-access-token-for-a-service-account):
   - `write_repository`
   - `api`
   - `ai_features`
1. デベロッパーロールを使用して、[サービスアカウントをプロジェクトに追加する](../../user/project/members/_index.md#add-users-to-a-project)。これにより、サービスアカウントに必要な最小限の権限が付与されます。

サービスアカウントをプロジェクトに追加するときは、サービスアカウントの正確な名前を入力する必要があります。間違った名前を入力すると、CLIエージェントは機能しません。

## CI/CD変数を構成する {#configure-cicd-variables}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

次のCI/CD変数をプロジェクト設定に追加します:

| インテグレーション                | 環境変数         | 説明 |
|----------------------------|------------------------------|-------------|
| すべて                        | `GITLAB_TOKEN_<integration>` | サービスアカウントユーザーのパーソナルアクセストークン。 |
| すべて                        | `GITLAB_HOST`                | GitLabインスタンスのホスト名（たとえば、`gitlab.com`）。 |
| Anthropic Claude、Opencode | `ANTHROPIC_API_KEY`          | Anthropic APIキー（`injectGatewayToken: true`が設定されている場合はオプション）。 |
| OpenAI Codex               | `OPENAI_API_KEY`             | OpenAI APIキー。 |
| Amazon Q                   | `AWS_SECRET_NAME`            | AWSシークレットマネージャーのシークレット名。 |
| Amazon Q                   | `AWS_REGION_NAME`            | AWSリージョン名。 |
| Amazon Q                   | `AMAZON_Q_SIGV4`             | AWS Q Sig V4認証情報。 |
| Google Gemini CLI          | `GOOGLE_CREDENTIALS`         | JSON認証情報ファイルの内容。 |
| Google Gemini CLI          | `GOOGLE_CLOUD_PROJECT`       | Google CloudプロジェクトID。 |
| Google Gemini CLI          | `GOOGLE_CLOUD_LOCATION`      | Google Cloudプロジェクトの場所。 |

プロジェクト設定で変数を追加または更新するには、次の手順に従ってください:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加する**を選択し、フィールドに入力します:
   - **種類**: **変数（デフォルト）**を選択します。
   - **環境**: **すべて（デフォルト）**を選択します。
   - **表示レベル**: 目的の表示レベルを選択します。

     APIキーとパーソナルアクセストークンの変数の場合は、**マスクする**または**マスクして非表示**を選択します。
   - **変数の保護**チェックボックスをオフにします。
   - **変数参照を展開**チェックボックスをオフにします。
   - **説明（オプション）**: 変数の説明を入力します。
   - **キー**: CI/CD変数の環境変数名を入力します（たとえば、`GITLAB_HOST`）。
   - **値**: APIキー、パーソナルアクセストークン、またはホストの値。
1. **変数を追加する**を選択します。

詳細については、[プロジェクトの設定にCI/CD変数を追加する](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)方法を参照してください。

## フロー設定ファイルを作成する {#create-a-flow-configuration-file}

前提要件: 

- プロジェクトのデベロッパーロール以上を持っている必要があります。

GitLabが環境のCLIエージェントを実行する方法を指示するには、プロジェクトで、フロー設定ファイルを作成します。たとえば`.gitlab/duo/flows/claude.yaml`などです。

CLIエージェントごとに異なるAIフロー設定ファイルを作成する必要があります。

### サンプルフロー設定ファイル {#example-flow-configuration-files}

次のサンプルを使用して、フロー設定ファイルを作成します。これらのサンプルには、次の変数が含まれています:

- `AI_FLOW_CONTEXT`: JSONシリアル化された親オブジェクト。以下を含みます:
  - マージリクエストでは、差分とコメント（制限付き）
  - イシューまたはエピックでは、コメント（制限付き）
- `$AI_FLOW_EVENT`: フローイベントのタイプ（たとえば、`mention`）
- `$AI_FLOW_INPUT`: ユーザーがマージリクエスト、イシュー、またはエピックにコメントとして入力するプロンプト

#### Anthropic Claude {#anthropic-claude}

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

#### OpenAI Codex {#openai-codex}

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

#### Opencode {#opencode}

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

#### AWS Q {#amazon-q}

AWS認証情報をハードコードされた値にする代わりに、AWSシークレットマネージャーに保存します。次に、YAMLファイルでそれらを参照できます。

1. コンソールアクセス権を持たない[IAMユーザーを作成](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)します。
1. プログラムによるアクセスのアクセスキーペアを生成します。
1. GitLabランナーがホストされている同じAWSアカウントで、AWSシークレットマネージャーにシークレットを作成します。次のJSON形式を使用します:

   ```json
   {
     "q-cli-access-token": {"AWS_ACCESS_KEY_ID": "AKIA...", "AWS_SECRET_ACCESS_KEY": "abc123..."}
   }
   ```

   重要: プレースホルダーの値を実際のアクセスキーIDとシークレットアクセスキーに置き換えます。

1. AWSシークレットマネージャーにアクセスする権限をGitLabランナーIAMロールに付与します。
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

#### Google Gemini CLI {#google-gemini-cli}

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

#### Cursor CLI {#cursor-cli}

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

## フロートリガーを作成する {#create-a-flow-trigger}

{{< history >}}

- **アサイン**および**レビュアーをアサインする**イベントタイプは、GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)されました。

{{< /history >}}

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

フロートリガーは、サービスアカウント、フロー設定ファイル、およびユーザーがCLIエージェントをトリガーするために行うアクションをリンクします。

フロートリガーを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **flowトリガー**を選択します。
1. **新しいフロートリガー**を選択します。
1. **説明**に、フロートリガーの説明を入力します。
1. **イベントタイプ**ドロップダウンリストから、1つまたは複数のイベントタイプを選択します:
   - **Mention**（メンション）: サービスアカウントユーザーがイシューまたはマージリクエストのコメントで言及されている場合。
   - **アサイン**: サービスアカウントユーザーがイシューまたはマージリクエストに割り当てられている場合。
   - **レビュアーをアサインする**: サービスアカウントユーザーがマージリクエストにレビュアーとして割り当てられている場合。
1. **サービスアカウントユーザー**ドロップダウンリストから、サービスアカウントユーザーを選択します。
1. **Configuration source**（構成ソース）で、次のいずれかを選択します:
   - **AIカタログ**: このプロジェクト用に構成されたフローから、トリガーを実行するフローを選択します。
   - **Configuration path**（構成パス）: フロー設定ファイルへのパスを入力します（たとえば、`.gitlab/duo/flows/claude.yaml`）。
1. **flowトリガーの作成**を選択します。

フロートリガーが**自動化** > **flowトリガー**に表示されるようになりました。

タスクを達成するために、コメントでサービスアカウントのユーザー名でCLIエージェントに言及できるようになりました。次に、CLIエージェントは、ユーザーが定義したフロートリガーを使用して、そのタスクを達成しようとします。

### フロートリガーを編集する {#edit-a-flow-trigger}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **flowトリガー**を選択します。
1. 変更するフロートリガーについて、**flowトリガーの編集**（{{< icon name="pencil" >}}）を選択します。
1. 変更を加え、**変更を保存**を選択します。

### フロートリガーを削除する {#delete-a-flow-trigger}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **flowトリガー**を選択します。
1. 変更するフロートリガーについて、**flowトリガーの削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**OK**を選択します。

## CLIエージェントを使用する {#use-the-cli-agent}

前提要件: 

- プロジェクトのデベロッパーロール以上を持っている必要があります。

1. プロジェクトで、イシュー、マージリクエスト、またはエピックを開きます。
1. CLIエージェントに完了させたいタスクにコメントを追加し、サービスアカウントユーザーに言及します。例: 

   ```markdown
   @service-account-username can you help analyze this code change?
   ```

1. コメントの下に、CLIエージェントは**Processing the request and starting the agent...**（リクエストを処理し、エージェントを開始しています...）と応答します。
1. CLIエージェントが動作している間、コメント**エージェントが開始されました。ここに進捗状況が表示されます**が表示されます。**here**（ここ）を選択すると、進行中のパイプラインを確認できます。
1. CLIエージェントがタスクを完了すると、確認が表示され、すぐにマージできる変更またはインラインコメントが表示されます。

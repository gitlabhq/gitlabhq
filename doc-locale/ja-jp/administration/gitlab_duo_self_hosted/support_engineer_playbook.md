---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo Self-Hostedのトラブルシューティングのヒント
title: GitLab Duo Self-Hostedサポートエンジニアプレイブック
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/epics/15176)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
- 機能フラグ`ai_custom_model`は、GitLab 17.8で削除されました。
- GitLab 17.9で一般提供になりました。
- GitLab 18.0でPremiumを含むように変更されました。

{{< /history >}}

## サポートエンジニア向けプレイブックと一般的な問題 {#support-engineer-playbook-and-common-issues}

このセクションでは、GitLab Duo Self-Hostedの問題をデバッグするための重要なコマンドとトラブルシューティング手順をサポートエンジニアに提供します。

## 基本的なデバッグコマンド {#essential-debugging-commands}

### AIゲートウェイ環境変数を表示する {#display-ai-gateway-environment-variables}

すべてのAIゲートウェイ環境変数をチェックして、設定を検証します:

```shell
docker exec -it <ai-gateway-container> env | grep AIGW
```

確認すべき主要な変数:

- `AIGW_CUSTOM_MODELS__ENABLED` - `true`である必要があります
- `AIGW_GITLAB_URL` - GitLabインスタンスのURLと一致する必要があります
- `AIGW_GITLAB_API_URL` - コンテナからアクセスできる必要があります
- `AIGW_AUTH__BYPASS_EXTERNAL` - トラブルシューティング中にのみ`true`である必要があります

### ユーザー権限を検証する {#verify-user-permissions}

セルフホストモデルでのコード提案について、ユーザーが正しい権限を持っているか確認します:

```ruby
# In GitLab Rails console
user = User.find_by_id("<user_id>")
user.allowed_to_use?(:code_suggestions, service_name: :self_hosted_models)
```

### AIゲートウェイクライアントログを調べる {#examine-ai-gateway-client-logs}

AIゲートウェイクライアントログを表示して、接続の問題を特定します:

```shell
docker logs <ai-gateway-container> | grep "Gitlab::Llm::AiGateway::Client"
```

### AIゲートウェイリクエストに関するGitLabログを表示する {#view-gitlab-logs-for-ai-gateway-requests}

AIゲートウェイに対して実際に行われたリクエストを確認するには、以下を使用します:

```shell
# View live logs
sudo gitlab-ctl tail | grep -E "(ai_gateway|llm\.log)"

# View specific log file with JSON formatting
sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq '.'

# Filter for specific request types
 sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq 'select(.message)'

 sudo cat /var/log/gitlab/gitlab-rails/llm.log | grep Llm::CompletionWorker | jq '.'
```

### モデルリクエストに関するAIゲートウェイログを表示する {#view-ai-gateway-logs-for-model-requests}

モデルに送信された実際のリクエストを確認するには:

```shell
# View AI Gateway container logs
docker logs <ai-gateway-container> 2>&1 | grep -E "(model|litellm|custom_openai)"

# For structured logs, if available
docker logs <ai-gateway-container> 2>&1 | grep "model_endpoint"
```

## 一般的な設定の問題と解決策 {#common-configuration-issues-and-solutions}

### モデルエンドポイントに`/v1`サフィックスが欠落している {#missing-v1-suffix-in-model-endpoint}

**現象**: vLLMまたはOpenAI互換モデルにリクエストを行う際の404エラー

**ログでの確認方法**:

```shell
# Look for 404 errors in AI Gateway logs
docker logs <ai-gateway-container> | grep "404"
```

**解決策**: モデルエンドポイントに`/v1`サフィックスが含まれていることを確認する:

- 誤: `http://localhost:4000`
- 正: `http://localhost:4000/v1`

### 証明書の検証の問題 {#certificate-validation-issues}

**現象**: SSL証明書エラーまたは接続失敗

**ログでの確認方法**:

```shell
# Look for SSL/TLS errors
sudo cat /var/log/gitlab/gitlab-rails/llm.log | grep -i "ssl\|certificate\|tls"
```

**検証**: 証明書のステータスを検証する - GitLabサーバーは信頼された証明書を使用する必要があります。自己署名証明書はサポートされていません。

**解決策**: 

- GitLabインスタンスに信頼された証明書を使用する
- 自己署名証明書を使用する場合は、AIゲートウェイコンテナで適切な証明書パスを設定する

### ネットワーク接続の問題 {#network-connectivity-issues}

**現象**: タイムアウトまたは接続拒否エラー

**ログでの確認方法**:

```shell
# Look for network-related errors
docker logs <ai-gateway-container> | grep -E "(timeout|connection|refused|unreachable)"
```

**検証コマンド**:

```shell
# Test from AI Gateway container to GitLab
docker exec -it <ai-gateway-container> curl "$AIGW_GITLAB_API_URL/projects"

# Test from AI Gateway container to model endpoint
docker exec -it <ai-gateway-container> curl "<model_endpoint>/health"
```

### 認証と認可の問題 {#authentication-and-authorization-issues}

**現象**: 401 Unauthorizedまたは403 Forbiddenエラー

**ログでの確認方法**:

```shell
# Look for authentication errors
sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq 'select(.status == 401 or .status == 403)'
```

**一般的な原因**:

- ユーザーにGitLab Duo Enterpriseのシートが割り当てられていない
- ライセンスの問題
- AIゲートウェイURLの設定が正しくない

### モデル設定の問題 {#model-configuration-issues}

**現象**: モデルが応答しない、またはエラーを返す

**ログでの確認方法**:

```shell
# Look for model-specific errors
docker logs <ai-gateway-container> | grep -E "(model_name|model_endpoint|litellm)"
```

**検証**: 

```shell
# Test model directly from AI Gateway container
docker exec -it <ai-gateway-container> sh
curl --request POST "<model_endpoint>/v1/chat/completions" \
     --header 'Content-Type: application/json' \
     --data '{"model": "<model_name>", "messages": [{"role": "user", "content": "Hello"}]}'
```

## ログ分析ワークフロー {#log-analysis-workflow}

### ステップ1: 詳細ログの有効化 {#step-1-enable-verbose-logging}

**管理者 > GitLab Duo > Change Configuration**で、**AIログの有効化**にチェックが入っているか確認します。このインスタンスレベルの設定は、GitLab Railsコンソールで`enabled_instance_verbose_ai_logs`をtrueに設定するのと同じです:

```ruby
::Ai::Setting.instance.enabled_instance_verbose_ai_logs
```

`false`が返された場合は、以下を使用してフラグを有効にします:

```ruby
::Ai::Setting.instance.update!(enabled_instance_verbose_ai_logs: true)
```

> [!note]ロギングを有効にするには、`enabled_instance_verbose_ai_logs`UIまたはRailsコンソールでインスタンス設定を使用します。`expanded_ai_logging`機能フラグは使用しないでください。`expanded_ai_logging`機能フラグは、デバッグ目的でGitLab.comでのみ使用してください。GitLab Self-Managedインスタンス（GitLab Duo Self-Hostedを実行しているインスタンスを含む）では、`expanded_ai_logging`を使用しないでください。

### ステップ2: 問題の再現 {#step-2-reproduce-the-issue}

ログをモニタリングしながら、ユーザーに問題を再現してもらいます:

```shell
# Terminal 1: Monitor GitLab logs
sudo gitlab-ctl tail | grep -E "(ai_gateway|llm\.log)"

# Terminal 2: Monitor AI Gateway logs
docker logs -f <ai-gateway-container>
```

### ステップ3: リクエストフローの分析 {#step-3-analyze-request-flow}

1. **GitLabからAIゲートウェイへ**: リクエストがAIゲートウェイに到達するかを確認します
1. **AIゲートウェイからモデルへ**: モデルエンドポイントが呼び出されるかを確認します
1. **レスポンスパス**: レスポンスが適切にフォーマットされ、返されるかを確認します

### ステップ4: 一般的なエラーパターン {#step-4-common-error-patterns}

| エラーパターン | 場所 | 考えられる原因 |
|---------------|----------|--------------|
| `Connection refused` | GitLabログ | AIゲートウェイにアクセスできない |
| `404 Not Found` | AIゲートウェイログ | モデルエンドポイントに`/v1`がない |
| `401 Unauthorized` | GitLabログ | 認証/ライセンスの問題 |
| `Timeout` | いずれか | ネットワークまたはモデルのパフォーマンスの問題 |
| `SSL certificate verify failed` | GitLabログ | 証明書の検証の問題 |

## クイック診断コマンド {#quick-diagnostic-commands}

## **AIゲートウェイインスタンスコマンド:** {#ai-gateway-instance-commands}

**1. AIゲートウェイのヘルスをテストする:**

```shell
curl --silent --output /dev/null --write-out "%{http_code}" "<ai-gateway-url>/monitoring/healthz"
```

**2. AIゲートウェイの環境変数を確認する:**

```shell
docker exec <ai-gateway-container> env | grep AIGW
```

**3. AIゲートウェイログでエラーを確認する:**

```shell
docker logs <ai-gateway-container> 2>&1 | grep --ignore-case error | tail --lines=20
```

## **GitLab Self-Managedインスタンスコマンド:** {#gitlab-self-managed-instance-commands}

**4. ユーザー権限を確認します（GitLab Railsコンソール）:**

```shell
sudo gitlab-rails console
```

次に、コンソールで:

```ruby
User.find_by_id('<user_id>').can?(:access_code_suggestions)
```

**5. GitLab LLMログでエラーを確認します:**

```shell
sudo tail --lines=100 /var/log/gitlab/gitlab-rails/llm.log | grep --ignore-case error
```

**6. 機能フラグを確認します:**

```shell
sudo gitlab-rails console
```

次に:

```ruby
Feature.enabled?(:expanded_ai_logging)
```

**7. GitLabからAIゲートウェイへの接続をテストする:**

```shell
curl --verbose "<ai-gateway-url>/monitoring/healthz"
```

### 緊急診断ワンライナー {#emergency-diagnostic-one-liner}

迅速な問題特定のため:

```shell
# Check all critical components at once
docker exec <ai-gateway-container> env | grep AIGW_CUSTOM_MODELS__ENABLED && \
curl --silent "<ai-gateway-url>/monitoring/healthz" && \
sudo tail --lines=10 /var/log/gitlab/gitlab-rails/llm.log | jq '.level'
```

## エスカレーション基準 {#escalation-criteria}

以下の場合、カスタムモデルチームにエスカレーションします:

1. **基本的なトラブルシューティング手順がすべて完了している**が、解決しない場合
1. 高度な技術知識を必要とする**モデルインテグレーションの問題**
1. セルフホストモデルのunit primitiveに**記載されていない機能**
1. 複数のユーザーに影響を与える**疑わしいGitLab Duoプラットフォームのバグ**
1. 特定のモデル設定での**パフォーマンスの問題**

## 追加リソース {#additional-resources}

- [AIゲートウェイインストールガイド](../../install/install_ai_gateway.md)
- [GitLab Duo Self-Hostedのトラブルシューティング](troubleshooting.md)

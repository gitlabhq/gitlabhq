---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duoセルフホストのトラブルシューティングのヒント
title: GitLab Duo Self-Hostedサポートエンジニアプレイブック
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176)で有効になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.8で機能フラグ`ai_custom_model`は削除されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

## サポートエンジニアプレイブックと一般的なイシュー {#support-engineer-playbook-and-common-issues}

このセクションでは、サポートエンジニアがGitLab Duoセルフホストの問題をデバッグするための重要なコマンドとトラブルシューティング手順について説明します。

## 重要なデバッグコマンド {#essential-debugging-commands}

### AIゲートウェイ環境変数の表示 {#display-ai-gateway-environment-variables}

すべてのAIゲートウェイ環境変数をチェックして、設定を検証します:

```shell
docker exec -it <ai-gateway-container> env | grep AIGW
```

確認すべきキーとなる変数:

- `AIGW_CUSTOM_MODELS__ENABLED`は`true`trueである必要があります。
- `AIGW_GITLAB_URL` - GitLabインスタンスのURLと一致する必要があります
- `AIGW_GITLAB_API_URL` - コンテナからアクセスできる必要があります
- `AIGW_AUTH__BYPASS_EXTERNAL` - トラブルシューティング中にのみ`true`である必要があります

### ユーザー権限の検証 {#verify-user-permissions}

ユーザーがセルフホストモデルでコード提案の正しいユーザー権限を持っているかどうかを確認します:

```ruby
# In GitLab Rails console
user = User.find_by_id("<user_id>")
user.allowed_to_use?(:code_suggestions, service_name: :self_hosted_models)
```

### AIゲートウェイクライアントログの調査 {#examine-ai-gateway-client-logs}

AIゲートウェイのクライアントログを表示して、接続の問題を特定します:

```shell
docker logs <ai-gateway-container> | grep "Gitlab::Llm::AiGateway::Client"
```

### AIゲートウェイリクエストのGitLabログの表示 {#view-gitlab-logs-for-ai-gateway-requests}

AIゲートウェイへの実際のリクエストを確認するには、以下を使用します:

```shell
# View live logs
sudo gitlab-ctl tail | grep -E "(ai_gateway|llm\.log)"

# View specific log file with JSON formatting
sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq '.'

# Filter for specific request types
 sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq 'select(.message)'

 sudo cat /var/log/gitlab/gitlab-rails/llm.log | grep Llm::CompletionWorker | jq '.'
```

### モデルリクエストのAIゲートウェイログの表示 {#view-ai-gateway-logs-for-model-requests}

モデルに送信された実際のリクエストを確認するには:

```shell
# View AI Gateway container logs
docker logs <ai-gateway-container> 2>&1 | grep -E "(model|litellm|custom_openai)"

# For structured logs, if available
docker logs <ai-gateway-container> 2>&1 | grep "model_endpoint"
```

## 一般的な設定の問題と解決策 {#common-configuration-issues-and-solutions}

### モデルエンドポイントの`/v1`サフィックスの欠落 {#missing-v1-suffix-in-model-endpoint}

**Symptom**（現象）: vLLMまたはOpenAI互換モデルにリクエストを行う際の404エラー

**How to spot in logs**（ログでの確認方法）:

```shell
# Look for 404 errors in AI Gateway logs
docker logs <ai-gateway-container> | grep "404"
```

**解決策**: モデルエンドポイントに`/v1`サフィックスが含まれていることを確認します:

- 誤った例: `http://localhost:4000`
- 正しい例: `http://localhost:4000/v1`

### 証明書の検証の問題 {#certificate-validation-issues}

**Symptom**（現象）: SSL証明書エラーまたは接続障害

**How to spot in logs**（ログでの確認方法）:

```shell
# Look for SSL/TLS errors
sudo cat /var/log/gitlab/gitlab-rails/llm.log | grep -i "ssl\|certificate\|tls"
```

**Validation**（検証）: 証明書のステータスを検証します - GitLabサーバーは、自己署名証明書がサポートされていないため、信頼できる証明書を使用する必要があります。

**解決策**: 

- GitLabインスタンスに信頼できる証明書を使用する
- 自己署名証明書を使用している場合は、AIゲートウェイコンテナで適切な証明書パスを設定します

### ネットワーク接続の問題 {#network-connectivity-issues}

**Symptom**（現象）: タイムアウトまたは接続拒否エラー

**How to spot in logs**（ログでの確認方法）:

```shell
# Look for network-related errors
docker logs <ai-gateway-container> | grep -E "(timeout|connection|refused|unreachable)"
```

**Validation commands**（検証コマンド）:

```shell
# Test from AI Gateway container to GitLab
docker exec -it <ai-gateway-container> curl "$AIGW_GITLAB_API_URL/projects"

# Test from AI Gateway container to model endpoint
docker exec -it <ai-gateway-container> curl "<model_endpoint>/health"
```

### 認証と認可の問題 {#authentication-and-authorization-issues}

**Symptom**（現象）: 401 Unauthorizedまたは403 Forbiddenエラー

**How to spot in logs**（ログでの確認方法）:

```shell
# Look for authentication errors
sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq 'select(.status == 401 or .status == 403)'
```

**Common causes**（一般的な原因）:

- ユーザーにGitLab Duo Enterpriseのシートが割り当てられていません
- ライセンスの問題
- AIゲートウェイURLの設定が正しくありません

### モデル設定の問題 {#model-configuration-issues}

**Symptom**（現象）: モデルが応答しないか、エラーを返しています

**How to spot in logs**（ログでの確認方法）:

```shell
# Look for model-specific errors
docker logs <ai-gateway-container> | grep -E "(model_name|model_endpoint|litellm)"
```

**Validation**（検証）:

```shell
# Test model directly from AI Gateway container
docker exec -it <ai-gateway-container> sh
curl --request POST "<model_endpoint>/v1/chat/completions" \
     --header 'Content-Type: application/json' \
     --data '{"model": "<model_name>", "messages": [{"role": "user", "content": "Hello"}]}'
```

## ログ分析ワークフロー {#log-analysis-workflow}

### ステップ1: 詳細ログの有効化 {#step-1-enable-verbose-logging}

GitLab Railsコンソールで、`Capture detailed information about AI-related activities and requests`インスタンス設定が有効になっているかどうかを確認します:

```ruby
::Ai::Setting.instance.enabled_instance_verbose_ai_logs
```

`false`が返された場合は、以下を使用してフラグを有効にします:

```ruby
::Ai::Setting.instance.update!(enabled_instance_verbose_ai_logs: true)
```

{{< alert type="note" >}}

ログを有効にするには、`enabled_instance_verbose_ai_logs`インスタンス設定を使用します。`expanded_ai_logging`機能フラグは使用しないでください。デバッグを目的として、GitLab.comでのみ`expanded_ai_logging`機能フラグを使用してください。GitLab Duoセルフホストを実行しているインスタンスを含む、GitLab Self-Managedインスタンスでは、この機能フラグを使用しないでください。

{{< /alert >}}

### ステップ2: 問題の再現 {#step-2-reproduce-the-issue}

ログをモニタリングしながら、ユーザーに問題を再現してもらいます:

```shell
# Terminal 1: Monitor GitLab logs
sudo gitlab-ctl tail | grep -E "(ai_gateway|llm\.log)"

# Terminal 2: Monitor AI Gateway logs
docker logs -f <ai-gateway-container>
```

### ステップ3: リクエストフローの分析 {#step-3-analyze-request-flow}

1. **GitLab to AI Gateway**（GitLabからAIゲートウェイへ）: リクエストがAIゲートウェイに到達するかどうかを確認します
1. **AI Gateway to Model**（AIゲートウェイからモデルへ）: モデルエンドポイントが呼び出すされることを確認します
1. **Response Path**（応答パス）: 応答が適切にフォーマットされ、返されることを確認します

### ステップ4: 一般的なエラーパターン {#step-4-common-error-patterns}

| エラーパターン | 場所 | 考えられる原因 |
|---------------|----------|--------------|
| `Connection refused` | GitLabログ | AIゲートウェイにアクセスできません |
| `404 Not Found` | AIゲートウェイのログ | モデルエンドポイントに`/v1`がない |
| `401 Unauthorized` | GitLabログ | 認証・ライセンスの問題 |
| `Timeout` | いずれか | ネットワークまたはモデルのパフォーマンスの問題 |
| `SSL certificate verify failed` | GitLabログ | 証明書の検証の問題 |

## クイック診断コマンド {#quick-diagnostic-commands}

## **AI Gateway Instance Commands:**（AIゲートウェイインスタンスコマンド） {#ai-gateway-instance-commands}

**1\.AIゲートウェイのヘルスをテストします：**

```shell
curl --silent --output /dev/null --write-out "%{http_code}" "<ai-gateway-url>/monitoring/healthz"
```

**2\.AIゲートウェイの環境変数を確認します：**

```shell
docker exec <ai-gateway-container> env | grep AIGW
```

**3\.AIゲートウェイログでエラーを確認します：**

```shell
docker logs <ai-gateway-container> 2>&1 | grep --ignore-case error | tail --lines=20
```

## **GitLab Self-Managed Instance Commands:**（GitLab Self-Managedインスタンスコマンド） {#gitlab-self-managed-instance-commands}

**4\.ユーザーユーザー権限の確認（GitLab Railsコンソール）：**

```shell
sudo gitlab-rails console
```

次に、コンソールで:

```ruby
User.find_by_id('<user_id>').can?(:access_code_suggestions)
```

**5\.GitLab大規模言語モデルログでエラーを確認します：**

```shell
sudo tail --lines=100 /var/log/gitlab/gitlab-rails/llm.log | grep --ignore-case error
```

**6\.機能フラグの確認：**

```shell
sudo gitlab-rails console
```

次に:

```ruby
Feature.enabled?(:expanded_ai_logging)
```

**7\.GitLabからAIゲートウェイへの接続をテストします：**

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

1. **All basic troubleshooting steps completed**（基本的なトラブルシューティング手順がすべて完了している）が、解決しない場合
1. 高度な技術知識を必要とする**Model integration issues**（モデルインテグレーションの問題）
1. **Feature not listed**（セルフホストモデルユニットのプリミティブにリストされていない機能）
1. 複数のユーザーに影響を与える**Suspected GitLab Duo platform bugs**（疑わしいGitLab Duoプラットフォームのバグ）
1. 特定なモデル設定での**Performance issues**（パフォーマンスの問題）

## 追加リソース {#additional-resources}

- [AIゲートウェイインストールガイド](../../install/install_ai_gateway.md)
- [GitLab Duoセルフホストトラブルシューティング](troubleshooting.md)

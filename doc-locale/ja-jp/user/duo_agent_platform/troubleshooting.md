---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Agent Platformの一般的なフロー、パーミッション、プッシュルールの設定に関する問題のトラブルシューティングを行います。
title: GitLab Duo Agent Platformのトラブルシューティング
---

GitLab Duo Agent Platformを使用している場合、次の問題が発生する可能性があります。

## ログを表示する {#view-logs}

フローが作成された後、**AI** > **セッション**に移動してフローのセッションを表示できます。

**詳細**タブには、CI/CDジョブログへのリンクが表示されます。これらのログには、トラブルシューティング情報が含まれている場合があります。

## UIにフローが表示されない {#flows-not-visible-in-the-ui}

フローを実行しようとしてもGitLab UIに表示されない場合、次のことを確認してください:

1. プロジェクトのデベロッパーロール以上を持っている。
1. GitLab Duoが[オンになっており、フローの実行が許可されている](../gitlab_duo/turn_on_off.md)。
1. あなたがいるグループが[フローを使用する](../../administration/gitlab_duo/configure/access_control.md)許可を与えられていることを確認してください。
1. トップレベルグループが正しく設定されているにもかかわらず、個々のプロジェクトでフローが表示されない場合:
   1. プロジェクトに移動します。
   1. **AI** > **フロー**を選択します。
   1. 右上隅で、**グループからのフローを有効にする**を選択します。
   1. フローを選択し、**有効**を選択します。

1. それでも動作しない場合は、次の手順を試してください:
   1. トップレベルグループで該当するフローを無効にし、設定を保存します。
   1. トップレベルグループで該当するフローを有効にし、設定を保存します。
   1. 設定がグループ全体に反映されるまで、数分待ちます。

## インポートされたプロジェクト用の新しいパイプラインを作成する権限が不十分です {#insufficient-permissions-to-create-a-new-pipeline-for-imported-projects}

インポートされたプロジェクトまたはテンプレートから作成されたプロジェクトで基本フローを実行しようとすると、次のエラーが表示されることがあります: `Error in creating workload: Insufficient permissions to create a new pipeline`

この問題を解決するには:

1. トップレベルグループに移動します。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **フローの実行**で、有効にしたい基本フローを特定します。
1. トップレベルグループでフローを無効にし、設定を保存します。
1. トップレベルグループで同じフローを有効にし、設定を保存します。
1. グループ内のプロジェクト全体に設定が反映されるまで数分待ちます。

## エラー: `Your request was valid but Workflow failed to complete it` {#error-your-request-was-valid-but-workflow-failed-to-complete-it}

フローには、プロジェクトリポジトリに少なくとも1つのコミットが必要です。コミットがないプロジェクトでフローを実行すると、次のエラーが表示されます: `Your request was valid but Workflow failed to complete it. Please try again.`

このエラーは、フローがコミットのないリポジトリでデフォルトブランチを見つけられないために発生します。

この問題を修正するには、フローを実行する前に初期コミットをプロジェクトにプッシュする必要があります。たとえば、`README.md`ファイルを追加します。

## セッションが作成済みステータスで停止している {#session-is-stuck-in-created-state}

フローのセッションが開始されない場合、次のことを確認してください:

- プッシュルールが設定されていること。

### サービスアカウントを許可するようにプッシュルールを設定する {#configure-push-rules-to-allow-a-service-account}

GitLab UIでは、基本フローは次の操作を行うサービスアカウントを使用します:

- 独自のメールアドレスでコミットを作成します。
- [ワークロードパイプライン](../../ci/pipelines/pipeline_types.md#workload-pipeline)を作成します。

前提条件: 

- 管理者アクセス権。

プロジェクトのプッシュルールを設定するには:

1. サービスアカウントに関連付けられたメールアドレスを見つけます:
   1. 右上隅で、**管理者**を選択します。
   1. **概要** > **ユーザー**を選択し、フローに関連付けられたアカウントを検索します。アカウントは`duo-[flow-name]-[top-level-group-name]`のパターンに従います。
   1. サービスアカウントのユーザーを見つけ、メールアドレスをコピーします。

1. メールアドレスによるプロジェクトへのプッシュを許可します:
   1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **設定** > **リポジトリ**を選択します。
   1. **プッシュルール**を展開します。
   1. **コミットの作成者のメール**で、先ほどコピーしたメールアドレスを許可する正規表現を追加します。
   1. **プッシュルールを保存**を選択します。

1. `duo/feature/`ブランチプレフィックスを許可します:
   1. **プッシュルール**セクションで、**ブランチ名**を見つけます。
   1. ^duo/(fix\|feature\|refactor\|docs/).\* で始まるブランチを許可する正規表現を追加します。例: `^(duo/feature)/.*$`
   1. **プッシュルールを保存**を選択します。

インスタンスのプッシュルールを作成するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**プッシュルール**を選択します。
1. 前の手順に従って、**コミットの作成者のメール**と**ブランチ名**を許可します。
1. **プッシュルールを保存**を選択します。

## フローのジョブが開始しない、または`Starting job`でスタックしている {#job-for-a-flow-does-not-start-or-is-stuck-at-starting-job}

フローのジョブが開始しない、または`Starting job`でスタックしている場合、ジョブをピックアップできるRunnerがありません。フローは、次の要件を満たすRunnerで実行されます:

- Runnerには`gitlab--duo`タグがあります。
- Runnerは、`docker`、`docker-autoscaler`、または`kubernetes`のようなDockerイメージをサポートするexecutorを使用します。`shell` executorはサポートされていません。
- Runnerは、インスタンスRunnerまたはトップレベルグループに割り当てられたグループRunnerです。サブグループまたはプロジェクトにスコープ設定されたRunnerは、`duo_runner_restrictions`機能フラグが無効になっていない限り、フローのジョブをピックアップしません。

この問題を解決するには、次の手順に従います:

1. GitLab.comで、[hosted runners](../../ci/runners/hosted_runners/_index.md)がプロジェクトで有効になっていることを確認します。ホストされたRunnerは、デフォルトですべての要件を満たします。
1. 独自のRunnerを使用する場合は、少なくとも1つのRunnerが要件を満たしていることを確認します:
   1. トップバーで、**検索または移動先**を選択し、プロジェクトまたはトップレベルグループを見つけます。
   1. 左サイドバーで、**ビルド** > **Runners**を選択します。
   1. `gitlab--duo`タグを持つRunnerがオンラインであることを確認します。
1. 要件を満たすRunnerがない場合は、[configure a runner to execute flows](flows/execution/_index.md#configure-runners-to-execute-flows)。

## エラー: `Something went wrong while requesting a review from GitLab Duo` {#error-something-went-wrong-while-requesting-a-review-from-gitlab-duo}

GitLab 18.8以前では、このエラーメッセージはコードレビューフローの失敗に対して表示されます。一般的な根本原因は次のとおりです:

- 基本フローのサービスアカウントが作成されていませんでした。
- グループメンバーシップロックにより、サービスアカウントがプロジェクトに追加されません。
- 複数のGitLab Duoネームスペースに属しており、デフォルトのネームスペースが設定されていません。

GitLab 18.9以降では、より具体的なエラーメッセージが表示されます。詳細については、[troubleshooting Code Review Flow](flows/foundational_flows/code_review.md#troubleshooting)を参照してください。

### 基本フローのサービスアカウントが作成されていません {#foundational-flow-service-account-not-created}

基本フローが有効になっているのに機能しない場合、トップレベルグループのサービスアカウントが正常に作成されていない可能性があります。

サービスアカウントが存在するかどうかを確認するには:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. 左サイドバーで、**設定** > **Service Accounts**を選択します。
1. `duo-[flow-name]-[top-level-group-name]`という名前のアカウントを探します。

アカウントが見つからない場合、`CascadeSyncFoundationalFlowsWorker`はそれを作成することに失敗した可能性があります。アカウントが見つからないことを確認するには、Sidekiqログで次のエラーを確認します:

```json
{
  "severity": "ERROR",
  "meta.caller_id": "Ai::Catalog::Flows::CascadeSyncFoundationalFlowsWorker",
  "message": "Cannot obtain an exclusive lease. There must be another instance already in execution.",
  "lease_key": "sidekiq:concurrency_limit:{ai/catalog/flows/cascade_sync_foundational_flows_worker}",
  "lease_timeout": 600
}
```

この問題を解決するには、[turn off foundational flows](flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)してから10分後に再度有効にします。

### グループメンバーシップがロックされました {#group-membership-locked}

トップレベルグループの[membership is locked](../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)されている場合、サービスアカウントが必要なプロジェクトに追加できないため、基本フローはサイレントに失敗します。

この問題を解決するには、次の手順に従います:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **このグループのプロジェクトにユーザーを追加することはできません**チェックボックスをオフにしてから、**変更を保存**を選択します。
1. [Turn off foundational flows](flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)を選択し、次に**変更を保存**を選択します。
1. 基本フローを再度有効にしてから、**変更を保存**を選択します。
1. **このグループのプロジェクトにユーザーを追加することはできません**チェックボックスを選択し、次に**変更を保存**を選択します。

### デフォルトのGitLab Duoネームスペースが設定されていません {#default-gitlab-duo-namespace-not-set}

GitLab 18.3以降では、複数のGitLab Duoネームスペースに属しており、デフォルトのネームスペースが設定されていない場合、GitLab Duo Agent Platformは無効になります。

GitLab 18.8以前では、次のエラーメッセージが表示される場合があります:

```plaintext
Something went wrong while requesting a review from GitLab Duo.
```

GitLab 18.9以降では、ネームスペース関連のエラーが発生する場合があります。

この問題を解決するには、[set a default GitLab Duo namespace](../profile/preferences.md#set-a-default-gitlab-duo-namespace)。

## エラー: `SSL certificate OpenSSL verify result: unable to get local issuer certificate (20)` {#error-ssl-certificate-openssl-verify-result-unable-to-get-local-issuer-certificate-20}

カスタムまたは自己署名CA証明書を使用するGitLab Self-Managedインスタンスでは、GitLab Duo Agent Platformのジョブが最初の`git clone`（`get_sources`フェーズ）中に失敗すると、このメッセージが表示される場合があります。

これは、GitLab Duo Agent Platformのジョブが`GIT_CONFIG_GLOBAL=/dev/null`と`GIT_CONFIG_NOSYSTEM=1`を設定してエージェントサンドボックスを強化するためです。これらの変数は、Gitがシステムおよびグローバルな設定ファイルを読み取るのを防ぎます。これにより、Runnerの`get_sources`中のCA証明書パスを注入するメカニズムが破損します。

CI/CDのジョブがフローを実行しない場合は影響を受けません。この問題は、GitLab Duo Agent Platformのワークロードパイプラインに固有のものです。

この問題を解決するには、[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/)ファイルで、`GIT_SSL_CAINFO`環境変数をRunnerレベルで設定し、CA証明書をコンテナにマウントします:

```toml
[[runners]]
  environment = ["GIT_SSL_CAINFO=/etc/gitlab-runner/certs/ca.crt"]
  [runners.docker]
    volumes = ["/path/to/your/ca-bundle.crt:/etc/gitlab-runner/certs/ca.crt:ro"]
```

`/path/to/your/ca-bundle.crt`をRunnerホスト上のCA証明書バンドルへのパスに置き換えます。このファイルは、ルートCAおよびすべての中間証明書を含むPEM形式のCAバンドルである必要があります。

これをCI/CD変数として設定することを期待するかもしれませんが、カスタムCI/CD変数はGitLab Duo Agent Platformのジョブでは[not available](flows/execution/execution-variables.md#custom-cicd-variables)です。代わりに、Runnerの`config.toml` `environment`ディレクティブを使用する必要があります。

GitLab Duo CLIをカスタムCA経由でGitLabインスタンスに接続するには、`NODE_EXTRA_CA_CERTS`を同じ`environment`行に追加します:

```toml
[[runners]]
  environment = [
    "GIT_SSL_CAINFO=/etc/gitlab-runner/certs/ca.crt",
    "NODE_EXTRA_CA_CERTS=/etc/gitlab-runner/certs/ca.crt"
  ]
  [runners.docker]
    volumes = ["/path/to/your/ca-bundle.crt:/etc/gitlab-runner/certs/ca.crt:ro"]
```

GitLab Duo CLIがAnthropic Sandbox Runtime（SRT）で実行されている場合、Runner `environment`変数は到達しない可能性があります。この変更後もTLSエラーが続く場合は、`agent-config.yml`の`setup_script`で、代わりに`NODE_EXTRA_CA_CERTS`を設定します。`setup_script`はコンテナ内で実行され、サンドボックスによってフィルタリングされません。

`GIT_SSL_CAINFO`変数は、GitLab Duo CLIが起動する前に発生するGit操作に対処します。GitLab Duo CLIの証明書設定については、[certificate errors](../gitlab_duo_cli/use.md#certificate-errors)を参照してください。

## WebSocketエラー`1006`または`404`で接続が失敗します {#connection-fails-with-websocket-error-1006-or-404}

GitLab Duo CLI、GitLab言語サーバー、およびIDEクライアント（GitLab for VS Code、JetBrains IDE用GitLab Duoプラグイン、およびGitLab for Visual Studio）は、WebSocket接続を介してGitLab Duo Agent Platformに接続します。この接続が失敗すると、クライアントは次のいずれかのエラーをログに記録します:

- `1006`: WebSocketは、クローズハンドシェイクなしで異常終了しました。
- `404`: クライアントは次のWebSocketエンドポイントに到達できません:
  - GitLab Duo非エージェント型: `/-/cable`。
  - GitLab Duo Agent Platform: `wss://\<instance\>/api/v4/ai/duo_workflows/ws`。

これらのエラーは通常、カスタム認証局（CA）、HTTPプロキシ、TLS検査プロキシ、またはネットワーク上の相互TLS（mTLS）プロキシが接続を妨げるときに発生します。この問題を解決するには、次の原因を確認してください。

### カスタムCA証明書 {#custom-ca-certificate}

ネットワークがカスタムまたは自己署名CA証明書を使用している場合、クライアントはGitLabインスタンスへの接続を検証できません。クライアントの証明書を設定します:

- GitLab Duo CLIの場合は、`NODE_EXTRA_CA_CERTS`環境変数をCA証明書のパスに設定します。
- IDEクライアントの場合、GitLab言語サーバーが証明書を管理します。JetBrains IDEの場合は、[certificate errors](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md#certificate-errors)を参照してください。VS Codeの場合は、[errors with custom certificates](../../editor_extensions/visual_studio_code/troubleshooting.md#errors-with-custom-certificates)を参照してください。

### HTTPプロキシ {#http-proxy}

ネットワークがHTTPプロキシを必要とする場合は、クライアントのプロキシを設定します:

- GitLab Duo CLIの場合は、`HTTP_PROXY`、`HTTPS_PROXY`、および`NO_PROXY`環境変数を設定します。
- IDEクライアントの場合は、[configure the Language Server to use a proxy](../../editor_extensions/language_server/_index.md#configure-the-language-server-to-use-a-proxy)。

### WebSocketトラフィックがブロックされました {#websocket-traffic-blocked}

`404`エラー、またはログに`/-/cable` WebSocketエンドポイントの代わりに`HTTP/1.1`応答が表示される場合、GitLabインスタンスが受信WebSocket接続をブロックしている可能性があります。管理者に、[allow WebSocket traffic to your GitLab instance](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)を依頼してください。

### mTLSまたはTLS検査プロキシ {#mtls-or-tls-inspection-proxy}

ネットワークがTLS検査（SSLインターセプション）プロキシを介してトラフィックをルーティングする場合、次の両方を設定します:

- `HTTPS_PROXY`環境変数をプロキシURLに設定します。
- プロキシの[CA certificate](#custom-ca-certificate)を追加します。

GitLab Duo CLI、JetBrains IDE用GitLab Duoプラグイン、およびGitLab for Visual Studioには、2つの既知の問題があります:

- プロキシURLが`https://`を使用している場合、WebSocket接続は失敗します。可能であれば、`http://`プロキシURLを使用します。
- これらのクライアントは、mTLS用のクライアント証明書を提示できません。

詳細については、[issue 2527](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2527)を参照してください。GitLab for VS Codeは影響を受けません。

## IDEでのトラブルシューティング {#troubleshooting-in-your-ide}

IDEでGitLab Duo Agent Platformを使用中に問題が発生した場合は、GitLab Duoがオンになっており、適切に接続されていることを確認することから始めます。

- GitLab Duo Agent Platformの[prerequisites](_index.md#prerequisites)を満たしています。
- 管理者モードは[disabled](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)です。
- プロジェクトは[group namespace](../namespace/_index.md)にあります。
- [default GitLab Duo namespace](../profile/preferences.md#namespace-resolution-in-your-local-environment)が設定されているか、GitLab Duoアクセス権のあるプロジェクトを開いています。

詳細なサポートについては、拡張機能とIDEのトラブルシューティングページを参照してください:

- [GitLab for VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md#gitlab-duo)
- [JetBrains IDE用GitLab Duoプラグイン](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)
- [GitLab for Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)

## 設定診断スクリプトを実行する {#run-the-configuration-diagnostic-script}

関連する機能ドキュメントからGitLab Duo Agent Platformの問題の原因を特定できない場合は、診断スクリプトを実行して設定を確認します。

このスクリプトは、GitLab Duo Agent Platform機能に必要な完全な設定チェーンをチェックします:

- ライセンスの有効性とプラン。
- インスタンスレベルのGitLab Duo設定。
- `gitlab--duo`タグを持つCI/CD Runner。
- ネームスペースおよびプロジェクトのGitLab Duo設定。
- 基本フローとそのサービスアカウント。
- コードレビューフローの可用性や自動レビュー設定などの機能の利用可能性。

> [!warning]
> このスクリプトは設定データのみを読み取り、設定を変更しません。出力には内部設定の詳細が含まれる場合があります。サポートと共有する前に、出力をサニタイズしてください。

前提条件: 

- GitLab 18.8以降

GitLab 19.0以降で診断スクリプトを実行するには:

- 組み込みの`gitlab:duo:verify_setup` [Rakeタスク](../../administration/raketasks/_index.md)を実行します。`<group/project>`をプロジェクトへの完全なパスに置き換えます（例: `gitlab-org/gitlab`）。

  例: 

  ```shell
  sudo gitlab-rake "gitlab:duo:verify_setup[<group/project>]"
  ```

GitLab 18.8からGitLab 18.11で診断スクリプトを実行するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb)をダウンロードします。
1. `verify_setup.rb`ファイルをGitLabサーバーにコピーします。
1. スクリプトを実行します。`<group/project>`をプロジェクトへの完全なパスに置き換えます（例: `gitlab-org/gitlab`）。

   ```shell
   sudo gitlab-rails runner "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb)をダウンロードします。
1. `verify_setup.rb`ファイルをコンテナにコピーします。
1. スクリプトを実行します。`<group/project>`をプロジェクトへの完全なパスに置き換えます（例: `gitlab-org/gitlab`）。

   ```shell
   docker cp verify_setup.rb <container-id>:/tmp/verify_setup.rb
   docker exec -it <container-id> gitlab-rails runner \
   "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb)をダウンロードします。
1. `verify_setup.rb`ファイルをGitLabサーバーにコピーします。
1. GitLabアプリケーションディレクトリからスクリプトを実行します。`<group/project>`をプロジェクトへの完全なパスに置き換えます（例: `gitlab-org/gitlab`）。

   ```shell
   sudo -u git bundle exec rails runner \
   "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb)をダウンロードします。
1. `verify_setup.rb`ファイルをツールボックスポッドにコピーします。
1. スクリプトを実行します。`<group/project>`をプロジェクトへの完全なパスに置き換えます（例: `gitlab-org/gitlab`）。

   ```shell
   # Find the toolbox pod
   kubectl get pods --namespace <namespace> -lapp=toolbox

   kubectl cp verify_setup.rb <namespace>/<toolbox-pod-name>:/tmp/verify_setup.rb
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner \
   "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< /tabs >}}

## 関連トピック {#related-topics}

- [Troubleshooting GitLab Duo Agentic Chat](../gitlab_duo_chat/troubleshooting.md)
- [Troubleshooting Code Review Flow](flows/foundational_flows/code_review.md#troubleshooting)
- [Troubleshooting GitLab MCP clients](../gitlab_duo/model_context_protocol/mcp_clients.md#troubleshooting)
- [Troubleshooting the GitLab MCP Server](../model_context_protocol/mcp_server_troubleshooting.md)

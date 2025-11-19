---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: クラスター内のワークスペースを認証および承認するためのGitLabワークスペースプロキシを作成します。
title: ワークスペースのトラブルシューティング
---

GitLabワークスペースを使用する場合、次の問題が発生する可能性があります。

## エラー: `Failed to renew lease` {#error-failed-to-renew-lease}

ワークスペースの作成時に、エージェントのログファイルに次のエラーメッセージが表示されることがあります:

```plaintext
{"level":"info","time":"2023-01-01T00:00:00.000Z","msg":"failed to renew lease gitlab-agent-remote-dev-dev/agent-123XX-lock: timed out waiting for the condition\n","agent_id":XXXX}
```

このエラーは、Kubernetes向けGitLabエージェントの既知の問題が原因です。このエラーは、エージェントインスタンスがリーダーシップリースを更新できず、`remote_development`などのリーダーのみのモジュールがシャットダウンすることが原因で発生します。

この問題を解決するには、以下を実行します:

1. エージェントインスタンスを再起動します。
1. 問題が解決しない場合は、Kubernetesクラスターのヘルスと接続を確認してください。

## エラー: `No agents available to create workspaces` {#error-no-agents-available-to-create-workspaces}

プロジェクトでワークスペースを作成するときに、次のエラーが発生することがあります:

```plaintext
No agents available to create workspaces. Please consult Workspaces documentation for troubleshooting.
```

このエラーは、いくつかの理由で発生する可能性があります。次のトラブルシューティングの手順を実行してください。

### 権限を確認する {#check-permissions}

1. ワークスペースプロジェクトとエージェントプロジェクトの両方に対して、少なくともデベロッパーロールがあることを確認してください。
1. エージェントがワークスペースプロジェクトの祖先グループで許可されていることを確認します。詳細については、[エージェントを許可する](gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-in-a-group)を参照してください。

### エージェントの設定 {#check-agent-configuration}

`remote_development`モジュールがエージェントの設定で有効になっていることを確認します:

   ```yaml
   remote_development:
     enabled: true
   ```

Kubernetes向けGitLabエージェントで`remote_development`モジュールが無効になっている場合は、[`enabled`](settings.md#enabled)を`true`に設定します。

### エージェント名の不一致を確認する {#check-agent-name-mismatch}

[KubernetesトークンのGitLabエージェントを作成する](set_up_infrastructure.md#create-a-gitlab-agent-for-kubernetes-token)の手順で作成したエージェント名が、`.gitlab/agents/FOLDER_NAME/`のフォルダー名と一致していることを確認します。

名前が異なる場合は、エージェント名と正確に一致するようにフォルダーの名前を変更します。

### エージェント接続ステータスを確認する {#check-agent-connection-status}

エージェントがGitLabに接続されていることを確認します:

1. グループに移動します。
1. **操作** > **Kubernetesクラスター**を選択します。
1. **接続ステータス**が**接続済み**かどうかを確認します。接続されていない場合は、エージェントのログを確認してください。接続されていない場合は、エージェントのログを確認してください:

   ```shell
   kubectl logs -f -l app=gitlab-agent -n gitlab-workspaces
   ```

## エラー: `unsupported scheme in GitLab Kubernetes Agent Server address` {#error-unsupported-scheme-in-gitlab-kubernetes-agent-server-address}

このエラーは、KubernetesエージェントServer（KAS）アドレスに必要なプロトコルスキームがない場合に発生します。

この問題を解決するには、以下を実行します:

1. `TF_VAR_kas_address`変数に`wss://`プレフィックスを追加します。例: `wss://kas.gitlab.com`。
1. 設定を更新して、エージェントを再デプロイします。

## エラー: オフライン環境でワークスペースを起動するときの`ImagePullBackOff` {#error-imagepullbackoff-when-starting-workspace-in-offline-environment}

オフライン環境でワークスペースを作成すると、次のエラーが表示されることがあります:

```plaintext
workspace-example-abc123-def456   0/1   Init:ImagePullBackOff   0
```

このエラーは、ワークスペースが`registry.gitlab.com`からinitコンテナイメージをプルできない場合に発生します。オフライン環境では、initコンテナイメージがハードコードされており、devfileから上書きできません。

{{< alert type="warning" >}}

次の回避策はサポートされておらず、一時的なものです。[issue 509983](https://gitlab.com/gitlab-org/gitlab/-/issues/509983)でサポートされているソリューションが提供されるまで、ご自身の責任で使用してください。

{{< /alert >}}

回避策は次のとおりです:

1. コンテナイメージの参照を変更するために、[Kubernetes mutating webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)をデプロイします。
1. `MutatingWebhookConfiguration`を作成、更新、または削除するには、クラスターの管理者権限が必要です。

実装例については、[シンプルなKubernetesアドミッションWebhook](https://slack.engineering/simple-kubernetes-webhook/)を参照してください。

## エラー: `redirect URI included is not valid` {#error-redirect-uri-included-is-not-valid}

ワークスペースにアクセスすると、無効なリダイレクトURIに関するOAuthエラーが発生することがあります。

このエラーは、次の理由で発生する可能性があります:

- OAuthアプリケーションが正しく設定されていません。この問題を解決するには、以下を実行します:

  1. GitLabのOAuthアプリケーションのリダイレクトURIがドメインと一致することを確認します。
  1. OAuthアプリケーションのリダイレクトURIを更新します。例: `https://YOUR_DOMAIN/auth/callback`。

- ワークスペースプロキシが古いOAuth認証情報を使用しています。この問題を解決するには、次のようにします:

  1. プロキシが最新のOAuth認証情報を使用していることを確認します。
  1. ワークスペースプロキシを再起動します:

      ```shell
      kubectl rollout restart deployment -n gitlab-workspaces gitlab-workspaces-proxy
      ```

## エラー: `Workspace does not exist` {#error-workspace-does-not-exist}

VS Codeで次のエラーが表示されることがあります。

```plaintext
Workspace does not exist

Please select another workspace to open.
```

この問題は、ワークスペースは正常に起動するものの、Gitクローン操作が失敗したために、予期されるプロジェクトディレクトリが見つからない場合に発生します。Gitクローン操作は、ネットワークの問題、インフラストラクチャの問題、または失効したリポジトリ権限が原因で失敗します。

この問題を解決するには、以下を実行します:

1. エラーダイアログで別のワークスペースを選択するように求められたら、**キャンセル**を選択します。
1. VS Codeメニューから、**ファイル** > **Open Folder**（フォルダーを開く） を選択します。
1. `/projects`ディレクトリに移動し、**OK**を選択します。
1. **EXPLORER**（エクスプローラー）パネルで、プロジェクトと同じ名前のディレクトリがあるかどうかを確認します。
   - ディレクトリが見つからない場合は、Gitクローン操作が完全に失敗しました。
   - ディレクトリが存在するが空の場合は、クローン操作は開始されたものの完了しませんでした。
1. ターミナルを開きます。メニューから**ターミナル** > **New Terminal**（新しいターミナル） を選択します。
1. ワークスペースのログディレクトリに移動します:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. Gitクローンが失敗した理由を示すエラー出力がないかログを確認します:

   ```shell
   less poststart-stderr.log
   ```

1. 特定された問題を解決し、ワークスペースを再起動します。

問題が解決しない場合は、Gitを含む作業中のコンテナイメージを使用して、新しいワークスペースを作成します。

## `postStart`イベントをデバッグする {#debug-poststart-events}

カスタム`postStart`イベントが失敗した場合、または期待どおりに動作しない場合は、ワークスペースログディレクトリを使用して問題をデバッグできます。

一般的な`postStart`デバッグシナリオとその解決策:

- `Command not found`: コンテナイメージに依存関係がないことを示すエラーがないか`poststart-stderr.log`を確認してください。
- `Permission denied`: `poststart-stderr.log`で、ファイルの権限またはユーザー設定の調整が必要な権限エラーがないか確認します。
- `Network issues`: `postStart`イベントが依存関係をダウンロードしたり、外部リソースにアクセスしたりするときに、接続タイムアウトまたはDNS解決の失敗がないか確認します。
- `Long-running commands`: `postStart`イベントがハングアップする場合は、`poststart-stdout.log`を調べて、コマンドがまだ実行中か、正常に完了したかを確認します。

`postStart`コマンド実行ログを確認するには:

1. ワークスペースでターミナルを開きます。
1. ワークスペースのログディレクトリに移動します:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. ログファイルを表示します:

   ```shell
   # Monitor postStart execution output in real-time
   tail -f poststart-stdout.log

   # Check postStart errors
   cat poststart-stderr.log

   # Check VS Code server startup
   cat start-vscode.log
   ```

1. エラーがないか確認します:

   ```shell
   # Search for error messages across all logs
   grep -i error *.log

   # Search for specific command output
   grep "your-command-name" poststart-stdout.log
   ```

1. 特定された問題を解決し、ワークスペースを再起動します。

詳細については、[ワークスペースログディレクトリ](_index.md#workspace-logs-directory)と[利用可能なログファイル](_index.md#available-log-files)を参照してください。

<!--- Other suggested topics:

## DNS configuration

## Workspace stops unexpectedly

## Workspace creation fails due to quotas

## Network connectivity

## SSH connection failures

### Network policy restrictions

-->

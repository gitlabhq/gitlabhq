---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabワークスペースの認証と認可を行うために、GitLabワークスペースプロキシをクラスター内に作成します。
title: ワークスペースのトラブルシューティング
---

GitLabワークスペースを使用している際に、以下の問題が発生する可能性があります。

## エラー: `Failed to renew lease` {#error-failed-to-renew-lease}

ワークスペースを作成する際に、エージェントのログに以下のエラーメッセージが表示される場合があります:

```plaintext
{"level":"info","time":"2023-01-01T00:00:00.000Z","msg":"failed to renew lease gitlab-agent-remote-dev-dev/agent-123XX-lock: timed out waiting for the condition\n","agent_id":XXXX}
```

このエラーは、Kubernetes向けGitLabエージェントの既知のイシューが原因です。このエラーは、エージェントインスタンスがリーダシップリースを更新できず、`remote_development`のようなリーダー専用のモジュールがシャットダウンする場合に発生します。

この問題を解決するには、次の手順に従います:

1. エージェントインスタンスを再起動します。
1. 問題が解決しない場合は、Kubernetesクラスターの正常性と接続性を確認してください。

## エラー: `Workspace create failed: Expiration date must be before <date>` {#error-workspace-create-failed-expiration-date-must-be-before-date}

ワークスペースを作成する際に、UIにこのエラーが表示されることがあります:

```plaintext
Workspace create failed: Expiration date must be before <date>
```

このエラーは、新しく作成されたワークスペースへの[パーソナルアクセストークン認証のために作成された](_index.md#personal-access-token)の有効期限が、インスタンスのトークン有効期限設定を超えている場合に発生します。

この問題を解決するには、[アクセストークン有効期限制限](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)を無効にしてください。[イシュー579331)](https://gitlab.com/gitlab-org/gitlab/-/work_items/579331)は、この制限に対処するために、ワークスペース関連のトークンに対して設定可能な制限を提案しています。

## エラー: `No agents available to create workspaces` {#error-no-agents-available-to-create-workspaces}

プロジェクトでワークスペースを作成すると、次のエラーが表示されることがあります:

```plaintext
No agents available to create workspaces. Please consult Workspaces documentation for troubleshooting.
```

このエラーはいくつかの理由で発生する可能性があります。次のトラブルシューティング手順を実行してください。

### パーミッションを確認 {#check-permissions}

1. ワークスペースプロジェクトとエージェントプロジェクトの両方で、デベロッパー、メンテナー、またはオーナーのロールを持っていることを確認してください。
1. あなたのワークスペースプロジェクトの祖先グループで、エージェントが許可されていることを確認してください。

詳細については、[エージェントを許可する](gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-in-a-group)を参照してください。

### エージェント設定を確認 {#check-agent-configuration}

あなたのエージェント設定で`remote_development`モジュールが有効になっていることを確認してください:

   ```yaml
   remote_development:
     enabled: true
   ```

`remote_development`モジュールがKubernetes向けGitLabエージェントで無効になっている場合、[`enabled`](settings.md#enabled)を`true`に設定してください。

### エージェント名の不一致を確認 {#check-agent-name-mismatch}

[Kubernetes向けGitLabエージェントトークンの作成](set_up_infrastructure.md#create-a-gitlab-agent-for-kubernetes-token)ステップで作成したエージェント名が、`.gitlab/agents/FOLDER_NAME/`のフォルダー名と一致することを確認してください。

名前が異なる場合は、フォルダー名をエージェント名と正確に一致するように変更してください。

### エージェント接続ステータスを確認 {#check-agent-connection-status}

エージェントがGitLabに接続されていることを確認してください:

1. あなたのグループに移動します。
1. **操作** > **Kubernetesクラスター**を選択します。
1. **接続ステータス**が**接続済み**であることを確認してください。接続されていない場合は、エージェントログを確認してください:

   ```shell
   kubectl logs -f -l app=gitlab-agent -n gitlab-workspaces
   ```

## エラー: `unsupported scheme in kas address` {#error-unsupported-scheme-in-kas-address}

このエラーは、GitLab Relay (KAS) アドレスに、必要なプロトコルスキームがない場合に発生します。

この問題を解決するには、次の手順に従います:

1. あなたの`TF_VAR_kas_address`変数に`wss://`プレフィックスを追加してください。例: 。例: `wss://kas.gitlab.com`。
1. あなたの設定を更新し、エージェントを再デプロイしてください。

## エラー: オフライン環境でワークスペースを開始する際の`ImagePullBackOff` {#error-imagepullbackoff-when-starting-workspace-in-offline-environment}

オフライン環境でワークスペースを作成すると、このエラーが表示されることがあります:

```plaintext
workspace-example-abc123-def456   0/1   Init:ImagePullBackOff   0
```

このエラーは、ワークスペースが`registry.gitlab.com`から初期化コンテナイメージをプルすることができない場合に発生します。オフライン環境では、初期化コンテナイメージはハードコードされており、あなたのdevfileからオーバーライドすることはできません。

> [!warning]
> 次の回避策はサポートされておらず、一時的なものです。[イシュー509983](https://gitlab.com/gitlab-org/gitlab/-/issues/509983)がサポートされているソリューションを提供するまで、自己責任で使用してください。

回避策は次のとおりです:

1. 初期化コンテナイメージの参照を変更するために、[KubernetesミューテートWebhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)をデプロイします。
1. `MutatingWebhookConfiguration`を作成、更新、または削除するためのクラスター管理者権限があることを確認してください。

実装例については、[シンプルなKubernetesアドミッションWebhook](https://slack.engineering/simple-kubernetes-webhook/)を参照してください。

## エラー: `redirect URI included is not valid` {#error-redirect-uri-included-is-not-valid}

ワークスペースにアクセスする際に、無効なリダイレクトURIに関するOAuthエラーに遭遇する場合があります。

このエラーは次の理由で発生する可能性があります:

- OAuthアプリケーションが正しく設定されていません。この問題を解決するには、次の手順に従います:
  1. GitLabのOAuthアプリケーションリダイレクトURIが、あなたのドメインと一致することを確認してください。
  1. OAuthアプリケーションリダイレクトURIを更新します。例: `https://YOUR_DOMAIN/auth/callback`。
- ワークスペースプロキシが古いOAuth認証情報を使用しています。この問題を解決するには:
  1. プロキシが最新のOAuth認証情報を使用していることを確認してください。
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

この問題は、ワークスペースは正常に起動するものの、Gitクローン操作が失敗したために、予期されるプロジェクトディレクトリが見つからない場合に発生します。Gitクローン操作は、ネットワークの問題、インフラストラクチャの問題、または失効したリポジトリパーミッションが原因で失敗します。

この問題を解決するには、次の手順に従います:

1. エラーダイアログで別のワークスペースを選択するように促されたら、**キャンセル**を選択します。
1. VS Codeメニューから、**ファイル** > **Open Folder**を選択します。
1. `/projects`ディレクトリに移動し、**OK**を選択します。
1. **EXPLORER**パネルで、あなたのプロジェクトと同じ名前のディレクトリがあるか確認してください。
   - ディレクトリが見つからない場合、Gitクローン操作は完全に失敗しています。
   - ディレクトリは存在するが空の場合、クローン操作は開始されたものの完了していません。
1. ターミナルを開きます。メニューから**ターミナル** > **New Terminal**を選択します。
1. ワークスペースのログディレクトリに移動します:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. Gitクローンが失敗した理由を示す可能性のあるエラー出力についてログを確認してください:

   ```shell
   less poststart-stderr.log
   ```

1. 特定された問題を解決し、あなたのワークスペースを再起動してください。

問題が解決しない場合は、Gitを含む動作するコンテナイメージで新しいワークスペースを作成してください。

## `postStart`イベントをデバッグ {#debug-poststart-events}

あなたのカスタム`postStart`イベントが失敗したり、期待通りに動作しない場合、ワークスペースログディレクトリを使用して問題をデバッグできます。

一般的な`postStart`デバッグシナリオとその解決策:

- `Command not found`: あなたのコンテナイメージにおける不足している依存関係を示すエラーがないか`poststart-stderr.log`を確認してください。
- `Permission denied`: ファイルパーミッションまたはユーザー設定の調整が必要となる可能性のあるパーミッションエラーを`poststart-stderr.log`で確認してください。
- `Network issues`: あなたの`postStart`イベントが依存関係をダウンロードしたり、外部リソースにアクセスしたりする際に、接続タイムアウトまたはDNS解決の失敗がないか確認してください。
- `Long-running commands`: もし`postStart`イベントがハングしている場合、`poststart-stdout.log`でコマンドがまだ実行中か、または正常に完了したかを確認してください。

`postStart`コマンドの実行ログを確認するには:

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

1. エラーを確認してください:

   ```shell
   # Search for error messages across all logs
   grep -i error *.log

   # Search for specific command output
   grep "your-command-name" poststart-stdout.log
   ```

1. 特定された問題を解決し、あなたのワークスペースを再起動してください。

詳細については、[ワークスペースログディレクトリ](_index.md#workspace-logs-directory)と[利用可能なログファイル](_index.md#available-log-files)を参照してください。

<!--- Other suggested topics:

## DNS configuration

## Workspace stops unexpectedly

## Workspace creation fails due to quotas

## Network connectivity

## SSH connection failures

### Network policy restrictions

-->

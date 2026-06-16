---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBaoのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

リカバリーキーのタスクとブレークグラスルートトークンについては、[リカバリーキー管理](recovery_key.md)を参照してください。Geoフェイルオーバーについては、[Geoディザスターリカバリー](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster)を参照してください。

## OpenBaoの実行場所 {#where-openbao-runs}

GitLabがLinuxパッケージを使用している場合でも、OpenBaoは常にKubernetesで実行されます。ネームスペースとデプロイ名はインストール方法によって異なります:

| インストール方法 | ネームスペース | デプロイ       | ポッドコンテナ    |
|---------------------|-----------|------------------|------------------|
| クラウドネイティブGitLab | `gitlab`  | `gitlab-openbao` | `openbao-server` |
| Linuxパッケージ       | `openbao` | `openbao`        | `openbao-server` |

これらの例では、クラウドネイティブネームスペース`gitlab`を使用しています。Linuxパッケージインストールの場合、`kubectl`コマンドで`gitlab`を`openbao`に置き換えてください。

OpenBaoポッドはラベル`app.kubernetes.io/name=openbao`を持ちます。アクティブノードも`openbao-active=true`を持ちます。

## OpenBaoログの検索 {#find-openbao-logs}

`kubectl logs`でOpenBaoのログを読み取ります。関連するGitLab RailsおよびSidekiqログは、インストール方法に応じて個別に保存されます:

| ソース         | クラウドネイティブGitLab                              | Linuxパッケージ                                      |
|----------------|--------------------------------------------------|----------------------------------------------------|
| OpenBaoサーバー | `openbao-server`コンテナ上の`kubectl logs` | `openbao-server`コンテナ上の`kubectl logs`   |
| GitLab Rails   | `webservice`ポッド上の`kubectl logs`          | `/var/log/gitlab/gitlab-rails/production_json.log` |
| Sidekiq        | `sidekiq`ポッド上の`kubectl logs`             | `/var/log/gitlab/sidekiq/current`                  |
| GitLab Runner  | GitLab UIのCI/CDジョブログ                   | GitLab UIのCI/CDジョブログ                     |

OpenBaoは監査イベントをGitLabにポストし、OpenBaoポッドログにも書き込みます。

### OpenBaoポッドを見つける {#find-the-openbao-pods}

OpenBaoポッドをリストし、どのアクティブノードであるかを確認するには:

```shell
kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao \
  --label-columns openbao-active,openbao-sealed
```

`OPENBAO-ACTIVE`が`true`に設定されているポッドがアクティブノードです。その他はスタンバイノードです。

### OpenBaoステータスを確認する {#check-openbao-status}

OpenBaoはリクエストを処理するためにアンシールされている必要があります。確認するには、ポッドで`bao status`を実行します:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
```

出力では、`Sealed`は`false`である必要があります。アクティブノードは`HA Mode    active`を表示し、スタンバイノードは`HA Mode    standby`を表示します:

```plaintext
Seal Type       static
Initialized     true
Sealed          false
Storage Type    postgresql
HA Enabled      true
HA Mode         active
```

`sys/seal-status`エンドポイントは`"sealed":false`と同じ状態を報告します:

```shell
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao read sys/seal-status"
```

> [!note]
> `bao`バイナリはポッド内に存在します。ポッド内からのエンドポイントクエリには`bao read`を使用します。

ログでは、アンシールに成功したノードは`vault is unsealed`をログに記録します。アクティブノードは`acquired lock, enabling active operation`をログに記録し、スタンバイノードは`entering standby mode`をログに記録します:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server \
  | grep -E "acquired lock, enabling active operation|entering standby mode"
```

### 時間枠内のエラーの検索 {#find-errors-in-a-time-window}

時間枠からOpenBaoログを読み取るには、`--since`を使用します:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server --since=30m \
  | grep -iE "error|warn|failed"
```

Linuxパッケージインストールの場合、RailsおよびSidekiqログファイルを時間で検索します。ログはJSON形式で、1行に1つのイベントがあります。

> [!note]
> OpenBaoはすべての出力を標準エラーに書き込むため、一部のログプラットフォームではすべての行をエラーとしてタグ付けします。プラットフォームのラベルではなく、メッセージ本文のレベル（`[info]`、`[warn]`）を信頼してください。

### GitLab Railsログ {#gitlab-rails-logs}

Railsログには、UIおよびGraphQL APIからのシークレット操作と、OpenBaoからの監査コールバックが含まれます。

クラウドネイティブインストールの場合:

```shell
kubectl logs -n gitlab -l app=webservice -c webservice \
  | grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs"
```

Linuxパッケージインストールの場合:

```shell
grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs" \
  /var/log/gitlab/gitlab-rails/production_json.log
```

GraphQL操作は、`caller_id`（`graphql:createProjectSecret`や`graphql:getGroupSecrets`など）とともに表示されます。監査コールバックはパス`/api/v4/internal/secrets_manager/audit_logs`として表示されます。

### Sidekiqログ {#sidekiq-logs}

プロビジョニング、デプロビジョニング、およびシークレットマネージャーレコードを維持するワーカーは、`SecretsManagement::`ネームスペースの下で実行されます。

クラウドネイティブインストールの場合:

```shell
kubectl logs -n gitlab -l app=sidekiq -c sidekiq | grep "SecretsManagement::"
```

Linuxパッケージインストールの場合:

```shell
grep "SecretsManagement::" /var/log/gitlab/sidekiq/current
```

プロビジョニングの問題については、`ProvisionProjectSecretsManagerWorker`または`ProvisionGroupSecretsManagerWorker`でフィルタリングしてください。

### Runnerログ {#gitlab-runner-logs}

CI/CDジョブがシークレットのフェッチに失敗すると、原因はGitLab UIのジョブログに表示されます。これらの文字列についてジョブログを検索します:

| 文字列                                           | 意味                                                            |
|--------------------------------------------------|--------------------------------------------------------------------|
| `Resolving secrets`                              | Runnerはジョブのシークレットの解決を開始しました。                    |
| `Using "gitlab_secrets_manager" secret resolver` | RunnerはGitLab Secrets Managerリゾルバーを選択しました。           |
| `not initialized or sealed Vault server`         | OpenBaoはシールされているか、初期化されていません。                              |
| `api error: status code 403: permission denied`  | OpenBaoはリクエストを拒否しました。これは多くの場合、オーディエンスまたは権限の問題です。 |
| `inline auth JWT is required`                    | Runnerは認証リクエストをビルドできませんでした。            |

### 正常な起動ログ {#healthy-startup-logs}

再起動後、アクティブノードはこのシーケンスをログに記録します。スタンバイノードは`vault is unsealed`で停止し、その後`entering standby mode`をログに記録します。行形式は設定によって異なるため、プレフィックスではなくメッセージテキストを照合してください。

| ログメッセージ                                | 意味                              | 不足している場合                                            |
|--------------------------------------------|--------------------------------------|-------------------------------------------------------|
| `==> OpenBao server started!`              | プロセスが開始され、設定が読み込まれました。 | ポッドの起動に失敗しました。ポッドイベントを確認してください。        |
| `vault is unsealed`                        | 自動アンシールに成功しました。               | 自動アンシールに失敗しました。アンシールシークレットまたはKMSを確認してください。   |
| `acquired lock, enabling active operation` | このノードがアクティブになりました。             | アクティブなノードはありません。データベースとHAロックを確認してください。    |
| `post-unseal setup complete`               | アクティブノードがセットアップを完了しました。      | セットアップが完了しませんでした。データベース接続を確認してください。  |

### エラーメッセージ {#error-messages}

OpenBaoメッセージは`openbao-server`コンテナから発信されます。GitLabメッセージはRailsまたはSidekiqログから発信されます。

| コンテナ        | メッセージ                                                       | 説明                                                        | アクション                                                              |
|------------------|---------------------------------------------------------------|--------------------------------------------------------------------|---------------------------------------------------------------------|
| `openbao-server` | `cipher: message authentication failed`                       | シールキーが保存されているデータを復号化できません。                       | 静的アンシールの場合は、プライマリサイトからアンシールシークレットをコピーしてください。KMSシールの場合は、KMSキーを確認してください。[Geoデプロイのトラブルシューティング](#troubleshoot-geo-deployments)を参照してください。 |
| `openbao-server` | `unknown key ID`                                              | 静的アンシールキーIDがデータベースのデータと一致しません。  | プライマリサイトからアンシールシークレットをコピーしてください。[Geoデプロイのトラブルシューティング](#troubleshoot-geo-deployments)を参照してください。 |
| `openbao-server` | `failed to acquire lock`                                      | スタンバイノードは読み取り専用データベースのHAロックを取得できません。 | Geoセカンダリでは予期された動作です。アクションは不要です。                    |
| `openbao-server` | `cannot execute INSERT in a read-only transaction`            | スタンバイノードが読み取りレプリカへの書き込みを試行しました。                   | Geoセカンダリでは予期された動作です。それ以外の場合は、OpenBaoがデータベースへの書き込みアクセス権を持っていることを確認し、データベースのアクセス許可を確認してください。 |
| `openbao-server` | `post-unseal upgrade seal keys failed: error="no recovery key found"` | リカバリーキーが一度も保存されていませんでした。                         | 無害です。`recovery_key:store`を実行します。 |
| RailsまたはSidekiq | `[OpenBao] health check returned unhealthy`                   | OpenBaoは応答しましたが、異常な状態を報告しました。                 | `bao status`とOpenBaoログを確認してください。                            |
| RailsまたはSidekiq | `[OpenBao] health check failed`                               | GitLabはOpenBaoに接続できませんでした。                                    | 接続を確認してください。[GitLabがOpenBaoに接続できない](#gitlab-cannot-connect-to-openbao)を参照してください。 |
| RailsまたはSidekiq | `Failed to authenticate with OpenBao`                         | OpenBaoはJWTを拒否しました。                                          | オーディエンスを確認してください。[JWT認証に失敗する](#jwt-authentication-fails)を参照してください。 |
| RailsまたはSidekiq | `Failed to open TCP connection to <host>:443 (execution expired)` | SidekiqがOpenBao URLに到達できませんでした。                       | SidekiqポッドからDNSとOpenBao URLを確認してください。                   |
| RailsまたはSidekiq | `SSL_connect ... state=error: wrong version number`           | `https` URLが`http`を提供するOpenBaoリスナーを指しています。   | URLスキームをリスナーと一致させてください。[GitLabがOpenBaoに接続できない](#gitlab-cannot-connect-to-openbao)を参照してください。 |
| RailsまたはSidekiq | `Retrying failed secrets_manager maintenance task`            | プロビジョニングまたはデプロビジョニングタスクが再試行されています。            | 同じログ内のワーカーエラーを確認してください。再試行は3回後に停止します。 |

## シークレットマネージャーがプロビジョニングでスタックする {#secrets-manager-is-stuck-in-provisioning}

シークレットマネージャーを有効にすると、切替は`provisioning`のステータスで読み込み状態のままになることがあります。シークレットマネージャーには`failed`状態がないため、アクティベーション前に失敗したステップはレコードをスタックさせます。通常、原因はSidekiqがOpenBaoに到達できないことです。

診断するには:

1. プロビジョニングワーカーのSidekiqログを確認してください:

   ```shell
   kubectl logs -n gitlab -l app=sidekiq -c sidekiq \
     | grep -E "ProvisionProjectSecretsManagerWorker|ProvisionGroupSecretsManagerWorker"
   ```

1. Sidekiqポッドまたはノードから、SidekiqがOpenBaoに到達できるかテストしてください:

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

メンテナンスワーカーは古いタスクを最大3回再試行し、その後停止します。その後、レコードは自動リカバリーなしで`provisioning`状態のままになり、再試行ログには`Retrying failed
secrets_manager maintenance task`と表示されます。

接続を修正した後、シークレットマネージャーを無効にしてから再度有効にして、再度プロビジョニングします。

### 自己初期化後に認証マウントが見つからない {#authentication-mount-missing-after-self-initialization}

複数のOpenBaoポッドがある新規インストールでは、自己初期化の競合により、OpenBaoがアンシールされていても`gitlab_rails_jwt/`認証マウントなしで残されることがあります。ポッドは正常に見えますが、シークレット操作は権限拒否で失敗します。マウントが存在することを確認するために、ルートトークンを使用して`bao auth list`を実行します。競合を防ぐために、単一レプリカで新規インストールを開始し、初期化が完了することを確認してからスケールアップします。

## GitLabがOpenBaoに接続できない {#gitlab-cannot-connect-to-openbao}

GitLab RailsおよびSidekiqはHTTP経由でOpenBaoに接続します。Railsは`internal_url`を使用し、`internal_url`が設定されていない場合は`url`にフォールバックします。設定を検査するには、[Railsコンソール](../operations/rails_console.md)でこれを実行します:

```ruby
Gitlab.config.openbao.to_h
```

一般的な原因:

- `https://` URLが`http`を提供するOpenBaoリスナーに対して機能すると`wrong version number`で失敗します。`global.openbao.https`はGitLabが接続するスキームを設定し、OpenBaoリスナーTLSは設定しません。リスナーはデフォルトでプレーンHTTPを提供します。一致させるには`global.openbao.https`を設定しないままにするか、`openbao.config.tlsDisable: false`でリスナーTLSを有効にし、`global.openbao.https`を`true`に設定してください。
- OIDC検出および監査ログ記録は、信頼されていないTLS証明書のために失敗します。GitLabが信頼する証明書を使用してください。
- OpenBao監査イベントを生成しないリクエストは、認証バックエンドに到達しませんでした。Ingressまたはリバースプロキシを確認してください。

クラウドネイティブインストールの場合、機能する設定は次のようになります:

```yaml
global:
  openbao:
    enabled: true
    url: http://gitlab-openbao-active:8200
    internal_url: http://gitlab-openbao-active:8200
```

Linuxパッケージインストールの場合、GitLabは`/etc/gitlab/gitlab.rb`の`gitlab_rails['openbao']['url']`設定を使用してOpenBaoに接続します。バンドルされたNGINXリバースプロキシは、`oak['components']['openbao']`設定でOpenBaoにルーティングします。詳細については、[Linuxパッケージデプロイ用のOpenBaoのインストール](linux_package_integration.md)を参照してください。

## JWT認証に失敗する {#jwt-authentication-fails}

GitLabはJWTでOpenBaoを認証します。JWTの`aud`（オーディエンス）クレームは、OpenBao認証ロールの`bound_audiences`値と完全に一致する必要があります。末尾のスラッシュ、`http`と`https`の比較、またはポートなどの違いがあると、認証に失敗します。

OpenBaoは、初期化時にOpenBao URLから派生した`bound_audiences`を保存します。保存された値は、後でURLを変更しても変更されません。したがって、URLを変更すると、保存された`bound_audiences`がGitLabが送信する`aud`と一致しなくなるため、認証が機能しなくなります。接続URLとは独立してオーディエンスを設定するには、`global.openbao.jwt_audience`を使用します。

GitLabが送信するオーディエンスを見つけるには、Railsコンソールでこれを実行します:

```ruby
SecretsManagement::ProjectSecretsManager.jwt_audience
```

このメソッドは、`jwt_audience`が設定されていない場合はOpenBaoの`url`を、そうでない場合は設定済みの`jwt_audience`を返します。保存された値を検査するには、ルートトークンで認証ロールを読み取り、`bound_audiences`をそのオーディエンスと比較してください。

> [!warning]
> 特権アクセスなしではこれを修正することはできません。ルートトークンは自己初期化後に失効され、アンシールキーは代替ではありません。アンシールシークレットにはアンシールキーのみが含まれ、ルートトークンは含まれません。

保存されたシークレットを削除せずに不一致を修正するには、リカバリーキーで認証を再設定します。手順については、[リカバリーキーで認証を再設定](maintenance.md#reconfigure-authentication-with-a-recovery-key)を参照してください。

リカバリーキーがない場合は、[OpenBaoデータをリセット](maintenance.md#reset-openbao-data)してください。これにより、保存されているすべてのシークレットが削除されます。

## OpenBaoポッドがシールされる {#openbao-pods-are-sealed}

起動時に`bao status`が`Sealed    true`と報告された場合、自動アンシールに失敗しました:

- デフォルトの静的アンシールでは、通常、原因はアンシールシークレットの欠落または誤りです。シークレットはクラウドネイティブインストールでは`gitlab-openbao-unseal`、Linuxパッケージインストールでは`openbao-static-unseal`です。
- KMS自動アンシール（現在のところAWS KMS (`awskms`)）では、通常、OpenBaoがKMSに到達できないことが原因です。

シールのステータスを確認するには、[OpenBaoステータスを確認](#check-openbao-status)を参照してください。

> [!warning]
> 以前のキーを保持せずに静的アンシールキーをローテーションすると、OpenBaoは既存のデータを復号化できません。以前のキーを新しいキーと並行して追加し、すべてのポッドが新しいキーで実行されるようになってから削除してください。

## データベースの問題 {#database-problems}

OpenBaoには独自のPostgreSQLデータベースが必要です。GitLabチャートは、専用のデータベースなしでOpenBaoを有効にした場合、インストールまたはアップグレードに失敗します。

その他のデータベースの問題:

- 接続プール枯渇または高いレイテンシーは、間欠的なタイムアウトを引き起こします。
- LinuxパッケージPostgreSQL設定で誤った`md5_auth_cidr_addresses`、`sslMode`、またはパスワード値が設定されていると、OpenBaoポッドは`CrashLoopBackOff`状態になります。正しい設定については、[Linuxパッケージデプロイ用のOpenBaoのインストール](linux_package_integration.md)を参照してください。

## 監査イベントが不足している {#audit-events-are-missing}

OpenBaoは`/api/v4/internal/secrets_manager/audit_logs`に監査イベントをGitLabにポストします。GitLabチャートは、デフォルトで監査ログ記録を有効にします。監査イベントが到達しない場合:

- `config.audit.http.enabled`を`false`に設定すると、OpenBaoがイベントをポストしなくなります。監査ログ記録が有効になっていることを確認してください。
- 共有監査ログトークンの不一致は、監査イベントエンドポイントで`401`を返します。GitLabとOpenBaoが同じ監査ログトークンを使用していることを確認してください。

## Geoデプロイのトラブルシューティング {#troubleshoot-geo-deployments}

OpenBaoはプライマリGeoサイトでアクティブノードとして、各セカンダリサイトでスタンバイノードとして実行されます。セカンダリノードは読み取り専用のPostgreSQLレプリカに接続するため、`failed to acquire lock`と`cannot execute INSERT in a read-only transaction`をログに記録します。これらのメッセージは予期されたものです。

セカンダリノードが`cipher: message authentication failed`または`unknown key ID`をログに記録する場合、そのシールキーはプライマリと一致しません。修正はシールメカニズムによって異なります:

- 静的アンシールの場合、プライマリクラスターから`gitlab-openbao-unseal`シークレットをセカンダリクラスターにコピーし、OpenBaoポッドを再起動してください:

  ```shell
  kubectl -n gitlab get secret gitlab-openbao-unseal -o yaml
  ```

- KMSシールの場合、両方のサイトで同じKMSキーを使用するように設定します。

フェイルオーバー後にJWT認証に失敗した場合、オーディエンスが保存されている`bound_audiences`と一致しなくなります。修正はドメインによって異なります:

- 両方のサイトがプライマリOpenBao URLを使用する場合、両方のサイトで`jwt_audience`をプライマリOpenBao URLに設定します。[セカンダリサイトへのOpenBaoのインストール](_index.md#install-openbao-on-a-secondary-site)を参照してください。
- セカンダリサイトが異なるドメインを使用する場合、この設定はサポートされていません。オーディエンスを再設定しても認証は復元されません。これは、すべてのプロジェクトおよびグループネームスペースも再プロビジョニングする必要があるためです。プライマリドメインが昇格されたセカンダリを指すようにDNSを更新してください。詳細については、[Geoデプロイ](_index.md#geo-deployment)を参照してください。

## 遅いシークレット操作を診断する {#diagnose-slow-secret-operations}

CI/CDジョブのシークレットのフェッチが遅い場合や、シークレット操作がタイムアウトする場合は、以下のクエリを使用して原因を特定してください。これらのクエリを、OpenBaoメトリクスをスクレイプするPrometheusまたはGrafanaインスタンスで実行します。これらのメトリクスを公開するには、[OpenBaoメトリクス](_index.md#openbao-metrics)を参照してください。

### レイテンシーが高いことを確認する {#confirm-latency-is-elevated}

平均要求レイテンシーをミリ秒単位で測定するには、次のクエリを使用します。このクエリは、低トラフィックデプロイを含むあらゆるトラフィックレベルで機能します:

```prometheus
rate(openbao_core_handle_request_sum[5m])
/
rate(openbao_core_handle_request_count[5m])
```

通常負荷では、すべてのリクエストタイプの平均レイテンシーは通常3〜7ミリ秒です。平均レイテンシーが継続的に20ミリ秒を超える場合は調査してください。

OpenBaoがアクティブに処理中のリクエストの場合は、P99レイテンシーに次のクエリを使用します:

```prometheus
openbao_core_handle_request{quantile="0.99"}
```

通常のP99は10ミリ秒未満です。OpenBaoがアイドル状態の場合、サマリーウィンドウに最近の観測がないため、このクエリは`NaN`を返します。その場合はレートベースのクエリを使用してください。

### 潜在的な問題を特定する {#identify-potential-issues}

| 潜在的な問題             | 確認事項                   | クエリ                                                                       | しきい値           | アクション                                                             |
|-----------------------------|---------------------------------|-----------------------------------------------------------------------------|---------------------|--------------------------------------------------------------------|
| CPU制限が低すぎる           | CFSスロットル比              | [CPUスロットリングクエリ](_index.md#cpu-throttling)                            | 25%超               | CPU制限を増やす                                                 |
| 需要がCPU容量を超える | CPU使用率                 | [CPU使用率クエリ](_index.md#cpu-utilization)                          | リクエストの50%超    | [サイジングテーブル](_index.md#pod-resources)の次の行にスケールする |
| リクエストの急増               | 処理中のリクエスト              | `openbao_core_in_flight_requests`                                           | 5を継続的に超える   | 一時的。再発を監視する。                                 |
| PostgreSQLボトルネック       | 平均PostgreSQL読み取りレイテンシー | `rate(openbao_postgres_get_sum[5m]) / rate(openbao_postgres_get_count[5m])` | 5ミリ秒超              | PostgreSQLリソースと接続プールを確認                     |
| メモリ負荷             | メモリ使用率              | [メモリ使用率クエリ](_index.md#memory-utilization)                    | メモリリクエストに近い | [ネームスペース数式](_index.md#memory-utilization)を使用してメモリを増やす |

PostgreSQLのレイテンシーが上昇している場合は、接続プールが飽和しているかどうかを確認してください。すべての接続がビジー状態の場合、追加のリクエストがキューに入れられ、レイテンシーが発生します。接続プールの設定については、[データベースリソース](_index.md#database-resources)を参照してください。

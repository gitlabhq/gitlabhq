---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 19アップグレードノート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページには、GitLab 19のマイナーバージョンおよびパッチバージョンに関するアップグレード情報が含まれています。以下の条件を考慮して、各手順を確認してください:

- お使いのインストールタイプ。
- 現在のバージョンから移行先バージョンまでのすべてのバージョン。

Helmチャートインストールの追加情報については、[Helmチャート10.0アップグレードノート](https://docs.gitlab.com/charts/releases/10_0/)を参照してください。

## 必須アップグレードストップ {#required-upgrade-stops}

インスタンス管理者に予測可能なアップグレードスケジュールを提供するために、必須アップグレードストップは、以下のバージョンで発生します:

- `19.2`
- `19.5`
- `19.8`
- `19.11`

## アップグレードノート参照 {#upgrade-notes-reference}

以下は、マイナーGitLabバージョンごとのアップグレードノートの参照リストです。各リスト項目は、詳細情報が記載されている特定のセクションを指しています。

インストール方法が示された項目（`(Geo)`や`(Linux package)`など）は、その方法にのみ適用されます。その他のすべての項目は、すべてのインストール方法に適用されます。

### 19.2へのアップグレード {#upgrade-to-192}

GitLab 19.2にアップグレードする前に、以下を確認してください:

- [19.2.0] - [GitLab Duo Self-Hosted AIゲートウェイURLがアップグレード後にクリアされる](#gitlab-duo-self-hosted-ai-gateway-urls-cleared-after-upgrade)（Linuxパッケージ）

### 19.0へのアップグレード {#upgrade-to-190}

GitLab 19.0へのアップグレード前に、以下を確認してください:

- [19.0.0 - 19.0.1] - [コンテナレジストリメタデータデータベースがデフォルトでプリファーモードで有効化される](#container-registry-metadata-database-enabled-by-default-in-prefer-mode)（Linuxパッケージ、自己コンパイル）
- [19.0.0] - [コンテナレジストリS3ストレージドライバーがs3_v2に置き換えられる](#container-registry-s3-storage-driver-replaced-by-s3_v2)（Linuxパッケージ、自己コンパイル）
- [19.0.0 - 19.1.0] - [LinuxパッケージRPMインストールにおける孤立した`.agents`および`.claude`ディレクトリ](#orphaned-agents-and-claude-directories-on-linux-package-rpm-installs)（Linuxパッケージ）
- [19.0.0] - [PostgreSQL 17の最小要件](#postgresql-17-minimum-requirement)
- [19.0.0] - [Ubuntu 20.04向けLinuxパッケージサポートの終了](#linux-package-support-for-ubuntu-2004-discontinued)（Linuxパッケージ）
- [19.0.0] - [Redis 6サポートの削除](#redis-6-support-removed)（Linuxパッケージ）
- [19.0.0] - [LinuxパッケージからのMattermostの削除](#mattermost-removed-from-the-linux-package)（Linuxパッケージ）
- [19.0.0] - [SUSEディストリビューション向けLinuxパッケージサポートの終了](#linux-package-support-for-suse-distributions-discontinued)（Linuxパッケージ）
- [19.0.0] - [LinuxパッケージおよびGitLab HelmチャートからのSpamcheckの削除](#spamcheck-removed-from-linux-package-and-gitlab-helm-chart)（Linuxパッケージ、Helmチャート）
- [19.0.0] - [NGINX IngressがゲートウェイAPIとEnvoy Gatewayに置き換え](#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway)（Helmチャート）
- [19.0.0] - [バンドルされたPostgreSQL、Redis、MinIOがGitLab Helmチャートから削除](#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart)（Helmチャート）
- [19.0.0 - 19.0.1] - [Geoコンテナリポジトリ同期がOCIイメージインデックスタグをサイレントにスキップする](#geo-container-repository-sync-silently-skips-oci-image-index-tags)（Geo）
- [16.0.0 - 19.0.1] - [Geoデザイン管理レプリケーションでプロジェクトが`nil`の場合に`NoMethodError`が発生する](#geo-design-management-replication-nomethoderror-when-project-is-nil)（Geo）

## アップグレードノート {#upgrade-notes}

GitLab 19に関する特定のアップグレードノート。

### GitLab Duo Self-Hosted AIゲートウェイURLがアップグレード後にクリアされる {#gitlab-duo-self-hosted-ai-gateway-urls-cleared-after-upgrade}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.2.0
- 修正バージョン: 19.2.1

インスタンスをGitLab 19.2.0に直接アップグレードすると、GitLab Duo Self-Hostedサービスエンドポイントの設定がクリアされる可能性があります。**管理者エリア** > **GitLab Duo** > **設定** > **サービスエンドポイント**の以下のフィールドがアップグレード後に空になる可能性があります:

- **ローカルAIゲートウェイURL**
- **GitLab Duo Agent PlatformサービスのローカルURL**

その他の関連する設定もデフォルトに戻る可能性があります。GitLab Duo Self-Hostedの機能は、URLが手動で再入力されるまで動作を停止します。

このイシューは、GitLab 19.2.1以降にアップグレードする場合には発生しません。

19.2.0にすでにアップグレードしていて影響を受けている場合は、**管理者エリア** > **GitLab Duo** > **設定** > **サービスエンドポイント**で正しいAIゲートウェイエンドポイントURLを復元し、変更を保存してください。詳細については、[イシュー606458](https://gitlab.com/gitlab-org/gitlab/-/work_items/606458)を参照してください。

### コンテナレジストリメタデータデータベースがデフォルトでプリファーモードで有効化される {#container-registry-metadata-database-enabled-by-default-in-prefer-mode}

- 対象: Linuxパッケージ、自己コンパイル
- 影響を受けるバージョン: 19.0.0、19.0.1

GitLab 19.0では、既存のインストールで`registry['database']['enabled']`が`/etc/gitlab/gitlab.rb`で明示的に設定されていない場合、コンテナレジストリメタデータデータベースは`prefer`モードをデフォルトとします。preferモードでは、レジストリはメタデータデータベースの使用を試行します。既存のレジストリデータがデータベースにインポートされていない場合、レジistrieは起動時に従来のファイルシステムメタデータにフォールバックします。

バグ（[イシュー600955](https://gitlab.com/gitlab-org/gitlab/-/work_items/600955)）のため、レジストリルーターはプリファーフォールバック検出が実行される前に初期化されました。これにより、すべての`/gitlab/v1/`ルートでnilポインター逆参照パニックが発生し、レジストリUIがグループレベルのストレージサイズをポーリングする際に`HTTP 500`エラーが発生しました。実際のDockerプッシュおよびプルプロトコル（`/v2/`）は、このバグの影響を受けません。

このバグはGitLab 19.0.2で修正されており、コンテナレジストリ`v4.40.1-gitlab`が含まれています。

19.0.0または19.0.1を実行していて、`/var/log/gitlab/registry/current`の`handlers.(*repositoryHandler).HandleGetRepository`で繰り返し`runtime error: invalid memory address or nil pointer dereference`のパニックが発生する場合は、以下の回避策を適用してください:

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   registry['database'] = {
     'enabled' => false
   }
   ```

1. レジストリを再構成して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart registry
   ```

19.0.2以降にアップグレードした後、オーバーライドを削除し、再度再構成してデフォルトの動作を復元します。

詳細については、[コンテナレジストリのメタデータデータベースドキュメント](../../administration/packages/container_registry_metadata_database.md)を参照してください。

### コンテナレジストリS3ストレージドライバーがs3_v2に置き換えられる {#container-registry-s3-storage-driver-replaced-by-s3_v2}

- 対象: Linuxパッケージ、自己コンパイル
- 影響を受けるバージョン: 19.0.0

GitLab 19.0では、レガシーの`s3`コンテナレジストリストレージドライバー（AWS SDK v1）が削除され、新しい`s3_v2`ドライバー（AWS SDK v2）のエイリアスが設定されます。この変更は、Ceph RGW、MinIO、OVH S3など、S3互換のオブジェクトストレージバックエンドを使用するインストールに影響します。

`s3_v2`ドライバーは、非AWS S3互換バックエンドに2つの破壊的変更をもたらします:

- `regionendpoint`には、スキームを含む完全なURIが必要です。`s3_v2`ドライバーは、`regionendpoint`の値に`https://`（または`http://`）を必要とします。`storage.example.com`のようなベアホスト名は無効になり、起動エラーが発生します:

  ```plaintext
  endpoint rule error, Custom endpoint `storage.example.com` was not a valid URI
  ```

  設定を更新して、スキームを含めます:

  ```ruby
  registry['storage'] = {
    's3_v2' => {
      'regionendpoint' => 'https://storage.example.com',
      # ...
    }
  }
  ```

- AWS SDK v2は、強化されたチェックサムをデフォルトで送信します。`s3_v2`ドライバーは、アップロード時に`x-amz-content-sha256`とCRC64NVMEチェックサムを送信します。Ceph RGW、以前のMinIOバージョン、OVH S3、およびその他のS3互換バックエンドは、これらをHTTP 400（`XAmzContentSHA256Mismatch`）で拒否する場合があります。この動作を無効にするには、`'checksum_disabled' => true`を追加してください。

  `checksum_disabled`設定は、アップロード（`PutObject`）呼び出しのチェックサムのみを抑制します。`DeleteObjects`コードパスも、一部のS3互換バックエンドがサポートしないCRC32チェックサムヘッダーを送信します。バックエンドがこのヘッダーを拒否する場合、blob削除をトリガーするイメージプッシュは、`checksum_disabled`が`true`に設定されていても`MissingContentMD5`または`InvalidRequest`エラーで失敗します。

  このイシューを解決するには、S3互換ストレージバックエンドを、CRC32チェックサムヘッダーをサポートするバージョンにアップグレードしてください。必要な最小バージョンについては、ストレージプロバイダーのドキュメントを参照してください。

  `gitlab.rb`設定の回避策は`DeleteObjects`コードパスには存在しません。詳細については、[イシュー2309](https://gitlab.com/gitlab-org/container-registry/-/issues/2309)を参照してください。

Ceph RGWおよびほとんどのS3互換バックエンドでは、次のように設定を更新してください:

```ruby
registry['storage'] = {
  's3_v2' => {
    'accesskey' => '<your-access-key>',
    'secretkey' => '<your-secret-key>',
    'bucket' => '<your-bucket>',
    'region' => '<your-region>',
    'regionendpoint' => 'https://<your-s3-endpoint>',
    'pathstyle' => true,
    'checksum_disabled' => true
  }
}
```

詳細については、[コンテナレジストリのオブジェクトストレージドキュメント](../../administration/packages/container_registry.md#use-object-storage)を参照してください。

### Geoデザイン管理レプリケーションでプロジェクトが`nil`の場合に`NoMethodError`が発生する {#geo-design-management-replication-nomethoderror-when-project-is-nil}

- 対象: Geo
- 影響を受けるバージョン: 16.0.0 - 19.0.1

Geoセカンダリサイトでは、関連するプロジェクトが削除され、孤立した`DesignManagement::Repository`レコードが残された場合に、デザイン管理リポジトリのレプリケーション中に`NoMethodError`が発生する可能性があります。GitLab 19.0.2でこのイシューが修正されます。

詳細については、[イシュー597049](https://gitlab.com/gitlab-org/gitlab/-/issues/597049)を参照してください。

### PostgreSQL 17の最小要件 {#postgresql-17-minimum-requirement}

- 対象: すべてのインストール方法
- 影響を受けるバージョン: 19.0.0

PostgreSQLの最小サポートバージョンはバージョン17になりました。GitLab 19.0をインストールする前に:

- バンドルされたPostgreSQL 16を使用している場合は、[バンドルされたPostgreSQLサーバーをアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)してください。
- [外部PostgreSQL](../../administration/postgresql/external.md)インスタンスを使用している場合は、PostgreSQL 17にアップグレードしてください。

### Geoコンテナリポジトリ同期がOCIイメージインデックスタグをサイレントにスキップする {#geo-container-repository-sync-silently-skips-oci-image-index-tags}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 対象: Geo（コンテナレジストリ）
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 19.0    | 19.0.0 - 19.0.1         | 19.0.2            |

Geoセカンダリサイトでは、コンテナリポジトリ同期が、マニフェストがOCIイメージインデックス（`application/vnd.oci.image.index.v1+json`）であるタグをサイレントにスキップしました。マルチアーチ画像とBuildKitキャッシュのタグは、一般的にこのマニフェストタイプを使用します。エラーは発生せず、タグのカウントは一致しましたが、セカンダリからの影響を受けたタグの`docker pull`は`manifest unknown`を返しました。同じ根本原因により、同期で削除できない孤立したタグがセカンダリに残されました。

プライマリサイトとセカンダリサイトの両方を修正済みバージョンにアップグレードすると、新しく同期されたタグは正しくなります。以前影響を受けたリポジトリは、次回の検証サイクルで収束します。これには再検証間隔（既定では90日）までかかる場合があります。影響を受けたリポジトリを直ちに修正するには、[セカンダリサイトでコンテナリポジトリを再同期](../../administration/geo/replication/container_registry.md#manually-trigger-a-container-registry-sync-event)してください。

詳細については、[イシュー600486](https://gitlab.com/gitlab-org/gitlab/-/work_items/600486)を参照してください。

### Ubuntu 20.04のLinuxパッケージサポートが終了しました {#linux-package-support-for-ubuntu-2004-discontinued}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

Ubuntu 20.04は2025年5月に標準サポートが終了しました。GitLab 19.0以降、Ubuntu 20.04用のLinuxパッケージは提供されなくなりました。GitLab 18.11がこのディストリビューション向けパッケージの最後のリリースです。GitLab 19.0にアップグレードする前に、Ubuntu 22.04または別の[サポートされているオペレーティングシステム](../../install/package/_index.md#supported-platforms)に移行してください。

### Redis 6のサポートが削除されました {#redis-6-support-removed}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

GitLab 19.0でRedis 6のサポートが削除されました。外部のRedis 6デプロイを使用している場合は、アップグレードする前にRedis 7.0以上またはValkey 7.2に移行してください。Redis 7.2またはValkey 7.2が推奨されます。Redis 7.0はアップストリームでEOL（End-of-Life）に達しましたが、Amazon ElastiCache for Redis 7.1のように、一部のケースではベンダーによって積極的にメンテナンスされています。Linuxパッケージに含まれるバンドルされたRedisは、GitLab 16.2以降Redis 7を使用しており、影響を受けません。

### MattermostがLinuxパッケージから削除されました {#mattermost-removed-from-the-linux-package}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

バンドル版Mattermostは、GitLab 19.0でLinuxパッケージから削除されました。現在、バンドルされたMattermostを使用している場合は、移行手順について[LinuxパッケージからMattermost Standaloneへの移行](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)を参照してください。バンドルされたMattermostを使用していない場合は、影響を受けません。

GitLab 19.0にアップグレードする前に、`/etc/gitlab/gitlab.rb`からすべての`mattermost[...]`設定を削除またはコメントアウトしてください。いずれかの`mattermost[...]`キーが残っている場合、パッケージのインストール直後に`gitlab-ctl reconfigure`が以下のメッセージで中断します:

```plaintext
RuntimeError: Removed configurations found in gitlab.rb. Aborting reconfigure.
```

> [!warning]
> 特定の18.11.xバージョンからアップグレードする場合の動作は異なります:
>
> - 18.11.0から18.11.6: アップグレードは古いMattermost設定を検知しないため、クリーンアップが不完全でも警告なしでアップグレードが続行されます。アップグレード前にMattermostキーの削除を検証するために`gitlab-ctl check-config --version 19.0.x`に依存しないでください（[イシュー9916](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9916)）。
> - 18.11.7: すべての`mattermost[...]`キーが`gitlab.rb`から削除されていても、アップグレードはブロックされます。このブロックは、GitLabがノードキャッシュ内で無条件に生成した古いMattermostシークレットによって引き起こされる誤検出です。アップグレードのブロックを解除するには、次のいずれかのオプションを使用してください:
>   - 19.0にアップグレードする前に、18.11.xの以降のバージョン（利用可能な場合）にアップグレードしてください。
>   - [手動の回避策](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/10001#workaround)を適用してください。

### SUSEディストリビューション向けのLinuxパッケージサポートが終了しました {#linux-package-support-for-suse-distributions-discontinued}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

SUSEディストリビューション向けのLinuxパッケージサポートはGitLab 19.0で終了します。これにはopenSUSE Leap 15.6、SUSE Linux Enterprise Server 12.5、およびSUSE Linux Enterprise Server 15.6が含まれます。GitLab 18.11がこれらのディストリビューション向けのLinuxパッケージを搭載した最後のバージョンです。SUSEディストリビューションの使用を継続するには、[GitLabのDockerデプロイ](../../install/docker/installation.md)に移行してください。

### SpamcheckがLinuxパッケージとGitLab Helmチャートから削除されました {#spamcheck-removed-from-linux-package-and-gitlab-helm-chart}

- 対象: Linuxパッケージ、Helmチャート
- 影響を受けるバージョン: 19.0.0

[Spamcheck](../../administration/reporting/spamcheck.md)はGitLab 19.0でLinuxパッケージとGitLab Helmチャートから削除されました。現在Spamcheckを使用していないお客様は影響を受けません。バンドル版のSpamcheckを使用している場合、[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)を使用して個別にデプロイできます。データ移行は不要です。

### NGINX IngressがEnvoy Gatewayを伴うゲートウェイAPIに置き換えられました {#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway}

- 対象: Helmチャート
- 影響を受けるバージョン: 19.0.0

Envoy Gatewayを伴うゲートウェイAPIが、GitLab 19.0のGitLab Helmチャートにおけるデフォルトのネットワーク設定となり、2026年3月にサポート終了となったNGINX Ingressを置き換えます。Envoy Gatewayへの移行がすぐに実行できない場合は、バンドルされているNGINX Ingressを明示的に再有効化できます。これはGitLab 20.0での削除が提案されるまで利用可能です。この変更は、Linuxパッケージで使用されているNGINX、または外部管理のIngressもしくはゲートウェイAPIコントローラーを使用しているHelmチャートインスタンスには影響しません。

詳細な移行手順については、[Helmチャート10.0アップグレードノート](https://docs.gitlab.com/charts/releases/10_0/)を参照してください。

### バンドル版PostgreSQL、Redis、MinIOがGitLab Helmチャートから削除されました {#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart}

- 対象: Helmチャート
- 影響を受けるバージョン: 19.0.0

バンドル版Bitnami PostgreSQL、Bitnami Redis、およびMinIOチャートは、GitLab 19.0でGitLab HelmチャートおよびGitLab Operatorから削除され、代替品はありません。これらのコンポーネントは概念実証およびテスト環境のみを目的としており、本番環境での使用は推奨されません。これらのバンドルサービスを伴うインスタンスを実行している場合は、GitLab 19.0にアップグレードする前に、[移行ガイド](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)に従って外部サービスを設定してください。

### LinuxパッケージRPMインストールにおける孤立した`.agents`および`.claude`ディレクトリ {#orphaned-agents-and-claude-directories-on-linux-package-rpm-installs}

- 対象: Linuxパッケージ（RPM）
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  |:--------|:------------------------|:------------------|
  | 19.0    | 19.0.0 - 19.0.2         | 19.0.3            |
  | 19.1    | 19.1.0                  | 19.1.1            |

影響を受けたパッチリリースのLinuxパッケージには、誤って`/opt/gitlab/embedded/service/gitlab-rails/`の下に2つのディレクトリが含まれていました:

- `.agents/`
- `.claude/`

これらのディレクトリは、修正済みパッチレベルからパッケージペイロードから除外され、GitLab 19.2以降ではデフォルトで除外されます。詳細については、[イシュー603547](https://gitlab.com/gitlab-org/gitlab/-/issues/603547)を参照してください。

RPMベースのディストリビューションでは、RPMは、ディレクトリにファイルが含まれている場合、所有しなくなったディレクトリを削除しません。LinuxパッケージRPMインストールを修正済みバージョンを過ぎてアップグレードした後でも、これらのディレクトリはディスク上に残る可能性があります:

- `/opt/gitlab/embedded/service/gitlab-rails/.agents`
- `/opt/gitlab/embedded/service/gitlab-rails/.claude`

RPMはこれらの孤立したディレクトリを自動的に削除しません。これらのディレクトリを確認し、存在する場合は手動で削除してください:

1. ディレクトリが存在するかどうかを確認します:

   ```shell
   ls -la /opt/gitlab/embedded/service/gitlab-rails/.agents \
          /opt/gitlab/embedded/service/gitlab-rails/.claude
   ```

1. ディレクトリが存在する場合は、削除します:

   ```shell
   sudo rm -rf /opt/gitlab/embedded/service/gitlab-rails/.agents \
               /opt/gitlab/embedded/service/gitlab-rails/.claude
   ```

DEBベースのディストリビューションは、`dpkg`がアップグレード中に所有しなくなったディレクトリを削除するため、影響を受けません。

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

### 19.0へのアップグレード {#upgrade-to-190}

GitLab 19.0へのアップグレード前に、以下を確認してください:

- [19.0.0] - [PostgreSQL 17の最小要件](#postgresql-17-minimum-requirement)
- [19.0.0] - [Ubuntu 20.04向けLinuxパッケージサポートの終了](#linux-package-support-for-ubuntu-2004-discontinued) (Linuxパッケージ)
- [19.0.0] - [Redis 6サポートの削除](#redis-6-support-removed) (Linuxパッケージ)
- [19.0.0] - [LinuxパッケージからのMattermostの削除](#mattermost-removed-from-the-linux-package) (Linuxパッケージ)
- [19.0.0] - [SUSEディストリビューション向けLinuxパッケージサポートの終了](#linux-package-support-for-suse-distributions-discontinued) (Linuxパッケージ)
- [19.0.0] - [LinuxパッケージおよびGitLab HelmチャートからのSpamcheckの削除](#spamcheck-removed-from-linux-package-and-gitlab-helm-chart) (Linuxパッケージ, Helmチャート)
- [19.0.0] - [NGINX IngressがゲートウェイAPIとEnvoy Gatewayに置き換え](#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway) (Helmチャート)
- [19.0.0] - [バンドルされたPostgreSQL、Redis、MinIOがGitLab Helmチャートから削除](#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart) (Helmチャート)

## アップグレードノート {#upgrade-notes}

GitLab 19に関する特定のアップグレードノート。

### PostgreSQL 17の最小要件 {#postgresql-17-minimum-requirement}

- 対象: すべてのインストール方法
- 影響を受けるバージョン: 19.0.0

PostgreSQLの最小サポートバージョンはバージョン17になりました。GitLab 19.0をインストールする前に:

- バンドルされたPostgreSQL 16を使用している場合は、[バンドルされたPostgreSQLサーバーをアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)してください。
- [外部PostgreSQL](../../administration/postgresql/external.md)インスタンスを使用している場合は、PostgreSQL 17にアップグレードしてください。

### Ubuntu 20.04のLinuxパッケージサポートが終了しました {#linux-package-support-for-ubuntu-2004-discontinued}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

Ubuntu 20.04は2025年5月に標準サポートが終了しました。GitLab 19.0以降、Ubuntu 20.04用のLinuxパッケージは提供されなくなりました。GitLab 18.11がこのディストリビューション向けパッケージの最後のリリースです。GitLab 19.0にアップグレードする前に、Ubuntu 22.04または別の[サポートされているオペレーティングシステム](../../install/package/_index.md#supported-platforms)に移行してください。

### Redis 6のサポートが削除されました {#redis-6-support-removed}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

GitLab 19.0でRedis 6のサポートが削除されました。外部のRedis 6デプロイを使用している場合は、アップグレードする前にRedis 7.2またはValkey 7.2に移行してください。Linuxパッケージに含まれるバンドル版Redisは、GitLab 16.2以降Redis 7を使用しており、影響を受けません。

### MattermostがLinuxパッケージから削除されました {#mattermost-removed-from-the-linux-package}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

バンドル版Mattermostは、GitLab 19.0でLinuxパッケージから削除されました。現在、バンドルされたMattermostを使用している場合は、移行手順について[LinuxパッケージからMattermost Standaloneへの移行](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)を参照してください。バンドルされたMattermostを使用していない場合は、影響を受けません。

### SUSEディストリビューション向けのLinuxパッケージサポートが終了しました {#linux-package-support-for-suse-distributions-discontinued}

- 対象: Linuxパッケージ
- 影響を受けるバージョン: 19.0.0

SUSEディストリビューション向けのLinuxパッケージサポートはGitLab 19.0で終了します。これにはopenSUSE Leap 15.6、SUSE Linux Enterprise Server 12.5、およびSUSE Linux Enterprise Server 15.6が含まれます。GitLab 18.11がこれらのディストリビューション向けのLinuxパッケージを搭載した最後のバージョンです。SUSEディストリビューションの使用を継続するには、[GitLabのDockerデプロイ](../../install/docker/installation.md)に移行してください。

### SpamcheckがLinuxパッケージとGitLab Helmチャートから削除されました {#spamcheck-removed-from-linux-package-and-gitlab-helm-chart}

- 対象: Linuxパッケージ、Helmチャート
- 影響を受けるバージョン: 19.0.0

[Spamcheck](../../administration/reporting/spamcheck.md)はGitLab 19.0でLinuxパッケージとGitLab Helmチャートから削除されました。現在Spamcheckを使用していないお客様は影響を受けません。バンドル版のSpamcheckを使用している場合、[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)を使用して個別にデプロイできます。データ移行は必要ありません。

### NGINX IngressがEnvoy Gatewayを伴うゲートウェイAPIに置き換えられました {#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway}

- 対象: Helmチャート
- 影響を受けるバージョン: 19.0.0

Envoy Gatewayを伴うゲートウェイAPIが、GitLab 19.0のGitLab Helmチャートにおけるデフォルトのネットワーク設定となり、2026年3月にサポート終了となったNGINX Ingressを置き換えます。Envoy Gatewayへの移行がすぐに実行できない場合は、バンドルされているNGINX Ingressを明示的に再有効化できます。これはGitLab 20.0での削除が提案されるまで利用可能です。この変更は、Linuxパッケージで使用されているNGINX、または外部管理のIngressもしくはゲートウェイAPIコントローラーを使用しているHelmチャートインスタンスには影響しません。

詳細な移行手順については、[Helmチャート10.0アップグレードノート](https://docs.gitlab.com/charts/releases/10_0/)を参照してください。

### バンドル版PostgreSQL、Redis、MinIOがGitLab Helmチャートから削除されました {#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart}

- 対象: Helmチャート
- 影響を受けるバージョン: 19.0.0

バンドル版Bitnami PostgreSQL、Bitnami Redis、およびMinIOチャートは、GitLab 19.0でGitLab HelmチャートおよびGitLab Operatorから削除され、代替品はありません。これらのコンポーネントは概念実証およびテスト環境のみを目的としており、本番環境での使用は推奨されません。これらのバンドルサービスを伴うインスタンスを実行している場合は、GitLab 19.0にアップグレードする前に、[移行ガイド](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)に従って外部サービスを設定してください。

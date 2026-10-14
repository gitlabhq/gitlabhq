---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 18のアップグレードノート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページには、GitLab 18のマイナーバージョンおよびパッチバージョンに関するアップグレード情報が記載されています。次の点について、必ずこの手順を確認してください。

- お使いのインストールタイプ。
- 現在のバージョンからアップグレード先のバージョンまでのすべてのバージョン。

Helmチャートのインストールに関する追加情報については、
[Helmチャート9.0のアップグレードノート](https://docs.gitlab.com/charts/releases/9_0/)を参照してください。

## 必須のアップグレードストップ {#required-upgrade-stops}

インスタンス管理者が予測しやすいアップグレードスケジュールを立てられるように、次のバージョンが必須のアップグレードストップとなっています。

- `18.2`
- `18.5`
- `18.8`
- `18.11`

## アップグレードノートのリファレンス {#upgrade-notes-reference}

以下は、GitLabの各マイナーバージョンに関するアップグレードノートのリファレンス一覧です。
各項目は、詳細情報が記載されている該当のセクションにリンクしています。

`(Geo)`や`(Linuxパッケージ)`のようにインストール方法が明記されている項目は、その方法にのみ該当します。それ以外の項目はすべてのインストール方法に該当します。

### 18.11へのアップグレード {#upgrade-to-1811}

GitLab 18.11にアップグレードする前に、次の内容を確認してください。

- [18.11.0 - 18.11.2] - [ファイルストレージで`log_error` NoMethodErrorが発生してGeo blobの同期が失敗する](#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage) (Geo)
- [18.11.0 - 18.11.4] - [Geoコンテナリポジトリの同期でOCIイメージインデックスタグが通知なくスキップされる](#geo-container-repository-sync-silently-skips-oci-image-index-tags) (Geo)
- [18.11.0 - 18.11.1] - [内部プロジェクトおよびパブリックプロジェクトからコンテナイメージをプルする際のCIジョブトークンのリグレッション](#ci-job-token-regression-pulling-container-images-from-internal-and-public-projects)
- [18.11.0] - [18.11へのアップグレードでPostgreSQL 17.7へのバージョンアップグレードが実行される](#postgresql-version-177-upgrade-on-gitlab-1811) (Linuxパッケージ、Docker、Geo)
- [18.11.0] - [SLES 12.5パッケージからMattermostとSpamcheckを削除](#mattermost-and-spamcheck-removed-from-sles-125-packages) (Linuxパッケージ)
- [18.11.0] - [コンパイルされたジョブごとの設定に1 MiBのサイズ制限が適用される](#compiled-per-job-config-is-subject-to-a-1-mib-size-limit)

### 18.10へのアップグレード {#upgrade-to-1810}

GitLab 18.10にアップグレードする前に、次の内容を確認してください。

- [18.10.0 - 18.10.3] - [SLES 12.5のRPMパッケージのインストール失敗](#sles-125-rpm-package-installation-failure) (Linuxパッケージ)
- [18.10.0 - 18.10.5] - [ファイルストレージで`log_error` NoMethodErrorが発生してGeo blobの同期が失敗する](#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage) (Geo)
- [18.10.0 - 18.10.7] - [Geoコンテナリポジトリの同期でOCIイメージインデックスタグが通知なくスキップされる](#geo-container-repository-sync-silently-skips-oci-image-index-tags) (Geo)
- [18.10.0 - 18.10.3] - [送信フィルタリング使用時にGeoサイトのURLがブロックされる](#geo-site-url-blocked-when-using-outbound-filtering) (Geo)
- [18.10.0 - 18.10.4] - [Geo blobダウンロードの失敗](#geo-blob-download-failures) (Geo)
- [18.10.0 - 18.10.3] - [Geoセカンダリのスロットリングされたジョブが消化されない](#geo-secondary-throttled-jobs-not-draining) (Geo)
- [18.10.0 - 18.10.3] - [HelmチャートおよびOperatorのデプロイで、Sidekiqの並行処理リミッターがジョブのバックログを引き起こす](#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments) (Helmチャート、Operator)
- [18.10.0] - [すべてのプロジェクトでシークレットの誤検出判定がデフォルトで有効になる](#secret-detection-false-positive-detection-enabled-by-default-on-all-projects)
- [18.10.0] - [引用符のないプレースホルダーを含むカスタムWebhookテンプレートを保存できない](#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)
- [18.10.0] - [パイプライン実行ポリシーのdotenv変数が`variables_override`に従う](#dotenv-variables-in-pipeline-execution-policies-respect-variables_override)

### 18.9へのアップグレード {#upgrade-to-189}

GitLab 18.9にアップグレードする前に、次の内容を確認してください。

- [18.9.1 - 18.9.5] - [SLES 12.5のRPMパッケージのインストール失敗](#sles-125-rpm-package-installation-failure) (Linuxパッケージ)
- [18.9.0 - 18.9.5] - [送信フィルタリング使用時にGeoサイトのURLがブロックされる](#geo-site-url-blocked-when-using-outbound-filtering) (Geo)
- [18.9.0 - 18.9.5] - [Geoセカンダリのスロットリングされたジョブが消化されない](#geo-secondary-throttled-jobs-not-draining) (Geo)
- [18.9.0 - 18.9.5] - [HelmチャートおよびOperatorのデプロイで、Sidekiqの並行処理リミッターがジョブのバックログを引き起こす](#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments) (Helmチャート、Operator)
- [18.9.0] - [18.9へのアップグレードがPostgreSQL CheckViolationで失敗する](#upgrade-to-189-fails-with-postgresql-checkviolation)
- [18.9.0] - [引用符のないプレースホルダーを含むカスタムWebhookテンプレートを保存できない](#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)

### 18.8へのアップグレード {#upgrade-to-188}

GitLab 18.8にアップグレードする前に、次の内容を確認してください。

- [18.8.2] - [ブロックされたユーザーのデプロイキーとパーソナルアクセストークンが無効化される](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.8.0] - [マージリクエストのマージデータに対するバッチ処理のバックグラウンド移行](#batched-background-migration-for-merge-request-merge-data)
- [18.8.0] - [ClickHouseディクショナリ作成エラー](#clickhouse-dictionary-creation-error)
- [18.8.0] - [CIデータに対するバッチ処理のバックグラウンド移行の再導入](#batched-background-migration-for-ci-data-reintroduced)
- [18.8.0] - [引用符のないプレースホルダーを含むカスタムWebhookテンプレートを保存できない](#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)

### 18.7へのアップグレード {#upgrade-to-187}

GitLab 18.7にアップグレードする前に、次の内容を確認してください。

- [18.7.2] - [ブロックされたユーザーのデプロイキーとパーソナルアクセストークンが無効化される](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.7.0] - [CIビルドのメタデータ移行](#ci-builds-metadata-migration)
- [18.7.0] - [Geo ActionCableの許可オリジン設定](#geo-actioncable-allowed-origins-setting) (Geo)

### 18.6へのアップグレード {#upgrade-to-186}

GitLab 18.6にアップグレードする前に、次の内容を確認してください。

- [18.6.5] - [Geo VerificationStateBackfillWorkerの低速クエリの修正](#geo-verificationstatebackfillworker-slow-queries-fix) (Geo)
- [18.6.4] - [ブロックされたユーザーのデプロイキーとパーソナルアクセストークンが無効化される](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.6.2] - [コミットAPIおよびファイルAPIのサイズ制限とレート制限](#commits-and-files-api-size-and-rate-limits)
- [18.6.2] - [Duo Agent PlatformのRunner制限](#duo-agent-platform-runner-restrictions)

### 18.5へのアップグレード {#upgrade-to-185}

GitLab 18.5にアップグレードする前に、次の内容を確認してください。

- [18.5.4] - [コミットAPIおよびファイルAPIのサイズ制限とレート制限](#commits-and-files-api-size-and-rate-limits)
- [18.5.0 - 18.5.1] - [Geoログカーソル移行の修正](#geo-log-cursor-migration-fix) (Geo)
- [18.5.0] - [デザイン管理のデザインバックフィルの完了処理](#finalize-design-management-designs-backfill)
- [18.5.0] - [NGINXのルーティング変更により404エラーが発生する](#nginx-routing-changes-cause-404-errors) (Linuxパッケージ)

### 18.4へのアップグレード {#upgrade-to-184}

GitLab 18.4にアップグレードする前に、次の内容を確認してください。

- [18.4.6] - [コミットAPIおよびファイルAPIのサイズ制限とレート制限](#commits-and-files-api-size-and-rate-limits)
- [18.4.2 - 18.4.3] - [バッチ処理のバックグラウンド移行のnilエラー](#batched-background-migration-nil-error)
- [18.4.1] - [サービス拒否を防止するためのJSON入力制限](#json-input-limits-for-denial-of-service-prevention)
- [18.4.0 - 18.4.3] - [Geoログカーソル移行の修正](#geo-log-cursor-migration-fix) (Geo)
- [18.4.0 - 18.4.1] - [GeoレプリケーションのTypeError](#geo-replication-typeerror) (Geo)

### 18.3へのアップグレード {#upgrade-to-183}

GitLab 18.3にアップグレードする前に、次の内容を確認してください。

- [18.3.3] - [サービス拒否を防止するためのJSON入力制限](#json-input-limits-for-denial-of-service-prevention)
- [18.3.0] - [LdapAddOnSeatSyncWorkerがDuoシートを削除する](#ldapaddonseatsyncworker-removes-duo-seats)
- [18.3.0] - [Geo Rakeチェックの修正](#geo-rake-check-fix) (Geo)
- [18.3.0 - 18.3.2] - [Geo Pagesファイル名の修正](#geo-pages-filename-fix) (Geo)

### 18.2へのアップグレード {#upgrade-to-182}

GitLab 18.2にアップグレードする前に、次の内容を確認してください。

- [18.2.7] - [サービス拒否を防止するためのJSON入力制限](#json-input-limits-for-denial-of-service-prevention)
- [18.2.0] - [18.1と18.2の間のゼロダウンタイムアップグレードでのプッシュエラー](#zero-downtime-upgrade-push-errors-between-181-and-182)
- [18.2.0 - 18.2.1] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.2.0 - 18.2.6] - [Geo Pagesファイル名の修正](#geo-pages-filename-fix) (Geo)

### 18.1へのアップグレード {#upgrade-to-181}

GitLab 18.1にアップグレードする前に、次の内容を確認してください。

- [18.1.0] - [Elasticsearch `strict_dynamic_mapping_exception`](#elasticsearch-strict_dynamic_mapping_exception)
- [18.1.0 - 18.1.1] - [PostgreSQL `ci_job_artifacts`エラー](#postgresql-ci_job_artifacts-error)
- [18.1.0] - [マージリクエストの「ほぼ準備完了」バグ](#merge-request-almost-ready-bug)
- [18.1.0] - [Geo HTTP 500プロキシエラー](#geo-http-500-proxy-errors) (Geo)
- [18.1.0 - 18.1.3] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.1.0] - [Geo Pagesファイル名の修正](#geo-pages-filename-fix) (Geo)

### 18.0へのアップグレード {#upgrade-to-180}

GitLab 18.0にアップグレードする前に、次の内容を確認してください。

- [18.0.0] - [PostgreSQL 14はサポート対象外](#postgresql-14-not-supported)
- [18.0.0] - [`pg_dump`バイナリの互換性](#pg_dump-binary-compatibility)
- [18.0.0] - [17.11からのゼロダウンタイムアップグレード中のパイプライン失敗](#pipeline-failures-during-zero-downtime-upgrades-from-1711)
- [18.0.0] - [Gitaly設定を`git_data_dirs`からstorageに移行する](#migrate-gitaly-configuration-from-git_data_dirs-to-storage) (Linuxパッケージ)
- [18.0.0 - 18.0.1] - [Geo CEからEEへのリバート移行エラー](#geo-ce-to-ee-revert-migration-errors) (Geo)
- [18.0.0 - 18.0.2] - [Geo HTTP 500プロキシエラー](#geo-http-500-proxy-errors) (Geo)
- [18.0.0 - 18.0.5] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.0.0] - [Docker環境での「PRNG is not seeded」エラー](#prng-is-not-seeded-error-on-docker-installations) (Docker)
- [17.11.0] - [BitnamiのPostgreSQLおよびRedisイメージの非推奨化](#bitnami-postgresql-and-redis-image-deprecation) (Helmチャート)

## アップグレードノート {#upgrade-notes}

GitLab 18に関する個別のアップグレードノートです。

### パイプライン実行ポリシーのdotenv変数が`variables_override`に従う {#dotenv-variables-in-pipeline-execution-policies-respect-variables_override}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

- 影響: パイプライン実行ポリシー
- 影響を受けるバージョン:

  | リリース     | 影響を受けるパッチリリース |
  | ----------- | ----------------------- |
  | 18.10       | 18.10.0以降       |

GitLab 18.10以降では、dotenvアーティファクト
(`artifacts:reports:dotenv`)の変数は、パイプライン実行ポリシー内の他の変数と同じ
`variables_override`ルールの対象となります(セキュアバイデフォルト)。
以前は、dotenv変数が`variables_override`の制限をバイパスできたため、
ポリシーのセキュリティ制御が損なわれていました。

パイプラインがdotenv変数を使用してポリシーで定義された変数をオーバーライドしていた場合、
`variables_override.allowed: false`が設定されていると、その動作は機能しなくなります。
以前の動作に戻すには、新しい`dotenv`オプションを`allow_override`に設定します。

```yaml
variables_override:
  allowed: false
  exceptions: []
  dotenv: allow_override
```

詳細については、
[パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)および
[マージリクエスト214991](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214991)を参照してください。

### ファイルストレージで`log_error` NoMethodErrorが発生してGeo blobの同期が失敗する {#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo(ファイルストレージのみ)
- 影響を受けるバージョン:

  | リリース           | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ----------------- |-------------------------|-------------------|
  | 18.11             | 18.11.0 - 18.11.2       | 18.11.3           |
  | 18.10             | 18.10.0 - 18.10.5       | 18.10.6           |
  | 18.0 - 18.9       | すべてのパッチリリース      | 未修正         |

blobを**ファイルストレージ**(オブジェクトストレージではなく)に保存しているGeoセカンダリサイトで、
blobのレプリケーション(パイプラインアーティファクト、LFSオブジェクト、アップロード、
ジョブアーティファクトなど)が、誤解を招くエラーで失敗することがあります。

```plaintext
Error while attempting to sync: undefined method `log_error' for an instance of Gitlab::Geo::Replication::BlobDownloader
```

詳細については、[イシュー598565](https://gitlab.com/gitlab-org/gitlab/-/work_items/598565)を参照してください。

### Geoコンテナリポジトリの同期でOCIイメージインデックスタグが通知なくスキップされる {#geo-container-repository-sync-silently-skips-oci-image-index-tags}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo(コンテナレジストリ)
- 影響を受けるバージョン:

  | リリース     | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ----------- | ----------------------- | ----------------- |
  | 18.11       | 18.11.0 - 18.11.4       | 18.11.5           |
  | 18.10       | 18.10.0 - 18.10.7       | 18.10.8           |
  | 18.0 - 18.9 | すべてのパッチリリース      | 未修正         |

Geoセカンダリサイトでは、コンテナリポジトリの同期時に、マニフェストがOCIイメージインデックス
(`application/vnd.oci.image.index.v1+json`)であるタグが通知なくスキップされていました。
マルチアーキテクチャイメージやBuildKitキャッシュタグでは、このマニフェストタイプが一般的に使用されます。
エラーは発生せず、タグ数も一致していましたが、影響を受けるタグをセカンダリから`docker pull`すると
`manifest unknown`が返されました。同じ根本原因により、同期で削除できない
孤立したタグがセカンダリに残る問題も発生していました。

プライマリサイトとセカンダリサイトの両方を修正済みバージョンにアップグレードすると、新たに
同期されるタグは正しくなります。以前に影響を受けたリポジトリは、次回の検証サイクルで
正常な状態に収束します。これには、再検証間隔(デフォルトでは90日)までかかる場合があります。
影響を受けたリポジトリをただちに修復するには、
[セカンダリサイトでコンテナリポジトリを再同期](../../administration/geo/replication/container_registry.md#manually-trigger-a-container-registry-sync-event)します。

詳細については、[イシュー600486](https://gitlab.com/gitlab-org/gitlab/-/work_items/600486)を参照してください。

### 内部プロジェクトおよびパブリックプロジェクトからコンテナイメージをプルする際のCIジョブトークンのリグレッション {#ci-job-token-regression-pulling-container-images-from-internal-and-public-projects}

- 影響: すべてのインストール方法
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.11   | 18.11.0 - 18.11.1       | 18.11.2           |

> [!warning]
> CIジョブが`CI_JOB_TOKEN`を使用して内部プロジェクトまたはパブリックプロジェクトから
> コンテナイメージをプルしている場合は、GitLab 18.11.0または18.11.1にアップグレードしないでください。

GitLab 18.11.0のリグレッションにより、CIジョブが`CI_JOB_TOKEN`を使用して内部プロジェクトまたは
パブリックプロジェクトからコンテナイメージをプルできなくなります。影響を受けるパイプラインは
`denied: requested access to the resource is denied`というエラーで失敗します。この修正は
`18-11-stable-ee`にバックポートされましたが、18.11.1のタグが作成された後にマージされたため、
18.11.0と18.11.1の両方が影響を受けます。

すでにアップグレードしてしまった管理者は、次の回避策を利用できます。

1. 使用する各プロジェクトを、ソースプロジェクトのCIジョブトークンの許可リストに追加します。
   [CI/CDジョブトークンのセキュリティ](../../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security)を参照してください。
1. コンテナのプルの認証に、`CI_JOB_TOKEN`ではなく、パーソナルアクセストークン、グループアクセストークン、
   またはプロジェクトアクセストークンを使用します。
1. バックポートのコミット
   [`e3c0f308`](https://gitlab.com/gitlab-org/gitlab/-/commit/e3c0f30800f803b8f519e9b937296b068d8f4cca)
   をGitLabインスタンスに適用します。

詳細については、[イシュー597223](https://gitlab.com/gitlab-org/gitlab/-/work_items/597223)を参照してください。

### SLES 12.5のRPMパッケージのインストール失敗 {#sles-125-rpm-package-installation-failure}

- 影響: Linuxパッケージ
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース          | インストール可能なパッチレベル |
  | ------- | -------------------------------- | ----------------------- |
  | 18.10   | 18.10.0 - 18.10.3                | 18.10.4 - 18.10.5       |
  | 18.9    | 18.9.1 - 18.9.5                  | 18.9.0、18.9.6          |

> [!warning]
> SLES 12.5で正常にインストールできるのは、GitLab 18.9.0、18.10.4、18.11.2のみです。
> 影響範囲内のその他のパッチリリースは、インストールに失敗します。

SLES 12.5向けのGitLab Linuxパッケージは、`rpm`コマンドまたは`zypper`コマンドを使用すると
`error: install failed`でインストールに失敗します。根本原因は、SLES 12 SP5に同梱されている
RPM 4.11.2に、RPMヘッダーデータサイズが16 MiBまでという制限(`HEADER_DATA_MAX`)があることです。
GitLabパッケージに含まれるファイル数が増加したことで、シリアライズされたRPMヘッダーがこの制限を超え、
インストール中にRPMデータベースのトランザクションが通知なく失敗していました。

この問題は、Linuxパッケージのファイル数を減らすことで、特定のパッチリリースで解決されました
([マージリクエスト9215](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9215)を参照)。
ただし、ファイル数が再び増加すると、以降のパッチリリースでリグレッションが発生する可能性があります。
SLES 12.5にGitLabをインストールするには、上記のインストール可能なパッチレベルのみを使用してください。

SUSEディストリビューションは
[GitLab 18.9で非推奨となり、GitLab 19.0で削除される予定です](../deprecations.md#linux-package-support-for-suse-distributions)。
サポート対象のオペレーティングシステムへの移行を検討してください。

詳細については、[イシュー9647](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9647)を参照してください。

### SLES 12.5パッケージからMattermostとSpamcheckを削除 {#mattermost-and-spamcheck-removed-from-sles-125-packages}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 18.11.0以降

[RPMパッケージのサイズ制約](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9716)により、
SLES 12.5のLinuxパッケージからMattermostとSpamcheckが削除されました。

SUSEディストリビューションは
[GitLab 18.9で非推奨となり、GitLab 19.0で削除される予定です](../deprecations.md#linux-package-support-for-suse-distributions)。
また、[Mattermost](../deprecations.md#mattermost-bundled-with-linux-package)と
[Spamcheck](../deprecations.md#spamcheck-support-in-the-linux-package-and-gitlab-helm-chart)は、
GitLab 19.0ですべてのディストリビューションから削除される予定です。

SLES 12.5でMattermostを使用している場合は、
[Mattermostをスタンドアロンデプロイに移行](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)できます。
SLES 12.5でSpamcheckを使用している場合は、
[Dockerを使用してデプロイ](../../administration/reporting/spamcheck.md)できます。

### Geoセカンダリのスロットリングされたジョブが消化されない {#geo-secondary-throttled-jobs-not-draining}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3       | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5         | 18.9.6            |

Geoセカンダリサイトで`ConcurrencyLimit::ResumeWorker`が無効化されていたため、スロットリングされた
`Geo::EventWorker`ジョブと`Geo::SyncWorker`ジョブがRedisに蓄積され、消化されませんでした。
これにより、Geoレプリケーションが停滞し、Redisのメモリ使用量が増加する可能性がありました。

詳細については、[イシュー595824](https://gitlab.com/gitlab-org/gitlab/-/work_items/595824)を参照してください。

### 送信フィルタリング使用時にGeoサイトのURLがブロックされる {#geo-site-url-blocked-when-using-outbound-filtering}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3       | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5         | 18.9.6            |

送信リクエストのフィルタリングが有効になっている場合、GeoサイトのURLが誤ってブロックされます。
このため、Geoサイトを保存する際に、
`Url is blocked: Requests to hosts and IP addresses not on the Allow List are denied`
のようなメッセージとともに検証エラーが発生します。

この問題は、送信フィルタリングが設定されている場合に、GeoサイトのURLがローカルへの送信リクエストの
許可リストに自動的に追加されないために発生します。

詳細については、[イシュー544821](https://gitlab.com/gitlab-org/gitlab/-/issues/544821)を参照してください。

### Geo blobダウンロードのタイムアウト設定 {#geo-blob-download-timeout-setting}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.10.0

現在のGeo blobダウンロードのタイムアウトは8時間(28,800秒)にハードコードされており、転送に長い時間を要する非常に大きなLFSオブジェクト(5 GB以上)で同期が失敗し、「started」状態のまま止まってしまいます。新しい`blob_download_timeout`設定で、blobレプリケーション(LFSオブジェクト、アップロード、ジョブアーティファクトなど)のサイトごとのタイムアウト(秒単位)を制御できます。[Geo Sites API](../../api/geo_sites.md)から設定できます。

- デフォルト: `28800`(8時間)。
- 最大値: `86400`(24時間)。

### Geo blobダウンロードの失敗 {#geo-blob-download-failures}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   |  18.10.0 - 18.10.4      | 18.10.5           |

すべてのGeo blobタイプ(アップロード、LFSオブジェクト、ジョブアーティファクトなど)が、セカンダリで
継続的に同期に失敗することがあります。一時的なネットワークエラーとは異なり、
この失敗はすべてのblobレコードに影響し、再試行しても回復しません。
影響を受けるセカンダリでは、blobが「failed」状態になり、Sidekiqのログに
セグメンテーション違反、`HPE_USER Span callback error in on_header_field`エラー、
または予期しないHTTPステータスコード(たとえば`status_code: 32`や`status_code: 34`)が
記録されることがあります。

根本原因は、`rugged` 1.9.0(GitLab 18.10でアップグレード)と`llhttp-ffi` gemの間でシンボルが
衝突していることです。`rugged.so`に静的リンクされた`llhttp`のシンボルが`llhttp-ffi`のコールバックを
オーバーライドし、HTTPレスポンスの解析を破損させます。詳細については、
[イシュー598564](https://gitlab.com/gitlab-org/gitlab/-/issues/598564)を参照してください。

GitLab 18.10.5では、競合するシンボルを含まない1.7.2に`rugged`がダウングレードされています。
アップグレード後に必要な操作はありません。

#### GitLab 18.10.4向けの機能フラグによる回避策 {#feature-flag-workaround-for-gitlab-18104}

GitLab 18.10.4を使用していて、GitLab 18.10.5にアップグレードできない場合は、
`geo_blob_download_with_gitlab_http`機能フラグを有効にします。このフラグにより、
blobのダウンロードに、FFIに依存する`http` gemではなく`Gitlab::HTTP`(`Net::HTTP`)が
使用されるようになります。

1. 機能フラグを有効にします。

   ```shell
   sudo gitlab-rails console
   Feature.enable(:geo_blob_download_with_gitlab_http)
   exit
   ```

1. Sidekiqを再起動します。

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

> [!note]
> この機能フラグによる回避策には、既知の制限事項があります。
>
> - 60秒を超える大きなblobの転送は、タイムアウトする可能性があります
>   ([イシュー598020](https://gitlab.com/gitlab-org/gitlab/-/issues/598020))。
> - コンテナレジストリのレプリケーションは、このフラグの対象外です。
> - 送信リクエストのフィルタリング(`deny_all_requests_except_allowed`)を使用している環境では、
>   追加の設定が必要になる場合があります
>   ([イシュー598514](https://gitlab.com/gitlab-org/gitlab/-/issues/598514))。

詳細については、[イシュー595139](https://gitlab.com/gitlab-org/gitlab/-/issues/595139)を参照してください。

### 18.9へのアップグレードがPostgreSQL CheckViolationで失敗する {#upgrade-to-189-fails-with-postgresql-checkviolation}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.9.0、18.9.1

GitLab Self-ManagedインスタンスをGitLab 18.9.0または18.9.1にアップグレードすると、
データベース移行中にアップグレードが次のエラーで失敗します。

```plaintext
PG::CheckViolation: ERROR: check constraint "check_xxxxxxxx" of relation "tablename" is violated by some row
```

この問題は、GitLab 18.10で修正されたバグが原因でした([マージリクエスト224446](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224446)を参照)。この修正はバックポートもされており、次のGitLab 18.9パッチリリースに含まれる予定です([マージリクエスト225026](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225026)を参照)。

ただし、このバグにより、レコードが1件のみの場合のバグが原因で、バッチ処理のバックグラウンド移行が通知なくスキップされることがあります。v18.8へのアップグレード時に、レコードが1件のみのテーブルを対象とするバッチ処理のバックグラウンド移行が、実行されないまま誤って`finished`としてマークされていました。その結果、データがバックフィルされず、GitLab Self-Managedインスタンスでアップグレードの失敗が発生していました。

修正案([マージリクエスト225461](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225461)を参照)では、影響を受けるバッチ処理のバックグラウンド移行を`finished`/`finalized`から`paused`に戻し、スケジューラーが再実行するようにします。対象は、`queued_migration_version`が18.5から18.8の間で、かつ`min_value = max_value`または`min_cursor = max_cursor`である移行に限定されます。

次の2つの選択肢があります。

- 今すぐ回避策を適用して、ただちにアップグレードを完了する。
- 完全な修正が含まれるリリースが公開されるまで待ってからアップグレードする。

次のナレッジベース記事では、既知の5つの症状に対する回避策を説明しています。

- [`PG::CheckViolation: ERROR: check constraint "check_96233d37c0" of relation "pool_repositories" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25929006135068-PG-CheckViolation-ERROR-check-constraint-check-96233d37c0-of-relation-pool-repositories-is-violated-by-some-row)
- [`PG::CheckViolation: ERROR: check constraint "check_f6590fe2c1" of relation "gpg_key_subkeys" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25756021007004-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-gpg-key-subkeys)
- [`PG::CheckViolation: ERROR: check constraint "check_17a3a18e31" of relation "user_agent_details" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25994671144348-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-user-agent-details)
- [`PG::CheckViolation: ERROR: check constraint "check_ddd6f289f4" of relation "commit_user_mentions" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25992549646364-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-commit-user-mentions)
- [`PG::CheckViolation: ERROR: check constraint "check_e69372e45f" of relation "suggestions" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25771198648732-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-suggestions)

### ブロックされたユーザーのデプロイキーとパーソナルアクセストークンが無効化される {#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated}

- 影響: すべてのインストール方法
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチレベル | 修正済みパッチレベル        |
  |---------|-----------------------|--------------------------|
  | 18.8    | 18.8.2以降      | 該当なし(意図的な変更) |
  | 18.7    | 18.7.2以降      | 該当なし(意図的な変更) |
  | 18.6    | 18.6.4以降      | 該当なし(意図的な変更) |

GitLab 18.8.2、18.7.2、18.6.4では、ブロックされたユーザーに関連付けられたデプロイキーを使用するAPIリクエストが拒否されるようになりました。
ブロックされたユーザーに関連付けられたデプロイキーがある場合、上記のバージョンにアップグレードした後は使用できなくなります。
これは、ブロックされたユーザーがキーやトークンを通じてGitLabのリソースにアクセスすることを防ぐための、セキュリティ上の修正です。

次の対応が必要です。

1. ブロックされたユーザーが所有するデプロイキーまたはパーソナルアクセストークン(PAT)を特定します。
1. それらを請求対象ユーザーに再割り当てするか、削除したうえで、
   請求対象ユーザーまたはサービスアカウントで新しいキー/トークンを作成します。

次のクエリを使用すると、ブロックされたアカウントに関連付けられていて、過去365日以内に少なくとも1回使用されたデプロイキーをすべて特定できます。

```sql
SELECT
  k.id,
  k.user_id,
  u.username,
  u.state as user_state,
  k.title,
  k.fingerprint,
  k.fingerprint_sha256,
  k.usage_type,
  k.last_used_at,
  k.created_at,
  k.updated_at
FROM keys k
INNER JOIN users u ON k.user_id = u.id
WHERE u.state IN ('blocked', 'ldap_blocked', 'blocked_pending_approval', 'banned')
  AND k.type = 'DeployKey'
  AND k.last_used_at >= NOW() - INTERVAL '365 days'
ORDER BY u.state, u.username, k.last_used_at DESC;
```

### ClickHouseディクショナリ作成エラー {#clickhouse-dictionary-creation-error}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.8.0

[ClickHouseインテグレーション](../../integration/clickhouse.md)を有効にしているGitLab Self-Managedのお客様は、
権限の不足(`DB::Exception: gitlab: Not enough privileges`)が原因で、アップグレード中に
ClickHouseデータベースの移行エラーが発生する場合があります。このエラーを解決するには、
[データベースディクショナリの読み取りサポートに関するトラブルシューティングドキュメント](../../integration/clickhouse.md#database-dictionary-read-support)を参照してください。

### CIデータに対するバッチ処理のバックグラウンド移行の再導入 {#batched-background-migration-for-ci-data-reintroduced}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.8.0

[CIビルドのメタデータ移行](#ci-builds-metadata-migration)で導入された[バッチ処理のバックグラウンド移行](../background_migrations.md)は、
データ構造のエッジケースに対処し、確実に完了するようにするため、
再導入されました。

### 引用符のないプレースホルダーを含むカスタムWebhookテンプレートを保存できない {#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved}

- 影響: すべてのインストール方法
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | すべてのパッチリリース      | 未修正         |
  | 18.9    | すべてのパッチリリース      | 未修正         |
  | 18.8    | すべてのパッチリリース      | 未修正         |

GitLab 18.8から18.10では、引用符で囲まれていないペイロードフィールドを含む
[カスタムWebhookテンプレート](../../user/project/integrations/webhooks.md#custom-webhook-template)を保存できません。この問題はGitLab 18.11で解決されました。

回避策として、フィールドを引用符で囲みます。たとえば、
`{"value": {{id}}}`は`{"value": "{{id}}"}`にします。

引用符で囲んだフィールドは、数値ではなく文字列値になります。これが
お使いのWebhookと互換性がない場合は、GitLab 18.11以降にアップグレードしてください。

詳細については、
[Webhookのトラブルシューティングドキュメント](../../user/project/integrations/webhooks_troubleshooting.md#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)を参照してください。

### CIビルドのメタデータ移行 {#ci-builds-metadata-migration}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.7.0

[デプロイ後の移行](../../development/database/post_deployment_migrations.md)により、
CIビルドのメタデータを新しい最適化されたテーブル(`p_ci_job_definitions`)にコピーする、バッチ処理の
[バックグラウンド移行](../background_migrations.md)がスケジュールされます。この移行は、
最終的にCIデータベースのサイズを削減する取り組みの一環です([エピック13886](https://gitlab.com/groups/gitlab-org/-/work_items/13886)を参照)。
数百万件のジョブがあるインスタンスで移行を高速化したい場合は、
[移行するデータを選択](#ci-builds-metadata-migration-details)できます。

### Geo ActionCableの許可オリジン設定 {#geo-actioncable-allowed-origins-setting}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.7.0

ActionCableのWebSocketリクエストで許可するオリジンを設定するための、新しい`action_cable_allowed_origins`設定が追加されました。
サイト間のWebSocket接続を正しく機能させるため、プライマリサイトを設定する際に許可するURLを指定してください。

- [Linuxパッケージ向けのGeoドキュメント](../../administration/geo/replication/configuration.md#add-primary-and-secondary-urls-as-allowed-actioncable-origins)
- [Helmチャート向けのGeoドキュメント](https://docs.gitlab.com/charts/advanced/geo/#configure-primary-database)

### Geo VerificationStateBackfillWorkerの低速クエリの修正 {#geo-verificationstatebackfillworker-slow-queries-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.6.5

`Geo::VerificationStateBackfillWorker`が`merge_request_diff_details`テーブルに対して大規模な低速クエリを生成するGeoの[イシュー587407](https://gitlab.com/gitlab-org/gitlab/-/work_items/587407)を修正しました。

### コミットAPIおよびファイルAPIのサイズ制限とレート制限 {#commits-and-files-api-size-and-rate-limits}

- 影響: すべてのインストール方法
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチレベル | 修正済みパッチレベル        |
  |---------|-----------------------|--------------------------|
  | 18.6    | 18.6.2以降      | 該当なし(意図的な変更) |
  | 18.5    | 18.5.4以降      | 該当なし(意図的な変更) |
  | 18.4    | 18.4.6以降      | 該当なし(意図的な変更) |

GitLab 18.6.2、18.5.4、18.4.6では、次のエンドポイントに対するリクエストにサイズ制限とレート制限が導入されました。

- `POST /projects/:id/repository/commits` - [コミットを作成](../../api/commits.md#create-a-commit)
- `POST /projects/:id/repository/files/:file_path` - [リポジトリにファイルを作成](../../api/repository_files.md#create-a-file-in-a-repository)
- `PUT /projects/:id/repository/files/:file_path` - [リポジトリ内のファイルを更新](../../api/repository_files.md#update-a-file-in-a-repository)

GitLabは、サイズ制限を超えるリクエストには`413 Entity Too large`ステータスで、レート制限を超えるリクエストには`429 Too Many Requests`ステータスで応答します。詳細については、[コミットAPIおよびファイルAPIの制限](../../administration/instance_limits.md#commits-and-files-api-limits)を参照してください。

### Duo Agent PlatformのRunner制限 {#duo-agent-platform-runner-restrictions}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.6.2

Duo Agent Platformで使用できるRunnerに関する[Runnerの制限](../../user/duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows)
が導入されました。

### Geoログカーソル移行の修正 {#geo-log-cursor-migration-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  |---------|-------------------------|-------------------|
  | 18.5    | 18.5.0 - 18.5.1         | 18.5.2            |
  | 18.4    | 18.4.0 - 18.4.3         | 18.4.4            |

セカンダリサイトでGeoログカーソルが起動しなくなる原因となっていた、Geoの[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210512)の欠落を修正しました。

### デザイン管理のデザインバックフィルの完了処理 {#finalize-design-management-designs-backfill}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.5.0

[デプロイ後の移行](../../development/database/post_deployment_migrations.md)
`20250922202128_finalize_correct_design_management_designs_backfill`は、18.4でスケジュールされた
バッチ処理の[バックグラウンド移行](../background_migrations.md)を完了させます。
アップグレードパスで18.4をスキップした場合、デプロイ後の移行を実行する際に、
この移行が完全に実行されます。
実行時間は、`design_management_designs`テーブルのサイズに直接関係します。
ほとんどのインスタンスでは移行にかかる時間は2分以内ですが、大規模なインスタンスでは
最大10分かかる場合があります。
移行プロセスを中断せず、完了までお待ちください。

### NGINXのルーティング変更により404エラーが発生する {#nginx-routing-changes-cause-404-errors}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 18.5.0

GitLab 18.5.0で導入されたNGINXのルーティング変更により、`localhost`や別のドメイン名など、一致しないホスト名を使用すると、サービスにアクセスできなくなる場合があります。
この問題により、次の現象が発生します。

- `/-/health`などのヘルスチェックのエンドポイントが、適切なレスポンスではなく`404`エラーを返す。
- 設定済みのFQDN以外のホスト名でアクセスすると、GitLabのWebインターフェースに`404`エラーページが表示される。
- GitLab Pagesが、他のサービス宛てのトラフィックを受信する可能性がある。
- 以前は機能していた、別のホスト名を使用するあらゆるリクエストで問題が発生する。

この問題はLinuxパッケージで[マージリクエスト8805](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8805)により解決されており、修正は
GitLab 18.5.2および18.6.0で利用可能になる予定です。

クローン、プッシュ、プルなどのGit操作は、この問題の影響を受けません。

### バッチ処理のバックグラウンド移行のnilエラー {#batched-background-migration-nil-error}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.4.2、18.4.3

`18.4.2`または`18.4.3`へのアップグレードは、次のバッチ処理のバックグラウンド移行で`no implicit conversion of nil into String`エラーが発生して失敗する場合があります。

- `FixIncompleteInstanceExternalAuditDestinations`
- `FinalizeAuditEventDestinationMigrations`

この問題を解決するには、最新のパッチリリースにアップグレードするか、[イシュー578938の回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/578938#workaround)を使用してください。

### GeoレプリケーションのTypeError {#geo-replication-typeerror}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  |---------|-------------------------|-------------------|
  | 18.4    | 18.4.0 - 18.4.1         | 18.4.2            |

セカンダリのGeoサイトでは、[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/571455)により、レプリケーションイベントが`no implicit conversion of String into Array (TypeError)`というエラーメッセージで失敗します。再検証などの冗長化の仕組みにより最終的な整合性は確保されますが、RPOが大幅に増加します。

### サービス拒否を防止するためのJSON入力制限 {#json-input-limits-for-denial-of-service-prevention}

- 影響: すべてのインストール方法
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチレベル | 修正済みパッチレベル        |
  |---------|-----------------------|--------------------------|
  | 18.4    | 18.4.1以降      | 該当なし(意図的な変更) |
  | 18.3    | 18.3.3以降      | 該当なし(意図的な変更) |
  | 18.2    | 18.2.7以降      | 該当なし(意図的な変更) |

GitLab 18.4.1、18.3.3、18.2.7では、サービス拒否攻撃を防止するために、JSON入力に対する制限が導入されました。
これらの制限を超えるHTTPリクエストに対して、GitLabは`400 Bad Request`ステータスで応答します。
詳細については、[HTTPリクエストの制限](../../administration/instance_limits.md#http-request-limits)を参照してください。

### LdapAddOnSeatSyncWorkerがDuoシートを削除する {#ldapaddonseatsyncworker-removes-duo-seats}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.3.0

新しいワーカー`LdapAddOnSeatSyncWorker`が導入されましたが、LDAPが有効な場合に、毎晩すべてのユーザーを
GitLab Duoシートから意図せず削除する可能性がありました。この問題はGitLab 18.4.0および18.3.2で修正されました。
詳細については、[イシュー565064](https://gitlab.com/gitlab-org/gitlab/-/issues/565064)を参照してください。

### Geo Rakeチェックの修正 {#geo-rake-check-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.3.0

Geoセカンダリサイトのインストール時に、`rake gitlab:geo:check`が誤って失敗を報告する[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545533)は、18.3.0で修正されました。

### Geo Pagesファイル名の修正 {#geo-pages-filename-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチレベル  | 修正済みパッチレベル |
  |---------|------------------------|-------------------|
  | 18.3    | 18.3.0 - 18.3.2        | 18.3.3            |
  | 18.2    | 18.2.0 - 18.2.6        | 18.2.7            |
  | 18.1    | 18.1.0以降       | 18.1では未修正 |

GitLab 18.3.3および18.2.7以降には、長いファイル名を持つPagesデプロイでGeoの検証が失敗することがある[イシュー559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196)の修正が含まれています。この修正により、レプリケーションと検証の間で一貫性を保つため、Geoセカンダリサイトでのファイル名のトリミングが行われなくなります。

### 18.1と18.2の間のゼロダウンタイムアップグレードでのプッシュエラー {#zero-downtime-upgrade-push-errors-between-181-and-182}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.2.0

18.1.xと18.2.xの間のアップグレードは、[既知のイシュー567543](https://gitlab.com/gitlab-org/gitlab/-/issues/567543)の影響を受けます。
このイシューにより、アップグレード中に既存のプロジェクトへのコードのプッシュでエラーが発生します。
18.1.xと18.2.xの間のアップグレードでダウンタイムが発生しないようにするには、
修正が含まれているバージョン18.2.6に直接アップグレードしてください。

### Geo VerificationStateBackfillService `ci_job_artifact_states` {#geo-verificationstatebackfillservice-ci_job_artifact_states}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチレベル | 修正済みパッチレベル |
  |---------|------------------------|-------------------|
  | 18.2    | 18.2.0 - 18.2.1        | 18.2.2            |
  | 18.1    | 18.1.0 - 18.1.3        | 18.1.4            |
  | 18.0    | 18.0.0 - 18.0.5        | 18.0.6            |

影響を受けるバージョンには、`ci_job_artifact_states`のプライマリキーの変更により、`VerificationStateBackfillService`の実行時に発生する既知のイシューがあります。解決するには、修正済みパッチレベルのリリースにアップグレードしてください。

### Elasticsearch `strict_dynamic_mapping_exception` {#elasticsearch-strict_dynamic_mapping_exception}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.1.0

Elasticsearchバージョン7で、Elasticsearchのインデックス作成が`strict_dynamic_mapping_exception`エラーで失敗する場合があります。解決するには、[イシュー566413](https://gitlab.com/gitlab-org/gitlab/-/issues/566413)の「Possible fixes」セクションを参照してください。

### PostgreSQL `ci_job_artifacts`エラー {#postgresql-ci_job_artifacts-error}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.1.0、18.1.1

GitLabバージョン18.1.0および18.1.1では、PostgreSQLのログに`ERROR:  relation "ci_job_artifacts" does not exist at ...`などのエラーが表示されます。
ログ内のこれらのエラーは無視しても問題ありませんが、Geoサイトを含め、モニタリングのアラートが発生する可能性があります。この問題を解決するには、GitLab 18.1.2以降にアップデートしてください。

### マージリクエストの「ほぼ準備完了」バグ {#merge-request-almost-ready-bug}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.1.0

一部のユーザーによるコミットを含むマージリクエストが先に進まず、`Your merge request is almost ready`と表示され続ける場合があります。[イシュー554613](https://gitlab.com/gitlab-org/gitlab/-/issues/554613)を参照してください。
また、[`sidekiq/current`ログ](../../administration/logs/_index.md#sidekiq-logs)に、`merge_request_diff_commit.rb`に関する`undefined method 'id' for nil:NilClass`エラーが表示されます。
これを修正するには、次の手順に従います。

1. [データベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)を起動します。
1. 次のコマンドを実行します。

   ```sql
   REINDEX TABLE CONCURRENTLY public.merge_request_diff_commit_users;
   ```

1. 影響を受けるマージリクエストを閉じて、再度開きます。

### Geo HTTP 500プロキシエラー {#geo-http-500-proxy-errors}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  |---------|-------------------------|-------------------|
  | 18.1    | 18.1.0                  | 18.1.1            |
  | 18.0    | 18.0.0 - 18.0.2         | 18.0.3            |

上の表のGitLabバージョンには、セカンダリのGeoサイトからプロキシされるGit操作がHTTP 500エラーで失敗する既知のイシューがあります。解決するには、修正済みパッチレベルのリリースにアップグレードしてください。

### PostgreSQL 14はサポート対象外 {#postgresql-14-not-supported}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.0.0

[PostgreSQL 14は、GitLab 18以降サポートされません](../deprecations.md#postgresql-14-and-15-no-longer-supported)。
GitLab 18.0以降にアップグレードする前に、PostgreSQLを少なくともバージョン16.5にアップグレードしてください。詳細については、
[インストール要件](../../install/requirements.md#postgresql)を参照してください。

> [!warning]
> データベースバージョンの自動アップグレードが適用されるのは、Linuxパッケージを使用する単一ノードのインスタンスのみです。
> Geoインスタンス、Linuxパッケージを使用した高可用性構成のPostgreSQL、
> 外部のPostgreSQLデータベース(Amazon RDSなど)を使用する場合など、それ以外のすべてのケースでは、PostgreSQLを手動でアップグレードする必要があります。詳細な手順については、[Geoインスタンスのアップグレード](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-geo-instance)を参照してください。

### `pg_dump`バイナリの互換性 {#pg_dump-binary-compatibility}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.0.0

GitLabには`pg_dump`バイナリが同梱されています。外部のPostgreSQLサーバーを使用する場合は、GitLabデータベースのバックアップの作成時と復元時の両方で、`pg_dump`クライアントのバージョンがPostgreSQLサーバーと互換性があることを確認してください。

### BitnamiのPostgreSQLおよびRedisイメージの非推奨化 {#bitnami-postgresql-and-redis-image-deprecation}

- 影響: Helmチャート
- 影響を受けるバージョン: 17.11.0以前

2025年9月29日以降、Bitnamiはタグ付きのPostgreSQLおよびRedisイメージの提供を停止します。バンドルされたRedisまたはPostgresを使用する
GitLabチャートでGitLab 17.11以前をデプロイしている場合は、予期しないダウンタイムを防ぐため、
レガシーリポジトリを使用するように、値を手動で更新する必要があります。詳細については、[イシュー6089](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6089)を参照してください。

### 17.11からのゼロダウンタイムアップグレード中のパイプライン失敗 {#pipeline-failures-during-zero-downtime-upgrades-from-1711}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.0.0

機能フラグ`ci_only_one_persistent_ref_creation`により、Railsはアップグレードされたものの、Sidekiqがバージョン17.11のままになっているゼロダウンタイムアップグレード中に、パイプラインが失敗します(詳細は[イシュー558808](https://gitlab.com/gitlab-org/gitlab/-/issues/558808)を参照)。

**予防策:** アップグレード前に、Railsコンソールを開いて機能フラグを有効にします。

```shell
$ sudo gitlab-rails console
Feature.enable(:ci_only_one_persistent_ref_creation)
```

**すでに影響を受けている場合:** 次のコマンドを実行し、失敗したパイプラインを再試行します。

```shell
$ sudo gitlab-rails console
Rails.cache.delete_matched("pipeline:*:create_persistent_ref_service")
```

### Gitaly設定を`git_data_dirs`からstorageに移行する {#migrate-gitaly-configuration-from-git_data_dirs-to-storage}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 18.0.0

GitLab 18.0以降では、`git_data_dirs`設定を使用してGitalyのストレージの場所を設定することはできなくなりました。

引き続き`git_data_dirs`を使用している場合は、GitLab 18.0にアップグレードする前に、
[Gitaly設定を移行](https://docs.gitlab.com/omnibus/settings/configuration/#migrating-from-git_data_dirs)する必要があります。

### Geo CEからEEへのリバート移行エラー {#geo-ce-to-ee-revert-migration-errors}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.0.0

GitLab Enterprise Editionをデプロイした後、GitLab Community Editionにリバートした場合、
データベーススキーマがGitLabアプリケーションの想定するスキーマからずれて、
移行エラーが発生する可能性があります。18.0.0へのアップグレード時に、4つの特定のエラーが発生する場合があります。
これは、このバージョンで、それらのカラムのデフォルト値を変更する移行が追加されたためです。

エラーは次のとおりです。

- `No such column: geo_nodes.verification_max_capacity`
- `No such column: geo_nodes.minimum_reverification_interval`
- `No such column: geo_nodes.repos_max_capacity`
- `No such column: geo_nodes.container_repositories_max_capacity`

この移行は、GitLab 18.0.2で、カラムが存在しない場合に追加するようパッチが適用されました。
[イシュー#543146](https://gitlab.com/gitlab-org/gitlab/-/issues/543146)を参照してください。

**影響を受けるリリース**:

| 影響を受けるマイナーリリース | 影響を受けるパッチリリース | 修正バージョン |
| ----------------------- | ----------------------- | -------- |
| 18.0                    |  18.0.0 - 18.0.1        | 18.0.2   |

### Docker環境での「PRNG is not seeded」エラー {#prng-is-not-seeded-error-on-docker-installations}

- 影響: Docker
- 影響を受けるバージョン: 18.0.0

FIPSが有効なホストでDockerインストールのGitLabを実行している場合、SSHキーの生成やOpenSSHサーバー(`sshd`)の起動が
次のエラーメッセージで失敗することがあります。

```plaintext
PRNG is not seeded
```

GitLab 18.0では、[ベースイメージがUbuntu 22.04から24.04に更新されました](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8928)。
このエラーは、Ubuntu 24.04では、[FIPSホストがFIPS非対応のOpenSSLプロバイダーを使用することが許可されなくなった](https://github.com/dotnet/dotnet-docker/issues/5849#issuecomment-2324943811)ために発生します。

この問題を解決するには、次のいくつかの選択肢があります。

- ホストシステムでFIPSを無効にする。
- GitLab Dockerコンテナ内で、FIPSベースのカーネルの自動検出を無効にする。
  これは、GitLab 18.0.2以降で、環境変数`OPENSSL_FORCE_FIPS_MODE=0`を設定することで実行できます。
- GitLab Dockerイメージを使用する代わりに、ホストに[ネイティブFIPSパッケージ](https://packages.gitlab.com/ui/browse/gitlab/gitlab-fips)をインストールする。

FIPSの要件を満たすには、最後の選択肢を推奨します。レガシーなインストールでは、
最初の2つの選択肢を暫定的な対処として使用できます。

### CIビルドのメタデータ移行の詳細 {#ci-builds-metadata-migration-details}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.7.0

> [!note]
> GitLab 18.6以降、新しいパイプラインは新しい形式にのみデータを書き込みます
> ([イシュー552065](https://gitlab.com/gitlab-org/gitlab/-/issues/552065)を参照)。
> この移行では、古い形式から新しい形式へ既存のデータをコピーするだけです。
> データは削除されません。

移行されなかったデータは、今後のリリースで削除されます([エピック18271](https://gitlab.com/groups/gitlab-org/-/work_items/18271)を参照)。

移行にかかる時間は、インスタンス内のCIジョブの総数に正比例します。
最新のデータを優先するため、ジョブは新しいパーティションから古いパーティションの順に処理されます。

大規模なプロジェクトでは、アップグレード前に
[パイプラインの自動クリーンアップ](../../ci/pipelines/settings.md#automatic-pipeline-cleanup)を有効にして
古いパイプラインを削除することで、移行するジョブの数を減らせます。

この移行では、次の2種類のデータをコピーします。

- **ジョブ処理データ**: `.gitlab-ci.yml`のジョブ実行設定(`script`や`variables`など)。
  ジョブの実行時にRunnerでのみ必要で、UIやAPIでは必要ありません。
- **ユーザーに表示されるジョブデータ**: すべてのジョブデータのうち、この移行の影響を受けるのは、ジョブのタイムアウト値、
  ジョブの終了コード、[公開されているアーティファクト](../../ci/jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui)、
  [環境の関連付け](../../ci/yaml/_index.md#environment)のみです。

大規模なCIデータセットを持つGitLab Self-ManagedおよびGitLab Dedicatedインスタンスでは、
移行するデータの範囲を絞ることで、移行を高速化できます。範囲を制御するには、以下で説明する設定を使用します。

#### ジョブ処理データの範囲の制御 {#controlling-the-scope-for-jobs-processing-data}

デフォルトでは、この移行はすべての既存ジョブの処理データをコピーします。
以下の設定のいずれかを使用して、範囲を絞り込めます。

設定の値で、保持するジョブ処理データの量を制御します。
たとえば、直近6か月以内に作成されたジョブのみが実行されると見込まれる場合は、`6mo`に設定します
([再試行](../../ci/jobs/_index.md#retry-jobs)、
[手動ジョブの実行](../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually)、
[環境の自動停止](../../ci/environments/_index.md#stopping-an-environment)による実行)。

GitLabは、次の優先順位で設定を参照します。

1. [パイプラインのアーカイブ](../../administration/settings/continuous_integration.md#archive-pipelines)設定(推奨されるベストプラクティス)。
   アーカイブされたパイプラインは、ジョブを手動で再試行または再実行できないことを示します。
   この設定が有効な場合、アーカイブされたジョブの処理データを移行する必要はありません。

   > [!note]
   > 後でパイプラインのアーカイブ範囲を拡大した場合、
   > 処理データのないジョブは実行できないままになります。
1. パイプラインのアーカイブが設定されていない場合、またはこの移行のために上書きする必要がある場合は、
   `GITLAB_DB_CI_JOBS_PROCESSING_DATA_CUTOFF`[環境変数](../../administration/environment_variables.md)。
   `1y`(1年)、`6mo`(6か月)、`90d`(90日)のような期間文字列を指定できます。
1. 上記のどちらも設定されていない場合は、`GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF`環境変数。
   `1y`(1年)、`6mo`(6か月)、`90d`(90日)のような期間文字列を指定できます。
   [ユーザーに表示されるジョブデータの範囲の制御](#controlling-the-scope-for-job-data-visible-to-users)を参照してください。
1. 設定が見つからない場合は、すべてのデータがコピーされます。

#### ユーザーに表示されるジョブデータの範囲の制御 {#controlling-the-scope-for-job-data-visible-to-users}

環境変数`GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF`で、どのジョブの表示データを
移行するかを制御します。

たとえば、`GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF=1y`を指定すると、直近1年間のジョブについて、
影響を受ける表示データ(タイムアウト値、環境、終了コード、公開されているアーティファクトのメタデータ)が
コピーされます。

デフォルトでは、カットオフ日はなく、すべてのジョブのデータが移行されます。

#### 移行の影響の見積もり {#estimating-migration-impact}

参考として、GitLab.comでは、4億行を約2か月で移行する見込みです。

お使いのインスタンスへの移行の影響を見積もるには、
[PostgreSQLコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)で次のクエリを実行します。

{{< tabs >}}

{{< tab title="テーブルサイズ" >}}

```sql
SELECT n.nspname AS schema_name, c.relname AS partition_name,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size
FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_class p ON p.oid = i.inhparent
WHERE p.relname = 'p_ci_builds_metadata'
ORDER BY pg_total_relation_size(c.oid) DESC;
```

新しいテーブルに必要な容量は、この容量の約20%です。

{{< /tab >}}

{{< tab title="ジョブ数の推定" >}}

これは、PostgreSQLの統計テーブルからの推定値です。

```sql
SELECT SUM(c.reltuples)::bigint AS estimated_jobs_count
FROM pg_class c
JOIN pg_inherits i ON c.oid = i.inhrelid
WHERE i.inhparent = 'p_ci_builds'::regclass;
```

{{< /tab >}}

{{< tab title="期間別のジョブ数" >}}

特定の期間に作成されたジョブの数を調べるには、テーブルに対してクエリを実行する必要があります。

```sql
SELECT COUNT(*) FROM p_ci_builds WHERE created_at >= now() - '1 year'::interval;
```

クエリがタイムアウトする場合は、[Railsコンソール](../../administration/operations/rails_console.md)を使用して
データをバッチ処理します。

```ruby
counts = []
CommitStatus.each_batch(of: 25000) do |batch|
  counts << batch.where(created_at: 1.year.ago...).count
end
counts.sum
```

{{< /tab >}}

{{< /tabs >}}

### マージリクエストのマージデータに対するバッチ処理のバックグラウンド移行 {#batched-background-migration-for-merge-request-merge-data}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.8.0

[バッチ処理のバックグラウンド移行](../background_migrations.md)により、マージリクエストのマージ関連データが、
`merge_requests`テーブルから、新しい専用の`merge_requests_merge_data`テーブルにコピーされます。

この移行は、マージ固有の属性を別のテーブルに正規化し、クエリのパフォーマンスと保守性を
向上させる、データベーススキーマ最適化の取り組みの一環です。

#### 移行されるデータ {#what-data-is-migrated}

この移行では、次のカラムを`merge_requests`から`merge_requests_merge_data`にコピーします。

- `merge_commit_sha`
- `merged_commit_sha`
- `merge_ref_sha`
- `squash_commit_sha`
- `in_progress_merge_commit_sha`
- `merge_status`
- `auto_merge_enabled`
- `squash`
- `merge_user_id`
- `merge_params`
- `merge_error`
- `merge_jid`

この移行では`merge_requests`テーブルを処理し、`merge_requests_merge_data`に対応するエントリがまだ存在しない
マージリクエストのデータのみをコピーします。

GitLab 18.7以降、新しいマージリクエストは、アプリケーションレベルのデュアルライトの仕組みにより、
両方のテーブルにデータを書き込みます([イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/560933)を参照)。
この移行では、デュアルライトの実装後に作成または更新されていない既存のデータのみをコピーします。

この移行中に、`merge_requests`テーブルからデータが削除されることはありません。

この移行は、GitLab 18.9で完了する予定です。詳細については、
[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/584459)を参照してください。

#### 移行にかかる時間の見積もり {#estimating-migration-duration}

移行にかかる時間は、インスタンス内のマージリクエストの数に正比例します。

影響を見積もるには、次のようにします。

**PostgreSQLクエリ:**

```sql
-- Count total merge requests
SELECT COUNT(*) FROM merge_requests;

-- Estimate table size
SELECT pg_size_pretty(pg_total_relation_size('merge_requests')) AS table_size;
```

**Railsコンソール:**

```ruby
# Count total merge requests
MergeRequest.count

# Count remaining merge requests to migrate
MergeRequest.left_joins(:merge_data)
  .where(merge_requests_merge_data: { merge_request_id: nil })
  .count
```

この移行ではマージリクエストをバッチで処理し、ほとんどのインスタンスで数時間から数日以内に完了します。

### GitLab 18.11でのPostgreSQLバージョン17.7へのアップグレード {#postgresql-version-177-upgrade-on-gitlab-1811}

- 影響: Linuxパッケージ、Docker、Geo
- 影響を受けるバージョン: 18.11.0

GitLab 18.11にアップグレードすると、単一ノードのLinuxパッケージインストールでは、[PostgreSQL 17.7](../../administration/package_information/postgresql_versions.md)への自動アップグレードが実行されます。

> [!warning]
> データベースバージョンの自動アップグレードが適用されるのは、Linuxパッケージを使用する単一ノードのインスタンスのみです。
> Geoデプロイの場合、メジャーバージョンのアップグレードにはGeoセカンダリへのPostgreSQLレプリケーションの再初期化が必要なため、
> PostgreSQLのアップグレードは[意図的にスケジュールし、計画する](../../administration/geo/replication/upgrading_the_geo_sites.md)必要があります。
> その結果、想定よりも長いダウンタイムが発生する可能性があります。

### HelmチャートおよびOperatorのデプロイで、Sidekiqの並行処理リミッターがジョブのバックログを引き起こす {#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments}

- 影響: Helmチャート、Operator
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3      | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5        | 18.9.6            |

GitLab 18.9で、GitLab Helmチャートがデフォルトで`GITLAB_SIDEKIQ_MAX_REPLICAS`を設定するようになりました
([charts/GitLabのマージリクエスト4348](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4348))。
KEDAベースのオートスケールを使用していないGitLab Self-ManagedおよびGitLab Dedicated環境では、
これによりSidekiqの並行処理リミッターが予期せず有効になり、ジョブがRedisベースの
スロットリングキューに繰り延べされます。

その結果、次のような問題が発生する可能性があります。

- Sidekiqジョブのバックログ。
- Redisのメモリ増加。
- ジョブ実行の遅延。
- `WebHookWorker`、`AuditEvents::AuditEventStreamingWorker`、
  Geoレプリケーションワーカー(`Geo::EventWorker`、`Geo::SyncWorker`)などのワーカーへの影響。

影響を受けている場合は、修正済みバージョンにアップグレードするまで、次のいずれかの一時的な緩和策を使用できます。

- 機能フラグを有効にして、特定のワーカーの並行処理リミッターを無効にします。
  Sidekiqポッドで`exec`を実行して、Railsコンソールを開きます。

  ```shell
  kubectl exec -it <sidekiq-pod-name> -- gitlab-rails console
  ```

  次に、影響を受けるワーカーのフラグを有効にします。

  ```ruby
  Feature.enable(:"disable_sidekiq_concurrency_limit_middleware_<WorkerClass>")
  ```

  `<WorkerClass>`を、影響を受けるワーカー名(たとえば`WebHookWorker`)に置き換えます。

- Sidekiqポッドの環境設定で`GITLAB_SIDEKIQ_MAX_REPLICAS=0`を設定して、すべてのデフォルトの並行処理制限を無効にします。
  これにより、デフォルトの並行処理制限の計算が完全に無効になります。

> [!warning]
> Geoを使用している場合、`ConcurrencyLimit::ResumeWorker`はGeoセカンダリでは実行されないため、
> セカンダリサイトで、すでにスロットリングされているジョブが自動的に消化されない可能性があります。
> スロットリングされたキューをクリアするには、手動での対応が必要になる場合があります。

デフォルトの並行処理制限の計算を機能フラグの背後に配置する修正が、
[マージリクエスト230713](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230713)でマージされ、
18.10.4([マージリクエスト231085](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231085))と
18.9.6([マージリクエスト231297](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231297))にバックポートされました。

### すべてのプロジェクトでシークレットの誤検出判定がデフォルトで有効になる {#secret-detection-false-positive-detection-enabled-by-default-on-all-projects}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.10.x

[シークレットの誤検出判定](../../user/application_security/vulnerabilities/false_positive_detection.md)の基本フローを有効にするには、
通常、次の2つの手順が必要です。

1. グループに対して基本フローを許可する。
1. 個々のプロジェクトで基本フローを有効にする。

しかし、GitLab 18.10のいずれかのバージョンにアップグレードすると、すべてのプロジェクトでシークレットの誤検出判定の
基本フローが有効になります。グループに対して基本フローが許可されると、そのグループ内のすべてのプロジェクトで
すでに有効になっています。

シークレットの誤検出判定の基本フローをグループに対して許可する前に、そのグループ内のプロジェクトの設定を
確認することをおすすめします。

### コンパイルされたジョブごとの設定に1 MiBのサイズ制限が適用される {#compiled-per-job-config-is-subject-to-a-1-mib-size-limit}

- 影響: すべてのインストール方法
- 影響を受けるバージョン:

  | リリース | 影響を受けるパッチリリース | 修正済みパッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.11   | 18.11.x                 | 未修正         |
  | 19.0    | 19.0.0から19.0.5         | 19.0.6            |
  | 19.1    | 19.1.0から19.1.3         | 19.1.4            |
  | 19.2    | 19.2.0から19.2.1         | 19.2.2            |

[JSONスキーマ検証を強制する変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218219)により、コンパイルされたジョブごとの設定に1 MiBのサイズ制限も適用されるようになりました。ジョブのコンパイル済み設定(オプション、YAML変数、トークン、シークレットなど)がこの制限を超えると、パイプラインの作成は次のエラーで失敗します。`Failed to persist the pipeline: Validation failed: Config is too large. Maximum size allowed is 1 MiB`。回避策は、ジョブの設定のサイズを1 MiB未満に減らすことです。

修正済みバージョンにアップグレードすると、`ci_max_total_yaml_size_bytes`アプリケーション設定を使用して、[サイズ制限を設定](../../administration/cicd/limits.md#maximum-size-of-the-entire-cicd-configuration)できるようになります。

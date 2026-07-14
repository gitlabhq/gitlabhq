---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 18アップグレードノート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLab 18のマイナーバージョンとパッチバージョンのアップグレード情報を提供します。以下の条件を考慮して、各手順を確認してください:

- お使いのインストールタイプ。
- 現在のバージョンから移行先バージョンまでのすべてのバージョン。

Helmチャートのインストールの詳細については、[Helmチャート9.0のアップグレードノート](https://docs.gitlab.com/charts/releases/9_0/)を参照してください。

## 必須アップグレードストップ {#required-upgrade-stops}

インスタンス管理者に予測可能なアップグレードスケジュールを提供するために、必須アップグレードストップは、以下のバージョンで発生します:

- `18.2`
- `18.5`
- `18.8`
- `18.11`

## アップグレードノートの参照 {#upgrade-notes-reference}

以下は、GitLabのマイナーバージョンごとのアップグレードノートの参照リストです。各リスト項目は、詳細情報が記載されている特定のセクションを指します。

インストール方法を示す項目（`(Geo)`や`(Linux package)`など）は、その方法にのみ適用されます。その他のすべての項目は、すべてのインストール方法に適用されます。

### 18.11へのアップグレード {#upgrade-to-1811}

GitLab 18.11にアップグレードする前に、以下を確認してください:

- [18.11.0 - 18.11.2] - [Geo blob同期の失敗: ファイルストレージでの`log_error` NoMethodError](#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage) (Geo)
- [18.11.0 - 18.11.4] - [Geoコンテナリポジトリの同期がOCIイメージのインデックスタグをサイレントスキップする](#geo-container-repository-sync-silently-skips-oci-image-index-tags) (Geo)
- [18.11.0 - 18.11.1] - [内部および公開プロジェクトからコンテナイメージをプルする際のCIジョブトークンのリグレッション](#ci-job-token-regression-pulling-container-images-from-internal-and-public-projects)
- [18.11.0] - [18.11へのアップグレードによりPostgreSQL 17.7バージョンへのアップグレードがトリガーされる](#postgresql-version-177-upgrade-on-gitlab-1811) (Linux package, Docker, Geo)
- [18.11.0] - [MattermostおよびSpamcheckがSLES 12.5パッケージから削除される](#mattermost-and-spamcheck-removed-from-sles-125-packages) (Linux package)

### 18.10へのアップグレード {#upgrade-to-1810}

GitLab 18.10へのアップグレード前に、以下を確認してください:

- [18.10.0 - 18.10.3] - [SLES 12.5 RPMパッケージのインストール失敗](#sles-125-rpm-package-installation-failure) (Linux package)
- [18.10.0 - 18.10.5] - [Geo blob同期の失敗: ファイルストレージでの`log_error` NoMethodError](#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage) (Geo)
- [18.10.0 - 18.10.7] - [Geoコンテナリポジトリの同期がOCIイメージのインデックスタグをサイレントスキップする](#geo-container-repository-sync-silently-skips-oci-image-index-tags) (Geo)
- [18.10.0 - 18.10.3] - [送信フィルタリング使用時にGeoサイトURLがブロックされる](#geo-site-url-blocked-when-using-outbound-filtering) (Geo)
- [18.10.0 - 18.10.4] - [Geo blobダウンロードの失敗](#geo-blob-download-failures) (Geo)
- [18.10.0 - 18.10.3] - [Geoセカンダリでスロットルされたジョブがドレインされない](#geo-secondary-throttled-jobs-not-draining) (Geo)
- [18.10.0 - 18.10.3] - [Sidekiq並行処理リミッターによりHelmチャートおよびOperatorデプロイでジョブのバックログが発生する](#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments) (Helmチャート, Operator)
- [18.10.0] - [すべてのプロジェクトでシークレット検出の誤検出判定がデフォルトで有効化される](#secret-detection-false-positive-detection-enabled-by-default-on-all-projects)
- [18.10.0] - [引用符なしのプレースホルダーを含むカスタムWebhookテンプレートを保存できない](#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)
- [18.10.0] - [パイプライン実行ポリシーでのdotenv変数は`variables_override`を尊重する](#dotenv-variables-in-pipeline-execution-policies-respect-variables_override)

### 18.9へのアップグレード {#upgrade-to-189}

GitLab 18.9へのアップグレード前に、以下を確認してください:

- [18.9.1 - 18.9.5] - [SLES 12.5 RPMパッケージのインストール失敗](#sles-125-rpm-package-installation-failure) (Linux package)
- [18.9.0 - 18.9.5] - [送信フィルタリング使用時にGeoサイトURLがブロックされる](#geo-site-url-blocked-when-using-outbound-filtering) (Geo)
- [18.9.0 - 18.9.5] - [Geoセカンダリでスロットルされたジョブがドレインされない](#geo-secondary-throttled-jobs-not-draining) (Geo)
- [18.9.0 - 18.9.5] - [Sidekiq並行処理リミッターによりHelmチャートおよびOperatorデプロイでジョブのバックログが発生する](#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments) (Helmチャート, Operator)
- [18.9.0] - [Upgrade to 18.9 fails with PostgreSQL CheckViolation](#upgrade-to-189-fails-with-postgresql-checkviolation)
- [18.9.0] - [引用符なしのプレースホルダーを含むカスタムWebhookテンプレートを保存できない](#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)

### 18.8へのアップグレード {#upgrade-to-188}

GitLab 18.8へのアップグレード前に、以下を確認してください:

- [18.8.2] - [Deploy keys and personal access tokens for blocked users invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.8.0] - [Batched background移行forマージリクエストマージdata](#batched-background-migration-for-merge-request-merge-data)
- [18.8.0] - [ClickHouse dictionary creation error](#clickhouse-dictionary-creation-error)
- [18.8.0] - [Batched background移行for CI data reintroduced](#batched-background-migration-for-ci-data-reintroduced)
- [18.8.0] - [引用符なしのプレースホルダーを含むカスタムWebhookテンプレートを保存できない](#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)

### 18.7へのアップグレード {#upgrade-to-187}

GitLab 18.7へのアップグレード前に、以下を確認してください:

- [18.7.2] - [Deploy keys and personal access tokens for blocked users invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.7.0] - [CIビルドmetadata移行](#ci-builds-metadata-migration)
- [18.7.0] - [Geo ActionCable allowed origins setting](#geo-actioncable-allowed-origins-setting) (Geo)

### 18.6へのアップグレード {#upgrade-to-186}

GitLab 18.6へのアップグレード前に、以下を確認してください:

- [18.6.5] - [Geo VerificationStateBackfillWorker slowクエリ修正](#geo-verificationstatebackfillworker-slow-queries-fix) (Geo)
- [18.6.4] - [Deploy keys and personal access tokens for blocked users invalidated](#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated)
- [18.6.2] - [コミットs andファイルAPI size andレート制限](#commits-and-files-api-size-and-rate-limits)
- [18.6.2] - [GitLab Duo Agent Platform Runner restrictions](#duo-agent-platform-runner-restrictions)

### 18.5へのアップグレード {#upgrade-to-185}

GitLab 18.5へのアップグレード前に、以下を確認してください:

- [18.5.4] - [コミットs andファイルAPI size andレート制限](#commits-and-files-api-size-and-rate-limits)
- [18.5.0 - 18.5.1] - [Geoログカーソル移行の修正](#geo-log-cursor-migration-fix) (Geo)
- [18.5.0] - [Finalize設計管理designsバックフィル](#finalize-design-management-designs-backfill)
- [18.5.0] - [NGINX routing changes cause 404 errors](#nginx-routing-changes-cause-404-errors) (Linuxパッケージ)

### 18.4へのアップグレード {#upgrade-to-184}

GitLab 18.4へのアップグレード前に、以下を確認してください:

- [18.4.6] - [コミットs andファイルAPI size andレート制限](#commits-and-files-api-size-and-rate-limits)
- [18.4.2 - 18.4.3] - [バッチ処理されたバックグラウンド移行のnilエラー](#batched-background-migration-nil-error)
- [18.4.1] - [JSON入力limits forサービス拒否prevention](#json-input-limits-for-denial-of-service-prevention)
- [18.4.0 - 18.4.3] - [Geoログカーソル移行の修正](#geo-log-cursor-migration-fix) (Geo)
- [18.4.0 - 18.4.1] - [GeoレプリケーションのTypeError](#geo-replication-typeerror) (Geo)

### 18.3へのアップグレード {#upgrade-to-183}

GitLab 18.3へのアップグレード前に、以下を確認してください:

- [18.3.3] - [サービス拒否防止のためのJSON入力制限](#json-input-limits-for-denial-of-service-prevention)
- [18.3.0] - [LdapAddOnSeatSyncWorkerがDuoシートを削除する](#ldapaddonseatsyncworker-removes-duo-seats)
- [18.3.0] - [Geo Rake check修正](#geo-rake-check-fix) (Geo)
- [18.3.0 - 18.3.2] - [Geo Pagesファイル名の修正](#geo-pages-filename-fix) (Geo)

### 18.2へのアップグレード {#upgrade-to-182}

GitLab 18.2へのアップグレード前に、以下を確認してください:

- [18.2.7] - [サービス拒否防止のためのJSON入力制限](#json-input-limits-for-denial-of-service-prevention)
- [18.2.0] - [18.1と18.2間のゼロダウンタイムアップグレード時のプッシュエラー](#zero-downtime-upgrade-push-errors-between-181-and-182)
- [18.2.0 - 18.2.1] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.2.0 - 18.2.6] - [Geo Pagesファイル名の修正](#geo-pages-filename-fix) (Geo)

### 18.1へのアップグレード {#upgrade-to-181}

GitLab 18.1へのアップグレード前に、以下を確認してください:

- [18.1.0] - [Elasticsearch `strict_dynamic_mapping_exception`](#elasticsearch-strict_dynamic_mapping_exception)
- [18.1.0 - 18.1.1] - [PostgreSQL `ci_job_artifacts`エラー](#postgresql-ci_job_artifacts-error)
- [18.1.0] - [マージリクエストalmost readyバグ](#merge-request-almost-ready-bug)
- [18.1.0] - [Geo HTTP 500 proxy errors](#geo-http-500-proxy-errors) (Geo)
- [18.1.0 - 18.1.3] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.1.0] - [Geo GitLab Pages filename修正](#geo-pages-filename-fix) (Geo)

### 18.0へのアップグレード {#upgrade-to-180}

GitLab 18.0へのアップグレード前に、以下を確認してください:

- [18.0.0] - [PostgreSQL 14のサポート終了](#postgresql-14-not-supported)
- [18.0.0] - [`pg_dump`バイナリ互換性](#pg_dump-binary-compatibility)
- [18.0.0] - [17.11からのゼロダウンタイムアップグレード中のパイプラインの失敗](#pipeline-failures-during-zero-downtime-upgrades-from-1711)
- [18.0.0] - [`git_data_dirs`からストレージにGitaly設定を移行する](#migrate-gitaly-configuration-from-git_data_dirs-to-storage)（Linuxパッケージ）
- [18.0.0 - 18.0.1] - [Geo CEからEEへのロールバック移行エラー](#geo-ce-to-ee-revert-migration-errors) (Geo)
- [18.0.0 - 18.0.2] - [Geo HTTP 500プロキシエラー](#geo-http-500-proxy-errors) (Geo)
- [18.0.0 - 18.0.5] - [Geo VerificationStateBackfillService `ci_job_artifact_states`](#geo-verificationstatebackfillservice-ci_job_artifact_states) (Geo)
- [18.0.0] - [DockerインストールでのPRNG is not seededエラー](#prng-is-not-seeded-error-on-docker-installations) (Docker)
- [17.11.0] - [Bitnami PostgreSQLおよびRedisイメージの廃止](#bitnami-postgresql-and-redis-image-deprecation) (Helmチャート)

## アップグレードノート {#upgrade-notes}

GitLab 18の特定のアップグレードノート。

### パイプライン実行ポリシーでのdotenv変数は`variables_override`を尊重する {#dotenv-variables-in-pipeline-execution-policies-respect-variables_override}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

- 影響: パイプライン実行ポリシー
- 影響を受けるバージョン: 

  | リリース     | 影響を受けるパッチリリース |
  | ----------- | ----------------------- |
  | 18.10       | 18.10.0以降       |

GitLab 18.10以降では、dotenv変数アーティファクト (`artifacts:reports:dotenv`) からの変数は、パイプライン実行ポリシーの他の変数と同じ`variables_override`ルールに従います（デフォルトで安全）。以前は、dotenv変数が`variables_override`の制限をバイパスでき、ポリシーのセキュリティ制御を損ねていました。

もしパイプラインが、ポリシーで定義された変数を上書きするためにdotenv変数に依存していた場合、`variables_override.allowed: false`が設定されていると、その動作は機能しなくなります。以前の動作を復元するには、新しい`dotenv`オプションを`allow_override`に設定します:

```yaml
variables_override:
  allowed: false
  exceptions: []
  dotenv: allow_override
```

詳細については、[パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)および[マージリクエスト214991](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214991)を参照してください。

### Geo blob同期の失敗: ファイルストレージでの`log_error` NoMethodError {#geo-blob-sync-failures-with-log_error-nomethoderror-on-file-storage}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo (ファイルストレージのみ)
- 影響を受けるバージョン: 

  | リリース           | 影響を受けるパッチリリース | 修正パッチレベル |
  | ----------------- |-------------------------|-------------------|
  | 18.11             | 18.11.0 - 18.11.2       | 18.11.3           |
  | 18.10             | 18.10.0 - 18.10.5       | 18.10.6           |
  | 18.0 - 18.9       | すべてのパッチリリース      | 未修正         |

Geoセカンダリサイトで、blobをオブジェクトストレージではなく**file storage**に保存している場合、blobのレプリケーション（パイプラインアーティファクト、LFSオブジェクト、アップロード、ジョブのアーティファクトなど）が誤解を招くエラーで失敗する可能性があります:

```plaintext
Error while attempting to sync: undefined method `log_error' for an instance of Gitlab::Geo::Replication::BlobDownloader
```

詳細については、[イシュー598565](https://gitlab.com/gitlab-org/gitlab/-/work_items/598565)を参照してください。

### Geoコンテナリポジトリの同期がOCIイメージのインデックスタグをサイレントスキップする {#geo-container-repository-sync-silently-skips-oci-image-index-tags}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo (コンテナレジストリ)
- 影響を受けるバージョン: 

  | リリース     | 影響を受けるパッチリリース | 修正パッチレベル |
  | ----------- | ----------------------- | ----------------- |
  | 18.11       | 18.11.0 - 18.11.4       | 18.11.5           |
  | 18.10       | 18.10.0 - 18.10.7       | 18.10.8           |
  | 18.0 - 18.9 | すべてのパッチリリース      | 未修正         |

Geoセカンダリサイトでは、マニフェストがOCIイメージのインデックス (`application/vnd.oci.image.index.v1+json`) であるタグが、コンテナリポジトリの同期によってサイレントにスキップされていました。マルチアーキテクチャイメージやBuildKitキャッシュタグは、一般的にこのマニフェストタイプを使用します。エラーは発生せず、タグのカウントは一致しましたが、セカンダリからの影響を受けるタグの`docker pull`は`manifest unknown`を返しました。同じ根本原因により、同期できなかった孤立したタグがセカンダリに残されました。

プライマリおよびセカンダリのサイトの両方を修正済みのバージョンにアップグレードすると、新しく同期されたタグは正しくなります。以前に影響を受けたリポジトリは、次回の検証サイクルで収束します。これには、再検証間隔（デフォルトで90日）までかかる場合があります。影響を受けたリポジトリをすぐに修復するには、[セカンダリサイト上のコンテナリポジトリを再同期](../../administration/geo/replication/container_registry.md#manually-trigger-a-container-registry-sync-event)してください。

詳細については、[イシュー600486](https://gitlab.com/gitlab-org/gitlab/-/work_items/600486)を参照してください。

### 内部および公開プロジェクトからコンテナイメージをプルする際のCIジョブトークンのリグレッション {#ci-job-token-regression-pulling-container-images-from-internal-and-public-projects}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.11   | 18.11.0 - 18.11.1       | 18.11.2           |

> [!warning]
> CIジョブが`CI_JOB_TOKEN`を使用して内部または公開プロジェクトからコンテナイメージをプルする場合、GitLab 18.11.0または18.11.1にアップグレードしないでください。

GitLab 18.11.0のリグレッションにより、CIジョブが`CI_JOB_TOKEN`を使用して内部または公開プロジェクトからコンテナイメージをプルするのを妨げます。影響を受けたパイプラインは`denied: requested access to the resource is denied`で失敗します。この修正は`18-11-stable-ee`にバックポートされましたが、18.11.1タグがカットされた後に含まれたため、18.11.0と18.11.1の両方が影響を受けます。

すでにアップグレード済みのオペレーター向けの利用可能な回避策:

1. 各消費プロジェクトをソースプロジェクトのCIジョブトークン許可リストに追加します。[CI/CDジョブトークンのセキュリティ](../../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security)を参照してください。
1. `CI_JOB_TOKEN`の代わりに、個人、グループ、またはプロジェクトアクセストークンを使用してコンテナのプルを認証します。
1. バックポートコミット[`e3c0f308`](https://gitlab.com/gitlab-org/gitlab/-/commit/e3c0f30800f803b8f519e9b937296b068d8f4cca)をGitLabインスタンスに適用します。

詳細については、[イシュー597223](https://gitlab.com/gitlab-org/gitlab/-/work_items/597223)を参照してください。

### SLES 12.5 RPMパッケージのインストール失敗 {#sles-125-rpm-package-installation-failure}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース          | インストール可能なパッチレベル |
  | ------- | -------------------------------- | ----------------------- |
  | 18.10   | 18.10.0 - 18.10.3                | 18.10.4 - 18.10.5       |
  | 18.9    | 18.9.1 - 18.9.5                  | 18.9.0, 18.9.6          |

> [!warning]
> SLES 12.5では、GitLab 18.9.0、18.10.4、および18.11.2のみが正常にインストールできます。影響を受ける範囲の他のすべてのパッチリリースはインストールに失敗します。

SLES 12.5向けのGitLab Linuxパッケージは、`rpm`または`zypper`コマンドを使用すると`error: install failed`エラーでインストールに失敗します。根本原因は、SLES 12 SP5に付属しているバージョンであるRPM 4.11.2における16 MiBのRPMヘッダーデータサイズ制限 (`HEADER_DATA_MAX`) です。GitLabパッケージ内のファイル数が増加したため、シリアル化されたRPMヘッダーがこの制限を超え、RPMデータベーストランザクションがインストール中にサイレントに失敗しました。

このイシューは、Linuxパッケージのファイル数を減らすことで、特定のパッチリリースで解決されました（[マージリクエスト9215](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9215)を参照）。しかし、ファイル数が増加すると、その後のパッチリリースでリグレッションが発生する可能性があります。SLES 12.5にGitLabをインストールするには、上記のインストール可能なパッチレベルのみを使用してください。

SUSEディストリビューションは、[GitLab 18.9で非推奨となり、GitLab 19.0で削除される予定](../deprecations.md#linux-package-support-for-suse-distributions)です。サポートされているオペレーティングシステムへの移行を検討してください。

詳細については、[イシュー9647](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/9647)を参照してください。

### MattermostおよびSpamcheckがSLES 12.5パッケージから削除される {#mattermost-and-spamcheck-removed-from-sles-125-packages}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 18.11.0以降

[RPMパッケージサイズの制約](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9716)により、MattermostとSpamcheckはSLES 12.5 Linuxパッケージから削除されました。

SUSEディストリビューションは、[GitLab 18.9で非推奨となり、GitLab 19.0で削除される予定](../deprecations.md#linux-package-support-for-suse-distributions)であり、[Mattermost](../deprecations.md#mattermost-bundled-with-linux-package)と[Spamcheck](../deprecations.md#spamcheck-support-in-the-linux-package-and-gitlab-helm-chart)の両方は、GitLab 19.0ですべてのディストリビューションから削除される予定です。

SLES 12.5でMattermostを使用している場合は、[Mattermostをスタンドアロンデプロイに移行](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)できます。SLES 12.5でSpamcheckを使用している場合は、[Dockerを使用してデプロイ](../../administration/reporting/spamcheck.md)できます。

### Geoセカンダリでスロットルされたジョブがドレインされない {#geo-secondary-throttled-jobs-not-draining}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3       | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5         | 18.9.6            |

Geoセカンダリサイトでは`ConcurrencyLimit::ResumeWorker`が無効になっていたため、スロットルされた`Geo::EventWorker`および`Geo::SyncWorker`のジョブがRedisに蓄積され、ドレインされませんでした。これにより、Geoのレプリケーションが停止し、Redisのメモリ使用量が増加する可能性があります。

詳細については、[イシュー595824](https://gitlab.com/gitlab-org/gitlab/-/work_items/595824)を参照してください。

### 送信フィルタリング使用時にGeoサイトURLがブロックされる {#geo-site-url-blocked-when-using-outbound-filtering}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3       | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5         | 18.9.6            |

送信リクエストフィルタリングが有効になっている場合、GeoサイトのURLが誤ってブロックされます。これにより、Geoサイトの保存時に`Url is blocked: Requests to hosts and IP addresses not on the Allow List are denied`のようなメッセージとともに検証エラーが発生します。

このイシューは、送信フィルタリングが設定されている場合、GeoサイトのURLが送信ローカルリクエスト許可リストに自動的に追加されないために発生します。

詳細については、[イシュー544821](https://gitlab.com/gitlab-org/gitlab/-/issues/544821)を参照してください。

### Geo blobダウンロードタイムアウト設定 {#geo-blob-download-timeout-setting}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.10.0

現在の8時間（28,800秒）ハードコードされたGeo blobダウンロードタイムアウトは、転送時間が長くかかる非常に大きなLFSオブジェクト（5GB以上）の失敗を引き起こし、「started」状態のままになります。新しい`blob_download_timeout`設定は、blobレプリケーション（LFSオブジェクト、アップロード、ジョブアーティファクトなど）のサイトごとのタイムアウト（秒単位）を制御します。[GeoサイトAPI](../../api/geo_sites.md)を通じて設定可能です。

- デフォルト: `28800`（8時間）。
- 最大: `86400`（24時間）。

### Geo blobダウンロードの失敗 {#geo-blob-download-failures}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   |  18.10.0 - 18.10.4      | 18.10.5           |

すべてのGeo blobタイプ（アップロード、LFSオブジェクト、ジョブのアーティファクトなど）は、セカンダリでの同期に永続的に失敗する可能性があります。一時的なネットワークエラーとは異なり、これらの失敗はすべてのblobレコードに影響を与え、再試行しても回復しません。影響を受けたセカンダリは「失敗」ステータスのblobを表示し、Sidekiqログにはセグメンテーション違反、`HPE_USER Span callback error in on_header_field`エラー、または予期しないHTTPステータスコード（たとえば、`status_code: 32`または`status_code: 34`）が含まれる可能性があります。

根本原因は、`rugged` 1.9.0（GitLab 18.10でアップグレード）と`llhttp-ffi` gem間のシンボル衝突です。`rugged.so`内の静的にリンクされた`llhttp`シンボルが`llhttp-ffi`コールバックを上書きし、HTTPレスポンスの解析を破損させます。詳細については、[イシュー598564](https://gitlab.com/gitlab-org/gitlab/-/issues/598564)を参照してください。

GitLab 18.10.5では、`rugged`は1.7.2にダウングレードされ、競合するシンボルは含まれていません。アップグレード後に必要なアクションはありません。

#### GitLab 18.10.4向けの機能フラグ回避策 {#feature-flag-workaround-for-gitlab-18104}

GitLab 18.10.4を使用しており、GitLab 18.10.5にアップグレードできない場合は、`geo_blob_download_with_gitlab_http`機能フラグを有効にしてください。この機能フラグは、blobダウンロードをFFIに依存する`http` gemの代わりに`Gitlab::HTTP` (`Net::HTTP`) を使用するように切り替えます:

1. 機能フラグを有効にします:

   ```shell
   sudo gitlab-rails console
   Feature.enable(:geo_blob_download_with_gitlab_http)
   exit
   ```

1. Sidekiqを再起動します:

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

> [!note]
> この機能フラグ回避策には既知の制限があります:
>
> - 60秒を超える大きなblob転送はタイムアウトする可能性があります（[イシュー598020](https://gitlab.com/gitlab-org/gitlab/-/issues/598020)）。
> - コンテナレジストリのレプリケーションはこの機能フラグの対象外です。
> - 環境によっては、送信リクエストフィルタリング (`deny_all_requests_except_allowed`) に追加の設定が必要になる場合があります（[イシュー598514](https://gitlab.com/gitlab-org/gitlab/-/issues/598514)）。

詳細については、[イシュー595139](https://gitlab.com/gitlab-org/gitlab/-/issues/595139)を参照してください。

### PostgreSQL CheckViolationにより18.9へのアップグレードが失敗する {#upgrade-to-189-fails-with-postgresql-checkviolation}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.9.0、18.9.1

Self-ManagedインスタンスをGitLab 18.9.0または18.9.1にアップグレードすると、データベース移行中にアップグレードが失敗します:

```plaintext
PG::CheckViolation: ERROR: check constraint "check_xxxxxxxx" of relation "tablename" is violated by some row
```

このイシューは、GitLab 18.10で修正されたバグによって引き起こされました（[マージリクエスト224446](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224446)を参照）。この修正はバックポートされており、次のGitLab 18.9のパッチリリースに含まれるはずです（[マージリクエスト225026](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225026)を参照）。

しかし、このバグは、単一レコードのバグのために、バッチバックグラウンド移行がサイレントにスキップされる原因となる可能性があります。v18.8へのアップグレード時に、単一レコードのテーブルを対象とするバッチバックグラウンド移行が、一度も実行されることなく誤って`finished`とマークされました。これによりデータがバックフィルされず、Self-Managedインスタンスでのアップグレードの失敗を引き起こしました。

提案されている修正（[マージリクエスト225461](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225461)を参照）は、影響を受けたバッチバックグラウンド移行を`finished`/`finalized`から`paused`にリセットし、スケジューラがそれらを再実行するようにします。これは、18.5から18.8の間で`queued_migration_version`を持つ移行にスコープされ、`min_value = max_value`または`min_cursor = max_cursor`の場合に適用されます。

次の2つの方法があります。

- 今すぐ回避策を適用して、すぐにアップグレードを完了してください。
- 完全な修正がリリースに含まれてからアップグレードするまで待ってください。

以下のKnowledge Base記事では、5つの既知の症状に対する回避策について説明しています:

- [`PG::CheckViolation: ERROR: check constraint "check_96233d37c0" of relation "pool_repositories" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25929006135068-PG-CheckViolation-ERROR-check-constraint-check-96233d37c0-of-relation-pool-repositories-is-violated-by-some-row)
- [`PG::CheckViolation: ERROR: check constraint "check_f6590fe2c1" of relation "gpg_key_subkeys" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25756021007004-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-gpg-key-subkeys)
- [`PG::CheckViolation: ERROR: check constraint "check_17a3a18e31" of relation "user_agent_details" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25994671144348-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-user-agent-details)
- [`PG::CheckViolation: ERROR: check constraint "check_ddd6f289f4" of relation "commit_user_mentions" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25992549646364-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-commit-user-mentions)
- [`PG::CheckViolation: ERROR: check constraint "check_e69372e45f" of relation "suggestions" is violated by some row`](https://support.gitlab.com/hc/en-us/articles/25771198648732-Upgrade-to-18-9-0-fails-with-PG-CheckViolation-on-suggestions)

### デプロイキーおよびブロックされたユーザーのパーソナルアクセストークンが無効化されました {#deploy-keys-and-personal-access-tokens-for-blocked-users-invalidated}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチレベル | 修正パッチレベル        |
  |---------|-----------------------|--------------------------|
  | 18.8    | 18.8.2以降      | 該当なし（意図的な変更） |
  | 18.7    | 18.7.2以降      | 該当なし（意図的な変更） |
  | 18.6    | 18.6.4以降      | 該当なし（意図的な変更） |

GitLab 18.8.2、18.7.2、および18.6.4では、ブロックされたユーザーに関連付けられたデプロイキーを使用するAPIリクエストが拒否されるようになりました。ブロックされたユーザーに関連付けられたデプロイキーがある場合、上記のバージョンにアップグレードした以降は機能しなくなります。これは、ブロックされたユーザーがキーとトークンを介してGitLabリソースにアクセスするのを防ぐためのセキュリティ修正です。

これを行うには、次の手順に従います。

1. ブロックされたユーザーが所有するデプロイキーまたはPATを特定します。
1. それらを請求対象ユーザーに再割り当てするか、削除して、請求対象ユーザーまたはサービスアカウントを使用して新しいキー/トークンを作成します。

以下のクエリは、ブロックされたアカウントに関連付けられており、過去365日間に少なくとも一度使用されたすべてのデプロイキーを特定するために使用できます:

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

### ClickHouse辞書作成エラー {#clickhouse-dictionary-creation-error}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.8.0

Self-Managedインスタンスのお客様で[ClickHouseインテグレーション](../../integration/clickhouse.md)が有効になっている場合、権限の不足（`DB::Exception: gitlab: Not enough privileges`）により、アップグレードプロセス中にClickHouseデータベースの移行エラーが発生する可能性があります。このエラーを解決するには、[データベースディクショナリの読み取りサポートのドキュメント](../../integration/clickhouse.md#database-dictionary-read-support)を参照してください。

### CIデータに対するバッチバックグラウンド移行の再導入 {#batched-background-migration-for-ci-data-reintroduced}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.8.0

[batched background移行](../background_migrations.md)が[CIビルドmetadata移行](#ci-builds-metadata-migration)に導入されましたが、データ構造のエッジケースを処理し、それらが完了することを保証するために再導入する必要がありました。

### 引用符なしのプレースホルダーを含むカスタムWebhookテンプレートを保存できない {#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | すべてのパッチリリース      | 未修正         |
  | 18.9    | すべてのパッチリリース      | 未修正         |
  | 18.8    | すべてのパッチリリース      | 未修正         |

GitLab 18.8から18.10では、引用符なしのペイロードフィールドを含む[カスタムWebhookテンプレート](../../user/project/integrations/webhooks.md#custom-webhook-template)を保存できません。このイシューはGitLab 18.11で解決されました。

回避策として、フィールドを引用符で囲んでください。たとえば、`{"value": {{id}}}`は`{"value": "{{id}}"}`になります。

引用符で囲まれたフィールドは、数値ではなく文字列値を生成します。これがあなたのWebhookと互換性がない場合、GitLab 18.11以降にアップグレードしてください。

詳細については、[Webhookトラブルシューティングドキュメント](../../user/project/integrations/webhooks_troubleshooting.md#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved)を参照してください。

### CIビルドメタデータ移行 {#ci-builds-metadata-migration}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.7.0

A [post deployment移行](../../development/database/post_deployment_migrations.md)は、CIビルドメタデータを新しい最適化されたテーブル（`p_ci_job_definitions`）にコピーするために、バッチ化された[background移行](../background_migrations.md)をスケジュールします。この移行は、最終的にCIデータベースサイズを削減するためのイニシアチブの一部です（[エピック13886](https://gitlab.com/groups/gitlab-org/-/epics/13886)を参照）。数百万のジョブを持つインスタンスがあり、移行を高速化したい場合は、[select what data is migrated](#ci-builds-metadata-migration-details)を実行できます。

### Geo ActionCableの許可されたorigin設定 {#geo-actioncable-allowed-origins-setting}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.7.0

ActionCableウェブソケットリクエストの許可されたoriginを設定するための新しい`action_cable_allowed_origins`設定が追加されました。適切なクロスサイトWebSocket接続を確保するために、プライマリサイトを設定する際に許可されるURLを指定します:

- [Geoドキュメントfor the Linuxパッケージ](../../administration/geo/replication/configuration.md#add-primary-and-secondary-urls-as-allowed-actioncable-origins)
- [Geoドキュメントfor the Helmチャート](https://docs.gitlab.com/charts/advanced/geo/#configure-primary-database)

### Geo VerificationStateBackfillWorkerの遅いクエリの修正 {#geo-verificationstatebackfillworker-slow-queries-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.6.5

Geoの[イシュー587407](https://gitlab.com/gitlab-org/gitlab/-/work_items/587407)を修正しました。このイシューでは、`Geo::VerificationStateBackfillWorker`が`merge_request_diff_details`テーブルに対して大量の遅いクエリを生成していました。

### コミットとファイルAPIのサイズとレート制限 {#commits-and-files-api-size-and-rate-limits}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチレベル | 修正パッチレベル        |
  |---------|-----------------------|--------------------------|
  | 18.6    | 18.6.2以降      | 該当なし（意図的な変更） |
  | 18.5    | 18.5.4以降      | 該当なし（意図的な変更） |
  | 18.4    | 18.4.6以降      | 該当なし（意図的な変更） |

GitLab 18.6.2、18.5.4、および18.4.6では、以下のエンドポイントへのリクエストに対してサイズおよびレート制限が導入されました:

- `POST /projects/:id/repository/commits` - [Create aコミット](../../api/commits.md#create-a-commit)
- `POST /projects/:id/repository/files/:file_path` - [Create a file in aリポジトリ](../../api/repository_files.md#create-a-file-in-a-repository)
- `PUT /projects/:id/repository/files/:file_path` - [Update a file in aリポジトリ](../../api/repository_files.md#update-a-file-in-a-repository)

GitLabは、サイズ制限を超えるリクエストには`413 Entity Too large`ステータスで応答し、レート制限を超えるリクエストには`429 Too Many Requests`ステータスで応答します。詳細については、[コミットとファイルAPIのAPI制限](../../administration/instance_limits.md#commits-and-files-api-limits)を参照してください。

### GitLab Duo Agent Platform Runnerの制限 {#duo-agent-platform-runner-restrictions}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.6.2

[runner restrictions](../../user/duo_agent_platform/flows/execution.md#configure-runners)が導入され、GitLab Duo Agent Platformで使用できるRunnerに関連する制限が設けられました。

### Geoログカーソル移行の修正 {#geo-log-cursor-migration-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  |---------|-------------------------|-------------------|
  | 18.5    | 18.5.0 - 18.5.1         | 18.5.2            |
  | 18.4    | 18.4.0 - 18.4.3         | 18.4.4            |

Geoログカーソルがセカンダリサイトで起動するのを防ぐ、不足しているGeo[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210512)が修正されました。

### 設計管理デザインバックフィルの完了 {#finalize-design-management-designs-backfill}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.5.0

`20250922202128_finalize_correct_design_management_designs_backfill`は、18.4でスケジュールされたバッチ[バックグラウンド移行](../background_migrations.md)を完了させる[デプロイ後の移行](../../development/database/post_deployment_migrations.md)です。アップグレードパスで18.4をスキップした場合、この移行はデプロイ後の移行時に完全に実行されます。実行時間は、`design_management_designs`テーブルのサイズに直接関係します。ほとんどのインスタンスでは移行に2分以上かかることはありませんが、一部の大規模なインスタンスでは、最大で10分ほどかかる場合があります。移行プロセスを中断せず、そのままお待ちください。

### NGINXルーティングの変更により404エラーが発生する {#nginx-routing-changes-cause-404-errors}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 18.5.0

GitLab 18.5.0で導入されたNGINXルーティングの変更により、`localhost`のような一致しないホスト名や代替ドメイン名を使用すると、サービスにアクセスできなくなる可能性があります。このイシューにより、以下が発生します:

- `/-/health`のようなヘルスチェックエンドポイントが、適切な応答ではなく`404`エラーを返す。
- 設定されたFQDN以外のホスト名でアクセスした場合に、GitLabウェブインターフェースに`404`エラーページが表示される。
- GitLab Pagesが、他のサービス向けのトラフィックを受信する可能性。
- 以前は機能していた代替ホスト名を使用するリクエストに関する問題。

このイシューは、[マージリクエスト8805](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8805)によりLinuxパッケージで解決されており、修正はGitLab 18.5.2および18.6.0で利用可能になります。

クローン、プッシュ、プルなどのGit操作は、このイシューの影響を受けません。

### バッチバックグラウンド移行nilエラー {#batched-background-migration-nil-error}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.4.2、18.4.3

`18.4.2`または`18.4.3`へのアップグレードは、これらのバッチバックグラウンド移行で`no implicit conversion of nil into String`エラーにより失敗する可能性があります:

- `FixIncompleteInstanceExternalAuditDestinations`
- `FinalizeAuditEventDestinationMigrations`

このイシューを解決するには、最新のパッチリリースにアップグレードするか、[workaround inイシュー578938](https://gitlab.com/gitlab-org/gitlab/-/issues/578938#workaround)を使用してください。

### GeoレプリケーションのTypeError {#geo-replication-typeerror}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  |---------|-------------------------|-------------------|
  | 18.4    | 18.4.0 - 18.4.1         | 18.4.2            |

Geoセカンダリサイトで、[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/571455)により、`no implicit conversion of String into Array (TypeError)`というエラーメッセージが表示され、レプリケーションイベントが失敗します。再検証などの冗長性機能によって最終的な整合性は確保されますが、目標リカバリー時点が大幅に長くなります。

### サービス拒否防止のためのJSON入力制限 {#json-input-limits-for-denial-of-service-prevention}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチレベル | 修正パッチレベル        |
  |---------|-----------------------|--------------------------|
  | 18.4    | 18.4.1以降      | 該当なし（意図的な変更） |
  | 18.3    | 18.3.3以降      | 該当なし（意図的な変更） |
  | 18.2    | 18.2.7以降      | 該当なし（意図的な変更） |

GitLab 18.4.1、18.3.3、18.2.7では、サービス拒否攻撃を防ぐためにJSON入力に対する制限が導入されました。GitLabは、これらの制限を超えるHTTPリクエストに対して`400 Bad Request`ステータスで応答します。詳細については、[HTTPリクエスト制限](../../administration/instance_limits.md#http-request-limits)を参照してください。

### LdapAddOnSeatSyncWorkerがDuoシートを削除する {#ldapaddonseatsyncworker-removes-duo-seats}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.3.0

新しいワーカー`LdapAddOnSeatSyncWorker`が導入されました。これにより、LDAPが有効になっている場合、毎晩、GitLab Duoシートからすべてのユーザーが誤って削除される可能性がありました。この問題はGitLab 18.4.0および18.3.2で修正されました。詳細については、[イシュー565064](https://gitlab.com/gitlab-org/gitlab/-/issues/565064)を参照してください。

### Geo Rakeチェックの修正 {#geo-rake-check-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.3.0

Geoセカンダリサイトをインストールするに際に、`rake gitlab:geo:check`が誤って失敗を報告する原因となっていた[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545533)が18.3.0で修正されました。

### Geo GitLab Pagesファイル名修正 {#geo-pages-filename-fix}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチレベル  | 修正パッチレベル |
  |---------|------------------------|-------------------|
  | 18.3    | 18.3.0 - 18.3.2        | 18.3.3            |
  | 18.2    | 18.2.0 - 18.2.6        | 18.2.7            |
  | 18.1    | 18.1.0以降       | 18.1では修正されず |

GitLab 18.3.3および18.2.7以降には、[イシュー559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196)の修正が含まれており、ファイル名が長いPagesデプロイでGeo検証が失敗する可能性がありました。この修正により、Geoセカンダリサイトでのファイル名のトリミングが防止され、レプリケーションおよび検証時の一貫性が維持されます。

### 18.1と18.2間のゼロダウンタイムアップグレード時のプッシュエラー {#zero-downtime-upgrade-push-errors-between-181-and-182}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.2.0

18.1.xから18.2.xへのアップグレードでは、[既知のイシュー567543](https://gitlab.com/gitlab-org/gitlab/-/issues/567543)の影響により、アップグレード中に既存プロジェクトへのコードのプッシュでエラーが発生します。バージョン18.1.xから18.2.xへのアップグレード中にダウンタイムを発生させないようにするには、修正を含むバージョン18.2.6に直接アップグレードします。

### Geo VerificationStateBackfillService `ci_job_artifact_states` {#geo-verificationstatebackfillservice-ci_job_artifact_states}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチレベル | 修正パッチレベル |
  |---------|------------------------|-------------------|
  | 18.2    | 18.2.0 - 18.2.1        | 18.2.2            |
  | 18.1    | 18.1.0 - 18.1.3        | 18.1.4            |
  | 18.0    | 18.0.0 - 18.0.5        | 18.0.6            |

影響を受けるバージョンには、`ci_job_artifact_states`の主キーの変更により`VerificationStateBackfillService`が実行されるときに発生する既知のイシューがあります。解決するには、修正されたパッチレベルのリリースにアップグレードしてください。

### Elasticsearch `strict_dynamic_mapping_exception` {#elasticsearch-strict_dynamic_mapping_exception}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.1.0

Elasticsearchバージョン7では、Elasticsearchのインデックス作成時に`strict_dynamic_mapping_exception`エラーが発生して失敗する可能性があります。解決するには、[イシュー566413](https://gitlab.com/gitlab-org/gitlab/-/issues/566413)の「Possible fixes」セクションを参照してください。

### PostgreSQL `ci_job_artifacts`エラー {#postgresql-ci_job_artifacts-error}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.1.0、18.1.1

GitLabバージョン18.1.0および18.1.1では、PostgreSQLログに`ERROR:  relation "ci_job_artifacts" does not exist at ...`のようなエラーが表示されることがあります。これらのログ上のエラーは無視しても問題ありませんが、Geoサイトを含め、モニタリングアラートがトリガーされる可能性があります。この問題を解決するには、GitLab 18.1.2以降にアップデートしてください。

### マージリクエストがほぼ準備完了バグ {#merge-request-almost-ready-bug}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.1.0

一部のユーザーによるコミットを含むマージリクエストは進行せず、継続的に`Your merge request is almost ready`と表示される場合があります。[イシュー554613](https://gitlab.com/gitlab-org/gitlab/-/issues/554613)を参照してください。さらに、[`sidekiq/current`ログ](../../administration/logs/_index.md#sidekiq-logs)には`merge_request_diff_commit.rb`の`undefined method 'id' for nil:NilClass`エラーが表示されます。これを修正するには、次の手順に従います:

1. [database console](../../administration/troubleshooting/postgresql.md#start-a-database-console)を起動します。
1. 次のコマンドを実行します:

   ```sql
   REINDEX TABLE CONCURRENTLY public.merge_request_diff_commit_users;
   ```

1. 影響を受けたマージリクエストを閉じて、再度開きます。

### Geo HTTP 500プロキシエラー {#geo-http-500-proxy-errors}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  |---------|-------------------------|-------------------|
  | 18.1    | 18.1.0                  | 18.1.1            |
  | 18.0    | 18.0.0 - 18.0.2         | 18.0.3            |

上記の表のGitLabバージョンには、セカンダリサイトからプロキシされたGit操作がHTTP 500エラーで失敗する既知のイシューがあります。解決するには、修正されたパッチレベルのリリースにアップグレードしてください。

### PostgreSQL 14はサポートされていません {#postgresql-14-not-supported}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.0.0

[PostgreSQL 14は、GitLab 18以降ではサポートされていません](../deprecations.md#postgresql-14-and-15-no-longer-supported)。GitLab 18.0以降にアップグレードする前に、PostgreSQLをバージョン16.5以降にアップグレードしてください。詳細については、[installation requirements](../../install/requirements.md#postgresql)を参照してください。

> [!warning]
> 自動データベースバージョンアップグレードは、Linuxパッケージを使用している場合の単一ノードインスタンスにのみ適用されます。それ以外のケース、たとえばGeoインスタンス、Linuxパッケージを使用した高可用性のPostgreSQLデータベース、または外部PostgreSQLデータベース（Amazon RDSなど）を使用している場合は、PostgreSQLを手動でアップグレードする必要があります。詳細な手順については、[Geoインスタンスをアップグレードする](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-geo-instance)を参照してください。

### `pg_dump`バイナリ互換性 {#pg_dump-binary-compatibility}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.0.0

GitLabは`pg_dump`バイナリをバンドルしています。外部のPostgreSQLサーバーを使用する場合は、`pg_dump`クライアントバージョンがPostgreSQLサーバーと互換性があることを確認し、GitLabデータベースのバックアップの作成と復元両方に対応していることを確認してください。

### Bitnami PostgreSQLおよびRedisイメージの廃止 {#bitnami-postgresql-and-redis-image-deprecation}

- 影響: Helmチャート
- 影響を受けるバージョン: 17.11.0以前

2025年9月29日以降、Bitnamiはタグ付きのPostgreSQLおよびRedisイメージの提供を終了します。GitLabチャートを使用し、RedisまたはPostgresをバンドルしたGitLab 17.11以前をデプロイしている場合は、予期しないダウンタイムを防ぐために、レガシーリポジトリを使用するように値を手動で更新する必要があります。詳細については、[イシュー6089](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6089)を参照してください。

### 17.11からのゼロダウンタイムアップグレード中のパイプラインの失敗 {#pipeline-failures-during-zero-downtime-upgrades-from-1711}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.0.0

機能フラグ`ci_only_one_persistent_ref_creation`により、RailsがアップグレードされてもSidekiqがバージョン17.11のままの場合、ゼロダウンタイムアップグレード中にパイプラインが失敗することがあります（詳細は[イシュー558808](https://gitlab.com/gitlab-org/gitlab/-/issues/558808)を参照してください）。

**予防策**: アップグレードする前に、Railsコンソールを開き、機能フラグを有効にします:

```shell
$ sudo gitlab-rails console
Feature.enable(:ci_only_one_persistent_ref_creation)
```

**すでに影響を受けている場合**: 次のコマンドを実行して、失敗したパイプラインを再試行します:

```shell
$ sudo gitlab-rails console
Rails.cache.delete_matched("pipeline:*:create_persistent_ref_service")
```

### Gitaly設定を`git_data_dirs`からストレージに移行する {#migrate-gitaly-configuration-from-git_data_dirs-to-storage}

- 影響: Linuxパッケージ
- 影響を受けるバージョン: 18.0.0

GitLab 18.0以降では、`git_data_dirs`設定を使用してGitalyストレージの場所を設定できなくなりました。

依然として`git_data_dirs`を使用している場合は、GitLab 18.0にアップグレードする前に[Gitaly設定を移行する](https://docs.gitlab.com/omnibus/settings/configuration/#migrating-from-git_data_dirs)必要があります。

### Geo CEからEEへのロールバック移行エラー {#geo-ce-to-ee-revert-migration-errors}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

- 影響: Geo
- 影響を受けるバージョン: 18.0.0

GitLab Enterprise Editionをデプロイした後にGitLab Community Editionに戻した場合、データベーススキーマがGitLabアプリケーションで想定されているスキーマと異なることがあり、移行エラーが発生する可能性があります。18.0.0へのアップグレード時には、このバージョンで追加された移行によって特定の列のデフォルトが変更されるため、4種類のエラーが発生する可能性があります。

発生するエラーは次のとおりです:

- `No such column: geo_nodes.verification_max_capacity`
- `No such column: geo_nodes.minimum_reverification_interval`
- `No such column: geo_nodes.repos_max_capacity`
- `No such column: geo_nodes.container_repositories_max_capacity`

この移行には、これらの列が欠落している場合に追加するためのパッチがGitLab 18.0.2で適用されました。[イシュー543146](https://gitlab.com/gitlab-org/gitlab/-/issues/543146)を参照してください。

**影響を受けるリリース**:

| 影響を受けるマイナーリリース | 影響を受けるパッチリリース | 修正リリース |
| ----------------------- | ----------------------- | -------- |
| 18.0                    |  18.0.0 - 18.0.1        | 18.0.2   |

### DockerインストールでのPRNG is not seededエラー {#prng-is-not-seeded-error-on-docker-installations}

- 影響: Docker
- 影響を受けるバージョン: 18.0.0

FIPSが有効なホスト上でDockerインストール環境のGitLabを実行している場合、SSHキーの生成やOpenSSHサーバー（`sshd`）の起動が失敗し、次のエラーメッセージが表示されることがあります:

```plaintext
PRNG is not seeded
```

GitLab 18.0では、[ベースイメージをUbuntu 22.04から24.04に更新しました](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8928)。このエラーは、Ubuntu 24.04で[FIPSホストが非FIPS OpenSSLプロバイダーを使用できなくなった](https://github.com/dotnet/dotnet-docker/issues/5849#issuecomment-2324943811)ことが原因で発生します。

この問題を解決するには、いくつかのオプションがあります:

- ホストシステムでFIPSを無効にする。
- GitLab Dockerコンテナ内でFIPSベースのカーネルの自動検出を無効にする。これは、GitLab 18.0.2以降で`OPENSSL_FORCE_FIPS_MODE=0`環境変数を設定することで実行できます。
- GitLab Dockerイメージを使用する代わりに、ホスト上に[ネイティブのFIPSパッケージ](https://packages.gitlab.com/ui/browse/gitlab/gitlab-fips)をインストールする。

最後のオプションが、FIPS要件を満たすための推奨手順です。レガシーインストールの場合は、最初の2つのオプションを一時的な対処方法として使用できます。

### CIビルドメタデータ移行の詳細 {#ci-builds-metadata-migration-details}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.7.0

> [!note]
> GitLab 18.6以降、新しいパイプラインは新しい形式にのみデータを書き込みます（[イシュー552065](https://gitlab.com/gitlab-org/gitlab/-/issues/552065)を参照）。この移行は、既存のデータを古いフォーマットから新しいフォーマットにコピーするだけです。データは削除されません。

移行されなかったデータは、将来のリリースで削除されます（[エピック18271](https://gitlab.com/groups/gitlab-org/-/epics/18271)を参照）。

移行期間は、インスタンス内のCIジョブの総数に正比例します。ジョブは、最新のパーティションから最も古いパーティションまで処理され、最近のデータが優先されます。

大規模なプロジェクトで[automaticパイプラインcleanup](../../ci/pipelines/settings.md#automatic-pipeline-cleanup)を有効にすることで、アップグレード前に古いパイプラインを削除し、移行するジョブの数を減らすことができます。

移行は2種類のデータをコピーします:

- **Jobs processing data**: ジョブ実行時にRunnerにのみ必要で、UIやAPIには不要な`.gitlab-ci.yml`（`script`、`variables`など）からのジョブ実行設定。
- **Job data visible to users**: すべてのジョブデータのうち、この移行はジョブタイムアウト値、ジョブ終了コード値、[exposedアーティファクト](../../ci/jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui) 、および[environment associations](../../ci/yaml/_index.md#environment)にのみ影響します。

大規模なCIデータセットを持つGitLab Self-ManagedインスタンスおよびGitLab Dedicatedインスタンスの場合、移行するデータのスコープを減らすことで、移行を高速化できます。スコープを制御するには、以下に定義されている設定を使用します。

#### ジョブ処理データのスコープの制御 {#controlling-the-scope-for-jobs-processing-data}

デフォルトでは、移行は既存のすべてのジョブの処理データをコピーします。以下のいずれかの設定を使用することで、スコープを削減できます。

設定の値は、保持したいジョブ処理データの量を制御します。例えば、過去6か月以内に作成されたジョブのみが実行されると予想される場合（[retries](../../ci/jobs/_index.md#retry-jobs) 、[execution of manualジョブs](../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually) 、[environment auto-stop](../../ci/environments/_index.md#stopping-an-environment)を通じて）、`6mo`に設定します。

GitLabは、以下の優先順位で設定を探します:

1. [パイプラインarchival](../../administration/settings/continuous_integration.md#archive-pipelines)設定（推奨されるベストプラクティス）。アーカイブされたパイプラインは、ジョブを手動で再試行または再実行できないことを示します。この設定が有効になっている場合、アーカイブされたジョブの処理データは移行する必要はありません。

   > [!note]
   > パイプラインアーカイブ範囲が以降延長された場合、処理データのないジョブは実行不能なままになります。
1. `GITLAB_DB_CI_JOBS_PROCESSING_DATA_CUTOFF` [環境変数](../../administration/environment_variables.md)（パイプラインアーカイブが設定されていない場合、またはこの移行のために上書きする必要がある場合）。`1y`（1年）、`6mo`（6ヶ月）、`90d`（90日）のような期間文字列を受け入れます。
1. 上記のどちらも設定されていない場合、`GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF`環境変数。`1y`（1年）、`6mo`（6ヶ月）、`90d`（90日）のような期間文字列を受け入れます。[Controlling theスコープforジョブdata visible to users](#controlling-the-scope-for-job-data-visible-to-users)を参照してください。
1. 設定が見つからない場合、すべてのデータがコピーされます。

#### ユーザーに表示されるジョブデータのスコープの制御 {#controlling-the-scope-for-job-data-visible-to-users}

環境変数`GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF`は、どのジョブの可視データを移行するかを制御します。

例えば、`GITLAB_DB_CI_JOBS_MIGRATION_CUTOFF=1y`は、最も最近の1年間のジョブについて、影響を受ける可視データ（タイムアウト値、環境、終了コード値、および公開されたアーティファクトのメタデータ）をコピーします。

デフォルトでは、カットオフ日付はなく、すべてのジョブのデータが移行されます。

#### 移行の影響の推定 {#estimating-migration-impact}

参考として、GitLab.comでは、約2ヶ月で4億行のデータを移行する予定です。

インスタンスへの移行の影響を推定するには、[PostgreSQL console](../../administration/troubleshooting/postgresql.md#start-a-database-console)で以下のクエリを実行できます:

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

新しいテーブルには、このスペースの約20％が必要です。

{{< /tab >}}

{{< tab title="ジョブ数推定" >}}

これはPostgreSQL統計テーブルからの推定です。

```sql
SELECT SUM(c.reltuples)::bigint AS estimated_jobs_count
FROM pg_class c
JOIN pg_inherits i ON c.oid = i.inhrelid
WHERE i.inhparent = 'p_ci_builds'::regclass;
```

{{< /tab >}}

{{< tab title="ジョブ期間別" >}}

特定の期間に作成されたジョブの数を見つけるには、テーブルをクエリする必要があります:

```sql
SELECT COUNT(*) FROM p_ci_builds WHERE created_at >= now() - '1 year'::interval;
```

クエリがタイムアウトした場合は、[Rails console](../../administration/operations/rails_console.md)を使用してデータをバッチ処理します:

```ruby
counts = []
CommitStatus.each_batch(of: 25000) do |batch|
  counts << batch.where(created_at: 1.year.ago...).count
end
counts.sum
```

{{< /tab >}}

{{< /tabs >}}

### マージリクエストマージデータに対するバッチバックグラウンド移行 {#batched-background-migration-for-merge-request-merge-data}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.8.0

A [batched background移行](../background_migrations.md)は、`merge_requests`テーブルから新しい専用の`merge_requests_merge_data`テーブルに、マージリクエストのマージ関連データをコピーします。

この移行は、マージ固有の属性を別のテーブルに正規化し、クエリパフォーマンスと保守性を向上させるデータベーススキーマ最適化イニシアチブの一部です。

#### 移行されるデータ {#what-data-is-migrated}

移行は、以下の列を`merge_requests`から`merge_requests_merge_data`にコピーします:

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

移行は`merge_requests`テーブルを処理し、`merge_requests_merge_data`にまだ対応するエントリがないマージリクエストのデータのみをコピーします。

GitLab 18.7以降、新しいマージリクエストは、アプリケーションレベルでのデュアルライトメカニズムを通じて両方のテーブルにデータを書き込みます（[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/560933)を参照）。この移行は、デュアルライトが実装された以降に作成または変更されていない既存のデータのみをコピーします。

この移行中に`merge_requests`テーブルからデータは削除されません。

この移行はGitLab 18.9で完了する予定です。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/584459)を参照してください。

#### 移行期間を見積もる {#estimating-migration-duration}

移行期間は、インスタンス内のマージリクエストの数に正比例します。

影響を推定するには:

**PostgreSQL query:**

```sql
-- Count total merge requests
SELECT COUNT(*) FROM merge_requests;

-- Estimate table size
SELECT pg_size_pretty(pg_total_relation_size('merge_requests')) AS table_size;
```

**Rails console:**

```ruby
# Count total merge requests
MergeRequest.count

# Count remaining merge requests to migrate
MergeRequest.left_joins(:merge_data)
  .where(merge_requests_merge_data: { merge_request_id: nil })
  .count
```

移行はマージリクエストをバッチで処理し、ほとんどのインスタンスでは数時間から数日以内に完了するはずです。

### GitLab 18.11でのPostgreSQLバージョン17.7アップグレード {#postgresql-version-177-upgrade-on-gitlab-1811}

- 影響: Linuxパッケージ、Docker、Geo
- 影響を受けるバージョン: 18.11.0

GitLab 18.11へのアップグレードにより、単一ノードのLinuxパッケージインストールの場合、[PostgreSQL 17.7への自動アップグレード](../../administration/package_information/postgresql_versions.md)がトリガーされます。

> [!warning]
> 自動データベースバージョンアップグレードは、Linuxパッケージを使用している場合の単一ノードインスタンスにのみ適用されます。Geoデプロイの場合、メジャーバージョンのアップグレードにはGeoセカンダリへのPostgreSQLレプリケーションの再初期化が必要となるため、PostgreSQLのアップグレードは[意図的にスケジュールおよび計画](../../administration/geo/replication/upgrading_the_geo_sites.md)される必要があります。これにより、予想よりも長いダウンタイムが発生する可能性があります。

### Sidekiq並行処理リミッターによりHelmチャートおよびOperatorデプロイでジョブのバックログが発生する {#sidekiq-concurrency-limiter-causes-job-backlogs-on-helm-chart-and-operator-deployments}

- 影響: Helmチャート, Operator
- 影響を受けるバージョン: 

  | リリース | 影響を受けるパッチリリース | 修正パッチレベル |
  | ------- | ----------------------- | ----------------- |
  | 18.10   | 18.10.0 - 18.10.3      | 18.10.4           |
  | 18.9    | 18.9.0 - 18.9.5        | 18.9.6            |

GitLab 18.9で、GitLab Helmチャートはデフォルトで`GITLAB_SIDEKIQ_MAX_REPLICAS`を設定し始めました（[charts/GitLabマージリクエスト4348](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4348)）。KEDAベースのオートスケールを使用しないGitLab Self-ManagedおよびGitLab Dedicated環境では、これによりSidekiq並行処理リミッターが予期せずアクティブになり、ジョブがRedisをバックエンドとするスロットルされたキューに繰り延べられます。

これにより、以下の結果が生じる可能性があります:

- Sidekiqジョブのバックログ。
- Redisメモリの増加。
- 遅延したジョブの実行。
- `WebHookWorker`、`AuditEvents::AuditEventStreamingWorker`、およびGeoレプリケーションワーカー（`Geo::EventWorker`、`Geo::SyncWorker`）などのワーカーへの影響。

影響を受ける場合は、修正済みのバージョンにアップグレードするまで、以下のいずれかの一時的な軽減策を使用できます:

- 機能フラグを有効にすることで、**Disable the concurrency limiter for a specific worker**にします。Sidekiqポッドで`exec`を実行して、Railsコンソールを開きます:

  ```shell
  kubectl exec -it <sidekiq-pod-name> -- gitlab-rails console
  ```

  次に、影響を受けるワーカーの機能フラグを有効にします:

  ```ruby
  Feature.enable(:"disable_sidekiq_concurrency_limit_middleware_<WorkerClass>")
  ```

  `<WorkerClass>`を影響を受けるワーカー名（例: `WebHookWorker`）に置き換えます。

- Sidekiqポッド環境設定で`GITLAB_SIDEKIQ_MAX_REPLICAS=0`を設定することにより、**Disable all default concurrency limits**にします。これにより、デフォルトの並行処理制限の計算が完全に無効になります。

> [!warning]
> Geoを使用している場合、セカンダリサイトで既にスロットルされたジョブは、`ConcurrencyLimit::ResumeWorker`がGeoセカンダリで実行されないため、自動的にドレインされない可能性があります。スロットルされたキューをクリアするために手動で介入する必要がある場合があります。

デフォルトの並行処理制限計算を機能フラグの背後にゲートする修正が[マージリクエスト230713](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230713)でマージされ、18.10.4（[マージリクエスト231085](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231085)）と18.9.6（[マージリクエスト231297](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231297)）にバックポートされました。

### すべてのプロジェクトでシークレット検出の誤検出判定がデフォルトで有効化される {#secret-detection-false-positive-detection-enabled-by-default-on-all-projects}

- 影響: すべてのインストール方法
- 影響を受けるバージョン: 18.10.x

[シークレット誤検出判定](../../user/application_security/vulnerabilities/false_positive_detection.md)の基本フローを有効にするには、通常2つのステップが必要です:

1. グループに対して基本フローを許可します。
1. 個々のプロジェクトに対して基本フローを有効にします。

しかし、GitLab 18.10のいずれかのバージョンへのアップグレードにより、すべてのプロジェクトに対してシークレット誤検出判定の基本フローが有効になります。グループに対して基本フローが許可されると、そのグループ内のすべてのプロジェクトで既に有効になります。

グループに対してシークレット誤検出判定の基本フローを許可する前に、グループ内のプロジェクトの設定を確認してください。

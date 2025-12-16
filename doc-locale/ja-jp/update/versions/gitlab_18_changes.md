---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 18アップグレードノート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLab 18のマイナーバージョンとパッチバージョンのアップグレード情報を提供します。以下の条件を考慮して、各手順を確認してください:

- お使いのインストールタイプ。
- 現在のバージョンから移行先バージョンまでのすべてのバージョン。

Helmチャートのインストールの詳細については、[Helmチャート9.0のアップグレードノート](https://docs.gitlab.com/charts/releases/9_0.html)を参照してください。

## 必須アップグレードストップ {#required-upgrade-stops}

インスタンス管理者に予測可能なアップグレードスケジュールを提供するために、必須アップグレードストップは、以下のバージョンで発生します:

- `18.2`
- `18.5`
- `18.8`
- `18.11`

## 17.11からのアップグレード時に注意すべき問題 {#issues-to-be-aware-of-when-upgrading-from-1711}

- [PostgreSQL 14は、GitLab 18以降ではサポートされていません](../deprecations.md#postgresql-14-and-15-no-longer-supported)。GitLab 18.0以降にアップグレードする前に、PostgreSQLを少なくともバージョン16.8にアップグレードしてください。

  {{< alert type="warning" >}}

  自動データベースバージョンアップグレードは、Linuxパッケージを使用している単一ノードインスタンスにのみ適用されます。それ以外のケース、たとえばGeoインスタンス、Linuxパッケージを使用した高可用性のPostgreSQLデータベース、または外部PostgreSQLデータベース（Amazon RDSなど）を使用している場合は、PostgreSQLを手動でアップグレードする必要があります。詳細な手順については、[Geoインスタンスをアップグレードする](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance)を参照してください。

  {{< /alert >}}

- 2025年9月29日以降、Bitnamiはタグ付きのPostgreSQLおよびRedisイメージの提供を終了します。GitLabチャートを使用し、RedisまたはPostgresをバンドルしたGitLab 17.11以前をデプロイしている場合は、予期しないダウンタイムを防ぐために、レガシーリポジトリを使用するように値を手動で更新する必要があります。詳細については、[イシュー6089](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6089)を参照してください。

- **既知の問題:** 機能フラグ`ci_only_one_persistent_ref_creation`により、RailsがアップグレードされてもSidekiqがバージョン17.11のままの場合、ゼロダウンタイムアップグレード中にパイプラインが失敗することがあります（詳細は[イシュー558808](https://gitlab.com/gitlab-org/gitlab/-/issues/558808)を参照してください）。

  **予防策:** アップグレードする前に、Railsコンソールを開き、機能フラグを有効にします:

  ```shell
  $ sudo gitlab-rails console
  Feature.enable(:ci_only_one_persistent_ref_creation)
  ```

  **すでに影響を受けている場合:** 次のコマンドを実行して、失敗したパイプラインを再試行します:

  ```shell
  $ sudo gitlab-rails console
  Rails.cache.delete_matched("pipeline:*:create_persistent_ref_service")
  ```

## 18.5.0 {#1850}

- `20250922202128_finalize_correct_design_management_designs_backfill`は、18.4でスケジュールされたバッチ[バックグラウンド移行](../background_migrations.md)を完了させる[デプロイ後の移行](../../development/database/post_deployment_migrations.md)です。アップグレードパスで18.4をスキップした場合、この移行はデプロイ後の移行時に完全に実行されます。実行時間は、`design_management_designs`テーブルのサイズに直接関係します。ほとんどのインスタンスでは移行に2分以上かかることはありませんが、一部の大規模なインスタンスでは、最大で10分ほどかかる場合があります。移行プロセスを中断せず、そのままお待ちください。

## 18.4.2 {#1842}

Geoで発生していた、`no implicit conversion of String into Array (TypeError)`というエラーメッセージが表示されレプリケーションイベントが失敗する[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/571455)が修正されました。

## 18.4.1 {#1841}

GitLab 18.4.1、18.3.3、18.2.7では、サービス拒否攻撃を防ぐためにJSON入力に対する制限が導入されました。GitLabは、これらの制限を超えるHTTPリクエストに対して`400 Bad Request`ステータスで応答します。詳細については、[HTTPリクエスト制限](../../administration/instance_limits.md#http-request-limits)を参照してください。

## 18.4.0 {#1840}

- Geoセカンダリサイトで、[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/571455)により、`no implicit conversion of String into Array (TypeError)`というエラーメッセージが表示され、レプリケーションイベントが失敗します。再検証などの冗長性機能によって最終的な整合性は確保されますが、目標リカバリー時点が大幅に長くなります。影響を受けるバージョン: 18.4.0および18.4.1。

## 18.3.0 {#1830}

### GitLab Duo {#gitlab-duo}

- 新しいワーカー`LdapAddOnSeatSyncWorker`が導入されました。これにより、LDAPが有効になっている場合、毎晩、GitLab Duoシートからすべてのユーザーが誤って削除される可能性がありました。この問題はGitLab 18.4.0および18.3.2で修正されました。詳細については、[イシュー565064](https://gitlab.com/gitlab-org/gitlab/-/issues/565064)を参照してください。

### Geoインストール18.3.0 {#geo-installations-1830}

- Geoセカンダリサイトをインストールするに際に、`rake gitlab:geo:check`が誤って失敗を報告する原因となっていた[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545533)が18.3.0で修正されました。
- GitLab 18.3.0には、長いファイル名を持つPagesデプロイでGeo検証が失敗する可能性のあった[イシュー559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196)の修正が含まれています。この修正により、Geoセカンダリサイトでのファイル名のトリミングが防止され、レプリケーションおよび検証時の一貫性が維持されます。

## 18.2.0 {#1820}

### ゼロダウンタイムアップグレード {#zero-downtime-upgrades}

- 18.1.xから18.2.xへのアップグレードでは、[既知のイシュー567543](https://gitlab.com/gitlab-org/gitlab/-/issues/567543)の影響により、アップグレード中に既存プロジェクトへのコードのプッシュでエラーが発生します。バージョン18.1.xから18.2.xへのアップグレード中にダウンタイムを発生させないようにするには、修正を含むバージョン18.2.6に直接アップグレードします。

### Geoインストール18.2.0 {#geo-installations-1820}

- このバージョンでは、`ci_job_artifact_states`の主キーの変更により、`VerificationStateBackfillService`の実行時に発生する既知の問題があります。解決するには、GitLab 18.2.2以降にアップグレードしてください。
- GitLab 18.2.0には、長いファイル名を持つPagesデプロイでGeo検証が失敗する可能性のあった[イシュー559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196)の修正が含まれています。この修正により、Geoセカンダリサイトでのファイル名のトリミングが防止され、レプリケーションおよび検証時の一貫性が維持されます。

## 18.1.0 {#1810}

- Elasticsearchバージョン7では、Elasticsearchのインデックス作成時に`strict_dynamic_mapping_exception`エラーが発生して失敗する可能性があります。解決するには、[イシュー566413](https://gitlab.com/gitlab-org/gitlab/-/issues/566413)の「Possible fixes」セクションを参照してください。
- GitLabバージョン18.1.0および18.1.1では、PostgreSQLログに`ERROR:  relation "ci_job_artifacts" does not exist at ...`のようなエラーが表示されることがあります。これらのログ上のエラーは無視しても問題ありませんが、Geoサイトを含め、モニタリングアラートがトリガーされる可能性があります。この問題を解決するには、GitLab 18.1.2以降にアップデートしてください。

### Geoインストール18.1.0 {#geo-installations-1810}

- GitLabバージョン18.1.0には、セカンダリGeoサイトからプロキシされたGit操作がHTTP 500エラーで失敗するという既知の問題があります。解決するには、GitLab 18.1.1以降にアップグレードしてください。
- このバージョンでは、`ci_job_artifact_states`の主キーの変更により、`VerificationStateBackfillService`の実行時に発生する既知の問題があります。解決するには、GitLab 18.1.4にアップグレードしてください。
- GitLab 18.1.0には、長いファイル名を持つPagesデプロイでGeo検証が失敗する可能性のあった[イシュー559196](https://gitlab.com/gitlab-org/gitlab/-/issues/559196)の修正が含まれています。この修正により、Geoセカンダリサイトでのファイル名のトリミングが防止され、レプリケーションおよび検証時の一貫性が維持されます。

## 18.0.0 {#1800}

### `git_data_dirs`から`storage`にGitaly設定を移行する {#migrate-gitaly-configuration-from-git_data_dirs-to-storage}

GitLab 18.0以降では、`git_data_dirs`設定を使用してGitalyストレージの場所を設定できなくなりました。

依然として`git_data_dirs`を使用している場合は、GitLab 18.0にアップグレードする前に[Gitaly設定を移行する](https://docs.gitlab.com/omnibus/settings/configuration/#migrating-from-git_data_dirs)必要があります。

### Geoインストール18.0.0 {#geo-installations-1800}

- GitLab Enterprise Editionをデプロイした後にGitLab Community Editionに戻した場合、データベーススキーマがGitLabアプリケーションで想定されているスキーマと異なることがあり、移行エラーが発生する可能性があります。18.0.0へのアップグレード時には、このバージョンで追加された移行によって特定の列のデフォルトが変更されるため、4種類のエラーが発生する可能性があります。

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

- GitLabバージョン18.0から18.0.2には、セカンダリGeoサイトからプロキシされたGit操作がHTTP 500エラーで失敗するという既知の問題があります。解決するには、GitLab 18.0.3以降にアップグレードしてください。
- このバージョンでは、`ci_job_artifact_states`の主キーの変更により、`VerificationStateBackfillService`の実行時に発生する既知の問題があります。解決するには、GitLab 18.0.6にアップグレードしてください。

### DockerインストールでのPRNG is not seededエラー {#prng-is-not-seeded-error-on-docker-installations}

FIPSが有効なホスト上でDockerインストール環境のGitLabを実行している場合、SSHキーの生成やOpenSSHサーバー（`sshd`）の起動が失敗し、次のエラーメッセージが表示されることがあります:

```plaintext
PRNG is not seeded
```

GitLab 18.0では、[ベースイメージをUbuntu 22.04から24.04に更新しました](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8928)。このエラーは、Ubuntu 24.04で[FIPSホストが非FIPS OpenSSLプロバイダーを使用できなくなった](https://github.com/dotnet/dotnet-docker/issues/5849#issuecomment-2324943811)ことが原因で発生します。

この問題を解決するには、いくつかのオプションがあります:

- ホストシステムでFIPSを無効にする。
- GitLab Dockerコンテナ内でFIPSベースのカーネルの自動検出を無効にする。これは、GitLab 18.0.2以降で`OPENSSL_FORCE_FIPS_MODE=0`環境変数を設定することで実行できます。
- GitLab Dockerイメージを使用する代わりに、ホスト上に[ネイティブのFIPSパッケージ](https://packages.gitlab.com/gitlab/gitlab-fips)をインストールする。

最後のオプションが、FIPS要件を満たすための推奨手順です。レガシーインストールの場合は、最初の2つのオプションを一時的な対処方法として使用できます。

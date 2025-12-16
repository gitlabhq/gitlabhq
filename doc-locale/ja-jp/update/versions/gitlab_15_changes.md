---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 15アップグレードノート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLab 15のマイナーバージョンとパッチバージョンのアップグレード情報を提供します。以下の条件を考慮して、各手順を確認してください:

- お使いのインストールタイプ。
- 現在のバージョンから移行先バージョンまでのすべてのバージョン。

Helmチャートインストールに関する追加情報については、[Helmチャート6.0アップグレードノート](https://docs.gitlab.com/charts/releases/6_0.html)を参照してください。

## 15.11.1 {#15111}

- 多くの[プロジェクトインポーター](../../user/project/import/_index.md)および[グループインポーター](../../user/group/import/_index.md)で、これまでのデベロッパーロールに加えて、メンテナーロールが必要になりました。詳細については、お使いの各インポーターのドキュメントを参照してください。

## 15.11.0 {#15110}

- **パッチリリース15.11.3以降にアップグレードしてください**。これにより、15.5.0以前のバージョンからアップグレードする際の[イシュー408304](https://gitlab.com/gitlab-org/gitlab/-/issues/408304)を回避できます。

- 通常、PgBouncerを使用している環境では、バックアップ時に[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)必要があります。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`は、オーバーライドで定義された直接接続ではなく、PgBouncerを介して標準のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けるリリース**:

  | 影響を受けるマイナーリリース | 影響を受けるパッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 15.11                   |  すべて                    | なし     |
  | 16.0                    |  すべて                    | なし     |
  | 16.1                    |  すべて                    | なし     |
  | 16.2                    |  すべて                    | なし     |
  | 16.3                    |  すべて                    | なし     |
  | 16.4                    |  すべて                    | なし     |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.6        | 16.7.7   |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |

### Linuxパッケージインストール {#linux-package-installations}

GitLab 15.11では、次の場合を除き、PostgreSQLは自動的に13.xにアップグレードされます:

- Patroniを使用して高可用性でデータベースを実行している。
- データベースノードがGitLab Geo構成の一部である。
- PostgreSQLの自動アップグレードを明示的に[オプトアウト](https://docs.gitlab.com/omnibus/settings/database.html#opt-out-of-automatic-postgresql-upgrades)している。
- `/etc/gitlab/gitlab.rb`で`postgresql['version'] = 12`を設定している。

耐障害性およびGeoインストールは、PostgreSQL 13への手動アップグレードをサポートしています。詳しくは、[HA/GeoクラスターにデプロイされたパッケージPostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#packaged-postgresql-deployed-in-an-hageo-cluster)を参照してください。

### Geoインストール {#geo-installations}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のプロジェクトのインポートでは、プロジェクトの作成時にWikiリポジトリが初期化されません。[詳細と回避策については、こちら](gitlab_16_changes.md#wiki-repositories-not-initialized-on-project-creation)を参照してください。
- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。

#### `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできない {#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13}

| 影響を受けるマイナーリリース | 影響を受けるパッチリリース | 修正リリース |
|-------------------------|-------------------------|----------|
| 15.2 - 15.10            | すべて                     | なし     |
| 15.11                   | 15.11.0 - 15.11.11      | 15.11.12 以降 |

組み込みの`pg-upgrade`ツールに[バグ](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7841)があり、バンドルされているPostgreSQLデータベースをバージョン13にアップグレードできません。この結果、セカンダリサイトが破損状態となり、GeoインストールをGitLab 16.xにアップグレードできなくなります（[PostgreSQL 12のサポートは16.0以降のリリースで削除されています](../deprecations.md#postgresql-12-deprecated)）。この問題は、バンドルされているPostgreSQLソフトウェアを使用しており、セカンダリのメインRailsデータベースとトラッキングデータベースの両方を同じノードで実行しているセカンダリサイトで発生します。15.11.12以降にアップグレードできない場合は、手動による[回避策](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7841#workaround)があります。

## 15.11.x {#1511x}

- [バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/411604)により、新しいLDAPユーザーが初めてサインインする際に、LDAPのユーザー名属性ではなく、メールアドレスに基づいたユーザー名が割り当てられることがあります。手動での回避策は、`gitlab_rails['omniauth_auto_link_ldap_user'] = true`を設定するか、バグが修正されたGitLab 16.1以降にアップグレードすることです。

## 15.10.5 {#15105}

- [Elastic IndexerのCronワーカーのバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/408214)により、Sidekiqが飽和状態になる可能性があります。
  - この問題が発生すると、マージリクエストのマージ、パイプライン、Slack通知などのイベントが作成されなかったり、発生するまでに長い時間がかかったりすることがあります。
  - Sidekiqが飽和状態に達するまでに最大で1週間かかることがあるため、この問題がすぐに表面化するとは限りません。
  - この問題は、Elasticsearchを有効にしていない場合でも発生する可能性があります。
  - この問題を解決するには、15.11にアップグレードするか、問題の回避策を使用してください。
- 多くの[プロジェクトインポーター](../../user/project/import/_index.md)および[グループインポーター](../../user/group/import/_index.md)で、これまでのデベロッパーロールに加えて、メンテナーロールが必要になりました。詳細については、お使いの各インポーターのドキュメントを参照してください。

## 15.10.0 {#15100}

- [Elastic IndexerのCronワーカーのバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/408214)により、Sidekiqが飽和状態になる可能性があります。
  - この問題が発生すると、マージリクエストのマージ、パイプライン、Slack通知などのイベントが作成されなかったり、発生するまでに長い時間がかかったりすることがあります。
  - Sidekiqが飽和状態に達するまでに最大で1週間かかることがあるため、この問題がすぐに表面化するとは限りません。
  - この問題は、Elasticsearchを有効にしていない場合でも発生する可能性があります。
  - この問題を解決するには、15.11にアップグレードするか、問題の回避策を使用してください。
- [ゼロダウンタイムインデックス再作成のバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/422938)により、インデックス再作成の際に`Couldn't load task status`エラーが発生する場合があります。また、Elasticsearchホストで`sliceId must be greater than 0 but was [-1]`エラーが発生する場合もあります。回避策として、[インデックスをゼロから再作成する](../../integration/elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)か、GitLab 16.3にアップグレードすることを検討してください。
- GitLab 16.0では、LinuxパッケージインスタンスにおけるGitaly設定が大幅に変更されています。GitLab 16.0に向けて下位互換性が維持されている間に、GitLab 15.10で新しい構造への移行を開始できます。[この変更の詳細についてはこちらを参照してください](gitlab_16_changes.md#gitaly-configuration-structure-change)。
- GitLab 15.10以降にアップグレードする際に、次のエラーが発生する可能性があります:

  ```shell
  STDOUT: rake aborted!
  StandardError: An error has occurred, all later migrations canceled:
  PG::CheckViolation: ERROR:  check constraint "check_70f294ef54" is violated by some row
  ```

  このエラーは、[GitLab 15.8で導入されたバッチバックグラウンド移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107701)が、GitLab 15.10にアップグレードする前に完了していないことが原因です。このエラーを解決するには:

  1. データベースコンソール（Linuxパッケージインストールの場合は`sudo gitlab-psql`）を使用して、次のSQLステートメントを実行します:

     ```sql
     UPDATE oauth_access_tokens SET expires_in = '7200' WHERE expires_in IS NULL;
     ```

  1. [データベースの移行を再実行します](../../administration/raketasks/maintenance.md#run-incomplete-database-migrations)。

- GitLab 15.10以降にアップグレードする際に、次のエラーが発生する可能性もあります:

  ```shell
  "exception.class": "ActiveRecord::StatementInvalid",
  "exception.message": "PG::SyntaxError: ERROR:  zero-length delimited identifier at or near \"\"\"\"\nLINE 1: ...COALESCE(\"lock_version\", 0) + 1 WHERE \"ci_builds\".\"\" IN (SEL...\n
  ```

  このエラーは、[GitLab 14.9で導入されたバッチバックグラウンド移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81410)が、GitLab 15.10以降にアップグレードする前に完了していないことが原因です。このエラーを解決するには、[移行を完了としてマークする](../background_migrations.md#mark-a-failed-migration-finished)のが安全な方法です:

  ```ruby
  # Start the rails console

  connection = Ci::ApplicationRecord.connection

  Gitlab::Database::SharedModel.using_connection(connection) do
    migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
      Gitlab::Database.gitlab_schemas_for_connection(connection), 'NullifyOrphanRunnerIdOnCiBuilds', :ci_builds, :id, [])

    # mark all jobs completed
    migration.batched_jobs.update_all(status: Gitlab::Database::BackgroundMigration::BatchedJob.state_machine.states[:succeeded].value)
    migration.update_attribute(:status, Gitlab::Database::BackgroundMigration::BatchedMigration.state_machine.states[:finished].value)
  end
  ```

  詳細については、[イシュー415724](https://gitlab.com/gitlab-org/gitlab/-/issues/415724)を参照してください。

- [Terraformの設定に関するバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/348453)が原因で、`gitlab.rb`設定ファイルで`gitlab_rails['terraform_state_enabled']`が`false`に設定されていても、Terraformステートが有効なままになる問題が発生していました。このバグはGitLab 15.10で修正されたため、`gitlab.rb`設定で[Terraformステート](../../administration/terraform_state.md)機能が無効になっている場合、GitLab 15.10にアップグレードすると、Terraformステート機能を使用しているプロジェクトが動作しなくなる可能性があります。そのため、`gitlab.rb`で`gitlab_rails['terraform_state_enabled'] = false`を設定している場合は、Terraformステート機能を使用しているプロジェクトが存在しないか確認してください。これを確認するには、次の手順に従います:
  1. [Railsコンソール](../../administration/operations/rails_console.md)の警告を確認します。
  1. [Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
  1. コマンド`Terraform::State.pluck(:project_id)`を実行します。このコマンドは、Terraformステートを持つすべてのプロジェクトIDの配列を返します。
  1. 各プロジェクトに移動し、必要に応じて関係者と協力して、Terraformステート機能が現在も使用されているかどうかを判断します。Terraformステートが不要な場合は、[ステートファイルを削除する](../../user/infrastructure/iac/terraform_state.md#remove-a-state-file)手順に従います。

### Geoインストール {#geo-installations-1}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.9.0 {#1590}

- [Elastic IndexerのCronワーカーのバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/408214)により、Sidekiqが飽和状態になる可能性があります。
  - この問題が発生すると、マージリクエストのマージ、パイプライン、Slack通知などのイベントが作成されなかったり、発生するまでに長い時間がかかったりすることがあります。
  - Sidekiqが飽和状態に達するまでに最大で1週間かかることがあるため、この問題がすぐに表面化するとは限りません。
  - この問題は、Elasticsearchを有効にしていない場合でも発生する可能性があります。
  - この問題を解決するには、15.11にアップグレードするか、問題の回避策を使用してください。
- [`BackfillTraversalIdsToBlobsAndWikiBlobs`高度検索の移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107730)に関するバグにより、Elasticsearchクラスターが飽和状態になる可能性があります。
  - この問題が発生すると、検索の速度が低下し、Elasticsearchクラスターの更新が完了するまでに時間がかかることがあります。
  - この問題を解決するには、GitLab 15.10にアップグレードして、[移行のバッチサイズを縮小](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113719)してください。
- **パッチリリース15.9.3以降にアップグレードしてください**。これには、次の2つのデータベース移行のバグ修正が含まれています:
  - パッチリリース15.9.0、15.9.1、15.9.2には、ユーザープロファイルフィールド`linkedin`、`twitter`、`skype`、`website_url`、`location`、`organization`のデータが失われる可能性があるバグが存在します。詳細については、[イシュー393216](https://gitlab.com/gitlab-org/gitlab/-/issues/393216)を参照してください。
  - 2つ目の[バグの修正](https://gitlab.com/gitlab-org/gitlab/-/issues/394760)により、15.4.xから直接アップグレードできるようになります。
- [CIパーティショニング作業](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ci_data_decay/pipeline_partitioning/)の一環として、[新しい外部キー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107547)が`ci_builds_needs`に追加されました。CIテーブルが大きいGitLabインスタンスでは、この制約の追加に通常よりも時間がかかることがあります。
- Praefectのメタデータ検証機能において[無効なメタデータの削除動作](../../administration/gitaly/praefect/configure.md#enable-deletions)がデフォルトで有効になりました。

  メタデータ検証機能は、Praefectデータベース内のレプリカレコードを処理し、そのレプリカがGitalyノードに実際に存在することを確認します。レプリカが存在しない場合、そのメタデータレコードは削除されます。これにより、Praefectは、メタデータレコード上ではレプリカに問題がないことが示されているものの、実際にはディスク上に存在しない状況を修正できます。メタデータレコードが削除されると、Praefect reconcilerがそのレプリカを再作成するためのレプリケーションジョブをスケジュールします。

  過去にステート管理ロジックに関する問題があったため、データベース内に無効なメタデータレコードが存在する可能性があります。これは、たとえばリポジトリの削除が不完全だった場合や、名前の変更が中断された場合などに発生します。検証機能は、影響を受けたリポジトリの古いレプリカレコードを削除します。レプリカレコードが削除されるため、これらのリポジトリはメトリクスおよび`praefect dataloss`サブコマンドで、利用できないリポジトリとして表示される場合があります。このようなリポジトリが確認された場合は、`praefect remove-repository`を使用して、そのリポジトリおよびリポジトリに残っているレコードを削除してください。

  GitLab 15.0以降では、検証機能が出力したログレコードを検索することで、無効なメタデータレコードを持つリポジトリを特定できます。[リポジトリの検証の詳細、およびログエントリの例については、こちらを参照してください](../../administration/gitaly/praefect/configure.md#repository-verification)。
- GitLab 16.0のLinuxパッケージインスタンスで、Praefect設定が大幅に変更されました。GitLab 16.0に向けて下位互換性が維持されている間に、GitLab 15.9で新しい構造への移行を開始できます。[この変更の詳細についてはこちらを参照してください](gitlab_16_changes.md#praefect-configuration-structure-change)。

### 自己コンパイルによるインストール {#self-compiled-installations}

- **自己コンパイル（ソース）によるインストール**の場合、`gitlab-sshd`の追加に伴い、GitLab ShellをビルドするにはKerberosヘッダーが必要になります。

  ```shell
  sudo apt install libkrb5-dev
  ```

### Geoインストール {#geo-installations-2}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.8.2 {#1582}

### Geoインストール {#geo-installations-3}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.8.1 {#1581}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-4}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.8.0 {#1580}

- Gitalyでは、Git 2.38.0以降が必須です。自己コンパイルによるインストールでは、[Gitalyが提供するGitバージョン](../../install/self_compiled/_index.md#git)を使用する必要があります。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-5}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.7.6 {#1576}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-6}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.7.5 {#1575}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-7}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.7.4 {#1574}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-8}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.7.3 {#1573}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-9}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.7.2 {#1572}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-10}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップグレードをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.7.1 {#1571}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-11}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.7.0 {#1570}

- このバージョンは、`issues.work_item_type_id`列に対して`NOT NULL DB`制約を検証します。このバージョンにアップグレードするには、`issues`テーブルに`work_item_type_id`が`NULL`のレコードが存在してはいけません。複数の`BackfillWorkItemTypeIdForIssues`バックグラウンド移行が存在し、それらは`EnsureWorkItemTypeBackfillMigrationFinished`デプロイ後移行によって完了します。
- GitLab 15.4.0では、[イシューテーブルの`namespace_id`値をバックフィル](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91921)する[バッチバックグラウンド移行](../background_migrations.md#check-for-pending-database-background-migrations)が導入されました。大規模なGitLabインスタンスでは、この移行が完了するまで数時間から数日かかる場合があります。15.7.0にアップグレードする前に、移行が正常に完了していることを確認してください。
- データベース制約が追加され、イシューテーブルの`namespace_id`列に`NULL`値が存在しないことが指定されます。

  - 15.4で実行された`namespace_id`のバッチバックグラウンド移行が失敗している場合（前の項目を参照）、15.7へのアップグレードはデータベース移行エラーで失敗します。

  - イシューテーブルが大きいGitLabインスタンスでは、この制約の検証により、アップグレードに通常よりも時間がかかります。すべてのデータベースの変更は、1時間以内に完了する必要があります:

    ```plaintext
    FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
    [..]
    Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
    ```

    [データ変更とアップグレードを手動で完了する](../package/package_troubleshooting.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s)ための回避策があります。
- デフォルトのSidekiqの`max_concurrency`が20に変更されました。これにより、ドキュメントと製品のデフォルト設定で値が統一されました。

  以前の例:

  - Linuxパッケージインストールのデフォルト（`sidekiq['max_concurrency']`）: 50
  - 自己コンパイルによるインストールのデフォルト: 50
  - Helmチャートのデフォルト（`gitlab.sidekiq.concurrency`）: 25

  リファレンスアーキテクチャでは、デフォルトとして引き続き10を使用します。これは、それぞれの構成に合わせて個別に設定されているためです。

  `max_concurrency`をすでに設定しているサイトには、この変更の影響はありません。[Sidekiqの並行処理設定の詳細については、こちらを参照してください](../../administration/sidekiq/extra_sidekiq_processes.md#concurrency)。
- GitLab Runner 15.7.0では、CI/CDジョブに影響を与える破壊的な変更が導入されました: [ジョブファイル変数の展開を正しく処理するようになっています](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3613)。以前は、ジョブ定義変数が[ファイルタイプ変数](../../ci/variables/_index.md#use-file-type-cicd-variables)を参照している場合、その変数はファイル変数の値（ファイルの内容）に展開されていました。この動作は、通常のShell変数の展開ルールに従っていませんでした。また、ファイル変数とその内容が出力された場合、シークレットや機密情報が漏洩する可能性もありました。たとえば、echoコマンドで出力した場合などです。詳細については、[Understanding the file type variable expansion change in GitLab 15.7](https://about.gitlab.com/blog/2023/02/13/impact-of-the-file-type-variable-change-15-7/)を参照してください。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

### Geoインストール {#geo-installations-12}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.6.7 {#1567}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-13}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.6.6 {#1566}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-14}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。

## 15.6.5 {#1565}

### Geoインストール {#geo-installations-15}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.6.4 {#1564}

### Geoインストール {#geo-installations-16}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.6.3 {#1563}

### Geoインストール {#geo-installations-17}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.6.2 {#1562}

### Geoインストール {#geo-installations-18}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.6.1 {#1561}

### Geoインストール {#geo-installations-19}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.6.0 {#1560}

- [公式にサポートされているPostgreSQLバージョン](../../administration/package_information/postgresql_versions.md)のいずれかを使用する必要があります。一部のデータベース移行は、古いPostgreSQLバージョンで安定性とパフォーマンスの問題を引き起こす可能性があります。
- Gitalyでは、Git 2.37.0以降が必須です。自己コンパイルによるインストールでは、[Gitalyが提供するGitバージョン](../../install/self_compiled/_index.md#git)を使用する必要があります。
- 4つのインデックスの動作を変更するためのデータベースの変更が、これらのインデックスが存在しないインスタンスでは失敗します:

  ```plaintext
  Caused by:
  PG::UndefinedTable: ERROR:  relation "index_issues_on_title_trigram" does not exist
  ```

  その他の3つのインデックスは、`index_merge_requests_on_title_trigram`、`index_merge_requests_on_description_trigram`、`index_issues_on_description_trigram`です。

  この問題は[GitLab 15.7で修正](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105375)され、GitLab 15.6.2にバックポートされました。この問題には回避策もあります: [これらのインデックスを作成する方法を参照してください](https://gitlab.com/gitlab-org/gitlab/-/issues/378343#note_1199863087)。

### Linuxパッケージインストール {#linux-package-installations-1}

GitLab 15.6では、[`omnibus-gitlab`パッケージに同梱されているPostgreSQLのバージョン](../../administration/package_information/postgresql_versions.md)が12.12および13.8にアップグレードされました。[明示的にオプトアウト](https://docs.gitlab.com/omnibus/settings/database.html#automatic-restart-when-the-postgresql-version-changes)しない限り、これによりPostgreSQLサービスが自動的に再起動され、ダウンタイムが発生する可能性があります。

### Geoインストール {#geo-installations-20}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- `/api/v4/container_registry_event/events`エンドポイントによって[コンテナレジストリプッシュイベントが拒否される](https://gitlab.com/gitlab-org/gitlab/-/issues/386389)ため、Geoセカンダリサイトがコンテナレジストリイメージの更新を検知できず、アップデートをレプリケートしません。その結果、フェイルオーバー後にセカンダリサイト上に古いコンテナイメージが含まれている可能性があります。この問題は、バージョン15.6.0 - 15.6.6および15.7.0 - 15.7.2に影響します。コンテナリポジトリでGeoを使用している場合は、フェイルオーバー後の潜在的なデータ損失を回避するために、この問題の修正が含まれているGitLab 15.6.7、15.7.3、または15.8.0にアップグレードすることをおすすめします。
- 一部のGeoインストールで、[プロジェクトおよびWikiのレプリケーションと検証が追いついていない](https://gitlab.com/gitlab-org/gitlab/-/issues/387980)問題が見つかりました。検証処理で一部のプロジェクトやWikiが長時間にわたって「キューに入っている」状態のままの場合、そのインストールがこの問題の影響を受けている可能性があります。この問題により、フェイルオーバー後にデータが失われる可能性があります。
  - 影響を受けるバージョン: GitLabバージョン15.6.x、15.7.x、および15.8.0 - 15.8.2。
  - 修正を含むバージョン: GitLab 15.8.3以降。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.5.5 {#1555}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.5.4 {#1554}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.5.3 {#1553}

- GitLab 15.4.0で、すべてのジョブを`default`キューにルーティングするデフォルトの[Sidekiqルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)が導入されました。[キューセレクター](https://archives.docs.gitlab.com/17.0/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を使用しているインスタンスでは、一部のSidekiqプロセスがアイドル状態になるため、このルールによって[パフォーマンスの問題](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991)が発生します。
  - デフォルトのルーティングルールは15.5.4でリバートされたため、そのバージョン以降にアップグレードすると以前の動作に戻ります。
  - GitLabインスタンスが`default`キューのみをリッスンしている場合（これは現在推奨されていません）、このルーティングルールを`/etc/gitlab/gitlab.rb`に追加する必要があります:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.5.2 {#1552}

- GitLab 15.4.0で、すべてのジョブを`default`キューにルーティングするデフォルトの[Sidekiqルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)が導入されました。[キューセレクター](https://archives.docs.gitlab.com/17.0/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を使用しているインスタンスでは、一部のSidekiqプロセスがアイドル状態になるため、このルールによって[パフォーマンスの問題](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991)が発生します。
  - デフォルトのルーティングルールは15.5.4でリバートされたため、そのバージョン以降にアップグレードすると以前の動作に戻ります。
  - GitLabインスタンスが`default`キューのみをリッスンしている場合（これは現在推奨されていません）、このルーティングルールを`/etc/gitlab/gitlab.rb`に追加する必要があります:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.5.1 {#1551}

- GitLab 15.4.0で、すべてのジョブを`default`キューにルーティングするデフォルトの[Sidekiqルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)が導入されました。[キューセレクター](https://archives.docs.gitlab.com/17.0/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を使用しているインスタンスでは、一部のSidekiqプロセスがアイドル状態になるため、このルールによって[パフォーマンスの問題](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991)が発生します。
  - デフォルトのルーティングルールは15.5.4でリバートされたため、そのバージョン以降にアップグレードすると以前の動作に戻ります。
  - GitLabインスタンスが`default`キューのみをリッスンしている場合（これは現在推奨されていません）、このルーティングルールを`/etc/gitlab/gitlab.rb`に追加する必要があります:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.5.0 {#1550}

- GitLab 15.4.0で、すべてのジョブを`default`キューにルーティングするデフォルトの[Sidekiqルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)が導入されました。[キューセレクター](https://archives.docs.gitlab.com/17.0/ee/administration/sidekiq/processing_specific_job_classes.html#queueselectors-deprecated)を使用しているインスタンスでは、一部のSidekiqプロセスがアイドル状態になるため、このルールによって[パフォーマンスの問題](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991)が発生します。
  - デフォルトのルーティングルールは15.5.4でリバートされたため、そのバージョン以降にアップグレードすると以前の動作に戻ります。
  - GitLabインスタンスが`default`キューのみをリッスンしている場合（これは現在推奨されていません）、このルーティングルールを`/etc/gitlab/gitlab.rb`に追加する必要があります:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

### Geoインストール {#geo-installations-21}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.4.6 {#1546}

- [GitLab 15.4.6で導入されたcURLのバグ](https://github.com/curl/curl/issues/10122)により、[`no_proxy`環境変数が正しく機能しない場合があります](../../administration/geo/replication/troubleshooting/client_http.md#secondary-site-returns-received-http-code-403-from-proxy-after-connect)。GitLab 15.4.5にダウングレードするか、GitLab 15.5.7以降のバージョンにアップグレードしてください。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.4.5 {#1545}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.4.4 {#1544}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.4.3 {#1543}

- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.4.2 {#1542}

- [ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:
  - 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
  - この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.4.1 {#1541}

- [ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:
  - 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
  - この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。

## 15.4.0 {#1540}

- GitLab 15.4.0には、[`ci_job_artifacts`テーブルの`expire_at`にある誤った値を削除する](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89318)ための[バッチバックグラウンド移行](../background_migrations.md#check-for-pending-database-background-migrations)が含まれています。大規模なGitLabインスタンスでは、この移行が完了するまで数時間から数日かかる場合があります。
- デフォルトでは、GitalyノードとPraefectノードは、`pool.ntp.org`のタイムサーバーを使用します。インスタンスが`pool.ntp.org`に接続できない場合は、[`NTP_HOST`変数を設定](../../administration/gitaly/praefect/configure.md#customize-time-server-setting)してください。そうしないと、ログや`gitlab-rake gitlab:gitaly:check`の出力に`ntp: read udp ... i/o timeout`エラーが記録される可能性があります。ただし、Gitalyホストの時刻が同期している場合は、これらのエラーは無視できます。
- GitLab 15.4.0で、すべてのジョブを`default`キューにルーティングするデフォルトの[Sidekiqルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)が導入されました。[キューセレクター](https://archives.docs.gitlab.com/17.0/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)を使用しているインスタンスでは、一部のSidekiqプロセスがアイドル状態になるため、このルールによって[パフォーマンスの問題](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991)が発生します。
  - デフォルトのルーティングルールは15.4.5でリバートされたため、そのバージョン以降にアップグレードすると以前の動作に戻ります。
  - GitLabインスタンスが`default`キューのみをリッスンしている場合（これは現在推奨されていません）、このルーティングルールを`/etc/gitlab/gitlab.rb`に追加する必要があります:

    ```ruby
    sidekiq['routing_rules'] = [['*', 'default']]
    ```

- [GitLab 15.4](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6310)で`/etc/gitlab/gitlab-secrets.json`の構造が変更され、`gitlab_pages`、`grafana`、`mattermost`セクションに新しい設定が追加されました。高可用性環境またはGitLab Geo環境では、すべてのノードでシークレットが同一である必要があります。シークレットファイルをノード間で手動同期している場合、または`/etc/gitlab/gitlab.rb`でシークレットを手動で指定している場合は、すべてのノードで`/etc/gitlab/gitlab-secrets.json`が同じであることを確認してください。
- GitLab 15.4.0では、[イシューテーブルの`namespace_id`値をバックフィル](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91921)する[バッチバックグラウンド移行](../background_migrations.md#check-for-pending-database-background-migrations)が導入されました。大規模なGitLabインスタンスでは、この移行が完了するまで数時間から数日かかる場合があります。15.7.0以降にアップグレードする前に、移行が正常に完了していることを確認してください。
- [GitLab 15.4で導入されたバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)が原因で、Gitaly Cluster (Praefect)内の1つ以上のGitリポジトリが[利用できない](../../administration/gitaly/praefect/recovery.md#unavailable-repositories)場合、影響を受けるGitaly Cluster (Praefect)内のすべてのプロジェクトまたはプロジェクトWikiリポジトリに対して、[リポジトリチェック](../../administration/repository_checks.md)と[Geoのレプリケーションおよび検証](../../administration/geo/_index.md)が停止します。このバグは、[GitLab 15.9.0で変更をリバート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110823)することにより修正されました。このバージョンにアップグレードする前に、「利用できない」リポジトリが存在しないか確認してください。詳細については、[このバグのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390155)を参照してください。
- GitLab 15.4以降では、再設計されたサインインページがデフォルトで有効になっており、今後のリリースでさらに改善される予定です。詳細については、[エピック8557](https://gitlab.com/groups/gitlab-org/-/epics/8557)を参照してください。この変更は、機能フラグで無効にできます。[Railsコンソール](../../administration/operations/rails_console.md)を起動し、次のコマンドを実行します:

  ```ruby
  Feature.disable(:restyle_login_page)
  ```

### Geoインストール {#geo-installations-22}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.3.4 {#1534}

[ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:

- 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
- この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.3.3 {#1533}

- GitLab 15.3.3では、[SAMLグループリンク](../../api/saml.md#saml-group-links)APIの`access_level`属性の型が`integer`に変更されました。[APIドキュメント](../../api/members.md)を参照してください。
- [ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:

  - 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
  - この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3

## 15.3.2 {#1532}

[ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:

- 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
- この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.3.1 {#1531}

[ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:

- 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
- この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.3.0 {#1530}

- Gitaly Cluster (Praefect)で新しく作成されたGitリポジトリは、`@hashed`ストレージパスを使用しなくなりました。新しいリポジトリのサーバーフックは、別の場所にコピーする必要があります。Praefectは、Gitaly Clusterで使用するためのレプリカパスを生成するようになりました。この変更は、Gitaly Cluster (Praefect)がGitリポジトリをアトミックに作成、削除、名前変更できるようにするための前提条件です。

  レプリカパスを特定するには、[Praefectリポジトリメタデータをクエリ](../../administration/gitaly/praefect/troubleshooting.md#view-repository-metadata)して、`@hashed`ストレージパスを`-relative-path`に渡します。

  この情報を使用すると、[サーバーフック](../../administration/server_hooks.md)を正しくインストールできます。

- [ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:

  - 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
  - この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
    - 15.2.5 --> 15.3.5
    - 15.3.0 - 15.3.4 --> 15.3.5
    - 15.4.1 --> 15.4.3

### Geoインストール {#geo-installations-23}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- LFS転送がセッションの途中でセカンダリサイトからプライマリサイトにリダイレクトされる場合があります。[詳細と回避策については、こちら](#lfs-transfers-redirect-to-primary-from-secondary-site-mid-session)を参照してください。
- Geoセカンダリサイトで、オブジェクトストレージ内のLFSファイルが誤って削除される場合があります。[詳細と回避策については、こちら](#incorrect-object-storage-lfs-file-deletion-on-secondary-sites)を参照してください。

#### LFS転送がセッションの途中でセカンダリサイトからプライマリサイトにリダイレクトされる {#lfs-transfers-redirect-to-primary-from-secondary-site-mid-session}

| 影響を受けるマイナーリリース | 影響を受けるパッチリリース | 修正リリース |
|-------------------------|-------------------------|----------|
| 15.1                    | すべて                     | なし     |
| 15.2                    | すべて                     | なし     |
| 15.3                    | 15.3.0 - 15.3.2         | 15.3.3以降 |

[Geoプロキシ](../../administration/geo/secondary_proxy/_index.md)が有効になっている場合、GitLab 15.1.0から15.3.2において、LFS転送が[セッションの途中でセカンダリサイトからプライマリサイトにリダイレクト](https://gitlab.com/gitlab-org/gitlab/-/issues/371571)され、プルリクエストやクローンリクエストが失敗することがあります。GitLab 15.1以降で、Geoプロキシはデフォルトで有効になっています。

この問題はGitLab 15.3.3で解決されているため、次の設定を使用している場合は15.3.3以降にアップグレードする必要があります:

- LFSが有効になっている。
- LFSオブジェクトがGeoサイト間でレプリケートされている。
- リポジトリがGeoセカンダリサイト経由でプルされている。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

#### セカンダリサイトでオブジェクトストレージ内のLFSファイルが誤って削除される {#incorrect-object-storage-lfs-file-deletion-on-secondary-sites}

| 影響を受けるマイナーリリース | 影響を受けるパッチリリース | 修正リリース |
|-------------------------|-------------------------|----------|
| 15.0                    | すべて                     | なし     |
| 15.1                    | すべて                     | なし     |
| 15.2                    | すべて                     | なし     |
| 15.3                    | 15.3.0 - 15.3.2         | 15.3.3以降 |

[Geoセカンダリサイトでオブジェクトストレージファイルが誤って削除される問題](https://gitlab.com/gitlab-org/gitlab/-/issues/371397)は、GitLab 15.0.0から15.3.2において、次の状況で発生する可能性があります:

- GitLab管理のオブジェクトストレージレプリケーションが無効になっており、オブジェクトストレージを有効にした状態でプロジェクトをインポートする際にLFSオブジェクトストレージが作成される場合。
- オブジェクトストレージを同期するためのGitLab管理のレプリケーションを有効にした後、再び無効にした場合。

この問題は15.3.3で解決されました。LFSが有効になっており、LFSオブジェクトがGeoサイト間でレプリケートされている場合は、セカンダリサイトでのデータ損失リスクを軽減するために、15.3.3に直接アップグレードする必要があります。

## 15.2.5 {#1525}

[ライセンスのキャッシュの問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376706)により、新しいライセンスを追加した場合に、GitLabのPremium機能の一部が正しく動作しなくなることがあります。この問題の回避策は次のとおりです:

- 新しいライセンスを適用した後、すべてのRails、Sidekiq、Gitalyノードを再起動します。これにより、関連するライセンスキャッシュがクリアされ、すべてのPremium機能が正しく動作するようになります。
- この問題の影響を受けないバージョンにアップグレードします。影響を受けるバージョンからのアップグレードパスは次のとおりです:
  - 15.2.5 --> 15.3.5
  - 15.3.0 - 15.3.4 --> 15.3.5
  - 15.4.1 --> 15.4.3

## 15.2.0 {#1520}

- ETagキーの生成に不整合を引き起こす可能性があるRailsの設定変更により、複数のWebノードがあるGitLabインストールでは、15.2（以降）にアップグレードする前に[15.1にアップグレード](#1510)する必要があります。
- このリリースでは、一部のSidekiqワーカーの名前が変更されました。中断を避けるため、GitLab 15.2.0へのアップグレードを開始する前に、[保留中のジョブを移行するためのRakeタスクを実行してください](../../administration/sidekiq/sidekiq_job_migration.md#migrate-queued-and-future-jobs)。
- Gitalyは[ランタイムの配置場所](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4670)でバイナリを実行するようになりました。Linuxパッケージインスタンスのデフォルトでは、このパスは`/var/opt/gitlab/gitaly/run/`です。`noexec`が指定されてこの場所がマウントされている場合、マージリクエストの際に次のエラーが発生します:

  ```plaintext
  fork/exec /var/opt/gitlab/gitaly/run/gitaly-<nnnn>/gitaly-git2go-v15: permission denied
  ```

  この問題を解決するには、ファイルシステムマウントから`noexec`オプションを削除します。別の方法として、Gitalyのランタイムディレクトリを変更することもできます:

  1. `/etc/gitlab/gitlab.rb`に`gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'`を追加し、`noexec`が設定されていない場所を指定します。
  1. `sudo gitlab-ctl reconfigure`を実行します。

### Geoインストール {#geo-installations-24}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- `pg_upgrade`が、バンドルされているPostregSQLデータベースをバージョン13にアップグレードできません。[詳細と回避策については、こちら](#pg_upgrade-fails-to-upgrade-the-bundled-postregsql-database-to-version-13)を参照してください。
- LFS転送がセッションの途中でセカンダリサイトからプライマリサイトにリダイレクトされる場合があります。[詳細と回避策については、こちら](#lfs-transfers-redirect-to-primary-from-secondary-site-mid-session)を参照してください。
- Geoセカンダリサイトで、オブジェクトストレージ内のLFSファイルが誤って削除される場合があります。[詳細と回避策については、こちら](#incorrect-object-storage-lfs-file-deletion-on-secondary-sites)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.1.0 {#1510}

- GitLab 15.1.0では、Railsの`ActiveSupport::Digest`がMD5ではなくSHA256を使用するように切り替えました。この変更は、スニペットのrawファイルダウンロードなど、リソースに対するETagキーの生成に影響します。アップグレード時に複数のWebノード間で一貫したETagキーが生成されるようにするには、すべてのサーバーをまず15.1.6にアップグレードしてから、15.2.0以降にアップグレードする必要があります:

  1. すべてのGitLab WebノードがGitLab 15.1.6を実行していることを確認します。
  1. クラウドネイティブのGitLab Helmチャートを使用して[Kubernetes上でGitLab](https://docs.gitlab.com/charts/installation/)を実行している場合は、すべてのWebserviceポッドがGitLab 15.1.Zを実行していることを確認してください:

     ```shell
     kubectl get pods -l app=webservice -o custom-columns=webservice-image:{.spec.containers[0].image},workhorse-image:{.spec.containers[1].image}
     ```

  1. SHA256を使用するように`ActiveSupport::Digest`を切り替えるには、[`active_support_hash_digest_sha256`機能フラグを有効にします](../../administration/feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags):

     1. [Railsコンソールを起動します](../../administration/operations/rails_console.md)
     1. 機能フラグを有効にします:

        ```ruby
        Feature.enable(:active_support_hash_digest_sha256)
        ```

  1. これらの手順を完了した後にのみ、GitLabの後続バージョンへのアップグレードを続行します。
- [`ciConfig` GraphQLフィールド](../../api/graphql/reference/_index.md#queryciconfig)への認証されていないリクエストはサポートされなくなりました。GitLab 15.1にアップグレードする前に、リクエストに[アクセストークン](../../api/rest/authentication.md)を追加してください。トークンを作成するユーザーには、プロジェクトでパイプラインを作成する[権限](../../user/permissions.md)が必要です。

### Geoインストール {#geo-installations-25}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- 15.1で、[Geoプロキシ](../../administration/geo/secondary_proxy/_index.md)が[異なるURLに対してデフォルトで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/346112)。これは破壊的な変更になる可能性があります。必要に応じて、[Geoプロキシを無効にする](../../administration/geo/secondary_proxy/_index.md#disable-secondary-site-http-proxying)ことができます。異なるURLでSAMLを使用している場合は、SAMLの設定およびIdentity Providerの設定を変更する必要があります。詳細については、[Geoにおけるシングルサインオン（SSO）のドキュメント](../../administration/geo/replication/single_sign_on.md)を参照してください。
- LFS転送がセッションの途中でセカンダリサイトからプライマリサイトにリダイレクトされる場合があります。[詳細と回避策については、こちら](#lfs-transfers-redirect-to-primary-from-secondary-site-mid-session)を参照してください。
- Geoセカンダリサイトで、オブジェクトストレージ内のLFSファイルが誤って削除される場合があります。[詳細と回避策については、こちら](#incorrect-object-storage-lfs-file-deletion-on-secondary-sites)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。[詳細と回避策については、こちら](gitlab_16_changes.md#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

## 15.0.0 {#1500}

- Elasticsearch 6.8は[サポートされなくなりました](../../integration/advanced_search/elasticsearch.md#version-requirements)。GitLab 15.0にアップグレードする前に、[Elasticsearchを7.xバージョンに更新](../../integration/advanced_search/elasticsearch.md#upgrade-to-a-new-elasticsearch-version)してください。
- 外部PostgreSQL、特にAWS RDSを使用してGitLabを実行している場合は、GitLab 14.8以降にアップグレードする前に、PostgreSQLを少なくとも12.7または13.3のパッチレベルにアップグレードしてください。

  GitLab Enterprise Editionの[14.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75511)およびGitLab Community Editionの[15.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87983)で、緩い外部キーというGitLabの機能フラグが有効になりました。

  この機能を有効にした後、セグメンテーションフォールトを引き起こすデータベースエンジンのバグが原因で、予期しないPostgreSQLの再起動が発生したという報告がありました。

  詳細については、[イシュー364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763)を参照してください。

- [`background_upload`の使用のサポートが削除](../deprecations.md#background-upload-for-object-storage)されたことに伴い、ストレージ固有の設定を使用する暗号化されたS3バケットの使用はサポートされなくなりました。
- [証明書ベースのKubernetesインテグレーション（非推奨）](../../user/infrastructure/clusters/_index.md#certificate-based-kubernetes-integration-deprecated)はデフォルトで無効になっていますが、GitLab 16.0までは[`certificate_based_clusters`機能フラグ](../../administration/feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags)を使用して再度有効にできます。
- GitLab Helmチャートプロジェクトでカスタムの`serviceAccount`を使用する場合は、そのアカウントに`serviceAccount`および`secret`リソースに対する`get`および`list`権限が付与されていることを確認してください。
- `FF_GITLAB_REGISTRY_HELPER_IMAGE`[機能フラグ](../../administration/feature_flags/_index.md#enable-or-disable-the-feature)が削除され、ヘルパーイメージは常にGitLabレジストリからプルされるようになりました。

### Linuxパッケージインストール {#linux-package-installations-2}

- グローバルサーバーフックを設定するための[`custom_hooks_dir`](../../administration/server_hooks.md#create-global-server-hooks-for-all-repositories)設定は、Gitalyで設定されるようになりました。これまでGitLab Shellで実装されていた設定は、GitLab 15.0で削除されました。この変更により、グローバルサーバーフックは、フックタイプにちなんで名付けられたサブディレクトリ内にのみ保存されるようになりました。グローバルサーバーフックを、カスタムフックディレクトリのルートに単一のフックファイルとして配置することはできなくなりました。たとえば、`<custom_hooks_dir>/<hook_name>.d/*`ではなく`<custom_hooks_dir>/<hook_name>`を使用する必要があります。
  - Linuxパッケージインスタンスの場合は、`gitlab.rb`で`gitaly['custom_hooks_dir']`を使用します。これは、`gitlab_shell['custom_hooks_dir']`を置き換えるものです。
- PostgreSQL 13.6は、新規インストール時のデフォルトバージョンとして提供され、アップグレード時には12.10が使用されます。[アップグレードドキュメント](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)に従って、PostgreSQL 13.6に手動でアップグレードできます:

  ```shell
  sudo gitlab-ctl pg-upgrade -V 13
  ```

  PostgreSQL 12が削除されるまでは、互換性またはテスト環境の理由に応じて、[PostgreSQLのバージョンを固定](https://docs.gitlab.com/omnibus/settings/database.html#pin-the-packaged-postgresql-version-fresh-installs-only)できます。

  [耐障害性およびGeoインストールには、追加の手順と計画が必要です](../../administration/postgresql/replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster)。

  基盤となる構造の変更により、PostgreSQLをアップグレードする際には、データベースの移行を実行する前に、実行中のPostgreSQLプロセスを再起動する必要があります。自動再起動をスキップした場合は、移行を実行する前に次のコマンドを実行する必要があります:

  ```shell
  # If using PostgreSQL
  sudo gitlab-ctl restart postgresql

  # If using Patroni for Database replication
  sudo gitlab-ctl restart patroni
  ```

  PostgreSQLを再起動しないと、[ライブラリの読み込みに関連するエラー](https://docs.gitlab.com/omnibus/settings/database.html#could-not-load-library-plpgsqlso)が発生する可能性があります。

- GitLab 15.0以降、PostgreSQLのバージョンが変更されると、`postgresql`および`geo-postgresql`サービスが自動的に再起動されます。PostgreSQLサービスを再起動すると、データベース操作が一時的に利用できなくなるため、ダウンタイムが発生します。この再起動はデータベースサービスを正常に動作させるために必須ですが、PostgreSQLの再起動のタイミングをより細かく制御したい場合があります。その場合は、`gitlab-ctl reconfigure`に含まれる自動再起動をスキップし、サービスを手動で再起動できます。

  GitLab 15.0へのアップグレード時に自動再起動をスキップするには、アップグレードの前に次の手順を実行します:

  1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

     ```ruby
     # For PostgreSQL/Patroni
     postgresql['auto_restart_on_version_change'] = false

     # For Geo PostgreSQL
     geo_postgresql['auto_restart_on_version_change'] = false
     ```

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  {{< alert type="note" >}}

  基盤となるPostgreSQLのバージョンを変更した場合は、[必要なライブラリの読み込みに関するエラー](https://docs.gitlab.com/omnibus/settings/database.html#could-not-load-library-plpgsqlso)など、ダウンタイムを引き起こす可能性のある問題を回避するために、PostgreSQLの再起動は必須です。そのため、前述の方法で自動再起動をスキップする場合は、GitLab 15.0にアップグレードする前にサービスを手動で再起動してください。

  {{< /alert >}}

- GitLab 15.0以降、NGINXにおいて`AES256-GCM-SHA384` SSL暗号がデフォルトで許可されなくなります。[AWS Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers)を使用しており、この暗号が必要な場合は、許可リストに追加できます。SSL暗号を許可リストに追加するには、次の手順に従います。

  1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

     ```ruby
     nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:AES256-GCM-SHA384"
     ```

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

- Gitalyの内部ソケットパスのサポートは削除されました。GitLab 14.10では、Gitalyが正しく動作するために必要なすべてのランタイムデータを保持する新しいディレクトリが導入されました。この新しいディレクトリは、従来の内部ソケットディレクトリを置き換えるものです。それに伴い、`gitaly['internal_socket_dir']`の使用は非推奨となり、代わりに`gitaly['runtime_dir']`が使用されるようになりました。

  今回のリリースで、古い`gitaly['internal_socket_dir']`設定が削除されました。

- オブジェクトストレージに関するバックグラウンドアップロード設定が削除されました。オブジェクトストレージは今後、直接アップロードを優先的に使用します。

  `/etc/gitlab/gitlab.rb`で、次のキーはサポートされなくなりました:

  - `gitlab_rails['artifacts_object_store_direct_upload']`
  - `gitlab_rails['artifacts_object_store_background_upload']`
  - `gitlab_rails['external_diffs_object_store_direct_upload']`
  - `gitlab_rails['external_diffs_object_store_background_upload']`
  - `gitlab_rails['lfs_object_store_direct_upload']`
  - `gitlab_rails['lfs_object_store_background_upload']`
  - `gitlab_rails['uploads_object_store_direct_upload']`
  - `gitlab_rails['uploads_object_store_background_upload']`
  - `gitlab_rails['packages_object_store_direct_upload']`
  - `gitlab_rails['packages_object_store_background_upload']`
  - `gitlab_rails['dependency_proxy_object_store_direct_upload']`
  - `gitlab_rails['dependency_proxy_object_store_background_upload']`

### 自己コンパイルによるインストール {#self-compiled-installations-1}

- GitLabでは、複数のデータベースをサポートするようになりました。**自己コンパイル（ソース）によるインストール**の場合、`config/database.yml`のデータベース設定にデータベース名を含める必要があります。`main: database`を最初に定義しなくてはなりません。無効または非推奨の構文を使用すると、アプリケーションの起動時にエラーが発生します:

  ```plaintext
  ERROR: This installation of GitLab uses unsupported 'config/database.yml'.
  The main: database needs to be defined as a first configuration item instead of primary. (RuntimeError)
  ```

  以前の`config/database.yml`ファイルは次のようになっていました:

  ```yaml
  production:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_production
    ...
  ```

  GitLab 15.0以降では、まず`main`データベースを定義する必要があります:

  ```yaml
  production:
    main:
      adapter: postgresql
      encoding: unicode
      database: gitlabhq_production
      ...
  ```

### Geoインストール {#geo-installations-26}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

- Geoセカンダリサイトで、オブジェクトストレージ内のLFSファイルが誤って削除される場合があります。[詳細と回避策については、こちら](#incorrect-object-storage-lfs-file-deletion-on-secondary-sites)を参照してください。

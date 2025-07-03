---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab 16の変更点
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

このページでは、GitLab 16のマイナーバージョンとパッチバージョンのアップグレード情報を提供します。以下の手順を確認してください。

- インストールタイプ。
- 現在のバージョンと移行先バージョン間のすべてのバージョン。

GitLab Helmチャートのアップグレードの詳細については、[7.0のリリースノート](https://docs.gitlab.com/charts/releases/7_0.html)を参照してください。

## 15.11からのアップグレード時に注意すべき問題

- [PostgreSQL 12は、GitLab 16以降ではサポートされていません](../deprecations.md#postgresql-12-deprecated)。GitLab 16.0以降にアップグレードする前に、PostgreSQLを少なくともバージョン13.6にアップグレードしてください。
- GitLabインスタンスが最初に 15.11.0、15.11.1、または 15.11.2 にアップグレードされた場合、データベーススキーマが正しくありません。16.xにアップグレードする前に、[回避策](#undefined-column-error-upgrading-to-162-or-later)を実行してください。
- 16.0以降、GitLab Self-Managedインストールでは、デフォルトのデータベース接続数が1つではなく2つになりました。この変更により、PostgreSQL接続の数が2倍になります。これにより、GitLabのSelf-ManagedバージョンはGitLab.comと同様に動作するようになり、GitLabのSelf-ManagedバージョンでCI機能用に別のデータベースを有効にするための第一歩となります。16.0にアップグレードする前に、[PostgreSQLの最大接続数を増やす](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections)必要があるかどうかを判断してください。
  - この変更は、Linux パッケージ (Omnibus)、GitLab Helmチャート、GitLab Operator、GitLab Dockerイメージ、および自己コンパイルインストールによるインストール方法に適用されます。
  - [2番目のデータベース接続は無効にできます](#disable-the-second-database-connection)。
- ほとんどのインストールでは、アップグレードパスで最初に必要な経由地点が16.3であるため、16.0、16.1、および16.2をスキップできます。すべての場合において、これらの中間バージョンに関する注記を確認する必要があります。

  一部のGitLabインストールでは、使用する機能と環境のサイズに応じて、これらの中間バージョンを経由する必要があります。

  - 16.0.8: ユーザーテーブルに多数のレコードを持つインスタンス。詳細については、[長時間実行されるユーザータイプのデータ変更](#long-running-user-type-data-change)を参照してください。
  - [16.1.5](#1610): NPMパッケージレジストリを使用するインスタンス。
  - [16.2.8](#1620): 多数のパイプライン変数（履歴パイプラインを含む）を持つインスタンス。

  インスタンスが影響を受けており、これらの経由地点をスキップする場合:

  - アップグレードの完了に数時間かかることがあります。
  - すべてのデータベース変更が完了するまで、インスタンスは500エラーを生成します。その後、PumaとSidekiqを再起動する必要があります。
  - Linuxパッケージのインストールの場合、タイムアウトが発生するため、[移行を完了するための手動による回避策](../package/package_troubleshooting.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s)が必要です。

- GitLab 16.0では、プロジェクトサイズに対する制限の適用に関する変更が導入されました。Self-Managedでこれらの制限を使用する場合に、制限に達したプロジェクトで、同じグループ内の影響を受けないGitリポジトリにプッシュするときに誤ってエラーメッセージが表示されます。エラーは、多くの場合、ゼロバイトの制限(`limit of 0 B`)を超えていることを示します。

  プッシュは成功しますが、エラーが表示されるため、自動化で問題が発生する可能性があります。[イシューの詳細](https://gitlab.com/gitlab-org/gitlab/-/issues/416646)をご覧ください。[このバグはGitLab 16.5以降で修正されています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131122)。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Linuxパッケージのインストール

- GitLab 16にアップグレードする前に、GitalyおよびPraefectの設定構造を変更する必要があります。**データ損失を回避するため**、最初にPraefectを再構成し、新しい設定の一部として、メタデータ検証を無効にします。詳細情報:

  - [Praefect設定構造の変更点](#praefect-configuration-structure-change)。
  - [Gitaly設定構造の変更点](#gitaly-configuration-structure-change)。

- Gitデータを`/var/opt/gitlab/git-data/repositories`以外の場所に保存するようにGitalyを再構成した場合、パッケージ化されたGitLab 16.0以降では、ディレクトリ構造は自動的に作成されません。[詳細と回避策については、イシューをお読みください](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8320)。

## 16.11.0

- [`groups_direct`フィールドが](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146881)[JSON ウェブトークン（IDトークン）](../../ci/secrets/id_token_authentication.md)に追加されました。
  - GitLab CI/CD IDトークンを使用してサードパーティサービスで認証する場合、この変更によりHTTPヘッダーサイズが増加する可能性があります。ヘッダーが大きくなりすぎると、プロキシサーバーがリクエストを拒否する可能性があります。
  - 可能であれば、受信システムのヘッダー制限を増やします。
  - 詳細については、[イシュー467253](https://gitlab.com/gitlab-org/gitlab/-/issues/467253)を参照してください。
- GitLab 16.11にアップグレードすると、大規模な環境とデータベースを持つ一部のユーザーは、ウェブUIでのソースコードページの読み込みの際にタイムアウトを経験するかもしれません。
  - これらのタイムアウトは、パイプラインデータのPostgreSQLクエリが遅く、内部の60秒のタイムアウトを超えることが原因です。
  - Gitリポジトリの複製や、リポジトリデータに対するその他のリクエストは引き続き機能します。
  - これが原因で影響を受けていることを確認する手順と、PostgreSQLで実行して修正するためのハウスキーピングなど、詳細については、[イシュー472420](https://gitlab.com/gitlab-org/gitlab/-/issues/472420)を参照してください。

### Linuxパッケージのインストール

GitLab 16.11では次の場合を除き、PostgreSQLは自動的に14.xにアップグレードされます。

- Patroniを使用して高可用性でデータベースを実行している。
- データベースノードがGitLab Geo構成の一部である。
- PostgreSQLの自動アップグレードを明示的に[オプトアウト](https://docs.gitlab.com/omnibus/settings/database.html#opt-out-of-automatic-postgresql-upgrades)している。
- `/etc/gitlab/gitlab.rb`に`postgresql['version'] = 13`がある。

耐障害性およびGeoインストールは、PostgreSQL 14への手動アップグレードをサポートしています。詳しくは、[HA/GeoクラスターにデプロイされたパッケージPostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#packaged-postgresql-deployed-in-an-hageo-cluster)を参照してください。

### Geoインストール

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

- GitLab 16.11からGitLab 17.2までのバージョンでは、PostgreSQLインデックスが欠落していると、CPU使用率が高くなったり、ジョブアーティファクトの検証の進行が遅くなったり、Geoメトリクスのステータスアップデートが遅延したり、タイムアウトしたりする可能性があります。インデックスは GitLab 17.3で追加されました。インデックスを手動で追加するには、[Geoトラブルシューティング - ジョブアーティファクトの検証中にプライマリでCPU使用率が高くなる](../../administration/geo/replication/troubleshooting/common.md#high-cpu-usage-on-primary-during-object-verification)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  すべて                    | なし     |
  | 17.0                    |  すべて                    | なし     |
  | 17.1                    |  すべて                    | なし     |
  | 17.2                    |  すべて                    | なし     |

- Geoレプリケーションが機能している場合でも、セカンダリサイトのGeoレプリケーションの詳細は空に見えます。[イシュー468509](https://gitlab.com/gitlab-org/gitlab/-/issues/468509)を参照してください。既知の回避策はありません。このバグはGitLab 17.4で修正されました。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.11                   |  16.11.5 - 16.11.10     | なし     |
  | 17.0                    |  すべて                    | 17.0.7   |
  | 17.1                    |  すべて                    | 17.1.7   |
  | 17.2                    |  すべて                    | 17.2.5   |
  | 17.3                    |  すべて                    | 17.3.1   |

## 16.10.0

GitLab 16.10以降にアップグレードする際に、次のエラーが発生する可能性があります。

```plaintext
PG::UndefinedColumn: ERROR:  column namespace_settings.delayed_project_removal does not exist
```

このエラーは、列を削除する移行が実行された後に、その削除された列を参照する移行が実行されると発生する可能性があります。このバグの[修正](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148135)は、16.11のリリースで計画されています。

問題を回避するには:

1. 列を一時的に再作成します。`gitlab-psql`を使用するか、データベースに手動で接続して、次を実行します。

   ```sql
   ALTER TABLE namespace_settings ADD COLUMN delayed_project_removal BOOLEAN DEFAULT NULL;
   ```

1. 保留中の移行を適用します。

   ```shell
   gitlab-ctl reconfigure
   ```

1. 最終的な確認をします。

   ```shell
   gitlab-ctl upgrade-check
   ```

1. 列を削除します。`gitlab-psql`を使用するか、データベースに手動で接続して、次を実行します。

   ```sql
   ALTER TABLE namespace_settings DROP COLUMN delayed_project_removal;
   ```

### Linuxパッケージのインストール

GitLab 16.10のLinuxパッケージのインストールには、Patroniの新しいメジャーバージョンへのアップグレード（バージョン2.1.0からバージョン3.0.1）が含まれています。

[高可用性(HA)](../../administration/reference_architectures/_index.md#high-availability-ha)（3,000ユーザー以上）を有効にする[リファレンスアーキテクチャ](../../administration/reference_architectures/_index.md)の1つを使用している場合、Patroniを使用する[Linuxパッケージインストール用のPostgreSQLレプリケーションとフェイルオーバー](../../administration/postgresql/replication_and_failover.md)を使用しています。

これが該当する場合は、マルチノードインスタンスのアップグレード方法について、[ダウンタイムを伴うマルチノードアップグレード](../with_downtime.md)をお読みください。

バージョン2.1.0とバージョン3.0.1の間で導入された変更点の詳細については、[Patroniリリースノート](https://patroni.readthedocs.io/en/latest/releases.html)を参照してください。

### Geoインストール

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

## 16.9.0

GitLab 16.9.0へのアップグレード中に、次のエラーが発生する可能性があります。

```plaintext
PG::UndefinedTable: ERROR:  relation "p_ci_pipeline_variables" does not exist
```

すべての移行が完了し、すべてのRailsノードとSidekiqノードが再起動されていることを確認してください。このバグの[修正](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144952)は、16.9.1でのリリースが計画されています。

### Geoインストール

- [コンテナレプリケーションのバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/431944)により、誤って設定されたセカンダリが、失敗したコンテナレプリケーションを成功としてマークする可能性があります。後続の検証では、チェックサムの不一致により、コンテナは失敗としてマークされます。回避策は、セカンダリ構成を修正することです。**影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | すべて                     |  すべて                    | 16.10.2  |

- GitLab 16.5のバグにより、[パーソナルスニペット](../../user/snippets.md)がセカンダリのGeoサイトにレプリケートされていません。これにより、Geoフェイルオーバーが発生した場合に、パーソナルスニペットデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#439933](https://gitlab.com/gitlab-org/gitlab/-/issues/439933)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  すべて                    | なし     |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- プライマリサイトとセカンダリサイトのチェックサムが一致しないため、コンテナレジストリイメージのサブセットで検証エラーが発生する可能性があります。[イシュー442667](https://gitlab.com/gitlab-org/gitlab/-/issues/442667)に詳細が記載されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失の直接的なリスクはありませんが、検証は成功していません。現時点では、既知の回避策はありません。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

### Linuxパッケージのインストール

- Sidekiqの`min_concurrency`オプションと`max_concurrency`オプションは、GitLab 16.9.0で非推奨となり、GitLab 17.0.0で削除される予定です。GitLab 16.9.0以降では、GitLab 17.0.0で破壊的な変更を回避するために、新しい[`concurrency`](../../administration/sidekiq/extra_sidekiq_processes.md#manage-thread-counts-with-concurrency-field)オプションを設定し、`min_concurrency`オプションと`max_concurrency`オプションを削除してください。

## 16.8.0

- GitLab 16.8.0および16.8.1では、Sidekiq gemがアップグレードされるため、新しいバージョンではRedis 6.2以降が必要です。Redis 6.0を使用している場合は、[Redis 6.0との互換性を復元する](https://gitlab.com/gitlab-org/gitlab/-/issues/439418)16.8.2に直接アップグレードしてください。
- 注：[Redis 6.0はサポートされなくなった](https://endoflife.date/redis)ため、Redis 6.2以降にアップグレードする必要があります。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Geoインストール

- PostgreSQLバージョン14は、GitLab 16.7以降の新規インストールのデフォルトです。既知の問題により、既存のGeoセカンダリサイトはPostgreSQLバージョン14にアップグレードできません。詳細については、[イシュー7768](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7768#note_1652076255)を参照してください。すべてのGeoサイトは、同じバージョンのPostgreSQLを実行する必要があります。GitLab 16.7から16.8.1に新しいGeoセカンダリサイトを追加するには、設定に基づいて次のいずれかの操作を行う必要があります。

  - 最初のGeoセカンダリサイトを追加するには: 新しいGeoセカンダリサイトをセットアップする前に、[プライマリサイトをPostgreSQL 14にアップグレードしてください](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)。プライマリサイトがすでにPostgreSQL 14を実行している場合は、特別な操作は必要ありません。
  - すでに1つ以上のGeoセカンダリがあるデプロイに新しいGeoセカンダリサイトを追加するには:
    - 既存のすべてのサイトがPostgreSQL 13を実行している場合は、[ピン留めしたPostgreSQLバージョン13](https://docs.gitlab.com/omnibus/settings/database.html#pin-the-packaged-postgresql-version-fresh-installs-only)を使用して新しいGeoセカンダリサイトをインストールします。
    - 既存のすべてのサイトがPostgreSQL 14を実行している場合は、特別な操作は必要ありません。
    - 新しいGeoセカンダリサイトをデプロイに追加する前に、既存のすべてのサイトをGitLab 16.8.2以降およびPostgreSQL 14にアップグレードしてください。

- GitLab 16.5のバグにより、[パーソナルスニペット](../../user/snippets.md)がセカンダリのGeoサイトにレプリケートされていません。これにより、Geoフェイルオーバーが発生した場合に、パーソナルスニペットデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#439933](https://gitlab.com/gitlab-org/gitlab/-/issues/439933)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  すべて                    | なし     |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- プライマリサイトとセカンダリサイトのチェックサムが一致しないため、コンテナレジストリイメージのサブセットで検証エラーが発生する可能性があります。[イシュー442667](https://gitlab.com/gitlab-org/gitlab/-/issues/442667)に詳細が記載されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失の直接的なリスクはありませんが、検証は成功していません。現時点では、既知の回避策はありません。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

## 16.7.0

- GitLab 16.7は必須のアップグレード経由地点です。これにより、GitLab 16.7以前に導入されたすべてのデータベース変更が、すべてのSelf-Managedインスタンスに実装されていることが保証されます。依存する変更は、GitLab 16.8以降でリリースできます。[イシュー429611](https://gitlab.com/gitlab-org/gitlab/-/issues/429611)に詳細が記載されています。

  - アップグレードパスで16.6をスキップすると、インスタンスがGitLab 16.6 リリースからのバックグラウンドデータベース移行を処理するときに、16.7にアップグレードした後でパフォーマンス問題が発生する可能性があります。[16.6.0 アップグレードノート](#1660)で`ci_builds`移行の詳細をお読みください。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Linuxパッケージのインストール

Linuxパッケージのインストールには、次の特定の情報が適用されます。

- GitLab 16.7以降、PostgreSQL 14はLinuxパッケージでインストールされるデフォルトバージョンです。パッケージアップグレード中、データベースはPostgreSQL 14にアップグレードされません。PostgreSQL 14へのアップグレードは、[手動で行う必要](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)があります。

  PostgreSQL 13を使用する場合は、`/etc/gitlab/gitlab.rb`で`postgresql['version'] = 13`を設定する必要があります。

### Geoインストール

- PostgreSQLバージョン14は、GitLab 16.7以降の新規インストールのデフォルトです。既知の問題により、既存のGeoセカンダリサイトはPostgreSQLバージョン14にアップグレードできません。詳細については、[イシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7768#note_1652076255)を参照してください。すべてのGeoサイトは、同じバージョンのPostgreSQLを実行する必要があります。GitLab 16.7から16.8.1に新しいGeoセカンダリサイトを追加するには、構成に基づいて次のいずれかの操作を行う必要があります。

  - 1つ目のGeoセカンダリサイトを追加する場合: 新しいGeoセカンダリサイトをセットアップする前に、[プライマリサイトをPostgreSQL 14にアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)してください。プライマリサイトがすでにPostgreSQL 14を実行している場合は、特別な操作は必要ありません。
  - すでに1つ以上のGeoセカンダリがあるデプロイメントに、新しいGeoセカンダリサイトを追加する場合:
    - 既存のすべてのサイトが PostgreSQL 13を実行している場合は、[ピン留めしたPostgreSQLバージョン13](https://docs.gitlab.com/omnibus/settings/database.html#pin-the-packaged-postgresql-version-fresh-installs-only)を使用して、新しいGeoセカンダリサイトをインストールします。
    - 既存のすべてのサイトがPostgreSQL 14を実行している場合は、特別な操作は必要ありません。
    - 新しいGeoセカンダリサイトをデプロイに追加する前に、既存のすべてのサイトをGitLab 16.8.2以降およびPostgreSQL 14にアップグレードしてください。

- プライマリサイトとセカンダリサイトの間でチェックサムが一致しないため、一部のプロジェクトで検証エラーが発生する可能性があります。詳細はこの[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/427493)で追跡されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失のリスクはありません。Geoセカンダリサイトから影響を受けたプロジェクトを複製すると、常にプライマリサイトにリダイレクトされます。現時点では、既知の回避策はありません。現在、修正に取り組んでいます。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.3                    |  すべて                    | なし     |
  | 16.4                    |  すべて                    | なし     |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  16.6.0 - 16.6.5        | 16.6.6   |
  | 16.7                    |  16.7.0 - 16.7.3        | 16.7.4   |

- GitLab 16.5のバグにより、[パーソナルスニペット](../../user/snippets.md)がセカンダリのGeoサイトにレプリケートされていません。これにより、Geoフェイルオーバーが発生した場合に、パーソナルスニペットデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#439933](https://gitlab.com/gitlab-org/gitlab/-/issues/439933)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  すべて                    | なし     |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

## 16.6.0

- GitLab 16.6では、プライマリキーを64ビットにアップグレードする一環として、CIジョブテーブル（`ci_builds`）のすべての行を書き換えるバックグラウンド移行が導入されています。`ci_builds`はほとんどのGitLabインスタンスで最大のテーブルの1つであるため、この移行は通常よりも積極的に実行され、妥当な時間で完了できるようになっています。通常、バックグラウンド移行は行のバッチ間で一時停止しますが、この移行は一時停止しません。

  このため、Self-Managed環境でパフォーマンスの問題が発生する可能性があります。

  - ディスクI/Oが通常よりも高くなります。これは、ディスクI/Oが制限されているクラウドプロバイダーがホストするインスタンスでは特に問題になります。
  - Autovacuumは、古い行（デッドタプル）を削除し、その他の関連するハウスキーピングを実行するために、バックグラウンドでより頻繁に実行される可能性があります。
  - PostgreSQLが非効率なクエリプランを選択するため、クエリの実行速度が一時的に低下する可能性があります。これは、テーブル上の変更量によってトリガーされる可能性があります。

  回避策:

  - [**管理者**エリア](../background_migrations.md#from-the-gitlab-ui)で実行中の移行を一時停止します。
  - 適切なクエリプランが選択されるように、[データベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)でテーブル統計を手動で再作成します。

    ```sql
    SET statement_timeout = 0;
    VACUUM FREEZE VERBOSE ANALYZE public.ci_builds;
    ```

- GitLab 16.6へのアップグレード後、古い[CI環境破棄ジョブが起動する](https://gitlab.com/gitlab-org/gitlab/-/issues/433264#)可能性があります。
- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Geoインストール

- プライマリサイトとセカンダリサイトの間でチェックサムが一致しないため、一部のプロジェクトで検証エラーが発生する可能性があります。詳細はこの[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/427493)で追跡されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失のリスクはありません。Geoセカンダリサイトから影響を受けたプロジェクトを複製すると、常にプライマリサイトにリダイレクトされます。現時点では、既知の回避策はありません。現在、修正に取り組んでいます。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.3                    |  すべて                    | なし     |
  | 16.4                    |  すべて                    | なし     |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  16.6.0 - 16.6.5        | 16.6.6   |
  | 16.7                    |  16.7.0 - 16.7.3        | 16.7.4   |

- GitLab 16.5のバグにより、[パーソナルスニペット](../../user/snippets.md)がセカンダリのGeoサイトにレプリケートされていません。これにより、Geoフェイルオーバーが発生した場合に、パーソナルスニペットデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#439933](https://gitlab.com/gitlab-org/gitlab/-/issues/439933)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  すべて                    | なし     |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

## 16.5.0

- GitalyではGit 2.42.0以降が必要です。自己コンパイルされたインストールでは、[Gitalyが提供するGitバージョン](../../install/installation.md#git)を使用する必要があります。
- リグレッションにより、[グループをナビゲートする際にHTTP 500エラー](https://gitlab.com/gitlab-org/gitlab/-/issues/431659)が発生することがあります。GitLab 16.6以降にアップグレードすると、この問題は解決します。
- リグレッションにより、[選択されていない高度な検索ファセットが読み込まれない](https://gitlab.com/gitlab-org/gitlab/-/issues/428246)場合があります。16.6以降にアップグレードすると、この問題は解決します。
- `unique_batched_background_migrations_queued_migration_version`インデックスは16.5で導入され、デプロイ後の移行`DeleteOrphansScanFindingLicenseScanningApprovalRules2`は、ゼロダウンタイムアップグレードを実行中に、この一意の制約を破る可能性があります。エラーを修正する回避策は、[イシュー#437291](https://gitlab.com/gitlab-org/gitlab/-/issues/437291#to-unblock)で入手できます。

  ```plaintext
  PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint
  "unique_batched_background_migrations_queued_migration_version"
  DETAIL:  Key (queued_migration_version)=(20230721095222) already exists.
  ```

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Linuxパッケージのインストール

- SSHクローンURLは、`/etc/gitlab/gitlab.rb`で`gitlab_rails['gitlab_ssh_host']`を設定することでカスタマイズできます。この設定は、[有効なホスト名](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132238)である必要があります。以前は、リポジトリクローンURLにカスタムホスト名とポートを表示するために使用される任意の文字列を指定できました。

  たとえば、GitLab 16.5より前は、次の設定が機能していました。

  ```ruby
  gitlab_rails['gitlab_ssh_host'] = "gitlab.example.com:2222"
  ```

  GitLab 16.5以降では、ホスト名とポートを個別に指定する必要があります。

  ```ruby
  gitlab_rails['gitlab_ssh_host'] = "gitlab.example.com"
  gitlab_rails['gitlab_shell_ssh_port'] = 2222
  ```

  設定を変更したら、必ずGitLabを再構成してください。

  ```shell
  sudo gitlab-ctl reconfigure
  ```

### Geoインストール

Geoを使用するインストールには、特定の情報が適用されます。

- いくつかのPrometheusメトリクスが、16.3.0で誤って削除されました。そのため、ダッシュボードとアラートを中断する可能性があります。

  | 影響を受けるメトリクス                          | 16.5.2以降で復元されたメトリクス  | 16.3以降で利用可能な代替手段                 |
  | ---------------------------------------- | ------------------------------------ | ---------------------------------------------- |
  | `geo_repositories_synced`                | はい                                  | `geo_project_repositories_synced`              |
  | `geo_repositories_failed`                | はい                                  | `geo_project_repositories_failed`              |
  | `geo_repositories_checksummed`           | はい                                  | `geo_project_repositories_checksummed`         |
  | `geo_repositories_checksum_failed`       | はい                                  | `geo_project_repositories_checksum_failed`     |
  | `geo_repositories_verified`              | はい                                  | `geo_project_repositories_verified`            |
  | `geo_repositories_verification_failed`   | はい                                  | `geo_project_repositories_verification_failed` |
  | `geo_repositories_checksum_mismatch`     | いいえ                                   | 利用可能なものはありません                                 |
  | `geo_repositories_retrying_verification` | いいえ                                   | 利用可能なものはありません                                 |

  - 影響を受けるバージョン:
    - 16.3.0 - 16.5.1
  - 修正を含むバージョン:
    - 16.5.2以降

  詳細については、[イシュー429617](https://gitlab.com/gitlab-org/gitlab/-/issues/429617)を参照してください。

- [オブジェクトストレージの検証](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#geo-verifies-object-storage)がGitLab 16.4で追加されました。[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429242)により、一部のGeoインストールでメモリ使用量が高くなっていると報告されており、プライマリ上のGitLabアプリケーションが応答しなくなる可能性があります。

  [オブジェクトストレージ](../../administration/object_storage.md)を使用するよう構成し、[GitLab管理のオブジェクトストレージレプリケーション](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication)を有効にしている場合、インストールが影響を受ける可能性があります

  これが修正されるまで、回避策としてオブジェクトストレージの検証を無効にします。プライマリサイトのいずれかのRailsノードで、次のコマンドを実行します。

  ```shell
  sudo gitlab-rails runner 'Feature.disable(:geo_object_storage_verification)'
  ```

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.4                    | 16.4.0 - 16.4.2         | 16.4.3   |
  | 16.5                    | 16.5.0 - 16.5.1         | 16.5.2   |

- GitLab 16.3で[グループWiki](../../user/project/wiki/group.md)の検証が追加された後、存在しないグループWikiリポジトリが誤って検証失敗としてフラグ付けされています。このイシューは、実際のレプリケーションや検証の失敗の結果ではなく、Geo内にリポジトリが存在しないために起こる内部の無効な状態が原因で、ログにエラーが記録され、検証の進行状況でこれらのグループWikiリポジトリが失敗状態として報告されます。

  問題の詳細と回避策については、イシュー[#426571](https://gitlab.com/gitlab-org/gitlab/-/issues/426571)を参照してください

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ------ | ------ | ------ |
  | 16.3   | すべて    | なし   |
  | 16.4   | すべて    | なし   |
  | 16.5   | 16.5.0 - 16.5.1    | 16.5.2   |

- プライマリサイトとセカンダリサイトの間でチェックサムが一致しないため、一部のプロジェクトで検証エラーが発生する可能性があります。詳細はこの[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/427493)で追跡されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失のリスクはありません。Geoセカンダリサイトから影響を受けたプロジェクトを複製すると、常にプライマリサイトにリダイレクトされます。現時点では、既知の回避策はありません。現在、修正に取り組んでいます。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.3                    |  すべて                    | なし     |
  | 16.4                    |  すべて                    | なし     |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  16.6.0 - 16.6.5        | 16.6.6   |
  | 16.7                    |  16.7.0 - 16.7.3        | 16.7.4   |

- GitLab 16.5のバグにより、[パーソナルスニペット](../../user/snippets.md)がセカンダリのGeoサイトにレプリケートされていません。これにより、Geoフェイルオーバーが発生した場合に、パーソナルスニペットデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#439933](https://gitlab.com/gitlab-org/gitlab/-/issues/439933)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  すべて                    | なし     |
  | 16.8                    |  16.8.0 - 16.8.3        | 16.8.4   |
  | 16.9                    |  16.9.0 - 16.9.1        | 16.9.2   |

- GitLab 16.5で導入され、17.0で修正されたバグにより、[GitLab Pages](../../administration/pages/_index.md)デプロイファイルがセカンダリGeoサイトで孤立するという事象が発生しています。Pagesのデプロイがローカルに保存されている場合、これにより、残りのストレージがゼロになり、フェイルオーバーが発生した場合にデータが失われる可能性があります。問題の詳細と回避策については、イシュー[#457159](https://gitlab.com/gitlab-org/gitlab/-/issues/457159)を参照してください。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  すべて                    | なし     |
  | 16.7                    |  16.7.0 - 16.7.7        | 16.7.8   |
  | 16.8                    |  16.8.0 - 16.8.7        | 16.8.8   |
  | 16.9                    |  16.9.0 - 16.9.8        | 16.9.9   |
  | 16.10                   |  16.10.0 - 16.10.6      | 16.10.7  |
  | 16.11                   |  16.11.0 - 16.11.3      | 16.11.4  |

## 16.4.0

- グループパスの更新で、16.3で導入されたデータベースインデックスを使用する[バグ修正を受信](https://gitlab.com/gitlab-org/gitlab/-/issues/419289)しました。

  16.3より前のバージョンから16.4にアップグレードする場合は、使用する前にデータベースで`ANALYZE packages_packages;`を実行する必要があります。

- GitLab 16.4以降にアップグレードする際に、次のエラーが発生する可能性があります。

  ```plaintext
  main: == 20230830084959 ValidatePushRulesConstraints: migrating =====================
  main: -- execute("SET statement_timeout TO 0")
  main:    -> 0.0002s
  main: -- execute("ALTER TABLE push_rules VALIDATE CONSTRAINT force_push_regex_size_constraint;")
  main:    -> 0.0004s
  main: -- execute("RESET statement_timeout")
  main:    -> 0.0003s
  main: -- execute("ALTER TABLE push_rules VALIDATE CONSTRAINT delete_branch_regex_size_constraint;")
  rails aborted!
  StandardError: An error has occurred, all later migrations canceled:

  PG::CheckViolation: ERROR:  check constraint "delete_branch_regex_size_constraint" of relation "push_rules" is violated by some row
  ```

  これらの制約により、エラーが返される可能性があります。

  - `author_email_regex_size_constraint`
  - `branch_name_regex_size_constraint`
  - `commit_message_negative_regex_size_constraint`
  - `commit_message_regex_size_constraint`
  - `delete_branch_regex_size_constraint`
  - `file_name_regex_size_constraint`
  - `force_push_regex_size_constraint`

  エラーを修正するには、511文字の制限を超える`push_rules`テーブル内のレコードを見つけます。

  ```sql
  ;; replace `delete_branch_regex` with a name of the field used in constraint
  SELECT id FROM push_rules WHERE LENGTH(delete_branch_regex) > 511;
  ```

  プッシュルールがプロジェクト、グループ、インスタンスのいずれに属しているかを確認するには、[Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)で次のスクリプトを実行します。

  ```ruby
  # replace `delete_branch_regex` with a name of the field used in constraint
  long_rules = PushRule.where("length(delete_branch_regex) > 511")

  array = long_rules.map do |lr|
    if lr.project
      "Push rule with ID #{lr.id} is configured in a project #{lr.project.full_name}"
    elsif lr.group
      "Push rule with ID #{lr.id} is configured in a group #{lr.group.full_name}"
    else
      "Push rule with ID #{lr.id} is configured on the instance level"
    end
  end

  puts "Total long rules: #{array.count}"
  puts array.join("\n")
  ```

  該当するプッシュルールレコードの正規表現フィールドの値を小さくしてから、移行を再試行してください。

  影響を受けるプッシュルールが多すぎて、GitLab UIから更新できない場合は、[GitLabサポート](https://about.gitlab.com/support/)にお問い合わせください。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### 自己コンパイルによるインストール

- GitLab 16.4以降では、GitLabシークレットとカスタムフックのパスを設定する新しい方法が推奨されています。
  1. 設定`[gitlab] secret_file`を更新して、GitLabシークレットトークンの[パスを構成](../../administration/gitaly/reference.md)します。
  1. カスタムフックがある場合は、設定`[hooks] custom_hooks_dir`を更新して、サーバー側のカスタムフックの[パスを構成](../../administration/gitaly/reference.md)します。
  1. `[gitlab-shell] dir`設定を削除します。

### Geoインストール

Geoを使用するインストールには、特定の情報が適用されます。

- いくつかのPrometheusメトリクスが、16.3.0で誤って削除されました。そのため、ダッシュボードとアラートを中断する可能性があります。

  | 影響を受けるメトリクス                          | 16.5.2以降で復元されたメトリクス  | 16.3以降で利用可能な代替手段                 |
  | ---------------------------------------- | ------------------------------------ | ---------------------------------------------- |
  | `geo_repositories_synced`                | はい                                  | `geo_project_repositories_synced`              |
  | `geo_repositories_failed`                | はい                                  | `geo_project_repositories_failed`              |
  | `geo_repositories_checksummed`           | はい                                  | `geo_project_repositories_checksummed`         |
  | `geo_repositories_checksum_failed`       | はい                                  | `geo_project_repositories_checksum_failed`     |
  | `geo_repositories_verified`              | はい                                  | `geo_project_repositories_verified`            |
  | `geo_repositories_verification_failed`   | はい                                  | `geo_project_repositories_verification_failed` |
  | `geo_repositories_checksum_mismatch`     | いいえ                                   | 利用可能なものはありません                                 |
  | `geo_repositories_retrying_verification` | いいえ                                   | 利用可能なものはありません                                 |

  - 影響を受けるバージョン:
    - 16.3.0 - 16.5.1
  - 修正を含むバージョン:
    - 16.5.2以降

  詳細については、[イシュー429617](https://gitlab.com/gitlab-org/gitlab/-/issues/429617)を参照してください。

- [オブジェクトストレージの検証](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#geo-verifies-object-storage)がGitLab 16.4で追加されました。[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429242)により、一部のGeoインストールでメモリ使用量が高くなっていると報告されており、プライマリ上のGitLabアプリケーションが応答しなくなる可能性があります。

  [オブジェクトストレージ](../../administration/object_storage.md)を使用するよう構成し、[GitLab管理のオブジェクトストレージレプリケーション](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication)を有効にしている場合、インストールが影響を受ける可能性があります

  これが修正されるまで、回避策としてオブジェクトストレージの検証を無効にします。プライマリサイトのいずれかのRailsノードで、次のコマンドを実行します。

  ```shell
  sudo gitlab-rails runner 'Feature.disable(:geo_object_storage_verification)'
  ```

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.4                    | 16.4.0 - 16.4.2         | 16.4.3   |
  | 16.5                    | 16.5.0 - 16.5.1         | 16.5.2   |

- 同期状態が保留状態のままになる[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/419370)により、影響を受けるアイテムのレプリケーションが無期限に停止し、フェイルオーバーが発生した場合にデータが失われるリスクがあります。これは主にリポジトリの同期に影響しますが、コンテナレジストリの同期にも影響を与える可能性があります。データ損失のリスクを回避するために、修正済みのバージョンにアップグレードすることをお勧めします。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ------ | ------ | ------ |
  | 16.3   | 16.3.0 - 16.3.5    | 16.3.6   |
  | 16.4   | 16.4.0 - 16.4.1    | 16.4.2   |

- GitLab 16.3で[グループWiki](../../user/project/wiki/group.md)の検証が追加された後、存在しないグループWikiリポジトリが誤って検証失敗としてフラグ付けされています。この問題は、実際のレプリケーションや検証の失敗の結果ではなく、Geo内にリポジトリが存在しないために起こる内部の無効な状態が原因で、ログにエラーが記録され、検証の進行状況でこれらのグループWikiリポジトリが失敗状態として報告されます。

  問題の詳細と回避策については、イシュー[#426571](https://gitlab.com/gitlab-org/gitlab/-/issues/426571)を参照してください

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ------ | ------ | ------ |
  | 16.3   | すべて    | なし   |
  | 16.4   | すべて    | なし   |
  | 16.5   | 16.5.0 - 16.5.1    | 16.5.2   |

- プライマリサイトとセカンダリサイトの間でチェックサムが一致しないため、一部のプロジェクトで検証エラーが発生する可能性があります。詳細はこの[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/427493)で追跡されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失のリスクはありません。Geoセカンダリサイトから影響を受けたプロジェクトを複製すると、常にプライマリサイトにリダイレクトされます。現時点では、既知の回避策はありません。現在、修正に取り組んでいます。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.3                    |  すべて                    | なし     |
  | 16.4                    |  すべて                    | なし     |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  16.6.0 - 16.6.5        | 16.6.6   |
  | 16.7                    |  16.7.0 - 16.7.3        | 16.7.4   |

## 16.3.0

- **GitLab 16.3.5以降にアップデート**してください。これにより、GitLab 16.3.3および16.3.4でデータベースのディスクスペースを過剰に使用する[イシュー425971](https://gitlab.com/gitlab-org/gitlab/-/issues/425971)を回避できます。

- データベースに重複したNPMパッケージがないことを保証するために、一意のインデックスが追加されました。重複したNPMパッケージがある場合は、最初に16.1にアップグレードする必要があります。そうしないと、`PG::UniqueViolation: ERROR:  could not create unique index "idx_packages_on_project_id_name_version_unique_when_npm"`のエラーが発生する可能性があります。

- Goアプリケーションの場合、[`crypto/tls`: 大規模なRSAキーを含む証明書チェーンの検証が遅い (CVE-2023-29409)](https://github.com/golang/go/issues/61460)により、RSAキーのハードリミットが8192ビットに設定されました。GitLabのGoアプリケーションのコンテキストでは、RSAキーは以下のように構成できます。

  - [コンテナレジストリ](../../administration/packages/container_registry.md)
  - [Gitaly](../../administration/gitaly/tls_support.md)
  - [GitLab Pages](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manual-addition-of-ssltls-certificates)
  - [Workhorse](../../development/workhorse/configuration.md#tls-support)

  アップグレードする前に、上記のアプリケーションのいずれかでRSAキーのサイズ(`openssl rsa -in <your-key-file> -text -noout | grep "Key:"`)を確認する必要があります。

- `BackfillCiPipelineVariablesForPipelineIdBigintConversion`バックグラウンド移行は、`EnsureAgainBackfillForCiPipelineVariablesPipelineIdIsFinished`ポストデプロイ移行で完了します。GitLab 16.2.0では、[`ci_pipeline_variables`テーブルの`bigint` `pipeline_id`値を埋め戻す](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123132)[バッチバックグラウンド移行](../background_migrations.md#batched-background-migrations)が導入されました。この移行は、大規模なGitLabインスタンスでは完了までに長い時間がかかる場合があります（あるケースでは、5,000万行の処理に4時間かかったと報告されています）。アップグレードのダウンタイムが長期化しないように、16.3にアップグレードする前に、移行が正常に完了していることを確認してください。

  [データベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)で、`ci_pipeline_variables`テーブルのサイズを確認できます。

  ```sql
  select count(*) from ci_pipeline_variables;
  ```

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

     **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Linuxパッケージのインストール

Linuxパッケージのインストールには、次の特定の情報が適用されます。

- GitLab 16.0では、新しいバージョンのOpenSSH Serverを持つ、アップグレードされたベースDockerイメージを[発表](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#omnibus-improvements)しました。新しいバージョンでは、SSH RSA SHA-1署名の受け入れがデフォルトで無効になるという意図しない結果が生じました。この問題は、非常に古いSSHクライアントを使用しているユーザーにしか影響しないはずです。

  SHA-1署名が利用できなくなる問題を回避するには、ユーザーはSSHクライアントを更新する必要があります。セキュリティ上の理由から、アップストリームライブラリでSHA-1署名を使用することが推奨されていないためです。

  ユーザーがSSHクライアントをすぐにアップグレードできない移行期間を考慮して、GitLab 16.3以降では、`Dockerfile`の`GITLAB_ALLOW_SHA1_RSA`環境変数がサポートされています。`GITLAB_ALLOW_SHA1_RSA`が`true`に設定されている場合、この非推奨のサポートが再び有効になります。

  セキュリティのベストプラクティスを促進し、アップストリームの推奨事項に従うため、この環境変数はGitLab 17.0までのみ利用可能になり、その時点でサポートを停止する予定です。

  詳細については、以下を参照してください。

  - [OpenSSH 8.8リリースノート](https://www.openssh.com/txt/release-8.8)。
  - [非公式な説明](https://gitlab.com/gitlab-org/gitlab/-/issues/416714#note_1482388504)。
  - `omnibus-gitlab`[マージリクエスト7035](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7035)。これにより、環境変数が導入されます。

### Geoインストール

Geoを使用するインストールには、特定の情報が適用されます。

- セカンダリGeoサイトに対するGitpプルは、そのセカンダリサイトが最新の状態であっても、プライマリGeoサイトにプロキシされています。セカンダリGeoサイトに対してGitプルリクエストを行うリモートユーザーを高速化するためにGeoを使用している場合は、影響を受けます。

  - 影響を受けるバージョン:
    - 16.3.0 - 16.3.3
  - 修正を含むバージョン:
    - 16.3.4以降

  詳細については、[イシュー425224](https://gitlab.com/gitlab-org/gitlab/-/issues/425224)を参照してください。

- いくつかのPrometheusメトリクスが、16.3.0で誤って削除されました。そのため、ダッシュボードとアラートを中断する可能性があります。

  | 影響を受けるメトリクス                          | 16.5.2以降で復元されたメトリクス  | 16.3以降で利用可能な代替手段                 |
  | ---------------------------------------- | ------------------------------------ | ---------------------------------------------- |
  | `geo_repositories_synced`                | はい                                  | `geo_project_repositories_synced`              |
  | `geo_repositories_failed`                | はい                                  | `geo_project_repositories_failed`              |
  | `geo_repositories_checksummed`           | はい                                  | `geo_project_repositories_checksummed`         |
  | `geo_repositories_checksum_failed`       | はい                                  | `geo_project_repositories_checksum_failed`     |
  | `geo_repositories_verified`              | はい                                  | `geo_project_repositories_verified`            |
  | `geo_repositories_verification_failed`   | はい                                  | `geo_project_repositories_verification_failed` |
  | `geo_repositories_checksum_mismatch`     | いいえ                                   | 利用可能なものはありません                                 |
  | `geo_repositories_retrying_verification` | いいえ                                   | 利用可能なものはありません                                 |

  - 影響を受けるバージョン:
    - 16.3.0 - 16.5.1
  - 修正を含むバージョン:
    - 16.5.2以降

  詳細については、[イシュー429617](https://gitlab.com/gitlab-org/gitlab/-/issues/429617)を参照してください。

- 同期状態が保留状態のままになる[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/419370)により、影響を受けるアイテムのレプリケーションが無期限に停止し、フェイルオーバーが発生した場合にデータが失われるリスクがあります。これは主にリポジトリの同期に影響しますが、コンテナレジストリの同期にも影響を与える可能性があります。データ損失のリスクを回避するために、修正済みのバージョンにアップグレードすることをお勧めします。

- プライマリサイトとセカンダリサイトの間でチェックサムが一致しないため、一部のプロジェクトで検証エラーが発生する可能性があります。詳細については、[イシュー427493](https://gitlab.com/gitlab-org/gitlab/-/issues/427493)で追跡されています。データはセカンダリサイトに正しくレプリケートされているため、データ損失のリスクはありません。Geoセカンダリサイトから影響を受けたプロジェクトを複製すると、常にプライマリサイトにリダイレクトされます。既知の回避策はありません。修正を含むバージョンにアップグレードする必要があります。

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ----------------------- | ----------------------- | -------- |
  | 16.3                    |  すべて                    | なし     |
  | 16.4                    |  すべて                    | なし     |
  | 16.5                    |  すべて                    | なし     |
  | 16.6                    |  16.6.0 - 16.6.5        | 16.6.6   |
  | 16.7                    |  16.7.0 - 16.7.3        | 16.7.4   |

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ------ | ------ | ------ |
  | 16.3   | 16.3.0 - 16.3.5    | 16.3.6   |
  | 16.4   | 16.4.0 - 16.4.1    | 16.4.2   |

- GitLab 16.3で[グループWiki](../../user/project/wiki/group.md)の検証が追加された後、存在しないグループWikiリポジトリが誤って検証失敗としてフラグ付けされています。この問題は、実際のレプリケーションや検証の失敗の結果ではなく、Geo内にリポジトリが存在しないために起こる内部の無効な状態が原因で、ログにエラーが記録され、検証の進行状況でこれらのグループWikiリポジトリが失敗状態として報告されます。

  問題の詳細と回避策については、イシュー[#426571](https://gitlab.com/gitlab-org/gitlab/-/issues/426571)を参照してください

  **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
  | ------ | ------ | ------ |
  | 16.3   | すべて    | なし   |
  | 16.4   | すべて    | なし   |
  | 16.5   | 16.5.0 - 16.5.1    | 16.5.2   |

## 16.2.0

- 従来のLDAP設定により、[`NoMethodError: undefined method 'devise' for User:Class`エラー](https://gitlab.com/gitlab-org/gitlab/-/issues/419485)が発生する場合があります。このエラーは、`tls_options`ハッシュで指定されていないTLSオプション(`ca_file`など)がある場合、または従来の`gitlab_rails['ldap_host']`オプションを使用する場合に発生します。詳細については、[設定の回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/419485#workarounds)を参照してください。
- GitLabデータベースがバージョン15.11.0 - 15.11.2（両端を含む）で作成またはアップグレードされた場合、GitLab 16.2へのアップグレードでは次のエラーが発生します。

  ```plaintext
  PG::UndefinedColumn: ERROR:  column "id_convert_to_bigint" of relation "ci_build_needs" does not exist
  LINE 1: ...db_config_name:main*/ UPDATE "ci_build_needs" SET "id_conver...
  ```

  詳細と回避策については、[こちら](#undefined-column-error-upgrading-to-162-or-later)を参照してください。

- GitLab 16.2以降へのアップグレード中に、次のエラーが発生する可能性があります。

  ```plaintext
  main: == 20230620134708 ValidateUserTypeConstraint: migrating =======================
  main: -- execute("ALTER TABLE users VALIDATE CONSTRAINT check_0dd5948e38;")
  rake aborted!
  StandardError: An error has occurred, all later migrations canceled:
  PG::CheckViolation: ERROR:  check constraint "check_0dd5948e38" of relation "users" is violated by some row
  ```

  詳細については、[イシュー421629](https://gitlab.com/gitlab-org/gitlab/-/issues/421629)を参照してください。

- GitLab 16.2以降にアップグレードした後、次のエラーが発生する可能性があります。

  ```plaintext
  PG::NotNullViolation: ERROR:  null value in column "source_partition_id" of relation "ci_sources_pipelines" violates not-null constraint
  ```

  この問題を解決するには、SidekiqとPumaのプロセスを再起動する必要があります。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Linuxパッケージのインストール

Linuxパッケージのインストールには、次の特定の情報が適用されます。

- GitLab 16.2の時点では、PostgreSQL 13.11と14.8の両方がLinuxパッケージに同梱されています。パッケージアップグレード中、データベースはPostgreSQL 14にアップグレードされません。PostgreSQL 14にアップグレードする場合は、手動で行う必要があります。

  ```shell
  sudo gitlab-ctl pg-upgrade -V 14
  ```

  PostgreSQL 14はGeoデプロイではサポートされておらず、将来のリリースで[計画](https://gitlab.com/groups/gitlab-org/-/epics/9065)されています。

- 16.2では、Redisを6.2.11から7.0.12にアップグレードしています。このアップグレードは、完全に下位互換性があると予想されます。

  Redis は、`gitlab-ctl reconfigure`の一部として自動的に再起動しません。したがって、新しいRedisバージョンを使用するように、再構成の実行後、ユーザーは手動で`sudo gitlab-ctl restart redis`を実行する必要があります。再起動を実行するまで、インストールされたRedisバージョンが実行中のバージョンと異なっていることを示す警告が再構成の最後に表示されます。

  Redis HAクラスターをアップグレードするには、[ゼロダウンタイムの手順](../zero_downtime.md)に従ってください。

### 自己コンパイルによるインストール

- Gitalyでは、Git 2.41.0以降が必要です。[Gitalyから提供されるGitバージョン](../../install/installation.md#git)を使用する必要があります。

### Geoインストール

Geoを使用するインストールには、特定の情報が適用されます。

- ジョブアーティファクトがオブジェクトストレージに保存されるように構成され、`direct_upload`が有効になっている場合、新しいジョブアーティファクトはGeoによって複製されません。このバグは、GitLabバージョン16.1.4、16.2.3、16.3.0以降で修正されています。
  - 影響を受けるバージョン: GitLabバージョン16.1.0 - 16.1.3および16.2.0 - 16.2.2。
  - 影響を受けるバージョンを実行している場合、同期されたように見えるアーティファクトが、実際にはセカンダリサイトに存在しない可能性があります。影響を受けたアーティファクトは、16.1.5、16.2.5、16.3.1、16.4.0、またはそれ以降にアップグレードすると、自動的に再同期されます。必要に応じて、[影響を受けたジョブアーティファクトを手動で再同期](https://gitlab.com/gitlab-org/gitlab/-/issues/419742#to-fix-data)できます。

#### セカンダリサイトからのLFSオブジェクトのクローン作成で、プライマリサイトからダウンロードされる

LFSオブジェクトのGeoプロキシロジックの[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/410413)により、セカンダリサイトに対するすべてのLFSクローンリクエストは、セカンダリサイトが最新の状態であってもプライマリにプロキシされます。これにより、プライマリサイトの負荷が増加し、セカンダリサイトからクローンを作成するユーザーがLFSオブジェクトへアクセスするのに時間がかかる可能性があります。

GitLab 15.1では、プロキシがデフォルトで有効になっていました。

次の場合、影響はありません。

- インストール環境がLFSオブジェクトを使用するように構成されていない場合
- リモートユーザーを高速化するためにGeoを使用していない場合
- リモートユーザーを高速化するためにGeoを使用しているが、プロキシを無効にしている場合

| マイナーリリース | パッチリリース | 修正リリース |
|-------------------------|-------------------------|----------|
| 15.1 - 16.2             | すべて                     | 16.3     |

回避策: 考えられる回避策は、[プロキシを無効](../../administration/geo/secondary_proxy/_index.md#disable-secondary-site-http-proxying)にすることです。セカンダリサイトは、クローン作成時にレプリケートされていないLFSファイルを提供できないことに注意してください。

## 16.1.0

- `BackfillPreparedAtMergeRequests`バックグラウンド移行は、`FinalizeBackFillPreparedAtMergeRequests`ポストデプロイ移行で完了します。GitLab 15.10.0では、[`merge_requests`テーブルの`prepared_at`値を埋め戻す](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111865)[バッチバックグラウンド移行](../background_migrations.md#batched-background-migrations)が導入されました。この移行は、大規模なGitLabでは、完了するまでに数日かかる場合があります。16.1.0 にアップグレードする前に、移行が正常に完了していることを確認してください。
- GitLab 16.1.0には、破棄するために重複したNPMパッケージをマークする[バッチバックグラウンド移行](../background_migrations.md#batched-background-migrations)`MarkDuplicateNpmPackagesForDestruction`が含まれています。16.3.0以降にアップグレードする前に、移行が正常に完了していることを確認してください。
- `BackfillCiPipelineVariablesForBigintConversion`バックグラウンド移行は、`EnsureBackfillBigintIdIsCompleted`ポストデプロイ移行で完了します。GitLab 16.0.0では、[バッチバックグラウンド移行](../background_migrations.md#batched-background-migrations)が導入され、[`ci_pipeline_variables`テーブルの`bigint``id`値を埋め戻し](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118878)ます。この移行は、大規模なGitLabインスタンスでは完了までに長い時間がかかる場合があります（あるケースでは、5,000万行の処理に4時間かかったと報告されています）。アップグレードのダウンタイムが長引くのを避けるために、16.1にアップグレードする前に移行が正常に完了していることを確認してください。

  [データベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)で、`ci_pipeline_variables`テーブルのサイズを確認できます。

  ```sql
  select count(*) from ci_pipeline_variables;
  ```

### 自己コンパイルによるインストール

- Puma Worker Killerに関連する設定は`puma.rb`設定ファイルから削除する必要があります。これらの設定は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118645)されているためです。詳細については、[`puma.rb.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/16-0-stable-ee/config/puma.rb.example)ファイルを参照してください。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Geoインストール

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

Geoを使用するインストールには、特定の情報が適用されます。

- 一部のプロジェクトのインポートでは、プロジェクトの作成時にWikiリポジトリが初期化されません。詳細と回避策については、[こちら](#wiki-repositories-not-initialized-on-project-creation)を参照してください。
- プロジェクトデザインのSSFへの移行により、[存在しないデザインリポジトリが、検証失敗という誤ったフラグが立てられています](https://gitlab.com/gitlab-org/gitlab/-/issues/414279)。この問題は、実際のレプリケーションや検証の失敗の結果ではなく、Geo内にリポジトリが存在しないために起こる内部の無効な状態が原因で、ログにエラーが記録され、検証の進行状況でこれらのデザインリポジトリが失敗状態として報告されます。プロジェクトをインポートしていなくても、この問題の影響を受ける可能性があります。
  - 影響を受けるバージョン: GitLabバージョン16.1.0 - 16.1.2
  - 修正を含むバージョン: GitLab 16.1.3以降。
- ジョブアーティファクトがオブジェクトストレージに保存されるように構成され、`direct_upload`が有効になっている場合、新しいジョブアーティファクトはGeoによって複製されません。このバグは、GitLabバージョン16.1.4、16.2.3、16.3.0以降で修正されています。
  - 影響を受けるバージョン: GitLabバージョン16.1.0 - 16.1.3および16.2.0 - 16.2.2。
  - 影響を受けるバージョンを実行している場合、同期されたように見えるアーティファクトが、実際にはセカンダリサイトに存在しない可能性があります。影響を受けたアーティファクトは、16.1.5、16.2.5、16.3.1、16.4.0、またはそれ以降にアップグレードすると、自動的に再同期されます。必要に応じて、[影響を受けたジョブアーティファクトを手動で再同期](https://gitlab.com/gitlab-org/gitlab/-/issues/419742#to-fix-data)できます。
  - セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。詳細と回避策については、[こちら](#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

#### プロジェクト作成時にWikiリポジトリが初期化されない

| マイナーリリース | パッチリリース | 修正リリース |
|-------------------------|-------------------------|----------|
| 15.11                   | すべて                     | なし     |
| 16.0                    | すべて                     | なし     |
| 16.1                    | 16.1.0 - 16.1.2         | 16.1.3以降 |

一部のプロジェクトのインポートでは、プロジェクトの作成時にWikiリポジトリが初期化されません。プロジェクトWikiをSSFに移行して以来、[存在しないWikiリポジトリが検証に失敗したと誤ってフラグが立てられています](https://gitlab.com/gitlab-org/gitlab/-/issues/409704)。これは、実際のレプリケーションや検証の失敗の結果ではなく、Geo内にリポジトリが存在しないために起こる内部の無効な状態が原因で、ログにエラーが記録され、検証の進行状況でこれらのWikiリポジトリが失敗状態として報告されます。プロジェクトをインポートしていない場合、この問題の影響は受けません。

## 16.0.0

- `/etc/gitlab/gitlab.rb`ファイルに非ASCII文字が含まれている場合、Sidekiqがクラッシュします。[イシュー412767](https://gitlab.com/gitlab-org/gitlab/-/issues/412767#note_1404507549)の回避策に従って、これを修正できます。
- デフォルトでは、Sidekiqジョブは`default`キューと`mailers`キューにのみルーティングされます。その結果、すべてのSidekiqプロセスはこれらのキューもリッスンして、すべてのジョブがすべてのキューで処理されるようにします。[ルーティングルール](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)を構成している場合、この動作は適用されません。
- GitLab Dockerイメージを実行するには、Docker 20.10.10以降が必要です。古いバージョンは、[起動時にエラーを返し](../../install/docker/troubleshooting.md#threaderror-cant-create-thread-operation-not-permitted)ます。
- Azureストレージを使用するコンテナレジストリが空で、タグがゼロになっている可能性があります。[破壊的な変更の手順](../deprecations.md#azure-storage-driver-defaults-to-the-correct-root-prefix)に従って、これを修正できます。

- 通常、PgBouncerを使用する環境でのバックアップは、[`GITLAB_BACKUP_`をプレフィックスとする変数を設定してPgBouncerを回避する必要があります](../../administration/backup_restore/backup_gitlab.md#bypassing-pgbouncer)。ただし、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422163)により、`gitlab-backup`はオーバーライドで定義された直接接続ではなく、PgBouncerを介して通常のデータベース接続を使用するため、データベースのバックアップは失敗します。回避策は、`pg_dump`を直接使用することです。

    **影響を受けたリリース**:

  | マイナーリリース | パッチリリース | 修正リリース |
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

### Linuxパッケージのインストール

Linuxパッケージのインストールには、次の特定の情報が適用されます。

- PostgreSQL 12のバイナリは削除されました。

  アップグレードする前に、Linuxパッケージインストールの管理者は、インストールで[PostgreSQL 13](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)を使用していることを確認する必要があります。

- GitLabにバンドルされていたGrafanaは非推奨となり、サポートされなくなりました。GitLab 16.3で削除されます。
- これにより、`openssh-server`が`1:8.9p1-3`にアップグレードされます。

  [OpenSSH 8.7 リリースノート](https://www.openssh.com/txt/release-8.7)にリストされている廃止事項のため、古いOpenSSH クライアントで`ssh-keyscan -t rsa`を使用して公開キー情報を取得することはできません。

  回避策は、別のキータイプを使用するか、クライアントOpenSSHを8.7以上のバージョンにアップグレードすることです。

- GitLab 16.0以降ですべての`praefect['..']`設定が引き続き機能するように、[Praefect設定を新しい構造に移行します](#praefect-configuration-structure-change)。

- GitLab 16.0以降ですべての`gitaly['..']`設定が引き続き機能するように、[Gitaly設定を新しい構造に移行します](#gitaly-configuration-structure-change)。

### 有効期限切れのないアクセストークン

有効期限のないアクセストークンは無期限に有効であるため、アクセストークンが漏洩した場合、セキュリティリスクとなります。

GitLab 16.0以降にアップグレードすると、有効期限のない[個人](../../user/profile/personal_access_tokens.md)、[プロジェクト](../../user/project/settings/project_access_tokens.md)、または[グループ](../../user/group/settings/group_access_tokens.md)のアクセストークンには、アップグレード日から1年後の有効期限が自動的に設定されます。

この自動有効期限が適用される前に、混乱を最小限に抑えるために、次の手順を実行する必要があります。

1. [有効期限のないアクセストークンを特定](../../security/tokens/token_troubleshooting.md#find-tokens-with-no-expiration-date)します。
1. [それらのトークンに有効期限を付与](../../security/tokens/token_troubleshooting.md#extend-token-lifetime)します。

詳細については、以下を参照してください。

- [非推奨と削除に関するドキュメント](../deprecations.md#non-expiring-access-tokens)。
- [非推奨に関するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)。

### Geoインストール

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

Geoを使用するインストールには、特定の情報が適用されます。

- 一部のプロジェクトのインポートでは、プロジェクトの作成時にWikiリポジトリが初期化されません。詳細と回避策については、[こちら](#wiki-repositories-not-initialized-on-project-creation)を参照してください。
- セカンダリサイトからのLFSオブジェクトのクローン作成では、セカンダリが完全に同期されている場合でも、プライマリサイトからダウンロードされます。詳細と回避策については、[こちら](#cloning-lfs-objects-from-secondary-site-downloads-from-the-primary-site)を参照してください。

### Gitaly設定構造の変更点

GitLab 16.0では、LinuxパッケージのGitaly設定構造が[変更](https://gitlab.com/gitlab-org/gitaly/-/issues/4467)され、自己コンパイルインストールで使用されるGitaly設定構造と一貫性が保たれます。

この変更の結果、`gitaly['configuration']`の下の単一のハッシュには、ほとんどのGitaly設定が保持されます。一部の`gitaly['..']`設定オプションは、GitLab 16.0以降でも引き続き使用されます。

- `enable`
- `dir`
- `bin_path`
- `env_directory`
- `env`
- `open_files_ulimit`
- `consul_service_name`
- `consul_service_meta`

既存の設定を新しい構造に移動して移行します。`git_data_dirs`は、[GitLab 18.0まで](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8786)サポートされています。新しい構造はGitLab 15.10からサポートされています。

**新しい構造に移行する**

{{< alert type="warning" >}}

Gitalyクラスターを実行している場合は、[**最初に**Praefectを新しい設定構造に移行します](#praefect-configuration-structure-change)。この変更をテストしたら、Gitalyノードに進みます。設定構造の変更の一部としてGitalyが誤って構成されている場合、[リポジトリ検証](../../administration/gitaly/praefect.md#repository-verification)によって[Gitalyクラスターが機能するために必要なメタデータが削除](https://gitlab.com/gitlab-org/gitaly/-/issues/5529)されます。設定の誤りを防ぐために、Praefectでリポジトリの検証を一時的に無効にします。

{{< /alert >}}

1. Gitaly Clusterを実行している場合は、すべてのPraefectノードでリポジトリの検証が無効になっていることを確認してください。`verification_interval: 0`を設定し、`gitlab-ctl reconfigure`で適用します。
1. 新しい構造を設定に適用するには:
   1. 古いキーの値を`...`に置き換えます。
   1. `storage`を`git_data_dirs`に置き換えて設定する場合は、以下に示すように、**`path`の値に`/repositories`を付加します**。この手順を完了しないと、設定が修正されるまでGitリポジトリにアクセスできなくなります。この設定ミスにより、メタデータが削除される可能性があります。
   1. 以前に値を設定していないキーはスキップしてください。
   1. （推奨）すべてのハッシュキーに末尾のコンマを含め、キーの順序が変更されたり、キーが追加されたりしても、ハッシュが有効な状態を維持できるようにします。
1. `gitlab-ctl reconfigure`で変更を適用します。
1. GitLabでGitリポジトリの機能性をテストします。
1. 移行が完了したら、設定から古いキーを削除し、`gitlab-ctl reconfigure`を再実行します。
1. Gitaly Clusterを実行している場合は推奨されています。`verification_interval: 0`を削除して、Praefect[リポジトリの検証](../../administration/gitaly/praefect.md#repository-verification)を元に戻します。

新しい構造については以下に記載されており、古いキーについては新しいキーの上のコメントに記載されています。

{{< alert type="warning" >}}

`storage`へ更新したことを再確認してください。`path`の値に`/repositories`を付加する必要があります。

{{< /alert >}}

```ruby
gitaly['configuration'] = {
  # gitaly['socket_path']
  socket_path: ...,
  # gitaly['runtime_dir']
  runtime_dir: ...,
  # gitaly['listen_addr']
  listen_addr: ...,
  # gitaly['prometheus_listen_addr']
  prometheus_listen_addr: ...,
  # gitaly['tls_listen_addr']
  tls_listen_addr: ...,
  tls: {
    # gitaly['certificate_path']
    certificate_path: ...,
    # gitaly['key_path']
    key_path: ...,
  },
  # gitaly['graceful_restart_timeout']
  graceful_restart_timeout: ...,
  logging: {
    # gitaly['logging_level']
    level: ...,
    # gitaly['logging_format']
    format: ...,
    # gitaly['logging_sentry_dsn']
    sentry_dsn: ...,
    # gitaly['logging_ruby_sentry_dsn']
    ruby_sentry_dsn: ...,
    # gitaly['logging_sentry_environment']
    sentry_environment: ...,
    # gitaly['log_directory']
    dir: ...,
  },
  prometheus: {
    # gitaly['prometheus_grpc_latency_buckets']. The old value was configured as a string
    # such as '[0, 1, 2]'. The new value must be an array like [0, 1, 2].
    grpc_latency_buckets: ...,
  },
  auth: {
    # gitaly['auth_token']
    token: ...,
    # gitaly['auth_transitioning']
    transitioning: ...,
  },
  git: {
    # gitaly['git_catfile_cache_size']
    catfile_cache_size: ...,
    # gitaly['git_bin_path']
    bin_path: ...,
    # gitaly['use_bundled_git']
    use_bundled_binaries: ...,
    # gitaly['gpg_signing_key_path']
    signing_key: ...,
    # gitaly['gitconfig']. This is still an array but the type of the elements have changed.
    config: [
      {
        # Previously the elements contained 'section', and 'subsection' in addition to 'key'. Now
        # these all should be concatenated into just 'key', separated by dots. For example,
        # {section: 'first', subsection: 'middle', key: 'last', value: 'value'}, should become
        # {key: 'first.middle.last', value: 'value'}.
        key: ...,
        value: ...,
      },
    ],
  },
  # Storage could previously be configured through either gitaly['storage'] or 'git_data_dirs'. Migrate
  # the relevant configuration according to the instructions below.
  # For 'git_data_dirs', migrate only the 'path' to the gitaly['configuration'] and leave the rest of it untouched.
  storage: [
    {
      # gitaly['storage'][<index>]['name']
      #
      # git_data_dirs[<name>]. The storage name was configured as a key in the map.
      name: ...,
      # gitaly['storage'][<index>]['path']
      #
      # git_data_dirs[<name>]['path']. Use the value from git_data_dirs[<name>]['path'] and append '/repositories' to it.
      #
      # For example, if the path in 'git_data_dirs' was '/var/opt/gitlab/git-data', use
      # '/var/opt/gitlab/git-data/repositories'. The '/repositories' extension was automatically
      # appended to the path configured in `git_data_dirs`.
      path: ...,
    },
  ],
  hooks: {
    # gitaly['custom_hooks_dir']
    custom_hooks_dir: ...,
  },
  daily_maintenance: {
    # gitaly['daily_maintenance_disabled']
    disabled: ...,
    # gitaly['daily_maintenance_start_hour']
    start_hour: ...,
    # gitaly['daily_maintenance_start_minute']
    start_minute: ...,
    # gitaly['daily_maintenance_duration']
    duration: ...,
    # gitaly['daily_maintenance_storages']
    storages: ...,
  },
  cgroups: {
    # gitaly['cgroups_mountpoint']
    mountpoint: ...,
    # gitaly['cgroups_hierarchy_root']
    hierarchy_root: ...,
    # gitaly['cgroups_memory_bytes']
    memory_bytes: ...,
    # gitaly['cgroups_cpu_shares']
    cpu_shares: ...,
    repositories: {
      # gitaly['cgroups_repositories_count']
      count: ...,
      # gitaly['cgroups_repositories_memory_bytes']
      memory_bytes: ...,
      # gitaly['cgroups_repositories_cpu_shares']
      cpu_shares: ...,
    }
  },
  # gitaly['concurrency']. While the structure is the same, the string keys in the array elements
  # should be replaced by symbols as elsewhere. {'key' => 'value'}, should become {key: 'value'}.
  concurrency: ...,
  # gitaly['rate_limiting']. While the structure is the same, the string keys in the array elements
  # should be replaced by symbols as elsewhere. {'key' => 'value'}, should become {key: 'value'}.
  rate_limiting: ...,
  pack_objects_cache: {
    # gitaly['pack_objects_cache_enabled']
    enabled: ...,
    # gitaly['pack_objects_cache_dir']
    dir: ...,
    # gitaly['pack_objects_cache_max_age']
    max_age: ...,
  }
}
```

### Praefect設定構造の変更点

GitLab 16.0では、LinuxパッケージのPraefect設定構造が[変更](https://gitlab.com/gitlab-org/gitaly/-/issues/4467)され、自己コンパイルされたインストールで使用されるPraefect設定構造と一貫性が保たれるようになりました。

この変更の結果、`praefect['configuration']`の下の単一のハッシュが、ほとんどのPraefect設定を保持するようになりました。一部の`praefect['..']`設定オプションは、GitLab 16.0以降でも引き続き使用されます。

- `enable`
- `dir`
- `log_directory`
- `env_directory`
- `env`
- `wrapper_path`
- `auto_migrate`
- `consul_service_name`

既存の設定を新しい構造に移動して移行します。新しい構造はGitLab 15.9以降でサポートされています。

**新しい構造に移行する**

{{< alert type="warning" >}}

**最初に**、Praefectを新しい設定構造に移行します。この変更をテストしたら、[Gitalyノードに進みます](#gitaly-configuration-structure-change)。設定構造の変更の一部としてGitalyが誤って構成されている場合、[リポジトリ検証](../../administration/gitaly/praefect.md#repository-verification)によって[Gitalyクラスターが機能するために必要なメタデータが削除](https://gitlab.com/gitlab-org/gitaly/-/issues/5529)されます。設定の誤りを防ぐために、Praefectでリポジトリの検証を一時的に無効にします。

{{< /alert >}}

1. 新しい構造を設定に適用する場合:
   - 古いキーの値を`...`に置き換えます。
   - 以下に示すように、`verification_interval: 0`を使用してリポジトリの検証を無効にします。
   - 以前に値を設定していないキーはスキップしてください。
   - （推奨）すべてのハッシュキーに末尾のコンマを含め、キーの順序が変更されたり、キーが追加されたりしても、ハッシュが有効な状態を維持できるようにします。
1. `gitlab-ctl reconfigure`で変更を適用します。
1. GitLabでGitリポジトリの機能性をテストします。
1. 移行が完了したら、設定から古いキーを削除し、`gitlab-ctl reconfigure`を再実行します。

新しい構造については以下に記載されており、古いキーについては新しいキーの上のコメントに記載されています。

```ruby
praefect['configuration'] = {
  # praefect['listen_addr']
  listen_addr: ...,
  # praefect['socket_path']
  socket_path: ...,
  # praefect['prometheus_listen_addr']
  prometheus_listen_addr: ...,
  # praefect['tls_listen_addr']
  tls_listen_addr: ...,
  # praefect['separate_database_metrics']
  prometheus_exclude_database_from_default_metrics: ...,
  auth: {
    # praefect['auth_token']
    token: ...,
    # praefect['auth_transitioning']
    transitioning: ...,
  },
  logging: {
    # praefect['logging_format']
    format: ...,
    # praefect['logging_level']
    level: ...,
  },
  failover: {
    # praefect['failover_enabled']
    enabled: ...,
  },
  background_verification: {
    # praefect['background_verification_delete_invalid_records']
    delete_invalid_records: ...,
    # praefect['background_verification_verification_interval']
    #
    # IMPORTANT:
    # As part of reconfiguring Praefect, disable this feature.
    # Read about this above.
    #
    verification_interval: 0,
  },
  reconciliation: {
    # praefect['reconciliation_scheduling_interval']
    scheduling_interval: ...,
    # praefect['reconciliation_histogram_buckets']. The old value was configured as a string
    # such as '[0, 1, 2]'. The new value must be an array like [0, 1, 2].
    histogram_buckets: ...,
  },
  tls: {
    # praefect['certificate_path']
    certificate_path: ...,
   # praefect['key_path']
    key_path: ...,
  },
  database: {
    # praefect['database_host']
    host: ...,
    # praefect['database_port']
    port: ...,
    # praefect['database_user']
    user: ...,
    # praefect['database_password']
    password: ...,
    # praefect['database_dbname']
    dbname: ...,
    # praefect['database_sslmode']
    sslmode: ...,
    # praefect['database_sslcert']
    sslcert: ...,
    # praefect['database_sslkey']
    sslkey: ...,
    # praefect['database_sslrootcert']
    sslrootcert: ...,
    session_pooled: {
      # praefect['database_direct_host']
      host: ...,
      # praefect['database_direct_port']
      port: ...,
      # praefect['database_direct_user']
      user: ...,
      # praefect['database_direct_password']
      password: ...,
      # praefect['database_direct_dbname']
      dbname: ...,
      # praefect['database_direct_sslmode']
      sslmode: ...,
      # praefect['database_direct_sslcert']
      sslcert: ...,
      # praefect['database_direct_sslkey']
      sslkey: ...,
      # praefect['database_direct_sslrootcert']
      sslrootcert: ...,
    }
  },
  sentry: {
    # praefect['sentry_dsn']
    sentry_dsn: ...,
    # praefect['sentry_environment']
    sentry_environment: ...,
  },
  prometheus: {
    # praefect['prometheus_grpc_latency_buckets']. The old value was configured as a string
    # such as '[0, 1, 2]'. The new value must be an array like [0, 1, 2].
    grpc_latency_buckets: ...,
  },
  # praefect['graceful_stop_timeout']
  graceful_stop_timeout: ...,
  # praefect['virtual_storages']. The old value was a hash map but the new value is an array.
  virtual_storage: [
    {
      # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]. The name was previously the key in
      # the 'virtual_storages' hash.
      name: ...,
      # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]. The old value was a hash map
      # but the new value is an array.
      node: [
        {
          # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]. Use NODE_NAME key as the
          # storage.
          storage: ...,
          # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]['address'].
          address: ...,
          # praefect['virtual_storages'][VIRTUAL_STORAGE_NAME]['nodes'][NODE_NAME]['token'].
          token: ...,
        },
      ],
    }
  ]
}
```

### 2番目のデータベース接続を無効にする

GitLab 16.0では、GitLabはデフォルトで、同じPostgreSQLデータベースを指す2つのデータベース接続を使用するようになっています。

PostgreSQLでは、より大きな`max_connections`の値を設定する必要があるかもしれません。[Rakeタスクでこれが必要かどうかを確認できます](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections)。

PgBouncerをデプロイしている場合:

- PgBouncerサーバーのフロントエンドプール（ファイルハンドル制限と`max_client_conn`を含む）を、[大きくする必要があるかもしれません](../../administration/postgresql/pgbouncer.md#fine-tuning)。
- PgBouncerはシングルスレッドです。追加の接続により、単一のPgBouncerデーモンが完全に飽和する可能性があります。この問題に対処するため、すべてのスケールされたGitLabデプロイに対して、[ロードバランスされた3台のPgBouncerサーバーを実行することをおすすめします](../../administration/reference_architectures/5k_users.md#configure-pgbouncer)。

インストールタイプに基づく手順に従って、単一のデータベース接続に戻します。

{{< tabs >}}

{{< tab title="LinuxパッケージとDocker" >}}

1. `/etc/gitlab/gitlab.rb`にこの設定を追加します。

   ```ruby
   gitlab_rails['databases']['ci']['enable'] = false
   ```

1. `gitlab-ctl reconfigure`を実行します。

マルチノード環境では、この設定はすべてのRailsおよびSidekiqノードで更新する必要があります。

{{< /tab >}}

{{< tab title="Helmチャート (Kubernetes)" >}}

`ci.enabled`キーを`false`に設定します。

```yaml
global:
  psql:
    ci:
      enabled: false
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`config/database.yml`から`ci:`セクションを削除します。

{{< /tab >}}

{{< /tabs >}}

## 長時間実行されるユーザータイプのデータ変更

GitLab 16.0は、`users`テーブルに多数のレコードを持つ大規模なGitLabインスタンスに必要な経由地点です。

しきい値は**30,000ユーザー**で、以下が含まれます。

- アクティブ、ブロック、承認保留中など、あらゆる状態のデベロッパーおよびその他のユーザー。
- プロジェクトおよびグループアクセストークンのボットアカウント。

GitLab 16.0では、[バッチバックグラウンド移行](../background_migrations.md#batched-background-migrations)が導入され、[`user_type`値を`NULL`から`0`に移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115849)します。この移行は、大規模なGitLabでは、完了するまでに数日かかる場合があります。16.1.0以降にアップグレードする前に、移行が正常に完了していることを確認してください。

GitLab 16.1では、16.0`MigrateHumanUserType`バックグラウンド移行が完了していることを確認する`FinalizeUserTypeMigration`移行が導入され、完了していない場合は、アップグレード中に16.0の変更を同期的に実行します。

GitLab 16.2では、[`NOT NULL`データベース制約を実装](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122454)し、16.0の移行が完了していない場合には失敗します。

16.0がスキップされた場合（または16.0の移行が完了していない場合）、Linuxパッケージ(Omnibus)とDockerの後続のアップグレードは1時間後に失敗する可能性があります。

```plaintext
FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails]
[..]
Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
```

[この問題にはフィックスフォワードの回避策があります](../package/package_troubleshooting.md#mixlibshelloutcommandtimeout-rails_migrationgitlab-rails--command-timed-out-after-3600s)。

回避策がデータベースの変更を完了している間、GitLab使用できない状態になり、`500`エラーを生成します。このエラーは、SidekiqとPumaがデータベーススキーマと互換性のないアプリケーションコードを実行していることが原因で発生します。

回避策のプロセスの最後に、SidekiqとPumaが再起動し、その問題が解決されます。

## 16.2以降へのアップグレード時の未定義列のエラー

GitLab 15.11のバグにより、Self-Managedインスタンスでのデータベース変更が誤って無効になりました。詳細については、[イシュー408835](https://gitlab.com/gitlab-org/gitlab/-/issues/408835)を参照してください。

GitLabインスタンスが最初に15.11.0、15.11.1、または15.11.2にアップグレードされた場合、データベーススキーマが正しくないため、GitLab 16.2以降へのアップグレードでエラーが発生します。データベースの変更には、以前の変更が有効になっている必要があります。

```plaintext
PG::UndefinedColumn: ERROR:  column "id_convert_to_bigint" of relation "ci_build_needs" does not exist
LINE 1: ...db_config_name:main*/ UPDATE "ci_build_needs" SET "id_conver...
```

GitLab 15.11.3ではこのバグが送信されましたが、以前の15.11リリースをすでに実行しているインスタンスでは問題は修正されません。

インスタンスが影響を受けているかどうか不明な場合は、[データベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)で列を確認してください。

```sql
select pg_typeof (id_convert_to_bigint) from public.ci_build_needs limit 1;
```

回避策が必要な場合、このクエリは失敗します。

```plaintext
ERROR:  column "id_convert_to_bigintd" does not exist
LINE 1: select pg_typeof (id_convert_to_bigintd) from public.ci_buil...
```

影響を受けていないインスタンスは次を返します。

```plaintext
 pg_typeof
-----------
 bigint
```

この問題の回避策は、GitLabインスタンスのデータベーススキーマが最近作成されたかどうかによって異なります。

| インストール | 回避策 |
| -------------------- | ---------- |
| 15.9以前      | [15.9](#workaround-instance-created-with-159-or-earlier) |
| 15.10                | [15.10](#workaround-instance-created-with-1510) |
| 15.11                | [15.11](#workaround-instance-created-with-1511) |

ほとんどのインスタンスは15.9の手順を使用する必要があります。ごく最近のインスタンスのみ、15.10または15.11の手順が必要です。バックアップと復元とを使用してGitLabを移行した場合、データベーススキーマは元のインスタンスのものです。ソースインスタンスに基づいて回避策を選択します。

次のセクションのコマンドは、Linuxパッケージのインストール用であり、他のインストールタイプとは異なります。

{{< tabs >}}

{{< tab title="Docker" >}}

- `sudo`を省略
- GitLabコンテナにShellで接続し、同じコマンドを実行します。

  ```shell
  docker exec -it <container-id> bash
  ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

- `sudo gitlab-rake`の代わりに`sudo -u git -H bundle exec rake RAILS_ENV=production`を使用します
- [PostgreSQLデータベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)でSQLを実行します

{{< /tab >}}

{{< tab title="Helmチャート (Kubernetes)" >}}

- `sudo`を省略します。
- `toolbox`ポッドにShellで接続し、Rakeコマンドを実行します。`gitlab-rake`が`PATH`にない場合は、`/usr/local/bin`にあります。
  - 詳細については、[Kubernetesチートシート](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information)を参照してください。
- [PostgreSQLデータベースコンソール](../../administration/troubleshooting/postgresql.md#start-a-database-console)でSQLを実行します

{{< /tab >}}

{{< /tabs >}}

### 回避策: 15.9以前に作成されたインスタンス

```shell
# Restore schema
sudo gitlab-psql -c "DELETE FROM schema_migrations WHERE version IN ('20230130175512', '20230130104819');"
sudo gitlab-rake db:migrate:up VERSION=20230130175512
sudo gitlab-rake db:migrate:up VERSION=20230130104819

# Re-schedule background migrations
sudo gitlab-rake db:migrate:down VERSION=20230130202201
sudo gitlab-rake db:migrate:down VERSION=20230130110855
sudo gitlab-rake db:migrate:up VERSION=20230130202201
sudo gitlab-rake db:migrate:up VERSION=20230130110855
```

### 回避策: 15.10に作成されたインスタンス

```shell
# Restore schema for sent_notifications
sudo gitlab-psql -c "DELETE FROM schema_migrations WHERE version = '20230130175512';"
sudo gitlab-rake db:migrate:up VERSION=20230130175512

# Re-schedule background migration for sent_notifications
sudo gitlab-rake db:migrate:down VERSION=20230130202201
sudo gitlab-rake db:migrate:up VERSION=20230130202201

# Restore schema for ci_build_needs
sudo gitlab-rake db:migrate:down VERSION=20230321163547
sudo gitlab-psql -c "INSERT INTO schema_migrations (version) VALUES ('20230321163547');"
```

### 回避策: 15.11に作成されたインスタンス

```shell
# Restore schema for sent_notifications
sudo gitlab-rake db:migrate:down VERSION=20230411153310
sudo gitlab-psql -c "INSERT INTO schema_migrations (version) VALUES ('20230411153310');"

# Restore schema for ci_build_needs
sudo gitlab-rake db:migrate:down VERSION=20230321163547
sudo gitlab-psql -c "INSERT INTO schema_migrations (version) VALUES ('20230321163547');"
```

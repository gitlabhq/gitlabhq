---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部PostgreSQLサービスを使用したGitLabの設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabをクラウドプロバイダーでホストしている場合、オプションでPostgreSQLのマネージドサービスを使用できます。たとえば、AWSでは、PostgreSQLを実行するマネージドAmazon Relational Database Service（RDS）が提供されています。

または、Linuxパッケージとは別に、PostgreSQLのインスタンスまたはクラスターを自分で管理することもできます。

クラウドマネージドサービスを使用するか、独自のPostgreSQLインスタンスを提供する場合は、[データベース要件ドキュメント](../../install/requirements.md#postgresql)に従ってPostgreSQLを設定してください。

## GitLab Railsデータベース {#gitlab-rails-database}

外部PostgreSQLサーバーをセットアップした後:

1. データベースサーバーにログインします。
1. 任意のパスワードを持つ`gitlab`ユーザーをセットアップし、`gitlabhq_production`データベースを作成して、ユーザーにデータベースのオーナーにしてください。この設定例は、[セルフコンパイルインストールドキュメント](../../install/self_compiled/_index.md#7-database)に記載されています。
1. クラウドマネージドサービスを使用している場合は、`gitlab`ユーザーに追加のロールを付与する必要がある場合があります:
   - Amazon RDSには、[`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles)ロールが必要です。
   - Azure Database for PostgreSQLには、[`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql)ロールが必要です。Azure Database for PostgreSQL - Flexible Serverでは、[拡張機能をインストールする前に、許可リストに登録する](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions)必要があります。
   - Google Cloud SQLには、[`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users)ロールが必要です。

   これは、インストールおよびアップグレード中の拡張機能のインストール用です。別の方法として、[拡張機能が手動でインストールされていることを確認し、今後のGitLabアップグレードで発生する可能性のある問題について読んでください](../../install/postgresql_extensions.md)。
1. 外部PostgreSQLサービスの適切な接続の詳細を使用して、GitLabアプリケーションサーバーを`/etc/gitlab/gitlab.rb`ファイルで構成します:

   ```ruby
   # Disable the bundled Omnibus provided PostgreSQL
   postgresql['enable'] = false

   # PostgreSQL connection details
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['db_host'] = '10.1.0.5' # IP/hostname of database server
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_password'] = 'DB password'
   ```

   GitLabマルチノード設定の詳細については、[参照アーキテクチャ](../reference_architectures/_index.md)を参照してください。

1. 変更を有効にするには、GitLabを再設定してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. TCPポートを有効にするには、PostgreSQLを再起動します:

   ```shell
   sudo gitlab-ctl restart
   ```

## コンテナレジストリのメタデータデータベース {#container-registry-metadata-database}

[コンテナレジストリメタデータデータベース](../packages/container_registry_metadata_database.md)を使用する予定がある場合は、レジストリデータベースとユーザーも作成する必要があります。

外部PostgreSQLサーバーをセットアップした後:

1. データベースサーバーにログインします。
1. 次のSQLコマンドを使用して、ユーザーとデータベースを作成します:

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. クラウドマネージドサービスの場合は、必要に応じて追加のロールを付与します:

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azureデータベース" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. コンテナレジストリメタデータデータベースを有効にして使用を開始できるようになりました。

## トラブルシューティング {#troubleshooting}

### `SSL SYSCALL error: EOF detected`エラーを解決する {#resolve-ssl-syscall-error-eof-detected-error}

外部PostgreSQLインスタンスを使用すると、次のようなエラーが表示されることがあります:

```shell
pg_dump: error: Error message from server: SSL SYSCALL error: EOF detected
```

このエラーを解決するには、[PostgreSQLの最小要件](../../install/requirements.md#postgresql)を満たしていることを確認してください。RDSインスタンスを[サポート対象のバージョン](../../install/requirements.md#postgresql)にアップグレードすると、このエラーなしにバックアップを実行できるようになります。詳細については、[issue 64763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763)を参照してください。

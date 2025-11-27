---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Self-ManagedでPostgreSQL拡張機能をインストールおよび管理し、失敗の処理と移行の失敗からの復旧に関するガイダンスを提供します。
title: PostgreSQL拡張機能を管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントでは、外部PostgreSQLデータベースを使用するインストール環境向けのPostgreSQL拡張機能を管理する方法について説明します。

次の拡張機能をメインのGitLabデータベース（`gitlabhq_production`がデフォルト）に読み込む必要があります:

| 拡張機能    | GitLabの最小バージョン |
|--------------|------------------------|
| `pg_trgm`    | 8.6                    |
| `btree_gist` | 13.1                   |
| `plpgsql`    | 11.7                   |
| `amcheck`    | 18.4                   |

[GitLab](../administration/geo/_index.md)を使用している場合は、次の拡張機能をすべてのセカンダリ追跡データベース（`gitlabhq_geo_production`がデフォルト）に読み込む必要があります:

| 拡張機能    | GitLabの最小バージョン |
|--------------|------------------------|
| `plpgsql`    | 9.0                    |

拡張機能をインストールするには、PostgreSQLでユーザーがスーパーユーザー権限を持っている必要があります。通常、GitLabデータベースのユーザーはスーパーユーザーではありません。したがって、通常のデータベース移行を拡張機能のインストールに使用することはできません。代わりに、新しいバージョンのGitLabにアップグレードする前に、拡張機能を手動でインストールする必要があります。

## PostgreSQL拡張機能の手動インストール {#installing-postgresql-extensions-manually}

PostgreSQL拡張機能をインストールするには、次の手順に従ってください:

1. スーパーユーザーを使用して、GitLab PostgreSQLデータベースに接続します。例:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. [`CREATE EXTENSION`](https://www.postgresql.org/docs/16/sql-createextension.html)を使用して、拡張機能（この例では`btree_gist`）をインストールします:

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist
   ```

1. インストールされている拡張機能を確認します:

   ```shell
    gitlabhq_production=# \dx
                                        List of installed extensions
        Name    | Version |   Schema   |                            Description
    ------------+---------+------------+-------------------------------------------------------------------
    amcheck    | 1.3     | public     | functions for verifying relation integrity
    btree_gist | 1.5     | public     | support for indexing common datatypes in GiST
    pg_trgm    | 1.4     | public     | text similarity measurement and index searching based on trigrams
    plpgsql    | 1.0     | pg_catalog | PL/pgSQL procedural language
    (3 rows)
   ```

システムによっては、特定の拡張機能を使用できるようにするために、追加のパッケージ（例：`postgresql-contrib`）をインストールする必要がある場合があります。

## 一般的な失敗シナリオ {#typical-failure-scenarios}

以下は、拡張機能が最初にインストールされていないために、新しいGitLabのインストールが失敗する例です。

```shell
---- Begin output of "bash"  "/tmp/chef-script20210513-52940-d9b1gs" ----
STDOUT: psql:/opt/gitlab/embedded/service/gitlab-rails/db/structure.sql:9: ERROR:  permission denied to create extension "btree_gist"
HINT:  Must be superuser to create this extension.
rake aborted!
failed to execute:
psql -v ON_ERROR_STOP=1 -q -X -f /opt/gitlab/embedded/service/gitlab-rails/db/structure.sql --single-transaction gitlabhq_production
```

以下は、移行の実行前に拡張機能がインストールされていない場合の状況の例です。このシナリオでは、権限が不十分なため、データベース移行で拡張機能`btree_gist`を作成できません。

```shell
== 20200515152649 EnableBtreeGistExtension: migrating =========================
-- execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

GitLab requires the PostgreSQL extension 'btree_gist' installed in database 'gitlabhq_production', but
the database user is not allowed to install the extension.

You can either install the extension manually using a database superuser:

  CREATE EXTENSION IF NOT EXISTS btree_gist

Or, you can solve this by logging in to the GitLab database (gitlabhq_production) using a superuser and running:

    ALTER regular WITH SUPERUSER

This query will grant the user superuser permissions, ensuring any database extensions
can be installed through migrations.
```

失敗した移行から回復するには、スーパーユーザーが拡張機能を手動でインストールし、[データベース移行を再実行](../administration/raketasks/maintenance.md#run-incomplete-database-migrations)してGitLabのアップグレードを完了する必要があります:

```shell
sudo gitlab-rake db:migrate
```

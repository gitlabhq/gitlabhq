---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL拡張機能を管理する
description: GitLab Self-Managedに必要なPostgreSQL拡張機能をインストールします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、すべてのデータベースに特定のPostgreSQL拡張機能を必要とします。必須の拡張機能と最小限のGitLabバージョンのリストについては、[PostgreSQLの要件](../../install/requirements.md#extensions)を参照してください。

拡張機能をインストールするには、PostgreSQLにはスーパーユーザー権限が必要です。GitLabデータベースユーザーは通常スーパーユーザーではないため、GitLabをアップグレードする前に拡張機能を手動でインストールする必要があります。

## 必須の拡張機能をインストールする {#install-required-extensions}

1. スーパーユーザーを使用してGitLab PostgreSQLデータベースに接続します。例:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. 拡張機能（この例では`btree_gist`）を、[`CREATE EXTENSION`](https://www.postgresql.org/docs/16/sql-createextension.html)を使用してインストールします:

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist
   ```

1. インストールされている拡張機能を検証します:

   ```shell
   gitlabhq_production=# \dx
   ```

一部のシステムでは、特定の拡張機能を利用可能にするために、追加のパッケージ（例えば`postgresql-contrib`）をインストールする必要がある場合があります。

## pg_stat_statementsを有効にする {#enable-pg_stat_statements}

`pg_stat_statements`は、遅いデータベースクエリのトラブルシューティングに推奨されます。これを有効にするには、スーパーユーザー権限とPostgreSQLの再起動が必要です。

1. `postgresql.conf`の`shared_preload_libraries`に`pg_stat_statements`を追加します。Linuxパッケージインストールの場合、以下を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. PostgreSQLを再起動します。
1. スーパーユーザーとして拡張機能を作成します:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements
   ```

詳細については、[オプションのクエリ統計データを有効にする](../raketasks/maintenance.md#enable-optional-query-statistics-data)を参照してください。

## トラブルシューティング {#troubleshooting}

PostgreSQL拡張機能を使用しているときに、次の問題が発生する可能性があります。

### 拡張機能が不足しているため移行が失敗する {#migration-fails-because-an-extension-is-missing}

データベースの移行が、拡張機能が不足しているために失敗した場合は、スーパーユーザーとして手動でインストールし、その後移行を再実行します:

```shell
sudo gitlab-rake db:migrate
```

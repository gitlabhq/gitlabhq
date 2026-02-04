---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリメタデータデータベースのトラブルシューティング
description: コンテナレジストリメタデータデータベースに関する問題をトラブルシューティングします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## エラー: `there are pending database migrations` {#error-there-are-pending-database-migrations}

レジストリが更新され、保留中のスキーマの移行がある場合、レジストリは次のエラーメッセージで起動に失敗します:

```shell
FATA[0000] configuring application: there are pending database migrations, use the 'registry database migrate' CLI command to check and apply them
```

この問題を解決するには、[データベースの移行を適用する](container_registry_metadata_database.md#apply-database-migrations)手順に従ってください。

バージョン18.3より前は、バージョンをアップグレードするたびに、データベースの移行を手動で適用する必要があります。

### エラー: `offline garbage collection is no longer possible` {#error-offline-garbage-collection-is-no-longer-possible}

レジストリがメタデータデータベースを使用しており、[オフラインガベージコレクション](container_registry.md#container-registry-garbage-collection)を実行しようとすると、レジストリは次のエラーメッセージで失敗します:

```shell
ERRO[0000] this filesystem is managed by the metadata database, and offline garbage collection is no longer possible, if you are not using the database anymore, remove the file at the lock_path in this log message lock_path=/docker/registry/lockfiles/database-in-use
```

次のいずれかの条件を満たす必要があります。

- オフラインガベージコレクションの使用を停止します。
- メタデータデータベースを使用しなくなった場合は、エラーメッセージに表示されている`lock_path`にある、指定されたロックファイルを削除します。たとえば、`/docker/registry/lockfiles/database-in-use`ファイルを削除します。

### エラー: `cannot execute <STATEMENT> in a read-only transaction` {#error-cannot-execute-statement-in-a-read-only-transaction}

レジストリは、次のエラーメッセージで[データベースの移行の適用](container_registry_metadata_database.md#apply-database-migrations)に失敗する可能性があります:

```shell
err="ERROR: cannot execute CREATE TABLE in a read-only transaction (SQLSTATE 25006)"
```

また、[オンラインガベージコレクション](container_registry.md#performing-garbage-collection-without-downtime)を実行しようとすると、レジストリが次のエラーメッセージで失敗する可能性があります:

```shell
error="processing task: fetching next GC blob task: scanning GC blob task: ERROR: cannot execute SELECT FOR UPDATE in a read-only transaction (SQLSTATE 25006)"
```

読み取り専用トランザクションが無効になっていることを確認するには、PostgreSQLコンソールで`default_transaction_read_only`と`transaction_read_only`の値をチェックする必要があります。例: 

```sql
# SHOW default_transaction_read_only;
 default_transaction_read_only
 -------------------------------
 on
(1 row)

# SHOW transaction_read_only;
 transaction_read_only
 -----------------------
 on
(1 row)
```

これらの値のいずれかが`on`に設定されている場合は、無効にする必要があります:

1. `postgresql.conf`を編集して、次の値を設定します:

   ```shell
   default_transaction_read_only=off
   ```

1. これらの設定を適用するには、Postgresサーバーを再起動します。
1. 該当する場合は、[データベースの移行の適用](container_registry_metadata_database.md#apply-database-migrations)を再度試してください。
1. レジストリ`sudo gitlab-ctl restart registry`を再起動します。

### エラー: `cannot import all repositories while the tags table has entries` {#error-cannot-import-all-repositories-while-the-tags-table-has-entries}

[既存のレジストリメタデータのインポート](container_registry_metadata_database.md#enable-the-database-for-existing-registries)を実行しようとして、次のエラーが発生した場合:

```shell
ERRO[0000] cannot import all repositories while the tags table has entries, you must truncate the table manually before retrying,
see https://docs.gitlab.com/ee/administration/packages/container_registry_metadata_database.html#troubleshooting
common_blobs=true dry_run=false error="tags table is not empty"
```

このエラーは、レジストリデータベースの`tags`テーブルに既存のエントリがある場合に発生します。これは、次の場合に発生する可能性があります:

- [ワンステップインポート](container_registry_metadata_database_one_step_import.md)を試みて、エラーが発生した場合。
- [3段階インポート](container_registry_metadata_database_three_step_import.md)プロセスを試みて、エラーが発生した場合。
- インポートプロセスを意図的に停止した場合。
- 以前のいずれかの操作の後で、インポートを再度実行しようとした場合。
- 誤った設定ファイルに対してインポートを実行した場合。

この問題を解決するには、タグテーブル内の既存のエントリを削除する必要があります。PostgreSQLインスタンスで、テーブルを手動で切り捨てる必要があります:

1. `/etc/gitlab/gitlab.rb`を編集し、メタデータデータベースが無効になっていることを確認します:

   ```ruby
   registry['database'] = {
     'enabled' => false,
   }
   ```

1. PostgreSQLクライアントを使用して、レジストリデータベースに接続します。
1. `tags`テーブルを切り捨てて、既存のエントリをすべて削除します:

   ```sql
   TRUNCATE TABLE tags RESTART IDENTITY CASCADE;
   ```

1. `tags`テーブルを切り捨てた後、インポートプロセスを再度実行してみてください。

### エラー: `database-in-use lockfile exists` {#error-database-in-use-lockfile-exists}

[既存のレジストリメタデータのインポート](container_registry_metadata_database.md#enable-the-database-for-existing-registries)を実行しようとして、次のエラーが発生した場合:

```shell
|  [0s] step two: import tags failed to import metadata: importing all repositories: 1 error occurred:
    * could not restore lockfiles: database-in-use lockfile exists
```

このエラーは、以前にレジストリをインポートし、すべてのリポジトリデータ（ステップ2）のインポートを完了し、`database-in-use`がレジストリファイルシステムに存在することを意味します。この問題が発生した場合は、インポーターを再度実行しないでください。

続行する必要がある場合は、`database-in-use`ロックファイルをファイルシステムから手動で削除する必要があります。ファイルは`/path/to/rootdirectory/docker/registry/lockfiles/database-in-use`にあります。

### エラー: `pre importing all repositories: AccessDenied:` {#error-pre-importing-all-repositories-accessdenied}

[既存のレジストリのインポートを実行](container_registry_metadata_database.md#enable-the-database-for-existing-registries)し、ストレージバックエンドとしてAWS S3を使用している場合、`AccessDenied`エラーが発生する可能性があります:

```shell
/opt/gitlab/embedded/bin/registry database import --step-one /var/opt/gitlab/registry/config.yml
  [0s] step one: import manifests
  [0s] step one: import manifests failed to import metadata: pre importing all repositories: AccessDenied: Access Denied
```

コマンドを実行するユーザーに正しい[スコープの権限](https://docker-docs.uclv.cu/registry/storage-drivers/s3/#s3-permission-scopes)があることを確認してください。

### メタデータ管理の問題が原因でレジストリが起動に失敗しました {#registry-fails-to-start-due-to-metadata-management-issues}

レジストリは、次のいずれかのエラーで起動に失敗する可能性があります:

#### エラー: `registry filesystem metadata in use, please import data before enabling the database` {#error-registry-filesystem-metadata-in-use-please-import-data-before-enabling-the-database}

このエラーは、設定`registry['database'] = { 'enabled' => true}`でデータベースが有効になっているにもかかわらず、メタデータデータベースに[既存のレジストリメタデータをインポートしていない](container_registry_metadata_database.md#enable-the-database-for-existing-registries)場合に発生します。

#### エラー: `registry metadata database in use, please enable the database` {#error-registry-metadata-database-in-use-please-enable-the-database}

このエラーは、メタデータデータベースへの[既存のレジストリメタデータのインポート](container_registry_metadata_database.md#enable-the-database-for-existing-registries)が完了したにもかかわらず、設定でデータベースを有効にしていない場合に発生します。

#### ロックファイルのチェックまたは作成に関する問題 {#problems-checking-or-creating-the-lock-files}

次のいずれかのエラーが発生した場合: 

- `could not check if filesystem metadata is locked`
- `could not check if database metadata is locked`
- `failed to mark filesystem for database only usage`
- `failed to mark filesystem only usage`

レジストリは、設定された`rootdirectory`にアクセスできません。以前に動作していたレジストリがある場合は、このエラーが発生する可能性は低いです。設定ミスの問題がないかエラーログをレビューします。

### タグを削除した後もストレージ使用量が減少しない {#storage-usage-not-decreasing-after-deleting-tags}

デフォルトでは、オンラインガベージコレクターは、関連付けられているすべてのタグが削除された時点から48時間後に、参照されていないレイヤーの削除を開始します。この遅延により、イメージとタグに関連付けられる前にレイヤーがレジストリにプッシュされるため、ガベージコレクターが長時間実行されるイメージのプッシュや中断されたイメージのプッシュを妨げることがなくなります。

### エラー: `permission denied for schema public (SQLSTATE 42501)` {#error-permission-denied-for-schema-public-sqlstate-42501}

レジストリの移行またはGitLabのアップグレード中に、次のいずれかのエラーが発生する可能性があります:

- `ERROR: permission denied for schema public (SQLSTATE 42501)`
- `ERROR: relation "public.blobs" does not exist (SQLSTATE 42P01)`

これらのタイプのエラーは、PostgreSQL 15+の変更によるものであり、セキュリティ上の理由から、パブリックスキーマに対するデフォルトのCREATE特権が削除されています。デフォルトでは、データベースオーナーのみがPostgreSQL 15+のパブリックスキーマにオブジェクトを作成できます。

エラーを解決するには、次のコマンドを実行して、レジストリデータベースのオーナー特権をレジストリユーザーに付与します:

```sql
ALTER DATABASE <registry_database_name> OWNER TO <registry_user>;
```

これにより、レジストリユーザーは、テーブルを作成し、移行を正常に実行するために必要な許可が付与されます。

### エラー: `database-in-use and filesystem-in-use lockfiles present` {#error-database-in-use-and-filesystem-in-use-lockfiles-present}

このエラーは、設定されたレジストリストレージに`filesystem-in-use`と`database-in-use`のロックファイルの両方が存在し、あいまいなレジストリ状態を示している場合に発生します。

このエラーを解決するには、レジストリがメタデータデータベースと従来のメタデータストレージのどちらを使用するように設計されているかを判断する必要があります。

レジストリがメタデータデータベースを使用するように設計されている可能性が高いのは、次の場合です:

- 以前に[インポート処理](container_registry_metadata_database.md#how-to-choose-the-right-import-method)のいずれかを実行したことがある。
- レジストリの設定がレジストリが有効になっていることを示している。

レジストリが有効になっているかどうかを確認するには、`/etc/gitlab/gitlab.rb`にあるファイルを確認してください:

```ruby
registry['database'] = {
  'enabled' => true,
}
```

レジストリがデータベースを使用するように設計されていることを確認したら、`/docker/registry/lockfiles/filesystem-in-use`に存在する、設定されたレジストリストレージにある`filesystem-in-use`ロックファイルを削除します。

または、上記のシナリオが当てはまらず、レジストリが従来のメタデータストレージを使用するように設計されている場合は、`/docker/registry/lockfiles/database-in-use`にある`database-in-use`ロックファイルを削除します。

最後に、`REGISTRY_FF_ENFORCE_LOCKFILES`コンテナレジストリの機能フラグを`false`に設定して、ロックファイルのチェックを無効にすることができます。これによりチェックは無効になりますが、このエラーはレジストリデータの整合性を確保するためのものであり、使用しているメタデータストレージを確認することをお勧めします。`REGISTRY_FF_ENFORCE_LOCKFILES`は[非推奨](https://gitlab.com/gitlab-org/container-registry/-/issues/1439)であり、GitLab 18.10で削除される予定です。詳細については、[コンテナレジストリの機能フラグ](container_registry.md#container-registry-feature-flags)を参照してください。

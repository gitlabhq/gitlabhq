---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabバックアップのトラブルシューティング
---

GitLabのバックアップを取る際に、次の問題が発生する可能性があります。

## シークレットファイルが失われた場合 {#when-the-secrets-file-is-lost}

[シークレットファイルをバックアップ](backup_gitlab.md#storing-configuration-files)していなかった場合、GitLabを正常に動作させるにはいくつかの手順を完了する必要があります。

シークレットファイルは、必要な機密情報を含むカラムの暗号化キーを保存する役割を担っています。キーが失われると、GitLabはこれらのカラムを復号化することができず、次の項目へのアクセスが妨げられます:

- [CI/CD変数](../../ci/variables/_index.md)
- [Kubernetes / GCPインテグレーション](../../user/infrastructure/clusters/_index.md)
- [カスタムページドメイン](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [プロジェクトエラー追跡](../../operations/error_tracking.md)
- [Runner認証](../../ci/runners/_index.md)
- [プロジェクトミラーリング](../../user/project/repository/mirror/_index.md)
- [インテグレーション](../../user/project/integrations/_index.md)
- [Webhook](../../user/project/integrations/webhooks.md)
- [デプロイトークン](../../user/project/deploy_tokens/_index.md)

CI/CD変数およびRunner認証のようなケースでは、次のような予期せぬ動作が発生する可能性があります:

- スタックしたジョブ。
- 500エラー。

この場合、CI/CD変数とRunner認証のすべてのトークンをリセットする必要があります。これについては、以下のセクションで詳しく説明します。トークンをリセットした後、プロジェクトにアクセスできるようになり、ジョブが再び実行を開始します。

> [!warning]
> このセクションの手順は、以前にリストされた項目でデータ損失につながる可能性があります。PremiumまたはUltimateのお客様の場合は、[Support Request](https://support.gitlab.com/hc/en-us/requests/new)をオープンすることを検討してください。

### すべての値が復号化可能であることを検証します {#verify-that-all-values-can-be-decrypted}

[Rakeタスク](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)を使用して、データベースに復号化できない値が含まれているかどうかを判断できます。

### バックアップを取る {#take-a-backup}

失われたシークレットファイルを回避するには、GitLabデータを直接変更する必要があります。

> [!warning]
> 変更を試みる前に、必ず完全なデータベースバックアップを作成してください。

### ユーザーの2要素認証（2FA）を無効にする {#disable-user-two-factor-authentication-2fa}

2FAが有効になっているユーザーは、GitLabにサインインできません。その場合、[すべてのユーザーの2FAを無効](../../security/two_factor_authentication.md#for-all-users)にする必要があります。その後、ユーザーは2FAを再アクティブ化する必要があります。

### CI/CD変数をリセットする {#reset-cicd-variables}

1. データベースコンソールに入ります:

   Linuxパッケージ（Omnibus）の場合: 

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. `ci_group_variables`および`ci_variables`テーブルを調べます:

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   これらは削除する必要がある変数です。

1. すべての変数を削除します:

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. 特定のグループまたはプロジェクトから削除したい変数がわかっている場合は、`WHERE`ステートメントを含めて`DELETE`で指定できます:

   ```sql
   DELETE FROM ci_group_variables WHERE group_id = <GROUPID>;
   DELETE FROM ci_variables WHERE project_id = <PROJECTID>;
   ```

変更を有効にするには、GitLabを再構成または再起動する必要がある場合があります。

### Runner登録トークンをリセットする {#reset-runner-registration-tokens}

1. データベースコンソールに入ります:

   Linuxパッケージ（Omnibus）の場合: 

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. プロジェクト、グループ、およびインスタンス全体のすべてのトークンをクリアします:

   > [!warning]
   > 最終的な`UPDATE`操作は、Runnerが新しいジョブを受け取れないようにします。新しいRunnerを登録する必要があります。

   ```sql
   -- Clear project tokens
   UPDATE projects SET runners_token = null, runners_token_encrypted = null;
   -- Clear group tokens
   UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
   -- Clear instance tokens
   UPDATE application_settings SET runners_registration_token_encrypted = null;
   -- Clear key used for JWT authentication
   -- This may break the $CI_JWT_TOKEN job variable:
   -- https://gitlab.com/gitlab-org/gitlab/-/issues/325965
   UPDATE application_settings SET encrypted_ci_jwt_signing_key = null;
   -- Clear runner tokens
   UPDATE ci_runners SET token = null, token_encrypted = null;
   ```

### 保留中のパイプラインジョブをリセットする {#reset-pending-pipeline-jobs}

1. データベースコンソールに入ります:

   Linuxパッケージ（Omnibus）の場合: 

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. 保留中のジョブのすべてのトークンをクリアします:

   GitLab 15.3以前の場合:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token = null, token_encrypted = null;
   ```

   GitLab 15.4以降の場合:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token_encrypted = null;
   ```

残りの機能についても同様の戦略を採用できます。復号化できないデータを削除することで、GitLabを操作状態に戻し、失われたデータを手動で置き換えることができます。

### インテグレーションとWebhookを修正する {#fix-integrations-and-webhooks}

シークレットを紛失した場合、[インテグレーション設定](../../user/project/integrations/_index.md)ページと[Webhook設定](../../user/project/integrations/webhooks.md)ページに`500`エラーメッセージが表示される場合があります。失われたシークレットは、以前に構成されたインテグレーションまたはWebhookを持つプロジェクトのリポジトリにアクセスしようとしたときに、`500`エラーを生成する可能性もあります。

修正するには、影響を受けるテーブル（暗号化されたカラムを含むもの）を切り詰めます。これにより、構成されているすべてのインテグレーション、Webhook、および関連するメタデータが削除されます。データを削除する前に、シークレットが根本原因であることを検証する必要があります。

1. データベースコンソールに入ります:

   Linuxパッケージ（Omnibus）の場合: 

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. 次のテーブルを切り詰めます:

   ```sql
   -- truncate web_hooks table
   TRUNCATE integrations, chat_names, issue_tracker_data, jira_tracker_data, slack_integrations, web_hooks, zentao_tracker_data, web_hook_logs CASCADE;
   ```

## コンテナレジストリは復元されません {#container-registry-is-not-restored}

[コンテナレジストリ](../../user/packages/container_registry/_index.md)を使用する環境から、コンテナレジストリが有効になっていない新しくインストールされた環境にバックアップを復元する場合、コンテナレジストリは復元されません。

コンテナレジストリも復元するには、バックアップを復元する前に新しい環境で[それを有効にする](../packages/container_registry.md#enable-the-container-registry)必要があります。

## コンテナレジストリへのプッシュが、バックアップから復元した後に失敗する {#container-registry-push-failures-after-restoring-from-a-backup}

[コンテナレジストリ](../../user/packages/container_registry/_index.md)を使用している場合、レジストリデータの復元後にLinuxパッケージ（Omnibus）インスタンスでバックアップを復元すると、レジストリへのプッシュが失敗する可能性があります。

これらの失敗は、レジストリログのパーミッションの問題を示しており、次のようになります:

```plaintext
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

この問題は、権限のないユーザー`git`として復元が実行されていることが原因です。復元プロセス中にレジストリファイルに正しい所有権を割り当てることができません（[イシュー #62759](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759 "Incorrect permissions on registry filesystem after restore")）。

レジストリを再び機能させるには:

```shell
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

レジストリのデフォルトのファイルシステムの場所を変更した場合は、`/var/opt/gitlab/gitlab-rails/shared/registry/docker`の代わりにカスタムの場所に対して`chown`を実行します。

## Gzipエラーによりバックアップが失敗する {#backup-fails-to-complete-with-gzip-error}

バックアップの実行中に、Gzipエラーメッセージが表示される場合があります:

```shell
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

この問題が発生した場合は、次の点を確認してください:

- Gzip操作に十分なディスクスペースがあることを確認してください。[デフォルト](backup_gitlab.md#backup-strategy-option)戦略を使用するバックアップの場合、バックアップ作成時にインスタンスサイズの半分程度の空きディスクスペースが必要となることは珍しくありません。
- NFSが使用されている場合は、マウントオプション`timeout`が設定されているかどうかを確認してください。デフォルトは`600`であり、これを小さい値に変更するとこのエラーが発生します。

## `File name too long`エラーによりバックアップが失敗する {#backup-fails-with-file-name-too-long-error}

バックアップ中に、`File name too long`エラー（[イシュー #354984](https://gitlab.com/gitlab-org/gitlab/-/issues/354984)）が発生する場合があります。例: 

```plaintext
Problem: <class 'OSError: [Errno 36] File name too long:
```

この問題により、バックアップスクリプトが完了できなくなります。この問題を解決するには、問題の原因となっているファイル名を切り詰める必要があります。ファイル拡張子を含め、最大246文字が許可されます。

> [!warning]
> このセクションの手順は、データ損失につながる可能性があります。すべての手順は、指定された順序で厳密に実行する必要があります。PremiumまたはUltimateのお客様の場合は、[Support Request](https://support.gitlab.com/hc/en-us/requests/new)をオープンすることを検討してください。

エラーを解決するためのファイル名の切り詰めには、次のものが含まれます:

- データベースで追跡されていないリモートアップロードファイルをクリーンアップします。
- データベース内のファイル名を切り詰めます。
- バックアップタスクを再実行します。

### リモートアップロードファイルをクリーンアップする {#clean-up-remote-uploaded-files}

既知の[イシュー](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45425)により、親リソースが削除された後もオブジェクトストアのアップロードが残っていました。このイシューは[解決されました](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18698)。

これらのファイルを修正するには、ストレージにあるが`uploads`データベーステーブルで追跡されていないすべてのリモートアップロードファイルをクリーンアップする必要があります。

1. GitLabデータベースに存在しない場合に、失われたファイル用ディレクトリに移動できるすべてのオブジェクトストアアップロードファイルを一覧表示します:

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
   ```

1. これらのファイルを削除し、参照されていないすべてのアップロードファイルを削除してもよろしければ、次を実行します:

   > [!warning]
   > 次の操作は元に戻せません。

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production DRY_RUN=false
   ```

### データベースで参照されているファイル名を切り詰める {#truncate-the-filenames-referenced-by-the-database}

問題の原因となっている、データベースで参照されているファイルを切り詰める必要があります。データベースで参照されているファイル名は、次の場所に保存されます:

- `uploads`テーブル内。
- 見つかった参照内。他のデータベーステーブルおよびカラムから見つかった参照。
- ファイルシステム上。

`uploads`テーブル内のファイル名を切り詰めます:

1. データベースコンソールに入ります:

   Linuxパッケージ（Omnibus）の場合: 

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. `uploads`テーブルで、246文字より長いファイル名を検索します:

   次のクエリは、0から10000のバッチで、ファイル名が246文字を超える`uploads`レコードを選択します。これにより、数千のレコードを持つ大規模なGitLabインスタンスでのパフォーマンスが向上します。

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, id, path
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   SELECT
      u.id,
      u.path,
      -- Current filename
      (regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] AS current_filename,
      -- New filename
      CONCAT(
         LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
         COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
      ) AS new_filename,
      -- New path
      CONCAT(
         COALESCE((regexp_match(u.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      ) AS new_path
   FROM uploads_with_long_filenames AS u
   WHERE u.row_id > 0 AND u.row_id <= 10000;
   ```

   出力例:

   ```postgresql
   -[ RECORD 1 ]----+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   id               | 34
   path             | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
   current_filename | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
   new_filename     | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
   new_path         | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
   ```

   各項目の説明は以下のとおりです: 

   - `current_filename`: 246文字より長いファイル名。
   - `new_filename`: 最大246文字に切り詰められたファイル名。
   - `new_path`: `new_filename`（切り詰められた）を考慮した新しいパス。

   バッチ結果を検証した後、次の数値シーケンス（10000から20000）を使用してバッチサイズ（`row_id`）を変更する必要があります。`uploads`テーブルの最後のレコードに到達するまでこのプロセスを繰り返します。

1. `uploads`テーブルで見つかったファイルを、長いファイル名から新しく切り詰められたファイル名に名前変更します。次のクエリは更新をロールバックし、トランザクションラッパーで安全に結果を確認できるようにします:

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   BEGIN;
   WITH updated_uploads AS (
      UPDATE uploads
      SET
         path =
         CONCAT(
            COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
            CONCAT(
               LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
               COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
            )
         )
      FROM
         uploads_with_long_filenames AS updatable_uploads
      WHERE
         uploads.id = updatable_uploads.id
      AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000
      RETURNING uploads.*
   )
   SELECT id, path FROM updated_uploads;
   ROLLBACK;
   ```

   バッチ更新結果を検証した後、次の数値シーケンス（10000から20000）を使用してバッチサイズ（`row_id`）を変更する必要があります。`uploads`テーブルの最後のレコードに到達するまでこのプロセスを繰り返します。

1. 前のクエリからの新しいファイル名が期待されるものであることを検証します。前の手順で見つかったレコードを246文字に切り詰めることを確実にする場合は、次を実行します:

   > [!warning]
   > 次の操作は元に戻せません。

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   UPDATE uploads
   SET
   path =
      CONCAT(
         COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      )
   FROM
   uploads_with_long_filenames AS updatable_uploads
   WHERE
   uploads.id = updatable_uploads.id
   AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000;
   ```

   バッチ更新が完了したら、次の数値シーケンス（10000から20000）を使用してバッチサイズ（`updatable_uploads.row_id`）を変更する必要があります。`uploads`テーブルの最後のレコードに到達するまでこのプロセスを繰り返します。

見つかった参照内のファイル名を切り詰めます:

1. これらのレコードがどこかで参照されているかどうかを確認します。これを行う1つの方法は、データベースをダンプし、親ディレクトリ名とファイル名を検索することです:

   1. データベースをダンプするには、次のコマンドを例として使用できます:

      ```shell
      pg_dump -h /var/opt/gitlab/postgresql/ -d gitlabhq_production > gitlab-dump.tmp
      ```

   1. 次に、`grep`コマンドを使用して参照を検索できます。親ディレクトリとファイル名を組み合わせるのが良い方法です。例: 

      ```shell
      grep public/alongfilenamehere.txt gitlab-dump.tmp
      ```

1. `uploads`テーブルをクエリして取得した新しいファイル名を使用して、それらの長いファイル名を置き換えます。

ファイルシステム上のファイル名を切り詰めます。ファイルシステム内のファイルを、`uploads`テーブルをクエリして取得した新しいファイル名に手動で名前変更する必要があります。

### バックアップタスクを再実行する {#re-run-the-backup-task}

以前のすべての手順に従った後、バックアップタスクを再実行します。

## `pg_stat_statements`が以前に有効になっていた場合にデータベースバックアップの復元が失敗する {#restoring-database-backup-fails-when-pg_stat_statements-was-previously-enabled}

GitLabのPostgreSQLデータベースバックアップには、以前にデータベースで有効にされていた拡張機能を有効にするために必要なすべてのSQLステートメントが含まれています。

`pg_stat_statements`拡張機能は、`superuser`ロールを持つPostgreSQLユーザーのみが有効または無効にできます。復元プロセスは限られたパーミッションを持つデータベースユーザーを使用するため、次のSQLステートメントを実行できません:

```sql
DROP EXTENSION IF EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
```

`pg_stats_statements`拡張機能を持たないPostgreSQLインスタンスでバックアップを復元しようとすると、次のエラーメッセージが表示されます:

```plaintext
ERROR: permission denied to create extension "pg_stat_statements"
HINT: Must be superuser to create this extension.
ERROR: extension "pg_stat_statements" does not exist
```

`pg_stats_statements`拡張機能が有効になっているインスタンスで復元しようとすると、クリーンアップステップが次の同様のエラーメッセージで失敗します:

```plaintext
rake aborted!
ActiveRecord::StatementInvalid: PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Caused by:
PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:db:drop_tables
(See full trace by running task with --trace)
```

### ダンプファイルが`pg_stat_statements`を含むのを防ぐ {#prevent-the-dump-file-to-include-pg_stat_statements}

バックアップバンドルの一部であるPostgreSQLダンプファイルに拡張機能が含まれるのを防ぐには、`public`スキーマを除く任意のスキーマで拡張機能を有効にします:

```sql
CREATE SCHEMA adm;
CREATE EXTENSION pg_stat_statements SCHEMA adm;
```

拡張機能が以前に`public`スキーマで有効になっていた場合は、新しいスキーマに移動します:

```sql
CREATE SCHEMA adm;
ALTER EXTENSION pg_stat_statements SET SCHEMA adm;
```

スキーマを変更した後で`pg_stat_statements`データをクエリするには、ビュー名に新しいスキーマをプレフィックスとして付加します:

```sql
SELECT * FROM adm.pg_stat_statements limit 0;
```

`public`スキーマで有効になっていることを期待するサードパーティのモニタリングソリューションと互換性を持たせるには、`search_path`に含める必要があります:

```sql
set search_path to public,adm;
```

### 既存のダンプファイルを修正して`pg_stat_statements`への参照を削除する {#fix-an-existing-dump-file-to-remove-references-to-pg_stat_statements}

既存のバックアップファイルを修正するには、次の変更を行います:

1. バックアップから次のファイルを抽出します: `db/database.sql.gz`。
1. ファイルを解凍するか、圧縮された状態を処理できるエディタを使用します。
1. 次の行、または同様の行を削除します:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
   ```

   ```sql
   COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';
   ```

1. 変更を保存し、ファイルを再圧縮します。
1. 変更された`db/database.sql.gz`でバックアップファイルを更新します。

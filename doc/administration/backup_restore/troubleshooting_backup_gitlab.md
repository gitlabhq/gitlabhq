---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab backups
---

When you back up GitLab, you might encounter the following issues.

## When the secrets file is lost

If you didn't [back up the secrets file](../backup_restore/backup_gitlab.md#storing-configuration-files), you
must complete several steps to get GitLab working properly again.

The secrets file is responsible for storing the encryption key for the columns
that contain required, sensitive information. If the key is lost, GitLab can't
decrypt those columns, preventing access to the following items:

- [CI/CD variables](../../ci/variables/_index.md)
- [Kubernetes / GCP integration](../../user/infrastructure/clusters/_index.md)
- [Custom Pages domains](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [Project error tracking](../../operations/error_tracking.md)
- [Runner authentication](../../ci/runners/_index.md)
- [Project mirroring](../../user/project/repository/mirror/_index.md)
- [Integrations](../../user/project/integrations/_index.md)
- [Web hooks](../../user/project/integrations/webhooks.md)
- [Deploy tokens](../../user/project/deploy_tokens/_index.md)

In cases like CI/CD variables and runner authentication, you can experience
unexpected behaviors, such as:

- Stuck jobs.
- 500 errors.

In this case, you must reset all the tokens for CI/CD variables and
runner authentication, which is described in more detail in the following
sections. After resetting the tokens, you should be able to visit your project
and the jobs begin running again.

WARNING:
The steps in this section can potentially lead to **data loss** on the above listed items.
Consider opening a [Support Request](https://support.gitlab.com/hc/en-us/requests/new) if you're a Premium or Ultimate customer.

### Verify that all values can be decrypted

You can determine if your database contains values that can't be decrypted by using a
[Rake task](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

### Take a backup

You must directly modify GitLab data to work around your lost secrets file.

WARNING:
Be sure to create a full database backup before attempting any changes.

### Disable user two-factor authentication (2FA)

Users with 2FA enabled can't sign in to GitLab. In that case, you must
[disable 2FA for everyone](../../security/two_factor_authentication.md#for-all-users),
after which users must reactivate 2FA.

### Reset CI/CD variables

1. Enter the database console:

   For the Linux package (Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Examine the `ci_group_variables` and `ci_variables` tables:

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   These are the variables that you need to delete.

1. Delete all variables:

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. If you know the specific group or project from which you wish to delete variables, you can include a `WHERE` statement to specify that in your `DELETE`:

   ```sql
   DELETE FROM ci_group_variables WHERE group_id = <GROUPID>;
   DELETE FROM ci_variables WHERE project_id = <PROJECTID>;
   ```

You may need to reconfigure or restart GitLab for the changes to take effect.

### Reset runner registration tokens

1. Enter the database console:

   For the Linux package (Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Clear all tokens for projects, groups, and the entire instance:

   WARNING:
   The final `UPDATE` operation stops the runners from being able to pick
   up new jobs. You must register new runners.

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

### Reset pending pipeline jobs

1. Enter the database console:

   For the Linux package (Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Clear all the tokens for pending jobs:

   For GitLab 15.3 and earlier:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token = null, token_encrypted = null;
   ```

   For GitLab 15.4 and later:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token_encrypted = null;
   ```

A similar strategy can be employed for the remaining features. By removing the
data that can't be decrypted, GitLab can be returned to operation, and the
lost data can be manually replaced.

### Fix integrations and webhooks

If you've lost your secrets, the [integrations settings](../../user/project/integrations/_index.md)
and [webhooks settings](../../user/project/integrations/webhooks.md) pages might display `500` error messages. Lost secrets might also produce `500` errors when you try to access a repository in a project with a previously configured integration or webhook.

The fix is to truncate the affected tables (those containing encrypted columns).
This deletes all your configured integrations, webhooks, and related metadata.
You should verify that the secrets are the root cause before deleting any data.

1. Enter the database console:

   For the Linux package (Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Truncate the following tables:

   ```sql
   -- truncate web_hooks table
   TRUNCATE integrations, chat_names, issue_tracker_data, jira_tracker_data, slack_integrations, web_hooks, zentao_tracker_data, web_hook_logs CASCADE;
   ```

## Container registry is not restored

If you restore a backup from an environment that uses the [container registry](../../user/packages/container_registry/_index.md)
to a newly installed environment where the container registry is not enabled, the container registry is not restored.

To also restore the container registry, you need to [enable it](../packages/container_registry.md#enable-the-container-registry) in the new
environment before you restore the backup.

## Container registry push failures after restoring from a backup

If you use the [container registry](../../user/packages/container_registry/_index.md),
pushes to the registry may fail after restoring your backup on a Linux package (Omnibus)
instance after restoring the registry data.

These failures mention permission issues in the registry logs, similar to:

```plaintext
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

This issue is caused by the restore running as the unprivileged user `git`,
which is unable to assign the correct ownership to the registry files during
the restore process ([issue #62759](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759 "Incorrect permissions on registry filesystem after restore")).

To get your registry working again:

```shell
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

If you changed the default file system location for the registry, run `chown`
against your custom location, instead of `/var/opt/gitlab/gitlab-rails/shared/registry/docker`.

## Backup fails to complete with Gzip error

When running the backup, you may receive a Gzip error message:

```shell
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

If this happens, examine the following:

- Confirm there is sufficient disk space for the Gzip operation. It's not uncommon for backups that
  use the [default strategy](../backup_restore/backup_gitlab.md#backup-strategy-option) to require half the instance size
  in free disk space during backup creation.
- If NFS is being used, check if the mount option `timeout` is set. The
  default is `600`, and changing this to smaller values results in this error.

## Backup fails with `File name too long` error

During backup, you can get the `File name too long` error ([issue #354984](https://gitlab.com/gitlab-org/gitlab/-/issues/354984)). For example:

```plaintext
Problem: <class 'OSError: [Errno 36] File name too long:
```

This problem stops the backup script from completing. To fix this problem, you must truncate the filenames causing the problem. A maximum of 246 characters, including the file extension, is permitted.

WARNING:
The steps in this section can potentially lead to **data loss**. All steps must be followed strictly in the order given.
Consider opening a [Support Request](https://support.gitlab.com/hc/en-us/requests/new) if you're a Premium or Ultimate customer.

Truncating filenames to resolve the error involves:

- Cleaning up remote uploaded files that aren't tracked in the database.
- Truncating the filenames in the database.
- Rerunning the backup task.

### Clean up remote uploaded files

A [known issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45425) caused object store uploads to remain after a parent resource was deleted. This issue was [resolved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18698).

To fix these files, you must clean up all remote uploaded files that are in the storage but not tracked in the `uploads` database table.

1. List all the object store upload files that can be moved to a lost and found directory if they don't exist in the GitLab database:

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
   ```

1. If you are sure you want to delete these files and remove all non-referenced uploaded files, run:

   WARNING:
   The following action is **irreversible**.

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production DRY_RUN=false
   ```

### Truncate the filenames referenced by the database

You must truncate the files referenced by the database that are causing the problem. The filenames referenced by the database are stored:

- In the `uploads` table.
- In the references found. Any reference found from other database tables and columns.
- On the file system.

Truncate the filenames in the `uploads` table:

1. Enter the database console:

   For the Linux package (Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Search the `uploads` table for filenames longer than 246 characters:

   The following query selects the `uploads` records with filenames longer than 246 characters in batches of 0 to 10000. This improves the performance on large GitLab instances with tables having thousand of records.

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

      Output example:

      ```postgresql
      -[ RECORD 1 ]----+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      id               | 34
      path             | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
      current_filename | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
      new_filename     | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
      new_path         | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
      ```

      Where:

      - `current_filename`: a filename that is more than 246 characters long.
      - `new_filename`: a filename that has been truncated to 246 characters maximum.
      - `new_path`: new path considering the `new_filename` (truncated).

   After you validate the batch results, you must change the batch size (`row_id`) using the following sequence of numbers (10000 to 20000). Repeat this process until you reach the last record in the `uploads` table.

1. Rename the files found in the `uploads` table from long filenames to new truncated filenames. The following query rolls back the update so you can check the results safely in a transaction wrapper:

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

   After you validate the batch update results, you must change the batch size (`row_id`) using the following sequence of numbers (10000 to 20000). Repeat this process until you reach the last record in the `uploads` table.

1. Validate that the new filenames from the previous query are the expected ones. If you are sure you want to truncate the records found in the previous step to 246 characters, run the following:

   WARNING:
   The following action is **irreversible**.

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

   After you finish the batch update, you must change the batch size (`updatable_uploads.row_id`) using the following sequence of numbers (10000 to 20000). Repeat this process until you reach the last record in the `uploads` table.

Truncate the filenames in the references found:

1. Check if those records are referenced somewhere. One way to do this is to dump the database and search for the parent directory name and filename:

   1. To dump your database, you can use the following command as an example:

      ```shell
      pg_dump -h /var/opt/gitlab/postgresql/ -d gitlabhq_production > gitlab-dump.tmp
      ```

   1. Then you can search for the references using the `grep` command. Combining the parent directory and the filename can be a good idea. For example:

      ```shell
      grep public/alongfilenamehere.txt gitlab-dump.tmp
      ```

1. Replace those long filenames using the new filenames obtained from querying the `uploads` table.

Truncate the filenames on the file system. You must manually rename the files in your file system to the new filenames obtained from querying the `uploads` table.

### Re-run the backup task

After following all the previous steps, re-run the backup task.

## Restoring database backup fails when `pg_stat_statements` was previously enabled

The GitLab backup of the PostgreSQL database includes all SQL statements required to enable extensions that were
previously enabled in the database.

The `pg_stat_statements` extension can only be enabled or disabled by a PostgreSQL user with `superuser` role.
As the restore process uses a database user with limited permissions, it can't execute the following SQL statements:

```sql
DROP EXTENSION IF EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
```

When trying to restore the backup in a PostgreSQL instance that doesn't have the `pg_stats_statements` extension,
the following error message is displayed:

```plaintext
ERROR: permission denied to create extension "pg_stat_statements"
HINT: Must be superuser to create this extension.
ERROR: extension "pg_stat_statements" does not exist
```

When trying to restore in an instance that has the `pg_stats_statements` extension enabled, the cleaning up step
fails with an error message similar to the following:

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

### Prevent the dump file to include `pg_stat_statements`

To prevent the inclusion of the extension in the PostgreSQL dump file that is part of the backup bundle,
enable the extension in any schema except the `public` schema:

```sql
CREATE SCHEMA adm;
CREATE EXTENSION pg_stat_statements SCHEMA adm;
```

If the extension was previously enabled in the `public` schema, move it to a new one:

```sql
CREATE SCHEMA adm;
ALTER EXTENSION pg_stat_statements SET SCHEMA adm;
```

To query the `pg_stat_statements` data after changing the schema, prefix the view name with the new schema:

```sql
SELECT * FROM adm.pg_stat_statements limit 0;
```

To make it compatible with third-party monitoring solutions that expect it to be enabled in the `public` schema,
you need to include it in the `search_path`:

```sql
set search_path to public,adm;
```

### Fix an existing dump file to remove references to `pg_stat_statements`

To fix an existing backup file, do the following changes:

1. Extract from the backup the following file: `db/database.sql.gz`.
1. Decompress the file or use an editor that is capable of handling it compressed.
1. Remove the following lines, or similar ones:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
   ```

   ```sql
   COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';
   ```

1. Save the changes and recompress the file.
1. Update the backup file with the modified `db/database.sql.gz`.

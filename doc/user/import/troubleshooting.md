---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting
---

{{< details >}}

Tier: Free, Premium, Ultimate
Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When migrating to GitLab, you might encounter the following issues.

## Imported repository is missing branches

If an imported repository does not contain all branches of the source repository:

1. Set the [environment variable](../../administration/logs/_index.md#override-default-log-level) `IMPORT_DEBUG=true`.
1. Retry the import with a [different group, subgroup, or project name](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#re-import-projects-from-external-providers).
1. If some branches are still missing, inspect [`importer.log`](../../administration/logs/_index.md#importerlog)
   (for example, with [`jq`](../../administration/logs/log_parsing.md#parsing-gitlab-railsimporterlog)).

## Exception: `Error Importing repository - No such file or directory @ rb_sysopen - (filename)`

The error occurs if you attempt to import a `tar.gz` file download of a repository's source code.

Imports require a [GitLab export](../project/settings/import_export.md#export-a-project-and-its-data) file, not just a repository download file.

## Diagnosing prolonged or failed imports

If you're experiencing prolonged delays or failures with file-based imports, especially those using S3, the following may help identify the root cause of the problem:

- [Check import steps](#check-import-status)
- [Review logs](#review-logs)
- [Identify common issues](#identify-common-issues)

### Check import status

Check the import status:

1. Use the GitLab API to check the [import status](../../api/project_import_export.md#import-status) of the affected project.
1. Review the response for any error messages or status information, especially the `status` and `import_error` values.
1. Make note of the `correlation_id` in the response, as it's crucial for further troubleshooting.

### Review logs

Search logs for relevant information:

For GitLab Self-Managed instances:

1. Check the [Sidekiq logs](../../administration/logs/_index.md#sidekiqlog) and [`exceptions_json` logs](../../administration/logs/_index.md#exceptions_jsonlog).
1. Search for entries related to `RepositoryImportWorker` and the correlation ID from [Check import status](#check-import-status).
1. Look for fields such as `job_status`, `interrupted_count`, and `exception`.

For GitLab.com (GitLab team members only):

1. Use [Kibana](https://log.gprd.gitlab.net/) to search the Sidekiq logs with queries like:

   Target: `pubsub-sidekiq-inf-gprd*`

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.correlation_id.keyword: "<CORRELATION_ID>"
   ```

   or

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.meta.project: "<project.full_path>"
   ```

1. Look for the same fields as mentioned for GitLab Self-Managed instances.

### Identify common issues

Check the information gathered in [Review logs](#review-logs) against the following common issues:

- Interrupted jobs: If you see a high `interrupted_count` or `job_status` indicating failure, the import job may have been interrupted multiple times and placed in a dead queue.
- S3 connectivity: For imports using S3, check for any S3-related error messages in the logs.
- Large repository: If the repository is very large, the import might time out. Consider using [Direct transfer](../group/import/_index.md) in this case.

---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Import and export settings
description: "Configure settings for import sources, export limits, file sizes, user mapping, and placeholder users on your GitLab Self-Managed instance."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Settings for import- and export-related features.

## Configure allowed import sources

Before you can import projects from other systems, you must enable the
[import source](../../user/gitlab_com/_index.md#default-import-sources) for that system.

1. Sign in to GitLab as a user with Administrator access level.
1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Select each of **Import sources** to allow.
1. Select **Save changes**.

## Disable unused import sources

Only import projects from sources you trust. If you import a project from an untrusted source,
an attacker could steal your sensitive data. For example, an imported project
with a malicious `.gitlab-ci.yml` file could allow an attacker to exfiltrate group CI/CD variables.

GitLab Self-Managed administrators can reduce their attack surface by disabling import sources they don't need:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. Scroll to **Import sources**.
1. Clear checkboxes for importers that are not required.

## Enable project export

To enable the export of
[projects and their data](../../user/project/settings/import_export.md#export-a-project-and-its-data):

1. Sign in to GitLab as a user with Administrator access level.
1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Project export**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

## Enable migration of groups and projects by direct transfer

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/461326) in GitLab 18.3.

{{< /history >}}

Migration of groups and projects by direct transfer is disabled by default.
To enable migration of groups and projects by direct transfer:

1. Sign in to GitLab as a user with Administrator access level.
1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Allow migrating GitLab groups and projects by direct transfer**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

The same setting
[is available](../../api/settings.md#available-settings) in the API as the
`bulk_import_enabled` attribute.

## Enable export of groups and projects for offline transfer

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588971) in GitLab 19.3
  [with a feature flag](../../administration/feature_flags/_index.md) named `offline_transfer_exports`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Prerequisites:

- You must be an administrator.

Turn on this setting to allow users to create
[offline transfer](../../user/import/gitlab_instances/offline-transfer-migrations.md) exports of
groups and projects.

To enable export of groups and projects for offline transfer:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Allow exporting GitLab groups and projects by offline transfer**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

The same setting
[is available](../../api/settings.md#available-settings) in the API as the
`offline_transfer_exports_enabled` attribute.

## Enable import of groups and projects by offline transfer

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588971) in GitLab 19.3
  [with a feature flag](../../administration/feature_flags/_index.md) named `offline_transfer_imports`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Prerequisites:

- You must be an administrator.

Turn on this setting to allow users to import groups and projects from an
[offline transfer](../../user/import/gitlab_instances/offline-transfer-migrations.md) export.

To enable import of groups and projects by offline transfer:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Allow importing GitLab groups and projects by offline transfer**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

The same setting
[is available](../../api/settings.md#available-settings) in the API as the
`offline_transfer_imports_enabled` attribute.

## Allow S3-compatible object storage for offline transfer

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/579705) in GitLab 18.9
  [with a feature flag](../../administration/feature_flags/_index.md) named `offline_transfer_exports`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Prerequisites:

- You must be an administrator.

By default, [offline transfer](../../user/import/gitlab_instances/offline-transfer-migrations.md) supports
only AWS S3 and Google Cloud Storage. Turn on this setting to also allow S3-compatible providers,
such as MinIO.

> [!warning]
> When you enable this setting, users who can perform offline transfers can supply an arbitrary
> `endpoint` URL in the offline transfer object storage configuration. GitLab then sends requests
> to that endpoint. Enable this setting only if you trust the users who can perform offline transfers.

To allow S3-compatible object storage for offline transfer:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Allow S3 compatible object storage for offline transfer**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

## Allow application default credentials for offline transfer

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/8985) as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab 19.3 [with feature flags](../../administration/feature_flags/_index.md) named `offline_transfer_exports`, `offline_transfer_imports`, and `offline_transfer_ui`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Turn on this setting to allow [offline transfer](../../user/import/gitlab_instances/offline-transfer-migrations.md)
to authenticate with Google Cloud Storage by using
[Application Default Credentials](../object_storage.md#google-cloud-application-default-credentials) (ADC).

With every other object storage provider, the user who creates an export or an import supplies the
credentials. With ADC, no user supplies credentials. GitLab stores only the Google Cloud project ID
and resolves the credentials for each request from the environment of the instance, either from the
Compute Engine metadata server or from the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

Prerequisites:

- You must be an administrator.

> [!warning]
> An offline transfer that uses ADC acts with every Cloud Storage permission that the service account
> of the instance holds. That service account is usually more privileged than any individual user, so
> a user who creates an ADC transfer can reach buckets they hold no credentials for.

To limit this risk, GitLab applies the following restrictions, which you cannot turn off:

- Only users with administrator access can create an offline transfer export or import that uses
  ADC. Other users receive the error
  `Only administrators can use Application Default Credentials for offline transfer.`
- The bucket name must start with `gitlab-offline-transfer-`. This prefix keeps ADC transfers away
  from the buckets that the instance uses for its own object storage, such as uploads, job artifacts,
  and LFS objects.
- ADC is not available on GitLab.com.

The Google Cloud project ID that you provide for a transfer does not limit which buckets that
transfer can reach. Bucket names are globally unique in Cloud Storage, so an ADC transfer can use any
bucket that the service account can access and whose name starts with `gitlab-offline-transfer-`,
in any Google Cloud project.

GitLab checks these restrictions when a user creates a transfer. If you turn off this setting, users
can no longer create ADC transfers, but transfers that already started continue to run.

To allow Application Default Credentials for offline transfer:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Allow Google Cloud Application Default Credentials for offline transfer**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

The same setting
[is available](../../api/settings.md#available-settings) in the API as the
`allow_application_default_credentials_for_offline_transfer` attribute.

## Enable silent admin exports

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151278) in GitLab 17.0 [with a feature flag](../feature_flags/_index.md) named `export_audit_events`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153351) in GitLab 17.1. Feature flag `export_audit_events` removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152143) for file export downloads in GitLab 17.1.

{{< /history >}}

Enable silent admin exports to prevent [audit events](../compliance/audit_event_reports.md) when
instance administrators trigger a [project or group file export](../../user/project/settings/import_export.md) or download the export file.
Exports from non-administrators still generate audit events.

To enable silent admin project and group file exports:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**, then expand **Import and export settings**.
1. Scroll to **Silent exports by admins**.
1. Select the **Enabled** checkbox.

## Allow contribution mapping to administrators

{{< history >}}

- Introduced in GitLab 17.5 [with a feature flag](../feature_flags/_index.md) named `importer_user_mapping`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175371) in GitLab 17.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/508944) in GitLab 18.3. Feature flag `importer_user_mapping` removed.

{{< /history >}}

To allow mapping of imported user contributions to administrators:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**, then expand **Import and export settings**.
1. Scroll to **Allow contribution mapping to administrators**.
1. Select the **Enabled** checkbox.

## Skip confirmation when administrators reassign placeholder users

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/534330) in GitLab 18.1 [with a feature flag](../feature_flags/_index.md) named `importer_user_mapping_allow_bypass_of_confirmation`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/541373) in GitLab 18.6. Feature flag `importer_user_mapping_allow_bypass_of_confirmation` removed.

{{< /history >}}

Prerequisites:

- Ensure [user impersonation is not disabled](../../api/rest/authentication.md#disable-impersonation) on the GitLab instance.

To skip confirmation when administrators reassign placeholder users:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. Under **Skip confirmation when administrators reassign placeholder users**, select the **Enabled** checkbox.

When this setting is enabled, administrators can reassign contributions and memberships
to non-bot users with any of the following states:

- `active`
- `banned`
- `blocked`
- `blocked_pending_approval`
- `deactivated`
- `ldap_blocked`

## Max export size

To modify the maximum file size for exports in GitLab:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**, then expand **Import and export settings**.
1. Increase or decrease by changing the value in **Maximum export size (MiB)**.

## Max import size

To modify the maximum file size for imports in GitLab:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. Increase or decrease by changing the value in **Maximum import size (MiB)**.

This setting applies only to repositories
[imported from a GitLab export file](../../user/project/settings/import_export.md#import-a-project-and-its-data).

This setting only controls the limit enforced by GitLab itself.
Any HTTP proxy or load balancer in front of GitLab enforces its own,
independent request size limit, which you must configure separately.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Adjust the bundled NGINX `client_max_body_size` setting.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Adjust the Ingress controller or Gateway API configuration,
depending on which one your deployment uses.

{{< /tab >}}

{{< /tabs >}}

For GitLab.com repository size limits, read [accounts and limit settings](../../user/gitlab_com/_index.md#account-and-limit-settings).

## Maximum remote file size for imports

By default, the maximum remote file size for imports from external object storages (for example, AWS) is 10 GiB.

To modify this setting:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. In **Maximum import remote file size (MiB)**, enter a value. Set to `0` for no file size limit.

## Maximum download file size for imports by direct transfer

By default, the maximum download file size for imports by direct transfer is 5 GiB.

To modify this setting:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. In **Maximum download file size (MiB)**, enter a value. Set to `0` for no file size limit.

## Maximum decompressed file size for imported archives

When you import a project using [file exports](../../user/project/settings/import_export.md) or
[direct transfer](../../user/group/import/_index.md), you can specify the
maximum decompressed file size for imported archives. The default value is 25 GiB.

When you import a compressed file, the decompressed size cannot exceed the maximum decompressed file size limit. If the
decompressed size exceeds the configured limit, the following error is returned:

```plaintext
Decompressed archive size validation failed.
```

To modify this setting:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. Set another value for **Maximum decompressed file size for archives from imports (MiB)**.

## Timeout for decompressing archived files

When you [import a project](../../user/project/settings/import_export.md), you can specify the maximum timeout for decompressing imported archives. The default value is 210 seconds.

To modify the maximum decompressed file size for imports in GitLab:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. Set another value for **Timeout for decompressing archived files (seconds)**.

## Maximum number of concurrent import jobs across the instance

{{< history >}}

- Introduced in GitLab 19.1.

{{< /history >}}

Every import job holds a Sidekiq thread for its entire duration. The workers that
orchestrate an import (file-based project and group imports, direct transfer, and the
stage jobs for the GitHub, Bitbucket Cloud, and Bitbucket Server importers) can run for a
long time, so if too many run at once they can occupy the whole Sidekiq thread pool and
block other background work.

The `import_jobs_concurrency_limit` setting caps how many of these long-running jobs run
at the same time. The limit applies independently to each worker type, not as a
single shared total. Jobs beyond a worker type's limit wait until a running job of that
type finishes.

The default is `100` concurrent jobs per worker type. To change it, send an API request
to `/api/v4/application/settings` with `import_jobs_concurrency_limit`. For more
information, see the [application settings API](../../api/settings.md).

## Maximum number of simultaneous import jobs

Within a single project import, you can cap how many child jobs (for example, one job per issue or pull request) an
importer schedules at the same time. Use this to control how many jobs a single import schedules concurrently. It
applies to:

- [GitHub importer](../../user/project/import/github.md)
- [Bitbucket Cloud importer](../../user/import/bitbucket_cloud.md)
- [Bitbucket Server importer](../../user/import/bitbucket_server.md)

This is separate from [`import_jobs_concurrency_limit`](#maximum-number-of-concurrent-import-jobs-across-the-instance):
that setting caps the long-running orchestration and stage workers across the whole instance, but independently per
worker type, whereas this setting caps the short-lived child jobs inside a single import. Because child jobs finish
quickly, their defaults are much higher.

The job limit is not applied when importing merge requests, because a hard-coded limit for merge requests already
avoids overloading servers.

The default job limit is:

- GitHub importer: 1000.
- Bitbucket Cloud and Bitbucket Server importers: 100. The Bitbucket importers have a low default because a good
  default hasn't been determined yet. Instance administrators should experiment with a higher limit.

To modify this setting:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Import and export settings**.
1. Set another value for **Maximum number of simultaneous import jobs** for the desired importer.

## Maximum number of simultaneous batch export jobs

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122) in GitLab 17.6.

{{< /history >}}

Direct transfer exports can consume a significant amount of resources.
To prevent using up the database or Sidekiq processes,
administrators can configure the `concurrent_relation_batch_export_limit` setting.

The default value is `8` jobs, which corresponds to a
[reference architecture for up to 40 RPS or 2,000 users](../reference_architectures/2k_users.md).
If you encounter `PG::QueryCanceled: ERROR: canceling statement due to statement timeout` errors
or jobs getting interrupted due to Sidekiq memory limits, you might want to reduce this number.
If you have enough resources, you can increase this number to process more concurrent export jobs.

To modify this setting, send an API request to `/api/v4/application/settings`
with `concurrent_relation_batch_export_limit`.
For more information, see [application settings API](../../api/settings.md).

### Concurrent project file exports

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/599092) in GitLab 19.4.

{{< /history >}}

Project file exports run on Sidekiq nodes with limited memory and disk space, so too many
concurrent exports can saturate those nodes and delay every export on the instance.
To limit how many project file exports run at the same time, administrators can configure the
`concurrent_relation_export_limit` setting.

The default value is `25` exports. Exports requested while the limit is reached stay queued and
start in the order they were requested, as running exports finish.

To modify this setting, send an API request to `/api/v4/application/settings`
with `concurrent_relation_export_limit`.
For more information, see [application settings API](../../api/settings.md).

### Export batch size

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607) in GitLab 18.2.

{{< /history >}}

To further manage memory usage and database load, use the `relation_export_batch_size` setting to control the number of records processed in each batch during export operations.

The default value is `50` records per batch. To modify this setting, send an API request to `/api/v4/application/settings` with `relation_export_batch_size`.
For more information, see [application settings API](../../api/settings.md).

## Troubleshooting

## Error: `Help page documentation base url is blocked: execution expired`

While enabling application settings like [import source](#configure-allowed-import-sources), you might get a `Help page documentation base url is blocked: execution expired`
error. To work around this error:

1. Add `docs.gitlab.com`, or [the redirect help documentation pages URL](help_page.md#redirect-help-pages), to the
   [allowlist](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).
1. Select **Save Changes**.

## Related topics

- [Import and migrate to GitLab](../../user/import/_index.md).
- [Sidekiq configuration imports](../sidekiq/configuration_for_imports.md).
- [Running multiple Sidekiq processes](../sidekiq/extra_sidekiq_processes.md).
- [Processing specific job classes](../sidekiq/processing_specific_job_classes.md).

---
stage: Manage
group: Import and Integrate
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Import and export settings

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Settings for import- and export-related features.

## Configure allowed import sources

Before you can import projects from other systems, you must enable the
[import source](../../user/gitlab_com/index.md#default-import-sources) for that system.

1. Sign in to GitLab as a user with Administrator access level.
1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand the **Import and export settings** section.
1. Select each of **Import sources** to allow.
1. Select **Save changes**.

## Enable project export

To enable the export of
[projects and their data](../../user/project/settings/import_export.md#export-a-project-and-its-data):

1. Sign in to GitLab as a user with Administrator access level.
1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Project export**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

## Enable migration of groups and projects by direct transfer

DETAILS:
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383268) in GitLab 15.8.

WARNING:
In GitLab 16.1 and earlier, you should **not** use direct transfer with [scheduled scan execution policies](../../user/application_security/policies/scan-execution-policies.md). If using direct transfer, first upgrade to GitLab 16.2 and ensure security policy bots are enabled in the projects you are enforcing.

WARNING:
This feature is in [beta](../../policy/experiment-beta-support.md#beta) and subject to change without notice.
This feature is not ready for production use.

Migration of groups and projects by direct transfer is disabled by default.
To enable migration of groups and projects by direct transfer:

1. Sign in to GitLab as a user with Administrator access level.
1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand the **Import and export settings** section.
1. Scroll to **Allow migrating GitLab groups and projects by direct transfer**.
1. Select the **Enabled** checkbox.
1. Select **Save changes**.

The same setting
[is available](../../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls) in the API as the
`bulk_import_enabled` attribute.

## Enable silent admin exports

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151278) in GitLab 17.0 [with a flag](../../administration/feature_flags.md) named `export_audit_events`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153351) in GitLab 17.1. Feature flag `export_audit_events` removed.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152143) for file export downloads in GitLab 17.1.

Enable silent admin exports to prevent [audit events](../audit_event_reports.md) when
instance administrators trigger a [project or group file export](../../user/project/settings/import_export.md) or download the export file.
Exports from non-administrators still generate audit events.

To enable silent admin project and group file exports:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**, then expand **Import and export settings**.
1. Scroll to **Silent exports by admins**.
1. Select the **Enabled** checkbox.

## Max export size

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86124) in GitLab 15.0.

To modify the maximum file size for exports in GitLab:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**, then expand **Import and export settings**.
1. Increase or decrease by changing the value in **Maximum export size (MiB)**.

## Max import size

To modify the maximum file size for imports in GitLab:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Increase or decrease by changing the value in **Maximum import size (MiB)**.

This setting applies only to repositories
[imported from a GitLab export file](../../user/project/settings/import_export.md#import-a-project-and-its-data).

If you choose a size larger than the configured value for the web server,
you may receive errors. See the [troubleshooting section](../../administration/settings/account_and_limit_settings.md#troubleshooting) for more
details.

For GitLab.com repository size limits, read [accounts and limit settings](../../user/gitlab_com/index.md#account-and-limit-settings).

## Maximum remote file size for imports

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) in GitLab 16.3.

By default, the maximum remote file size for imports from external object storages (for example, AWS) is 10 GiB.

To modify this setting:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Increase or decrease by changing the value in **Maximum import remote file size (MiB)**. Set to `0` to set no file size limit.

## Maximum download file size for imports by direct transfer

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) in GitLab 16.3.

By default, the maximum download file size for imports by direct transfer is 5 GiB.

To modify this setting:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Increase or decrease by changing the value in **Direct transfer maximum download file size (MiB)**. Set to `0` to set no download file size limit.

## Maximum decompressed file size for imported archives

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218) in GitLab 16.3.
> - **Maximum decompressed file size for archives from imports** field [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130081) from **Maximum decompressed size** in GitLab 16.4.

When you import a project using [file exports](../../user/project/settings/import_export.md) or
[direct transfer](../../user/group/import/index.md), you can specify the
maximum decompressed file size for imported archives. The default value is 25 GiB.

When you import a compressed file, the decompressed size cannot exceed the maximum decompressed file size limit. If the
decompressed size exceeds the configured limit, the following error is returned:

```plaintext
Decompressed archive size validation failed.
```

To modify this setting:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Set another value for **Maximum decompressed file size for archives from imports (MiB)**.

## Timeout for decompressing archived files

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218) in GitLab 16.4.

When you [import a project](../../user/project/settings/import_export.md), you can specify the maximum time out for decompressing imported archives. The default value is 210 seconds.

To modify the maximum decompressed file size for imports in GitLab:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Set another value for **Timeout for decompressing archived files (seconds)**.

## Maximum number of simultaneous import jobs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875) in GitLab 16.11.

You can specify the maximum number of import jobs that are executed simultaneously for:

- [GitHub importer](../../user/project/import/github.md)
- [Bitbucket Cloud importer](../../user/project/import/bitbucket.md)
- [Bitbucket Server importer](../../user/project/import/bitbucket_server.md)

The job limit is not applied when importing merge requests because there is a hard-coded limit for merge requests to
avoid overloading servers.

The default job limit is:

- For the GitHub importer, 1000.
- For the Bitbucket Cloud and Bitbucket Server importer, 100. The Bitbucket importers have a low default limit because
  we haven't yet determined a good default limit. Administrators of self-managed GitLab instances should experiment with
  a higher limit.

To modify this setting:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Set another value for **Maximum number of simultaneous import jobs** for the desired importer.

## Troubleshooting

## Error: `Help page documentation base url is blocked: execution expired`

While enabling application settings like [import source](#configure-allowed-import-sources), you might get a `Help page documentation base url is blocked: execution expired`
error. To work around this error:

1. Add `docs.gitlab.com`, or [the redirect help documentation pages URL](help_page.md#redirect-help-pages), to the
   [allowlist](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).
1. Select **Save Changes**.

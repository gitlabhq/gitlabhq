---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate groups and projects by using offline transfer
description: "Migrate GitLab groups and projects through object storage."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/8985) as an [experiment](../../../policy/development_stages_support.md#experiment) in GitLab 19.3 [with feature flags](../../../administration/feature_flags/_index.md) named `offline_transfer_exports`, `offline_transfer_imports`, and `offline_transfer_ui`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by feature flags.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Offline transfer copies GitLab groups and projects between instances through object storage,
without a direct network connection between the source and destination instances.
The source instance exports data to a storage bucket, and the destination instance imports the
data from a bucket it can read.

Unlike [migration by direct transfer](../../group/import/direct_transfer_migrations.md), which requires the
destination instance to connect to the source instance, offline transfer decouples the export
and import. The export bucket and import bucket do not have to be the same bucket, or use the
same object storage provider. If the destination instance cannot access the export bucket, move
the export files to a bucket the destination can access. GitLab does not move these files for you.

Offline transfer is gated by both feature flags and application settings. All of them are off by
default, and for a given operation both layers must be on:

- Exports: the `offline_transfer_exports_enabled` application setting.
- Imports: the `offline_transfer_imports_enabled` application setting.

To perform exports and imports, use the [offline transfer REST API](https://api.gitlab.com/rest/#tag/offline-transfers).
Support offline transfers in the GitLab UI is proposed in [work item 19870](https://gitlab.com/groups/gitlab-org/-/work_items/19870).

## Version requirements

To create an offline transfer export, the source instance must run GitLab 19.3 or later.
To import an export, the destination instance must run GitLab 19.3 or later.

Every export records the version of the source instance that created it. If that version is earlier
than the minimum version the destination instance supports, the import fails with an
`Unsupported GitLab version` error.

## Supported object storage providers

Offline transfer supports these object storage providers:

| Provider | Description |
| -------- | ----------- |
| AWS S3 | Amazon S3 object storage. |
| S3-compatible | MinIO and other S3-compatible providers. Requires an administrator to [turn on S3-compatible object storage](../../../administration/settings/import_and_export_settings.md#allow-s3-compatible-object-storage-for-offline-transfer). |
| Google Cloud Storage (service account) | Google Cloud Storage authenticated with a service account JSON key. |
| Google Cloud Storage (HMAC) | Google Cloud Storage authenticated with S3-interoperability HMAC keys. |
| Google Cloud Storage with Application Default Credentials | Google Cloud Storage authenticated with Application Default Credentials (ADC). Restricted to administrators and to specific buckets, and not available on GitLab.com. For more information, see [Application Default Credentials](#application-default-credentials). |

### Required permissions

The object storage credentials you provide must have the following permissions.

For AWS S3:

- Export: `s3:PutObject` and `s3:ListBucket`
- Import: `s3:GetObject` and `s3:ListBucket`

For Google Cloud Storage with a service account:

- Export: `storage.buckets.get`, `storage.objects.create`, and `storage.objects.list`
- Import: `storage.objects.get`

Google Cloud Storage with ADC needs the same permissions, held by the service account of the instance
instead of by a key you supply.

Google Cloud Storage HMAC keys authenticate through the S3 interoperability API, so they require the
AWS S3 permissions listed above rather than the `storage.*` permissions.

Permissions for other S3-compatible providers vary by provider. Configure your provider with read
and write permissions equivalent to the AWS S3 permissions listed above.

### Application Default Credentials

Google Cloud Storage with ADC authenticates as the service account of the instance that runs GitLab,
not as the user who starts the transfer. Because that service account is usually more privileged than
any individual user, GitLab restricts ADC transfers to administrators and to buckets whose name
starts with `gitlab-offline-transfer-`.

An administrator must also turn on ADC for the instance. For the security implications and the full
list of restrictions, see
[Allow application default credentials for offline transfer](../../../administration/settings/import_and_export_settings.md#allow-application-default-credentials-for-offline-transfer).

## Migrated items

Offline transfer imports the same group and project items as migration by direct transfer.
For the full list, see [migrated group items](../../group/import/migrated_items.md#migrated-group-items) and
[migrated project items](../../group/import/migrated_items.md#migrated-project-items).

The following items are not imported by offline transfer:

- Group and project memberships. Support for membership import is proposed in [work item 538356](https://gitlab.com/gitlab-org/gitlab/-/work_items/538356).
- Wikis. Support for wiki import is proposed in [work item 538858](https://gitlab.com/gitlab-org/gitlab/-/work_items/538858).
- Snippets. Support for snippet import is proposed in [work item 538347](https://gitlab.com/gitlab-org/gitlab/-/work_items/538347).
- Badges. Support for badge import is proposed in [work item 538355](https://gitlab.com/gitlab-org/gitlab/-/work_items/538355).

When you import a group, its subgroups and projects are always imported if they are present in
the export.

## User contribution mapping

Offline transfer never creates real users on the destination instance. Instead, imported contributions
are mapped to [placeholder users](../../import/mapping/post_migration_mapping.md#placeholder-users).
After the import finishes,
[reassign the placeholder users](../../import/mapping/reassignment.md) to users on the destination
instance.

Because offline transfer does not import group and project memberships, you must add members to the
imported groups and projects yourself.

## Visibility rules

Offline transfer applies the same visibility rules as migration by direct transfer. For more
information, see [visibility rules](../../group/import/_index.md#visibility-rules).

## Migrate a group or project

Prerequisites:

- To export a project, you must have at least the Maintainer role for the project.
- To export a group, you must have the Owner role for the group.
- To import into a group, you must have the Owner role for the destination group.
- To import a group as a top-level group, you must have permission to create groups.
- To use Application Default Credentials for an export or an import, you must have administrator
  access.

To migrate a group or project:

1. On the source instance, the REST API to [create an offline transfer export](https://api.gitlab.com/rest/#tag/offline-transfers/POST/api/v4/offline_exports) to an object storage bucket.
1. When the export finishes, GitLab sends you an email with the export prefix. You need this prefix
   to start the import. If you do not receive the email, the export prefix can be viewed in the object storage service.
1. If the destination instance cannot access the export bucket, move the export files to a bucket
   the destination can access.
1. On the destination instance, [create an offline transfer import](https://api.gitlab.com/rest/#tag/offline-transfers/POST/api/v4/offline_imports) from the bucket and export prefix.
1. Monitor the import with the [group and project migration by direct transfer API](../../../api/bulk_imports.md#retrieve-a-group-or-project-migration).

## Rate limits

Offline transfer exports and imports are rate limited.
For more information, see [non-configurable rate limits](../../../rate_limits/non_configurable.md).

## Related topics

- [Migrate groups and projects by using direct transfer](../../group/import/direct_transfer_migrations.md)

---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo with Object storage
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> Verification of files stored in object storage was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8056) in GitLab 16.4 [with a flag](../../feature_flags.md) named `geo_object_storage_verification`. Enabled by default.

Geo can be used in combination with Object Storage (AWS S3, or other compatible object storage).

**Secondary** sites can use one of the following:

- The same storage bucket as the **primary** site.
- A replicated storage bucket.
- Local storage, if the primary uses local storage.

The storage method (local or object storage) for files is recorded in the database, and the database
is replicated from the **primary** Geo site to the **secondary** Geo site.

When accessing an uploaded object, we get its storage method (local or object storage) from the
database, so the **secondary** Geo site must match the storage method of the **primary** Geo site.

Therefore, if the **primary** Geo site uses object storage, the **secondary** Geo site must use it too.

To have:

- GitLab manage replication, follow [Enabling GitLab replication](#enabling-gitlab-managed-object-storage-replication).
- Third-party services manage replication, follow [Third-party replication services](#third-party-replication-services).

See [Object storage replication tests](geo_validation_tests.md#object-storage-replication-tests) for comparisons between GitLab-managed replication and third-party replication.

[Read more about using object storage with GitLab](../../object_storage.md).

## Enabling GitLab-managed object storage replication

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5551) in GitLab 15.1.

**Secondary** sites can replicate files stored on the **primary** site regardless of
whether they are stored on the local file system or in object storage.

To enable GitLab replication:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Nodes**.
1. Select **Edit** on the **secondary** site.
1. In the **Synchronization Settings** section, find the **Allow this secondary node to replicate content on Object Storage**
   checkbox to enable it.

For LFS, follow the documentation to
[set up LFS object storage](../../lfs/_index.md#storing-lfs-objects-in-remote-object-storage).

For CI job artifacts, there is similar documentation to configure
[jobs artifact object storage](../../cicd/job_artifacts.md#using-object-storage)

For user uploads, there is similar documentation to configure [upload object storage](../../uploads.md#using-object-storage)

If you want to migrate the **primary** site's files to object storage, you can
configure the **secondary** in a few ways:

- Use the exact same object storage.
- Use a separate object store but leverage your object storage solution's built-in
  replication.
- Use a separate object store and enable the **Allow this secondary node to replicate
  content on Object Storage** setting.

GitLab does not support the case where both:

- The **primary** site uses local storage.
- A **secondary** site uses object storage.

## Third-party replication services

When using Amazon S3, you can use
[Cross-Region Replication (CRR)](https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html) to
have automatic replication between the bucket used by the **primary** site and
the bucket used by **secondary** sites.

If you are using Google Cloud Storage, consider using
[Multi-Regional Storage](https://cloud.google.com/storage/docs/storage-classes#multi-regional).
Or you can use the [Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/overview),
although this only supports daily synchronization.

For manual synchronization, or scheduled by `cron`, see:

- [`s3cmd sync`](https://s3tools.org/s3cmd-sync)
- [`gsutil rsync`](https://cloud.google.com/storage/docs/gsutil/commands/rsync)

---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: howto
---

# Geo with Object storage **(PREMIUM ONLY)**

Geo can be used in combination with Object Storage (AWS S3, or other compatible object storage).

Currently, **secondary** nodes can use either:

- The same storage bucket as the **primary** node.
- A replicated storage bucket.

To have:

- GitLab manage replication, follow [Enabling GitLab replication](#enabling-gitlab-managed-object-storage-replication).
- Third-party services manage replication, follow [Third-party replication services](#third-party-replication-services).

[Read more about using object storage with GitLab](../../object_storage.md).

## Enabling GitLab managed object storage replication

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10586) in GitLab 12.4.

CAUTION: **Caution:**
This is a [**beta** feature](https://about.gitlab.com/handbook/product/#beta) and is not ready yet for production use at any scale.

**Secondary** nodes can replicate files stored on the **primary** node regardless of
whether they are stored on the local filesystem or in object storage.

To enable GitLab replication, you must:

1. Go to **{admin}** **Admin Area >** **{location-dot}** **Geo**.
1. Press **Edit** on the **secondary** node.
1. Enable the **Allow this secondary node to replicate content on Object Storage**
   checkbox.

For LFS, follow the documentation to
[set up LFS object storage](../../lfs/index.md#storing-lfs-objects-in-remote-object-storage).

For CI job artifacts, there is similar documentation to configure
[jobs artifact object storage](../../job_artifacts.md#using-object-storage)

For user uploads, there is similar documentation to configure [upload object storage](../../uploads.md#using-object-storage-core-only)

If you want to migrate the **primary** node's files to object storage, you can
configure the **secondary** in a few ways:

- Use the exact same object storage.
- Use a separate object store but leverage your object storage solution's built-in
  replication.
- Use a separate object store and enable the **Allow this secondary node to replicate
  content on Object Storage** setting.

GitLab does not currently support the case where both:

- The **primary** node uses local storage.
- A **secondary** node uses object storage.

## Third-party replication services

When using Amazon S3, you can use
[CRR](https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html) to
have automatic replication between the bucket used by the **primary** node and
the bucket used by **secondary** nodes.

If you are using Google Cloud Storage, consider using
[Multi-Regional Storage](https://cloud.google.com/storage/docs/storage-classes#multi-regional).
Or you can use the [Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/),
although this only supports daily synchronization.

For manual synchronization, or scheduled by `cron`, please have a look at:

- [`s3cmd sync`](https://s3tools.org/s3cmd-sync)
- [`gsutil rsync`](https://cloud.google.com/storage/docs/gsutil/commands/rsync)

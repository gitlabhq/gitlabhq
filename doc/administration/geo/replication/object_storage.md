# Geo with Object storage

Geo can be used in combination with Object Storage (AWS S3, or
other compatible object storage).

## Configuration

At this time it is required that if object storage is enabled on the
primary, it must also be enabled on the secondary.

The secondary nodes can use the same storage bucket as the primary, or
they can use a replicated storage bucket. At this time GitLab does not
take care of content replication in object storage.

For LFS, follow the documentation to
[set up LFS object storage](../../../workflow/lfs/lfs_administration.md#setting-up-s3-compatible-object-storage).

For CI job artifacts, there is similar documentation to configure
[jobs artifact object storage](../../job_artifacts.md#using-object-storage)

For user uploads, there is similar documentation to configure [upload object storage](../../uploads.md#using-object-storage)

You should enable and configure object storage on both **primary** and **secondary**
nodes. Migrating existing data to object storage should be performed on the
**primary** node only; secondaries will automatically notice that the migrated
files are now in object storage.

## Replication

When using Amazon S3, you can use
[CRR](https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html) to
have automatic replication between the bucket used by the primary and
the bucket used by the secondary.

If you are using Google Cloud Storage, consider using
[Multi-Regional Storage](https://cloud.google.com/storage/docs/storage-classes#multi-regional).
Or you can use the [Storage Transfer Service](https://cloud.google.com/storage/transfer/),
although this only supports daily synchronization.

For manual synchronization, or scheduled by `cron`, please have a look at:

- [`s3cmd sync`](http://s3tools.org/s3cmd-sync)
- [`gsutil rsync`](https://cloud.google.com/storage/docs/gsutil/commands/rsync)

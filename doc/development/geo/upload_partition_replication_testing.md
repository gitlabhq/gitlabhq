---
stage: Tenant Scale
group: Geo
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Test Geo replication of upload partitions
---

Create test data for every upload partition and exercise the partition replicators end to end
on the GitLab Development Kit (GDK) or on a reference environment.

Geo replicates and verifies each partition of the `uploads` table with its own replicator.

It does not track the whole table with the single legacy `Geo::UploadReplicator`.
Support for this is proposed in [epic 20933](https://gitlab.com/groups/gitlab-org/-/work_items/20933).

## Seed one upload per partition

The `gitlab:seed:geo_uploads` Rake task creates one real `Upload` in each upload partition.
It builds the parent records off an existing project and attaches a small file through each
model's uploader, so the rows land in the correct partition and store a real, verifiable blob.

Run the task on the primary site:

```shell
# Uses the first project it finds
bundle exec rake gitlab:seed:geo_uploads

# Or target a specific project (recommended: use a project in a group namespace so
# the namespace_uploads partition is covered)
bundle exec rake "gitlab:seed:geo_uploads[group/project]"
```

The task prints a result for each partition and a summary of upload counts by `model_type`.
The count is the partition's total row count, including any pre-existing data, not only
the rows this run created.
A partition reports `FAILED` when its recipe raised an error instead of creating a record.
Check the corresponding `FAIL` line above the summary for the reason.

## Switch to the partition replicators

The legacy and partition replicators are mutually exclusive.
While the `geo_upload_replication` flag is turned on, the partition replicators do not emit
events, and the partition registry consistency backfill is suppressed.

To exercise the partition replicators, turn on every partition flag first, then turn off the
legacy flag.
If a flag is disabled when you disable the legacy flag, the partition stops replicating.

On the primary site, run the following command in a Rails console:

```ruby
Gitlab::Geo.blob_replicator_classes.select { |replicator| replicator.model < ::Upload }.each do |replicator|
  Feature.enable(replicator.replication_enabled_feature_key)
end

Feature.disable(:geo_upload_replication)
```

To return to the legacy replicator, turn on `geo_upload_replication` again.

## Check verification on the primary site

The primary site calculates a checksum for each blob and stores it in the partition
`*_upload_states` table.
The `Geo::VerificationCronWorker` runs every minute, or you can run it directly:

```ruby
Geo::VerificationCronWorker.new.perform
```

To confirm a single record checksums correctly, verify one replicator directly:

```ruby
upload = Upload.where(model_type: 'Project').last
record = Geo::ProjectUpload.find(upload.id)
record.replicator.verify

record = Geo::ProjectUpload.find(upload.id)
record.verification_state      # 2 means succeeded
record.verification_checksum   # populated when verification succeeds
```

## Check replication and verification on a secondary site

On a secondary site, registries are created from replication events and from the
`Geo::Secondary::RegistryConsistencyWorker` backfill.
Both cron workers run every minute, or you can run them directly:

```ruby
Geo::Secondary::RegistryConsistencyWorker.new.perform
Geo::VerificationBatchWorker.new.perform_work('project_upload')
```

Check the overall status with the Rake task:

```shell
bundle exec rake gitlab:geo:check_replication_verification_status
```

Inspect a single partition registry directly:

```ruby
Geo::ProjectUploadRegistry.synced.count
Geo::ProjectUploadRegistry.failed.count
```

For a broader view, the [Geo administration area](../../administration/geo_sites.md) shows
replication and verification counts per data type.

## Test on a reference or staging environment

Reference environments such as staging behave like production, so the Rake task is
dependency free and does not use test factories.

1. Deploy the branch that contains the seed task, or run it from an existing checkout.
1. Run `gitlab:seed:geo_uploads` on the primary site with a Rails runner or console.
   Confirm the uploads store to object storage when object storage is enabled.
1. Set the feature flags through ChatOps, for example
   `/chatops run feature set geo_project_upload_replication true` for each partition, then
   `/chatops run feature set geo_upload_replication false`.
1. Wait for the cron workers to run, then check
   `gitlab:geo:check_replication_verification_status` and the Geo administration area.

## Cleaning up seeded data

The task tags the leaf records it creates with a `geo-seed` prefix in their name or message,
so you can find and remove them after testing.
Avatars set on reused records such as the project, group, and user replace the previous avatar
rather than adding rows.

## Automated test coverage

The per-replicator contract is covered by shared examples, so most correctness checks do not
need a running secondary site.
For details, see the [blob replicator strategy](framework.md#blob-replicator-strategy) of the
Geo self-service framework.

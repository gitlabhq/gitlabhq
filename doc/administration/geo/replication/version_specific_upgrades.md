---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Version-specific upgrade instructions **(PREMIUM SELF)**

NOTE:
We're in the process of merging all the version-specific upgrade information
into a single page. For more information,
see [epic 9581](https://gitlab.com/groups/gitlab-org/-/epics/9581).
For the latest Geo version-specific upgrade instructions,
see the [general upgrade page](../../../update/index.md).

Review this page for upgrade instructions for your version. These steps
accompany the [general steps](upgrading_the_geo_sites.md#general-upgrade-steps)
for upgrading Geo sites.

## Upgrading to 14.9

**Do not** upgrade to GitLab 14.9.0. Instead, use 14.9.1 or later.

We've discovered an issue with Geo's CI verification feature that may [cause job traces to be lost](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6664). This issue was fixed in [the GitLab 14.9.1 patch release](https://about.gitlab.com/releases/2022/03/23/gitlab-14-9-1-released/).

If you have already upgraded to GitLab 14.9.0, you can disable the feature causing the issue by [disabling the `geo_job_artifact_replication` feature flag](../../feature_flags.md#how-to-enable-and-disable-features-behind-flags).

## Upgrading to 14.2 through 14.7

There is [an issue in GitLab 14.2 through 14.7](https://gitlab.com/gitlab-org/gitlab/-/issues/299819#note_822629467)
that affects Geo when the GitLab-managed object storage replication is used, causing blob object types to fail synchronization.

Since GitLab 14.2, verification failures result in synchronization failures and cause
a resynchronization of these objects.

As verification is not yet implemented for files stored in object storage (see
[issue 13845](https://gitlab.com/gitlab-org/gitlab/-/issues/13845) for more details), this
results in a loop that consistently fails for all objects stored in object storage.

For information on how to fix this, see
[Troubleshooting - Failed syncs with GitLab-managed object storage replication](troubleshooting.md#failed-syncs-with-gitlab-managed-object-storage-replication).

## Upgrading to 14.4

There is [an issue in GitLab 14.4.0 through 14.4.2](../../../update/versions/gitlab_14_changes.md#1440) that can affect Geo and other features that rely on cronjobs. We recommend upgrading to GitLab 14.4.3 or later.

## Upgrading to 14.1, 14.2, 14.3

### Multi-arch images

We found an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336013) where the Container Registry replication wasn't fully working if you used multi-arch images. In case of a multi-arch image, only the primary architecture (for example `amd64`) would be replicated to the secondary site. This has been [fixed in GitLab 14.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67624) and was backported to 14.2 and 14.1, but manual steps are required to force a re-sync.

You can check if you are affected by running:

```shell
docker manifest inspect <SECONDARY_IMAGE_LOCATION> | jq '.mediaType'
```

Where `<SECONDARY_IMAGE_LOCATION>` is a container image on your secondary site.
If the output matches `application/vnd.docker.distribution.manifest.list.v2+json`
(there can be a `mediaType` entry at several levels, we only care about the top level entry),
then you don't need to do anything.

Otherwise, for each **secondary** site, on a Rails application node, open a [Rails console](../../operations/rails_console.md), and run the following:

 ```ruby
 list_type = 'application/vnd.docker.distribution.manifest.list.v2+json'

 Geo::ContainerRepositoryRegistry.synced.each do |gcr|
   cr = gcr.container_repository
   primary = Geo::ContainerRepositorySync.new(cr)
   cr.tags.each do |tag|
     primary_manifest = JSON.parse(primary.send(:client).repository_raw_manifest(cr.path, tag.name))
     next unless primary_manifest['mediaType'].eql?(list_type)

     cr.delete_tag_by_name(tag.name)
   end
   primary.execute
 end
 ```

If you are running a version prior to 14.1 and are using Geo and multi-arch containers in your Container Registry, we recommend [upgrading](upgrading_the_geo_sites.md) to at least GitLab 14.1.

## Upgrading to GitLab 14.0/14.1

### Primary sites cannot be removed from the UI

We found an issue where [Primary sites cannot be removed from the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/338231).

This bug only exists in the UI and does not block the removal of Primary sites using any other method.

If you are running an affected version and need to remove your Primary site, you can manually remove the Primary site by using the [Geo Sites API](../../../api/geo_nodes.md#delete-a-geo-node).

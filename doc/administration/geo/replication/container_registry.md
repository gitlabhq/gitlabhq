---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container registry for a secondary site
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

You can set up a container registry on your **secondary** Geo site that mirrors the one on the **primary** Geo site. This container registry replication is used only for disaster recovery purposes.

Do not push to the container registry on the **secondary** Geo site, because the data is not propagated to the **primary** site.

We do not recommend pulling container registry data from the **secondary** site because it may be stale. The feature request [issue 365864](https://gitlab.com/gitlab-org/gitlab/-/issues/365864) would solve this problem. You are encouraged to upvote the issue to register your interest.

## Supported container registries

Geo supports the following types of container registries:

- [Docker](https://distribution.github.io/distribution/)
- [OCI](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)

## Supported image formats

The following container image formats are support by Geo:

- [Docker V2, schema 1](https://distribution.github.io/distribution/spec/deprecated-schema-v1/)
- [Docker V2, schema 2](https://distribution.github.io/distribution/spec/manifest-v2-2/)
- [OCI (Open Container Initiative)](https://github.com/opencontainers/image-spec)

In addition, Geo also supports [BuildKit cache images](https://github.com/moby/buildkit).

## Supported storage

### Docker

For more information on supported registry storage drivers see
[Docker registry storage drivers](https://distribution.github.io/distribution/storage-drivers/)

Read the [Load balancing considerations](https://distribution.github.io/distribution/about/deploying/#load-balancing-considerations)
when deploying the Registry, and how to set up the storage driver for the GitLab integrated
[container registry](../../packages/container_registry.md#use-object-storage).

### Registries that support OCI artifacts

The following registries support OCI artifacts:

- CNCF Distribution - local/offline verification
- Azure Container Registry (ACR)
- Amazon Elastic Container Registry (ECR)
- Google Artifact Registry (GAR)
- GitHub Packages container registry (GHCR)
- Bundle Bar

For more information, see the [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec).

## Configure container registry replication

You can enable a storage-agnostic replication so it
can be used for cloud or local storage. Whenever a new image is pushed to the
**primary** site, each **secondary** site pulls it to its own container
repository.

To configure container registry replication:

1. Configure the [**primary** site](#configure-primary-site).
1. Configure the [**secondary** site](#configure-secondary-site).
1. Verify container registry [replication](#verify-replication).

### Configure **primary** site

Make sure that you have container registry set up and working on
the **primary** site before following the next steps.

To be able to replicate new container images, the container registry must send notification events to the
**primary** site for every push. The token shared between the container registry and the web nodes on the
**primary** is used to make communication more secure.

1. SSH into your GitLab **primary** server and sign in as root (for GitLab HA, you only need a Registry node):

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['notifications'] = [
     {
       'name' => 'geo_event',
       'url' => 'https://<example.com>/api/v4/container_registry_event/events',
       'timeout' => '500ms',
       'threshold' => 5,
       'backoff' => '1s',
       'headers' => {
         'Authorization' => ['<replace_with_a_secret_token>']
       }
     }
   ]
   ```

   NOTE:
   Replace `<example.com>` with the `external_url` defined in your primary site's `/etc/gitlab/gitlab.rb` file, and
   replace `<replace_with_a_secret_token>` with a case sensitive alphanumeric string
   that starts with a letter. You can generate one with `< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 32 | sed "s/^[0-9]*//"; echo`

   NOTE:
   If you use an external Registry (not the one integrated with GitLab), you only need to specify
   the notification secret (`registry['notification_secret']`) in the
   `/etc/gitlab/gitlab.rb` file.

1. For GitLab HA only. Edit `/etc/gitlab/gitlab.rb` on every web node:

   ```ruby
   registry['notification_secret'] = '<replace_with_a_secret_token_generated_above>'
   ```

1. Reconfigure each node you just updated:

   ```shell
   gitlab-ctl reconfigure
   ```

### Configure **secondary** site

Make sure you have container registry set up and working on
the **secondary** site before following the next steps.

The following steps should be done on each **secondary** site you're
expecting to see the container images replicated.

Because we need to allow the **secondary** site to communicate securely with
the **primary** site container registry, we need to have a single key
pair for all the sites. The **secondary** site uses this key to
generate a short-lived JWT that is pull-only-capable to access the
**primary** site container registry.

For each application and Sidekiq node on the **secondary** site:

1. SSH into the node and sign in as the `root` user:

   ```shell
   sudo -i
   ```

1. Copy `/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key` from the **primary** to the node.

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   gitlab_rails['geo_registry_replication_enabled'] = true

   # Primary registry's hostname and port, it will be used by
   # the secondary node to directly communicate to primary registry
   gitlab_rails['geo_registry_replication_primary_api_url'] = 'https://primary.example.com:5050/'
   ```

1. Reconfigure the node for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

### Verify replication

To verify container registry replication is working, on the **secondary** site:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Nodes**.
   The initial replication, or "backfill", is probably still in progress.

You can monitor the synchronization process on each Geo site from the **primary** site's **Geo Nodes** dashboard in your browser.

## Troubleshooting

### Confirm that container registry replication is enabled

This can be done with a check using the [Rails console](../../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Geo::ContainerRepositoryRegistry.replication_enabled?
```

### Missing container registry notification event

1. When an image is pushed to the primary site's container registry, it should trigger a [Container Registry notification](../../packages/container_registry.md#configure-container-registry-notifications)
1. The primary site's container registry calls the primary site's API on `https://<example.com>/api/v4/container_registry_event/events`
1. The primary site inserts a record to the `geo_events` table with `replicable_name: 'container_repository', model_record_id: <ID of the container repository>`.
1. The record gets replicated by PostgreSQL to the secondary site's database.
1. The Geo Log Cursor service processes the new event and enqueues a Sidekiq job `Geo::EventWorker`

To verify this is working correctly, push an image to the registry on the primary site, and run the following command on the Rails console to verify that the notification was received, and processed into an event:

```ruby
Geo::Event.where(replicable_name: 'container_repository')
```

You can further verify this by checking `geo.log` for entries from `Geo::ContainerRepositorySyncService`.

### Registry events logs response status 401 Unauthorized unaccepted

`401 Unauthorized` errors indicate that the primary site's container registry notification is not accepted by the Rails application, preventing it from notifying GitLab that something was pushed.

To fix this, make sure that the authorization headers being sent with the registry notification match what's configured on the primary site, as should be done during step [Configure primary site](#configure-primary-site).

#### Registry error: `token from untrusted issuer: "<token>"`

To replicate a container image, Sidekiq uses JWT to authenticate itself towards the container registry. Geo replication takes it as a prerequisite that the [container registry configuration](../../packages/container_registry.md) has been done correctly.

Make sure that both sites share a single signing key pair, as instructed under [Configure secondary site](#configure-secondary-site), and that both container registries, plus primary and secondary sites are [all configured to use the same token issuer](../../packages/container_registry.md#configure-gitlab-and-registry-to-run-on-separate-nodes-linux-package-installations).

On multinode deployments, make sure that the issuer configured on the Sidekiq node matches the value configured on the registries.

### Manually trigger a container registry sync event

To help with troubleshooting, you can manually trigger the container registry replication process:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Sites**.
1. In **Replication Details** for a **Secondary Site**, select **Container Repositories**.
1. Select **Resync** for one row, or **Resync all**.

You can also manually trigger a resync by running the following commands on the secondary's Rails console:

```ruby
registry = Geo::ContainerRepositoryRegistry.first # Choose a Geo registry entry
registry.replicator.sync # Resync the container repository
pp registry.reload # Look at replication state fields

#<Geo::ContainerRepositoryRegistry:0x00007f54c2a36060
 id: 1,
 container_repository_id: 1,
 state: "2",
 retry_count: 0,
 last_sync_failure: nil,
 retry_at: nil,
 last_synced_at: Thu, 28 Sep 2023 19:38:05.823680000 UTC +00:00,
 created_at: Mon, 11 Sep 2023 15:38:06.262490000 UTC +00:00>
```

The `state` field represents sync state:

- `"0"`: pending sync (usually means it was never synced)
- `"1"`: started sync (a sync job is currently running)
- `"2"`: successfully synced
- `"3"`: failed to sync

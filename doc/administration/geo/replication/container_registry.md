---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Container registry for a secondary site **(PREMIUM SELF)**

You can set up a container registry on your **secondary** Geo site that mirrors the one on the **primary** Geo site.

NOTE:
The container registry replication is used only for disaster recovery purposes. We do not recommend
pulling the container registry data from the secondary. For a feature proposal to implement it in the
future, see [Geo: Accelerate container images by serving read request from secondary site](https://gitlab.com/gitlab-org/gitlab/-/issues/365864) for details.

## Supported container registries

Geo supports the following types of container registries:

- [Docker](https://docs.docker.com/registry/)
- [OCI](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)

## Supported image formats

The following container image formats are support by Geo:

- [Docker V2, schema 1](https://docs.docker.com/registry/spec/manifest-v2-1/)
- [Docker V2, schema 2](https://docs.docker.com/registry/spec/manifest-v2-2/)
- [OCI (Open Container Initiative)](https://github.com/opencontainers/image-spec)

In addition, Geo also supports [BuildKit cache images](https://github.com/moby/buildkit).

## Supported storage

### Docker

For more information on supported registry storage drivers see
[Docker registry storage drivers](https://docs.docker.com/registry/storage-drivers/)

Read the [Load balancing considerations](https://docs.docker.com/registry/deploying/#load-balancing-considerations)
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

1. SSH into your GitLab **primary** server and login as root (for GitLab HA, you only need a Registry node):

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

1. SSH into the node and login as the `root` user:

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

1. On the left sidebar, at the bottom, select **Admin Area**.
1. On the left sidebar, select **Geo > Nodes**.
   The initial replication, or "backfill", is probably still in progress.

You can monitor the synchronization process on each Geo site from the **primary** site's **Geo Nodes** dashboard in your browser.

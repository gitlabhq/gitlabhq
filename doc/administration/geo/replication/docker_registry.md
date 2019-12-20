# Docker Registry for a secondary node **(PREMIUM ONLY)**

You can set up a [Docker Registry](https://docs.docker.com/registry/) on your
**secondary** Geo node that mirrors the one on the **primary** Geo node.

## Storage support

Docker Registry currently supports a few types of storages. If you choose a
distributed storage (`azure`, `gcs`, `s3`, `swift`, or `oss`) for your Docker
Registry on the **primary** node, you can use the same storage for a **secondary**
Docker Registry as well. For more information, read the
[Load balancing considerations](https://docs.docker.com/registry/deploying/#load-balancing-considerations)
when deploying the Registry, and how to set up the storage driver for GitLab's
integrated [Container Registry](../../packages/container_registry.md#container-registry-storage-driver).

## Replicating Docker Registry

You can enable a storage-agnostic replication so it
can be used for cloud or local storages. Whenever a new image is pushed to the
primary node, each **secondary** node will pull it to its own container
repository.

To configure Docker Registry replication:

1. Configure the [**primary** node](#configure-primary-node).
1. Configure the [**secondary** node](#configure-secondary-node).
1. Verify Docker Registry [replication](#verify-replication).

### Configure **primary** node

Make sure that you have Container Registry set up and working on
the **primary** node before following the next steps.

We need to make Docker Registry send notification events to the
**primary** node.

1. SSH into your GitLab **primary** server and login as root:

   ```sh
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['notifications'] = [
     {
       'name' => 'geo_event',
       'url' => 'https://example.com/api/v4/container_registry_event/events',
       'timeout' => '500ms',
       'threshold' => 5,
       'backoff' => '1s',
       'headers' => {
         'Authorization' => ['<replace_with_a_secret_token>'] # An alphanumeric string. Case sensitive and must start with a letter.
       }
     }
   ]
   ```

   NOTE: **Note:**
   If you use an external Registry (not the one integrated with GitLab), you must add
   these settings to its configuration yourself. In this case, you will also have to specify
   notification secret in `registry.notification_secret` section of
   `/etc/gitlab/gitlab.rb` file.

   NOTE: **Note:**
   If you use GitLab HA, you will also have to specify
   the notification secret in `registry.notification_secret` section of
   `/etc/gitlab/gitlab.rb` file for every web node.

1. Reconfigure the **primary** node for the change to take effect:

   ```sh
   gitlab-ctl reconfigure
   ```

### Configure **secondary** node

Make sure you have Container Registry set up and working on
the **secondary** node before following the next steps.

The following steps should be done on each **secondary** node you're
expecting to see the Docker images replicated.

Because we need to allow the **secondary** node to communicate securely with
the **primary** node Container Registry, we need to have a single key
pair for all the nodes. The **secondary** node will use this key to
generate a short-lived JWT that is pull-only-capable to access the
**primary** node Container Registry.

1. SSH into the **secondary** node and login as the `root` user:

   ```sh
   sudo -i
   ```

1. Copy `/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key` from the **primary** to the **secondary** node.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['geo_registry_replication_enabled'] = true
   gitlab_rails['geo_registry_replication_primary_api_url'] = 'http://primary.example.com:4567/' # Primary registry address, it will be used by the secondary node to directly communicate to primary registry
   ```

1. Reconfigure the **secondary** node for the change to take effect:

   ```sh
   gitlab-ctl reconfigure
   ```

### Verify replication

To verify Container Registry replication is working, go to **Admin Area > Geo** (`/admin/geo/nodes`) on the **secondary** node.
The initial replication, or "backfill", will probably still be in progress.
You can monitor the synchronization process on each Geo node from the **primary** node's **Geo Nodes** dashboard in your browser.

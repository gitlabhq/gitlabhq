---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use the GitLab container registry metadata database with Geo
description: Use the GitLab container registry metadata database with Geo
---
Use the GitLab container registry with Geo to replicate container images. Each site's container registry metadata database is
independent and does not use Postgres replication.

Each secondary site should have its own
separate PostgreSQL instance for the metadata database.

## Create a GitLab instance with the container registry and Geo

Prerequisites:

- A new instance of GitLab.
- A configured container registry for the instance with no data.

To set up Geo support:

1. Set up Geo for a primary and secondary site. For more information, see [Set up Geo for two single-node sites](../../geo/setup/two_single_node_sites.md).
1. On the primary and the secondary sites, set up [the metadata database](../container_registry_metadata_database.md#new-installations) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database) for each site.
1. Configure [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Add container registries to existing Geo sites

Prerequisites:

- Two new instances of GitLab, set up as primary and secondary sites.
- A configured container registry for the primary site with no data.

To add container registries to existing Geo secondary sites:

1. On the secondary site, [enable the container registry](../container_registry.md).
1. On the primary and the secondary sites, set up [the metadata database](../container_registry_metadata_database.md#new-installations) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database) for each site.
1. Configure [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Add Geo support and container registry to an existing instance of GitLab

Prerequisites:

- An existing instance of GitLab with no container registry configured.
- No existing Geo site.

To add Geo support to an existing instance and container registries to both Geo sites:

1. Set up Geo for the existing instance (primary) and add a secondary site. For more information, see [Set up Geo for two single-node sites](../../geo/setup/two_single_node_sites.md).
1. On the primary and the secondary sites:
   1. [Enable the container registry](../container_registry.md#enable-the-container-registry).
   1. Set up [the metadata database](../container_registry_metadata_database.md#new-installations) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database) for each site.
1. Configure [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Add Geo support to an instance with a configured container registry

The following sections provide instructions to add Geo support to an existing instance of GitLab with a configured container registry.

You can set up either:

- An external database connection.
- The default container registry metadata database.

### Use an external container registry metadata database

Prerequisites:

- An existing instance of GitLab with a configured container registry.
- No existing Geo site.

To add Geo support to an existing instance and container registry to the secondary site:

1. Set up Geo for the existing instance (primary) and add a secondary site. For more information, see [Set up Geo for two single-node sites](../../geo/setup/two_single_node_sites.md).
1. On the secondary site:
   1. [enable the container registry](../container_registry.md#enable-the-container-registry).
   1. Set up [the metadata database](../container_registry_metadata_database.md#new-installations) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database).
1. Configure [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication).

### Use the default container registry metadata database

Prerequisites:

- An existing instance of GitLab with a configured container registry.
- A container registry metadata database that uses the default PostgreSQL instance.
- No existing Geo site.

In this scenario, the metadata database must be moved to an external PostgreSQL instance.

1. Follow the steps here to [move the metadata database to an external PostgreSQL instance](../../postgresql/moving.md).
1. Continue with the steps to [Add Geo support and container registry to an existing instance of GitLab](#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab).

## Migrate the container registry from legacy metadata

In this scenario, you must migrate the container registry from legacy metadata
to the external PostgreSQL metadata database on an existing Geo site.

Prerequisites:

- GitLab 17.3 or later (database metadata support)
- Geo configured on primary and secondary sites
- Container registries on both sites using legacy metadata
- Both registries must have existing data (images pushed)

### Migration Steps

Downtime depends on the import method. For recommendations on import methods, see [How to choose the right import method](../container_registry_metadata_database.md#how-to-choose-the-right-import-method).

{{< alert type="note" >}}

The registry being migrated is read-only during the import.

{{< /alert >}}

During migration, the rest of Geo replication continues.

To migrate your metadata database:

1. On secondary site, [migrate the existing legacy metadata to the new metadata database](../container_registry_metadata_database.md#existing-registries).
1. On the primary site, [migrate the existing legacy metadata to the new metadata database](../container_registry_metadata_database.md#existing-registries).
1. Verify Geo replication continues working.

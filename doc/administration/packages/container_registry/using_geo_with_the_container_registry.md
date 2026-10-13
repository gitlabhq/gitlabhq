---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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
1. On the primary and the secondary sites, set up [the metadata database](../container_registry_metadata_database_new_install.md) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database) for each site.
1. Configure [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Add container registries to existing Geo sites

Prerequisites:

- Two new instances of GitLab, set up as primary and secondary sites.
- A configured container registry for the primary site with no data.

To add container registries to existing Geo secondary sites:

1. On the secondary site, [enable the container registry](../container_registry.md).
1. On the primary and the secondary sites, set up [the metadata database](../container_registry_metadata_database_new_install.md) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database) for each site.
1. Configure [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Add Geo support and container registry to an existing instance of GitLab

Prerequisites:

- An existing instance of GitLab with no container registry configured.
- No existing Geo site.

To add Geo support to an existing instance and container registries to both Geo sites:

1. Set up Geo for the existing instance (primary) and add a secondary site. For more information, see [Set up Geo for two single-node sites](../../geo/setup/two_single_node_sites.md).
1. On the primary and the secondary sites:
   1. [Enable the container registry](../container_registry.md#enable-the-container-registry).
   1. Set up [the metadata database](../container_registry_metadata_database_new_install.md) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database) for each site.
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
   1. [Enable the container registry](../container_registry.md#enable-the-container-registry).
   1. Set up [the metadata database](../container_registry_metadata_database_new_install.md) using a separate, [external database](../container_registry_metadata_database.md#using-an-external-database).
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

Downtime depends on the import method. For recommendations on import methods, see [choose the right import method](../container_registry_metadata_database.md#choose-the-right-import-method).

> [!note]
> The registry being migrated is read-only during the import.

During migration, the rest of Geo replication continues.

To migrate your metadata database:

1. On the secondary site, [migrate the existing legacy metadata to the new metadata database](../container_registry_metadata_database.md#enable-the-database-for-existing-registries).
1. On the primary site, [migrate the existing legacy metadata to the new metadata database](../container_registry_metadata_database.md#enable-the-database-for-existing-registries).
1. Verify Geo replication continues working.

## Add or rebuild a secondary site when the primary is already migrated

Prerequisites:

- An existing Geo primary site whose container registry uses the metadata database and holds data. The primary reaches this state after you [migrate the container registry from legacy metadata](#migrate-the-container-registry-from-legacy-metadata).
- A secondary site to add, already [set up as a Geo site](../../geo/setup/two_single_node_sites.md),
  or an existing secondary site to rebuild.

The following steps replace the secondary site's registry storage and database together.
They are not the recovery path for a secondary site whose registry storage and database are both
intact.

> [!warning]
> Provision and migrate the secondary site's registry database before the secondary
> site's registry starts against storage that holds data. A registry that starts
> first has no schema to write to.
> In [prefer mode](../container_registry_metadata_database.md#prefer-mode),
> a registry that finds no lockfile does not fall back to
> legacy metadata. It requires a reachable database, and adopts an empty one
> and serves an empty catalog.

To add or rebuild the secondary site:

1. On the primary site, confirm the registry uses the metadata database and holds data.
   For how to confirm the backend, see [Verify which metadata backend is active](../container_registry_metadata_database.md#verify-which-metadata-backend-is-active). If the primary still uses legacy metadata, use [Migrate the container registry from legacy metadata](#migrate-the-container-registry-from-legacy-metadata)
   instead.
1. On the secondary site, prepare the registry state.
   Complete one of the following:
   - If you are rebuilding an existing secondary site,
     remove the registry state you are replacing:
     1. Stop the registry.
     1. Delete the contents of the registry's object storage.
     1. Drop and recreate the registry database on that site's registry database instance, using the database name and owner configured for that site's registry.
        For example, in `psql`:

        ```sql
        DROP DATABASE registry;
        CREATE DATABASE registry OWNER registry;
        ```

     Remove both the storage contents and the database.
     A site with a recreated database and populated storage matches neither this procedure
     nor the greenfield ones.
   - If you are adding a new secondary site,
     confirm the secondary site's registry object storage is empty.
     If the storage holds data or an earlier attempt left a registry database behind,
     treat the site as a rebuild and complete the previous path instead.
1. On the secondary site, configure the
   [registry database connection](../container_registry_metadata_database.md#using-an-external-database)
   with the database still disabled, then [reconfigure GitLab](../../restart_gitlab.md).
   The migration in the next step reads the connection from the registry configuration file,
   so the connection must be present before it runs.
1. On the secondary site,
   [apply the database migrations](../container_registry_metadata_database.md#apply-database-migrations).
1. On the secondary site, enable the database and [reconfigure GitLab](../../restart_gitlab.md).
1. Configure
   [container registry replication](../../geo/replication/container_registry.md#configure-container-registry-replication)
   for the secondary site, if it is not configured already.
1. Verify the secondary site holds the images. Compare against the primary site:
   - The catalog, from `/v2/_catalog`.
   - The tag list for a repository, and the `Docker-Content-Digest` response header for a tag.
     The digests must match.
   - Repository, manifest, and tag row counts in each site's own registry database.

Do not compare object counts between the two sites. A primary site migrated from legacy metadata retains its former metadata files, while a secondary site built on the metadata database stores only content blobs, so the primary always holds more objects.

A difference that grows with each push has another cause.
For one known cause on secondary sites that still use legacy metadata, see
[issue 590744](https://gitlab.com/gitlab-org/gitlab/-/issues/590744).

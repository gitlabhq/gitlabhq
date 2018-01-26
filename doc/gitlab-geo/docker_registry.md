# Docker Registry for a secondary node

You can setup a [Docker Registry](https://docs.docker.com/registry/) on your
secondary Geo node that mirrors the one on the primary Geo node.

## Storage support

CAUTION: **Warning:**
If you use [local storage](../administration/container_registry.md#container-registry-storage-driver)
for the Container Registry you **cannot** replicate it to the secondary Geo node.

Docker Registry currently supports a few types of storages. If you choose a
distributed storage (`azure`, `gcs`, `s3`, `swift`, or `oss`) for your Docker
Registry on a primary Geo node, you can use the same storage for a secondary
Docker Registry as well. For more information, read the
[Load balancing considerations](https://docs.docker.com/registry/deploying/#load-balancing-considerations)
when deploying the Registry, and how to setup the storage driver for GitLab's
integrated [Container Registry](../administration/container_registry.md#container-registry-storage-driver).

[ee]: https://about.gitlab.com/gitlab-ee/

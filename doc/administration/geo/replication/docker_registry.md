# Docker Registry for a secondary node **(PREMIUM ONLY)**

You can set up a [Docker Registry] on your
**secondary** Geo node that mirrors the one on the **primary** Geo node.

## Storage support

CAUTION: **Warning:**
If you use [local storage][registry-storage]
for the Container Registry you **cannot** replicate it to a **secondary** node.

Docker Registry currently supports a few types of storages. If you choose a
distributed storage (`azure`, `gcs`, `s3`, `swift`, or `oss`) for your Docker
Registry on the **primary** node, you can use the same storage for a **secondary**
Docker Registry as well. For more information, read the
[Load balancing considerations][registry-load-balancing]
when deploying the Registry, and how to set up the storage driver for GitLab's
integrated [Container Registry][registry-storage].

[ee]: https://about.gitlab.com/pricing/
[Docker Registry]: https://docs.docker.com/registry/
[registry-storage]: ../../container_registry.md#container-registry-storage-driver
[registry-load-balancing]: https://docs.docker.com/registry/deploying/#load-balancing-considerations

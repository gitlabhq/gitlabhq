---
stage: GitLab Dedicated
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Supported Geo data types
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

A Geo data type is a specific class of data that is required by one or more GitLab features to
store relevant information.

To replicate data produced by these features with Geo, we use several strategies to access, transfer, and verify them.

## Data types

We distinguish between the following different data types:

- [Git repositories](#git-repositories)
- [Container repositories](#container-repositories)
- [Blobs](#blobs)
- [Databases](#databases)

See the list below of each feature or component we replicate, its corresponding data type, replication, and
verification methods:

| Type                 | Feature / component                             | Replication method                           | Verification method           |
|:---------------------|:------------------------------------------------|:---------------------------------------------|:------------------------------|
| Database             | Application data in PostgreSQL                  | Native                                       | Native                        |
| Database             | Redis                                           | Not applicable[^replication-note]            | Not applicable                |
| Database             | SSH public keys                                 | PostgreSQL Replication                       | PostgreSQL Replication        |
| Git                  | Project repository                              | Geo with Gitaly                              | Gitaly Checksum               |
| Git                  | Project wiki repository                         | Geo with Gitaly                              | Gitaly Checksum               |
| Git                  | Project designs repository                      | Geo with Gitaly                              | Gitaly Checksum               |
| Git                  | Snippets                                        | Geo with Gitaly                              | Gitaly Checksum               |
| Git                  | Group wiki repository                           | Geo with Gitaly                              | Gitaly Checksum               |
| Blob                 | User uploads _(file system)_                    | Geo with API                                 | SHA256 checksum               |
| Blob                 | User uploads _(object storage)_                 | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | LFS objects _(file system)_                     | Geo with API                                 | SHA256 checksum               |
| Blob                 | LFS objects _(object storage)_                  | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | CI job artifacts _(file system)_                | Geo with API                                 | SHA256 checksum               |
| Blob                 | CI job artifacts _(object storage)_             | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Archived CI build traces _(file system)_        | Geo with API                                 | Not implemented             |
| Blob                 | Archived CI build traces _(object storage)_     | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Package registry _(file system)_                | Geo with API                                 | SHA256 checksum               |
| Blob                 | Package registry _(object storage)_             | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Packages Helm Metadata Cache _(file system)_    | Geo with API                                 | SHA256 checksum               |
| Blob                 | Packages Helm Metadata Cache _(object storage)_ | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Terraform Module Registry _(file system)_       | Geo with API                                 | SHA256 checksum               |
| Blob                 | Terraform Module Registry _(object storage)_    | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Versioned Terraform State _(file system)_       | Geo with API                                 | SHA256 checksum               |
| Blob                 | Versioned Terraform State _(object storage)_    | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | External merge request diffs _(file system)_    | Geo with API                                 | SHA256 checksum               |
| Blob                 | External merge request diffs _(object storage)_ | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Pipeline artifacts _(file system)_              | Geo with API                                 | SHA256 checksum               |
| Blob                 | Pipeline artifacts _(object storage)_           | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Pages _(file system)_                           | Geo with API                                 | SHA256 checksum               |
| Blob                 | Pages _(object storage)_                        | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Project-level CI Secure Files _(file system)_   | Geo with API                                 | SHA256 checksum               |
| Blob                 | Project-level CI Secure Files _(object storage)_ | Geo with API/Managed[^object-storage-provider-replication]           | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Incident Metric Images _(file system)_          | Geo with API/Managed                         | SHA256 checksum               |
| Blob                 | Incident Metric Images _(object storage)_       | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Alert Metric Images _(file system)_             | Geo with API                                 | SHA256 checksum               |
| Blob                 | Alert Metric Images _(object storage)_          | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Dependency Proxy Images _(file system)_         | Geo with API                                 | SHA256 checksum               |
| Blob                 | Dependency Proxy Images _(object storage)_      | Geo with API/Managed[^object-storage-provider-replication]            | SHA256 checksum[^object-storage-verification-note]  |
| Blob                 | Packages NuGet Symbol _(file system)_      |  Geo with API                                   | SHA256 checksum |
| Blob                 | Packages NuGet Symbol _(object storage)_              |  Geo with API/Managed[^object-storage-provider-replication]                           | SHA256 checksum[^object-storage-verification-note] |
| Container Repository | Container registry _(file system)_              | Geo with API/Docker API                      | SHA256 checksum               |
| Container Repository | Container registry _(object storage)_           | Geo with API/Managed/Docker API[^object-storage-provider-replication] | SHA256 checksum[^object-storage-verification-note]  |

[^replication-note]: Redis replication can be used as part of HA with Redis sentinel. It's not used between Geo sites.
[^object-storage-provider-replication]: Object storage replication can be performed by Geo or by your object storage provider/appliance native replication feature.
[^object-storage-verification-note]: See [Object storage verification](object_storage.md#object-storage-verification) for information about the feature flag `geo_object_storage_verification`, which is enabled by default.

### Git repositories

A GitLab instance can have one or more repository shards. Each shard has a Gitaly instance that
is responsible for allowing access and operations on the locally stored Git repositories. It can run
on a machine:

- With a single disk.
- With multiple disks mounted as a single mount-point (like with a RAID array).
- Using LVM.

GitLab does not require a special file system and can work with a mounted Storage Appliance. However, there can be
performance limitations and consistency issues when using a remote file system.

Geo triggers garbage collection in Gitaly to deduplicate forked repositories on Geo secondary sites.

The Gitaly gRPC API does the communication, with three possible ways of synchronization:

- Using regular Git clone/fetch from one Geo site to another (with special authentication).
- Using repository snapshots (for when the first method fails or the repository is corrupt).
- Manual trigger from the **Admin** area (combines the other listed possible ways).

Each project can have at most 3 different repositories:

- A project repository, where the source code is stored.
- A wiki repository, where the wiki content is stored.
- A design repository, where design artifacts are indexed (assets are actually in LFS).

They all live in the same shard and share the same base name with a `-wiki` and `-design` suffix
for Wiki and Design Repository cases.

Besides that, there are snippet repositories. They can be connected to a project or to some specific user.
Both types are synced to a secondary site.

### Container repositories

Container repositories are stored in the container registry. They are a
GitLab-specific concept built on top of a container registry as the datastore.

### Blobs

GitLab stores files and blobs such as Issue attachments or LFS objects into either:

- The file system in a specific location.
- An [Object Storage](../../object_storage.md) solution. Object Storage solutions can be:
  - Cloud based like Amazon S3 and Google Cloud Storage.
  - Self-hosted S3-compatible object storage.
  - A Storage Appliance that exposes an Object Storage-compatible API.

When using the file system store instead of Object Storage, use network mounted file systems
to run GitLab when using more than one node.

With respect to replication and verification:

- We transfer files and blobs using an internal API request.
- With Object Storage, you can either:
  - Use a cloud provider replication functionality.
  - Have GitLab replicate it for you.

### Databases

GitLab relies on data stored in multiple databases, for different use-cases.
PostgreSQL is the single point of truth for user-generated content in the Web interface, like issues content, comments
as well as permissions and credentials.

PostgreSQL can also hold some level of cached data like HTML-rendered Markdown and cached merge request diffs.
This can also be configured to be offloaded to object storage.

We use PostgreSQL's own replication functionality to replicate data from the primary to secondary sites.

We use Redis both as a cache store and to hold persistent data for our background jobs system. Because both
use-cases have data that are exclusive to the same Geo site, we don't replicate it between sites.

Elasticsearch is an optional database for advanced search. It can improve search
in both source-code level, and user generated content in issues, merge requests, and discussions.
Elasticsearch is not supported in Geo. After a failover,
[recover data for advanced search](../disaster_recovery/planned_failover.md#recover-data-for-advanced-search).

## Replicated data types

Replication for some data types is released behind feature flags that are enabled by default.
These feature flags can't be enabled or disabled per-project, and they're recommended for production use.
[GitLab administrators with access to the GitLab Rails console](../../feature_flags/_index.md) can
opt to disable them for your instance. You can find feature flag names of each of those data types in the notes column of the table below.

> [!warning]
> Features not on this list, or documented as not replicated,
> are not replicated to a secondary site. Failing over without manually
> replicating data from those features causes the data to be lost.
> To use those features on a secondary site, or to execute a failover
> successfully, you must replicate their data using some other means.

| Feature                                                                                                               | Replicated                                                                    | Verified                                                                      | GitLab-managed object storage replication                                       | GitLab-managed object storage verification                                      | Notes |
|:----------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:------|
| [Application data in PostgreSQL](../../postgresql/_index.md)                                                           | {{< yes >}}                                                                 | {{< yes >}}                                                                 | Not applicable                                                                  | Not applicable                                                                  | None  |
| [Project repository](../../../user/project/repository/_index.md)                                                       | {{< yes >}}                                                                 | {{< yes >}}                                                                 | Not applicable                                                                  | Not applicable                                                                  | Replication is behind feature flag `geo_project_repository_replication`, enabled by default.<br /><br /> All projects, including [archived projects](../../../user/project/working_with_projects.md#archive-a-project), are replicated. |
| [Project wiki repository](../../../user/project/wiki/_index.md)                                                        | {{< yes >}}                                                    | {{< yes >}}                                                    | Not applicable                                                                  | Not applicable                                                                  | Replication is behind feature flag `geo_project_wiki_repository_replication`, enabled by default. |
| [Group wiki repository](../../../user/project/wiki/group.md)                                                          | {{< yes >}}                                                                       | {{< yes >}}                                                                       | Not applicable                                                                  | Not applicable                                                                  | Replication is behind feature flag `geo_group_wiki_repository_replication`, enabled by default. |
| [User uploads](../../uploads.md)                                                                                           | {{< yes >}}                                                                 | {{< yes >}}                                                                 | {{< yes >}}                                                                        | {{< yes >}}[^object-storage-verification]                                                      | Replication is behind feature flag `geo_upload_replication`, enabled by default. |
| [LFS objects](../../lfs/_index.md)                                                                                    | {{< yes >}}                                                                   | {{< yes >}}                                                                   | {{< yes >}}                                                                     | {{< yes >}}[^object-storage-verification]                                                        | Replication is behind feature flag `geo_lfs_object_replication`, enabled by default. |
| [Snippets](../../../user/snippets.md)                                                                        | {{< yes >}}                                                                 | {{< yes >}}                                                                 | Not applicable                                                                  | Not applicable                                                                  | Replication is behind feature flag `geo_snippet_repository_replication`, enabled by default. Includes both personal and project snippets. |
| [CI job artifacts](../../../ci/jobs/job_artifacts.md)                                                              | {{< yes >}}                                                                 | {{< yes >}}                                                                | {{< yes >}}                                                                     | {{< yes >}}[^object-storage-verification]                                                          | Replication is behind feature flag `geo_job_artifact_replication`, enabled by default. On the primary site, checksumming continues unless `geo_job_artifact_force_primary_checksumming` is also disabled. See [Enable or disable replication](#enable-or-disable-replication-for-some-data-types). |
| Pipeline artifacts                                                                                                 | {{< yes >}}                                                                      | {{< yes >}}                                                                      | {{< yes >}}                                                                             | {{< yes >}}[^object-storage-verification]                                                          | Replication is behind feature flag `geo_pipeline_artifact_replication`, enabled by default. Persists additional artifacts after a pipeline completes. |
| [Project-level CI Secure Files](../../../ci/secure_files/_index.md)                    | {{< yes >}}                                                                      | {{< yes >}}                                                                      | {{< yes >}}                                                                       | {{< yes >}}[^object-storage-verification]                                                                | Replication is behind feature flag `geo_ci_secure_file_replication`, enabled by default. |
| [Container registry](../../packages/container_registry.md)                                                            | {{< yes >}}                                                          | {{< yes >}}                                                                       | {{< yes >}}                                                            | {{< yes >}}                                                                         | Replication is behind feature flag `geo_container_repository_replication`, enabled by default. See [instructions](container_registry.md) to set up the container registry replication. |
| [Terraform Module Registry](../../../user/packages/terraform_module_registry/_index.md)                                | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                             | {{< yes >}}[^object-storage-verification]                                                                 | Replication is behind feature flag `geo_package_file_replication`, enabled by default. |
| [Project designs repository](../../../user/project/issues/design_management.md)                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                       | Not applicable                                                                 | Not applicable                                                                 | Replication is behind feature flag `geo_design_management_repository_replication`, enabled by default. Designs also require replication of LFS objects and Uploads. |
| [Package registry](../../../user/packages/package_registry/_index.md)                                                  | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                         | {{< yes >}}[^object-storage-verification]                                                                | Replication is behind feature flag `geo_package_file_replication`, enabled by default. |
| [Packages Helm Metadata Cache](../../../user/packages/helm_repository/_index.md)                                      | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                              | {{< yes >}}                                                                                               | Replication is behind feature flag `geo_packages_helm_metadata_cache_replication`, enabled by default. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) in GitLab 18.10. |
| [Versioned Terraform State](../../terraform_state.md)                                                                 | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                              | {{< yes >}}[^object-storage-verification]                                                                 | Replication is behind feature flag `geo_terraform_state_version_replication`, enabled by default. |
| [External merge request diffs](../../merge_request_diffs.md)                                                          | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                              | {{< yes >}}[^object-storage-verification]                                                                 | Replication is behind feature flag `geo_merge_request_diff_replication`, enabled by default. |
| [Pages](../../pages/_index.md)                                                                                  | {{< yes >}}                                                                          | {{< yes >}}                                                                       | {{< yes >}}                                                                             | {{< yes >}}[^object-storage-verification]                                                               | Replication is behind feature flag `geo_pages_deployment_replication`, enabled by default. |
| [Incident Metric Images](../../../operations/incident_management/incidents.md#metrics)                                | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                         | {{< yes >}}[^object-storage-verification]                                                                 | Replication and verification are handled through the Uploads data type. |
| [Alert Metric Images](../../../operations/incident_management/alerts.md#metrics-tab)                                  | {{< yes >}}                                                                       | {{< yes >}}                                                                       | {{< yes >}}                                                                         | {{< yes >}}[^object-storage-verification]                                                                 | Replication and verification are handled through the Uploads data type. |
| [Dependency Proxy Images](../../../user/packages/dependency_proxy/_index.md)                                           | {{< yes >}}                                                       | {{< yes >}}                                                                           | {{< yes >}}                                                                           | {{< yes >}}[^object-storage-verification]                                                                 | Replication is behind feature flags `geo_dependency_proxy_blob_replication` and `geo_dependency_proxy_manifest_replication`, enabled by default. |
| [Packages NuGet Symbol](../../../user/packages/nuget_repository/_index.md#symbol-packages)                             | {{< yes >}}                                                                  | {{< yes >}}                                                                      | {{< yes >}}                                                                           | {{< yes >}}[^object-storage-verification]                                               | Replication is behind feature flag `geo_packages_nuget_symbol_replication`, enabled by default. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/422929) in GitLab 18.10. |
| Packages Debian ProjectComponentFile                                                                                  | {{< yes >}}                                                                   | {{< yes >}}                                                                      | {{< yes >}}                                                                        | {{< yes >}}                                                                        | Behind feature flag `geo_packages_debian_project_component_file_replication`, disabled by default. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/333611) in GitLab 19.1. |

[^object-storage-verification]: See [Object storage verification](object_storage.md#object-storage-verification) for information about the feature flag `geo_object_storage_verification`, which is enabled by default.

### Enable or disable replication (for some data types)

To disable, such as for package file replication:

```ruby
Feature.disable(:geo_package_file_replication)
```

To enable, such as for package file replication:

```ruby
Feature.enable(:geo_package_file_replication)
```

Disabling a `geo_<replicable>_replication` flag stops replication
and verification on secondary sites.
On the primary site, checksumming continues while the corresponding
`geo_<replicable>_force_primary_checksumming` flag is enabled (the default).
To stop checksumming on the primary site as well, disable both flags:

```ruby
Feature.disable(:geo_package_file_replication)
Feature.disable(:geo_package_file_force_primary_checksumming)
```

## Data types not replicated

Geo doesn't replicate data for the following features:

| Feature                                                                                             | Reason                                                                                                                                    | Tracking issue |
|:----------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------|:---------------|
| [Server-side Git hooks](../../server_hooks.md)                                                      | Current implementation complexity, low customer interest, and availability of alternatives to hooks.                                      | [Epic 1867](https://gitlab.com/groups/gitlab-org/-/work_items/1867) |
| [Elasticsearch](../../../integration/advanced_search/elasticsearch.md)                              | Further product discovery is required and Elasticsearch (ES) clusters can be rebuilt. Secondaries use the same ES cluster as the primary. | [Issue 1186](https://gitlab.com/gitlab-org/gitlab/-/work_items/1186) |
| [Exact code search (Zoekt)](../../../integration/zoekt/_index.md)                                   | None                                                                                                                                      | [Issue 509597](https://gitlab.com/gitlab-org/gitlab/-/work_items/509597) |
| [Vulnerability Export](../../../user/application_security/vulnerability_report/_index.md#exporting) | Exports are ephemeral and contain sensitive information. They can be regenerated on demand.                                               | [Epic 3111](https://gitlab.com/groups/gitlab-org/-/work_items/3111) |
| Packages NPM metadata cache                                                                         | Would not notably improve disaster recovery capabilities nor response times at secondary sites.                                           | [Issue 408278](https://gitlab.com/gitlab-org/gitlab/-/work_items/408278) |
| Packages Debian GroupComponentFile                                                                  | None                                                                                                                                      | [Issue 556945](https://gitlab.com/gitlab-org/gitlab/-/work_items/556945) |
| Packages Debian GroupDistribution                                                                   | None                                                                                                                                      | [Issue 556947](https://gitlab.com/gitlab-org/gitlab/-/work_items/556947) |
| Packages Debian ProjectDistribution                                                                 | None                                                                                                                                      | [Issue 556946](https://gitlab.com/gitlab-org/gitlab/-/work_items/556946) |
| Packages RPM RepositoryFile                                                                         | None                                                                                                                                      | [Issue 379055](https://gitlab.com/gitlab-org/gitlab/-/work_items/379055) |
| VirtualRegistries Maven Cache Entry                                                                 | None                                                                                                                                      | [Issue 473033](https://gitlab.com/gitlab-org/gitlab/-/work_items/473033) |
| SBOM Vulnerability Scan Data                                                                        | Data is temporary and has a short lifespan with limited impact on disaster recovery capabilities at secondary sites.                      | [Issue 398199](https://gitlab.com/gitlab-org/gitlab/-/work_items/398199) |

---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Supported Geo data types
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

A Geo data type is a specific class of data that is required by one or more GitLab features to
store relevant information.

To replicate data produced by these features with Geo, we use several strategies to access, transfer, and verify them.

## Data types

We distinguish between three different data types:

- [Git repositories](#git-repositories)
- [Blobs](#blobs)
- [Database](#database)

See the list below of each feature or component we replicate, its corresponding data type, replication, and
verification methods:

| Type     | Feature / component                             | Replication method                           | Verification method           |
|:---------|:------------------------------------------------|:---------------------------------------------|:------------------------------|
| Database | Application data in PostgreSQL                  | Native                                       | Native                        |
| Database | Redis                                           | Not applicable <sup>1</sup>                  | Not applicable                |
| Database | Elasticsearch                                   | Native                                       | Native                        |
| Database | SSH public keys                                 | PostgreSQL Replication                       | PostgreSQL Replication        |
| Git      | Project repository                              | Geo with Gitaly                              | Gitaly Checksum               |
| Git      | Project wiki repository                         | Geo with Gitaly                              | Gitaly Checksum               |
| Git      | Project designs repository                      | Geo with Gitaly                              | Gitaly Checksum               |
| Git      | Project Snippets                                | Geo with Gitaly                              | Gitaly Checksum               |
| Git      | Personal Snippets                               | Geo with Gitaly                              | Gitaly Checksum               |
| Git      | Group wiki repository                           | Geo with Gitaly                              | Gitaly Checksum               |
| Blobs    | User uploads _(file system)_                    | Geo with API                                 | SHA256 checksum               |
| Blobs    | User uploads _(object storage)_                 | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | LFS objects _(file system)_                     | Geo with API                                 | SHA256 checksum               |
| Blobs    | LFS objects _(object storage)_                  | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | CI job artifacts _(file system)_                | Geo with API                                 | SHA256 checksum               |
| Blobs    | CI job artifacts _(object storage)_             | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Archived CI build traces _(file system)_        | Geo with API                                 | _Not implemented_             |
| Blobs    | Archived CI build traces _(object storage)_     | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Container registry _(file system)_              | Geo with API/Docker API                      | SHA256 checksum               |
| Blobs    | Container registry _(object storage)_           | Geo with API/Managed/Docker API <sup>2</sup> | SHA256 checksum <sup>3</sup>  |
| Blobs    | Package registry _(file system)_                | Geo with API                                 | SHA256 checksum               |
| Blobs    | Package registry _(object storage)_             | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Terraform Module Registry _(file system)_       | Geo with API                                 | SHA256 checksum               |
| Blobs    | Terraform Module Registry _(object storage)_    | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Versioned Terraform State _(file system)_       | Geo with API                                 | SHA256 checksum               |
| Blobs    | Versioned Terraform State _(object storage)_    | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | External merge request diffs _(file system)_    | Geo with API                                 | SHA256 checksum               |
| Blobs    | External merge request diffs _(object storage)_ | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Pipeline artifacts _(file system)_              | Geo with API                                 | SHA256 checksum               |
| Blobs    | Pipeline artifacts _(object storage)_           | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Pages _(file system)_                           | Geo with API                                 | SHA256 checksum               |
| Blobs    | Pages _(object storage)_                        | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | CI Secure Files _(file system)_                 | Geo with API                                 | SHA256 checksum               |
| Blobs    | CI Secure Files _(object storage)_              | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Incident Metric Images _(file system)_          | Geo with API/Managed                         | SHA256 checksum               |
| Blobs    | Incident Metric Images _(object storage)_       | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Alert Metric Images _(file system)_             | Geo with API                                 | SHA256 checksum               |
| Blobs    | Alert Metric Images _(object storage)_          | Geo with API/Managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |
| Blobs    | Dependency Proxy Images_(file system)_          | Geo with API                                 | SHA256 checksum               |
| Blobs    | Dependency Proxy Images _(object storage)_      | Geo with API/managed <sup>2</sup>            | SHA256 checksum <sup>3</sup>  |

**Footnotes:**

1. Redis replication can be used as part of HA with Redis sentinel. It's not used between Geo sites.
1. Object storage replication can be performed by Geo or by your object storage provider/appliance
   native replication feature.
1. Object Storage verification is behind a [feature flag](../../feature_flags.md), `geo_object_storage_verification`, [introduced in 16.4](https://gitlab.com/groups/gitlab-org/-/epics/8056) and enabled by default. It uses a checksum of the file size to verify the files.

### Git repositories

A GitLab instance can have one or more repository shards. Each shard has a Gitaly instance that
is responsible for allowing access and operations on the locally stored Git repositories. It can run
on a machine:

- With a single disk.
- With multiple disks mounted as a single mount-point (like with a RAID array).
- Using LVM.

GitLab does not require a special file system and can work with a mounted Storage Appliance. However, there can be
performance limitations and consistency issues when using a remote file system.

Geo triggers garbage collection in Gitaly to [deduplicate forked repositories](../../../development/git_object_deduplication.md#git-object-deduplication-and-gitlab-geo) on Geo secondary sites.

The Gitaly gRPC API does the communication, with three possible ways of synchronization:

- Using regular Git clone/fetch from one Geo site to another (with special authentication).
- Using repository snapshots (for when the first method fails or repository is corrupt).
- Manual trigger from the **Admin** area (a combination of both of the above).

Each project can have at most 3 different repositories:

- A project repository, where the source code is stored.
- A wiki repository, where the wiki content is stored.
- A design repository, where design artifacts are indexed (assets are actually in LFS).

They all live in the same shard and share the same base name with a `-wiki` and `-design` suffix
for Wiki and Design Repository cases.

Besides that, there are snippet repositories. They can be connected to a project or to some specific user.
Both types are synced to a secondary site.

### Blobs

GitLab stores files and blobs such as Issue attachments or LFS objects into either:

- The file system in a specific location.
- An [Object Storage](../../object_storage.md) solution. Object Storage solutions can be:
  - Cloud based like Amazon S3 and Google Cloud Storage.
  - Hosted by you (like MinIO).
  - A Storage Appliance that exposes an Object Storage-compatible API.

When using the file system store instead of Object Storage, use network mounted file systems
to run GitLab when using more than one node.

With respect to replication and verification:

- We transfer files and blobs using an internal API request.
- With Object Storage, you can either:
  - Use a cloud provider replication functionality.
  - Have GitLab replicate it for you.

### Database

GitLab relies on data stored in multiple databases, for different use-cases.
PostgreSQL is the single point of truth for user-generated content in the Web interface, like issues content, comments
as well as permissions and credentials.

PostgreSQL can also hold some level of cached data like HTML-rendered Markdown and cached merge-requests diff.
This can also be configured to be offloaded to object storage.

We use PostgreSQL's own replication functionality to replicate data from the **primary** to **secondary** sites.

We use Redis both as a cache store and to hold persistent data for our background jobs system. Because both
use-cases have data that are exclusive to the same Geo site, we don't replicate it between sites.

Elasticsearch is an optional database for advanced search. It can improve search
in both source-code level, and user generated content in issues, merge requests, and discussions.
Elasticsearch is not supported in Geo.

## Replicated data types

### Replicated data types behind a feature flag

The replication for some data types is behind a corresponding feature flag:

> - They're deployed behind a feature flag, enabled by default.
> - They're enabled on GitLab.com.
> - They can't be enabled or disabled per-project.
> - They are recommended for production use.
> - For a GitLab Self-Managed instance, GitLab administrators can opt to [disable them](#enable-or-disable-replication-for-some-data-types).

#### Enable or disable replication (for some data types)

Replication for some data types are released behind feature flags that are **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../feature_flags.md) can opt to disable it for your instance. You can find feature flag names of each of those data types in the notes column of the table below.

To disable, such as for package file replication:

```ruby
Feature.disable(:geo_package_file_replication)
```

To enable, such as for package file replication:

```ruby
Feature.enable(:geo_package_file_replication)
```

WARNING:
Features not on this list, or with **No** in the **Replicated** column,
are not replicated to a **secondary** site. Failing over without manually
replicating data from those features causes the data to be **lost**.
To use those features on a **secondary** site, or to execute a failover
successfully, you must replicate their data using some other means.

| Feature                                                                                                               | Replicated (added in GitLab version)                                          | Verified (added in GitLab version)                                            | GitLab-managed object storage replication (added in GitLab version)             | GitLab-managed object storage verification (added in GitLab version)            | Notes |
|:----------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:------|
| [Application data in PostgreSQL](../../postgresql/_index.md)                                                           | **Yes** (10.2)                                                                | **Yes** (10.2)                                                                | Not applicable                                                                  | Not applicable                                                                  |       |
| [Project repository](../../../user/project/repository/_index.md)                                                       | **Yes** (10.2)                                                                | **Yes** (10.7)                                                                | Not applicable                                                                  | Not applicable                                                                  | Migrated to [self-service framework](../../../development/geo/framework.md) in 16.2. See GitLab issue [#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925) for more details.<br /><br />Behind feature flag `geo_project_repository_replication`, enabled by default in (16.3).<br /><br /> All projects, including [archived projects](../../../user/project/working_with_projects.md#archive-a-project), are replicated. |
| [Project wiki repository](../../../user/project/wiki/_index.md)                                                        | **Yes** (10.2)<sup>2</sup>                                                    | **Yes** (10.7)<sup>2</sup>                                                    | Not applicable                                                                  | Not applicable                                                                  | Migrated to [self-service framework](../../../development/geo/framework.md) in 15.11. See GitLab issue [#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925) for more details.<br /><br />Behind feature flag `geo_project_wiki_repository_replication`, enabled by default in (15.11). |
| [Group wiki repository](../../../user/project/wiki/group.md)                                                          | [**Yes** (13.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)       | [**Yes** (16.3)](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)        | Not applicable                                                                  | Not applicable                                                                  | Behind feature flag `geo_group_wiki_repository_replication`, enabled by default. |
| [Uploads](../../uploads.md)                                                                                           | **Yes** (10.2)                                                                | **Yes** (14.6)                                                                | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Replication is behind the feature flag `geo_upload_replication`, enabled by default. Verification was behind the feature flag `geo_upload_verification`, removed in 14.8. |
| [LFS objects](../../lfs/_index.md)                                                                                     | **Yes** (10.2)                                                                | **Yes** (14.6)                                                                | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | GitLab versions 11.11.x and 12.0.x are affected by [a bug that prevents any new LFS objects from replicating](https://gitlab.com/gitlab-org/gitlab/-/issues/32696).<br /><br />Replication is behind the feature flag `geo_lfs_object_replication`, enabled by default. Verification was behind the feature flag `geo_lfs_object_verification`, removed in 14.7. |
| [Personal snippets](../../../user/snippets.md)                                                                        | **Yes** (10.2)                                                                | **Yes** (10.2)                                                                | Not applicable                                                                  | Not applicable                                                                  |       |
| [Project snippets](../../../user/snippets.md)                                                                         | **Yes** (10.2)                                                                | **Yes** (10.2)                                                                | Not applicable                                                                  | Not applicable                                                                  |       |
| [CI job artifacts](../../../ci/jobs/job_artifacts.md)                                                                 | **Yes** (10.4)                                                                | **Yes** (14.10)                                                               | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Verification is behind the feature flag `geo_job_artifact_replication`, enabled by default in 14.10. |
| [CI Pipeline Artifacts](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/pipeline_artifact.rb)        | [**Yes** (13.11)](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**Yes** (13.11)](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Persists additional artifacts after a pipeline completes. |
| [CI Secure Files](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb)                    | [**Yes** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**Yes** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**Yes** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430)   | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Verification is behind the feature flag `geo_ci_secure_file_replication`, enabled by default in 15.3. |
| [Container registry](../../packages/container_registry.md)                                                            | **Yes** (12.3)<sup>1</sup>                                                    | **Yes** (15.10)                                                               | **Yes** (12.3)<sup>1</sup>                                                      | **Yes** (15.10)                                                                 | See [instructions](container_registry.md) to set up the container registry replication. |
| [Terraform Module Registry](../../../user/packages/terraform_module_registry/_index.md)                                | **Yes** (14.0)                                                                | **Yes** (14.0)                                                                | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Behind feature flag `geo_package_file_replication`, enabled by default. |
| [Project designs repository](../../../user/project/issues/design_management.md)                                       | **Yes** (12.7)                                                                | **Yes** (16.1)                                                                | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Designs also require replication of LFS objects and Uploads. |
| [Package registry](../../../user/packages/package_registry/_index.md)                                                  | **Yes** (13.2)                                                                | **Yes** (13.10)                                                               | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Behind feature flag `geo_package_file_replication`, enabled by default. |
| [Versioned Terraform State](../../terraform_state.md)                                                                 | **Yes** (13.5)                                                                | **Yes** (13.12)                                                               | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Replication is behind the feature flag `geo_terraform_state_version_replication`, enabled by default. Verification was behind the feature flag `geo_terraform_state_version_verification`, which was removed in 14.0. |
| [External merge request diffs](../../merge_request_diffs.md)                                                          | **Yes** (13.5)                                                                | **Yes** (14.6)                                                                | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Replication is behind the feature flag `geo_merge_request_diff_replication`, enabled by default. Verification was behind the feature flag `geo_merge_request_diff_verification`, removed in 14.7. |
| [Versioned snippets](../../../user/snippets.md#versioned-snippets)                                                    | [**Yes** (13.7)](https://gitlab.com/groups/gitlab-org/-/epics/2809)           | [**Yes** (14.2)](https://gitlab.com/groups/gitlab-org/-/epics/2810)           | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Verification was implemented behind the feature flag `geo_snippet_repository_verification` in 13.11, and the feature flag was removed in 14.2. |
| [GitLab Pages](../../pages/_index.md)                                                                                  | [**Yes** (14.3)](https://gitlab.com/groups/gitlab-org/-/epics/589)            | **Yes** (14.6)                                                                | [**Yes** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Behind feature flag `geo_pages_deployment_replication`, enabled by default. Verification was behind the feature flag `geo_pages_deployment_verification`, removed in 14.7. |
| [Project-level Secure files](../../../ci/secure_files/_index.md)                                                       | **Yes** (15.3)                                                                | **Yes** (15.3)                                                                | **Yes** (15.3)                                                                  | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [Incident Metric Images](../../../operations/incident_management/incidents.md#metrics)                                | **Yes** (15.5)                                                                | **Yes** (15.5)                                                                | **Yes** (15.5)                                                                  | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Replication/Verification is handled via the Uploads data type. |
| [Alert Metric Images](../../../operations/incident_management/alerts.md#metrics-tab)                                  | **Yes** (15.5)                                                                | **Yes** (15.5)                                                                | **Yes** (15.5)                                                                  | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Replication/Verification is handled via the Uploads data type. |
| [Server-side Git hooks](../../server_hooks.md)                                                                        | [Not planned](https://gitlab.com/groups/gitlab-org/-/epics/1867)              | No                                                                            | Not applicable                                                                  | Not applicable                                                                  | Not planned because of current implementation complexity, low customer interest, and availability of alternatives to hooks. |
| [Elasticsearch integration](../../../integration/advanced_search/elasticsearch.md)                                    | [Not planned](https://gitlab.com/gitlab-org/gitlab/-/issues/1186)             | No                                                                            | No                                                                              | No                                                                              | Not planned because further product discovery is required and Elasticsearch (ES) clusters can be rebuilt. Secondaries use the same ES cluster as the primary. |
| [Dependency Proxy Images](../../../user/packages/dependency_proxy/_index.md)                                           | [**Yes** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**Yes** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**Yes** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**Yes** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [Vulnerability Export](../../../user/application_security/vulnerability_report/_index.md#export-vulnerability-details) | [Not planned](https://gitlab.com/groups/gitlab-org/-/epics/3111)              | No                                                                            | No                                                                              | No                                                                              | Not planned because they are ephemeral and sensitive information. They can be regenerated on demand. |
| Packages NPM metadata cache                                                                                           | [Not planned](https://gitlab.com/gitlab-org/gitlab/-/issues/408278)           | No                                                                            | No                                                                              | No                                                                              | Not planned because it would not notably improve disaster recovery capabilities nor response times at secondary sites. |

**Footnotes:**

1. Migrated to [self-service framework](../../../development/geo/framework.md) in 15.5. See GitLab issue [#337436](https://gitlab.com/gitlab-org/gitlab/-/issues/337436) for more details.
1. Migrated to [self-service framework](../../../development/geo/framework.md) in 15.11. Behind feature flag `geo_project_wiki_repository_replication`, enabled by default. See GitLab issue [#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925) for more details.
1. Verification of files stored in object storage was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8056) in GitLab 16.4 [with a feature flag](../../feature_flags.md) named `geo_object_storage_verification`, enabled by default.

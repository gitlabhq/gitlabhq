---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Geo data types support **(PREMIUM ONLY)**

A Geo data type is a specific class of data that is required by one or more GitLab features to
store relevant information.

To replicate data produced by these features with Geo, we use several strategies to access, transfer, and verify them.

## Data types

We currently distinguish between three different data types:

- [Git repositories](#git-repositories)
- [Blobs](#blobs)
- [Database](#database)

See the list below of each feature or component we replicate, its corresponding data type, replication, and
verification methods:

| Type     | Feature / component                             | Replication method                    | Verification method    |
|:---------|:------------------------------------------------|:--------------------------------------|:-----------------------|
| Database | Application data in PostgreSQL                  | Native                                | Native                 |
| Database | Redis                                           | _N/A_ (*1*)                           | _N/A_                  |
| Database | Elasticsearch                                   | Native                                | Native                 |
| Database | SSH public keys                                 | PostgreSQL Replication                | PostgreSQL Replication |
| Git      | Project repository                              | Geo with Gitaly                       | Gitaly Checksum        |
| Git      | Project wiki repository                         | Geo with Gitaly                       | Gitaly Checksum        |
| Git      | Project designs repository                      | Geo with Gitaly                       | Gitaly Checksum        |
| Git      | Object pools for forked project deduplication   | Geo with Gitaly                       | _Not implemented_      |
| Git      | Project Snippets                                | Geo with Gitaly                       | _Not implemented_      |
| Git      | Personal Snippets                               | Geo with Gitaly                       | _Not implemented_      |
| Blobs    | User uploads _(filesystem)_                     | Geo with API                          | _Not implemented_      |
| Blobs    | User uploads _(object storage)_                 | Geo with API/Managed (*2*)            | _Not implemented_      |
| Blobs    | LFS objects _(filesystem)_                      | Geo with API                          | _Not implemented_      |
| Blobs    | LFS objects _(object storage)_                  | Geo with API/Managed (*2*)            | _Not implemented_      |
| Blobs    | CI job artifacts _(filesystem)_                 | Geo with API                          | _Not implemented_      |
| Blobs    | CI job artifacts _(object storage)_             | Geo with API/Managed (*2*)            | _Not implemented_      |
| Blobs    | Archived CI build traces _(filesystem)_         | Geo with API                          | _Not implemented_      |
| Blobs    | Archived CI build traces _(object storage)_     | Geo with API/Managed (*2*)            | _Not implemented_      |
| Blobs    | Container registry _(filesystem)_               | Geo with API/Docker API               | _Not implemented_      |
| Blobs    | Container registry _(object storage)_           | Geo with API/Managed/Docker API (*2*) | _Not implemented_      |
| Blobs    | Package registry _(filesystem)_                 | Geo with API                          | _Not implemented_      |
| Blobs    | Package registry _(object storage)_             | Geo with API/Managed (*2*)            | _Not implemented_      |
| Blobs    | Versioned Terraform State _(filesystem)_        | Geo with API                          | _Not implemented_      |
| Blobs    | Versioned Terraform State _(object storage)_    | Geo with API/Managed (*2*)            | _Not implemented_      |
| Blobs    | External Merge Request Diffs _(filesystem)_     | Geo with API                          | _Not implemented_      |
| Blobs    | External Merge Request Diffs _(object storage)_ | Geo with API/Managed (*2*)            | _Not implemented_      |

- (*1*): Redis replication can be used as part of HA with Redis sentinel. It's not used between Geo nodes.
- (*2*): Object storage replication can be performed by Geo or by your object storage provider/appliance
         native replication feature.

### Git repositories

A GitLab instance can have one or more repository shards. Each shard has a Gitaly instance that
is responsible for allowing access and operations on the locally stored Git repositories. It can run
on a machine with a single disk, multiple disks mounted as a single mount-point (like with a RAID array),
or using LVM.

It requires no special filesystem and can work with NFS or a mounted Storage Appliance (there may be
performance limitations when using a remote filesystem).

Communication is done via Gitaly's own gRPC API. There are three possible ways of synchronization:

- Using regular Git clone/fetch from one Geo node to another (with special authentication).
- Using repository snapshots (for when the first method fails or repository is corrupt).
- Manual trigger from the Admin UI (a combination of both of the above).

Each project can have at most 3 different repositories:

- A project repository, where the source code is stored.
- A wiki repository, where the wiki content is stored.
- A design repository, where design artifacts are indexed (assets are actually in LFS).

They all live in the same shard and share the same base name with a `-wiki` and `-design` suffix
for Wiki and Design Repository cases.

Besides that, there are snippet repositories. They can be connected to a project or to some specific user.
Both types will be synced to a secondary node.

### Blobs

GitLab stores files and blobs such as Issue attachments or LFS objects into either:

- The filesystem in a specific location.
- An [Object Storage](../../object_storage.md) solution. Object Storage solutions can be:
  - Cloud based like Amazon S3 Google Cloud Storage.
  - Hosted by you (like MinIO).
  - A Storage Appliance that exposes an Object Storage-compatible API.

When using the filesystem store instead of Object Storage, you need to use network mounted filesystems
to run GitLab when using more than one server.

With respect to replication and verification:

- We transfer files and blobs using an internal API request.
- With Object Storage, you can either:
  - Use a cloud provider replication functionality.
  - Have GitLab replicate it for you.

### Database

GitLab relies on data stored in multiple databases, for different use-cases.
PostgreSQL is the single point of truth for user-generated content in the Web interface, like issues content, comments
as well as permissions and credentials.

PostgreSQL can also hold some level of cached data like HTML rendered Markdown, cached merge-requests diff (this can
also be configured to be offloaded to object storage).

We use PostgreSQL's own replication functionality to replicate data from the **primary** to **secondary** nodes.

We use Redis both as a cache store and to hold persistent data for our background jobs system. Because both
use-cases has data that are exclusive to the same Geo node, we don't replicate it between nodes.

Elasticsearch is an optional database, that can enable advanced searching capabilities, like improved Global Search
in both source-code level and user generated content in Issues / Merge-Requests and discussions. Currently it's not
supported in Geo.

## Limitations on replication/verification

The following table lists the GitLab features along with their replication
and verification status on a **secondary** node.

You can keep track of the progress to implement the missing items in
these epics/issues:

- [Geo: Build a scalable, self-service Geo replication and verification framework](https://gitlab.com/groups/gitlab-org/-/epics/2161)
- [Geo: Improve the self-service Geo replication framework](https://gitlab.com/groups/gitlab-org/-/epics/3761)
- [Geo: Move existing blobs to framework](https://gitlab.com/groups/gitlab-org/-/epics/3588)
- [Geo: Add unreplicated data types](https://gitlab.com/groups/gitlab-org/-/epics/893)
- [Geo: Support GitLab Pages](https://gitlab.com/groups/gitlab-org/-/epics/589)

### Replicated data types behind a feature flag

The replication for some data types is behind a corresponding feature flag:

> - They're deployed behind a feature flag, enabled by default.
> - They're enabled on GitLab.com.
> - They can't be enabled or disabled per-project.
> - They are recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable them](#enable-or-disable-replication-for-some-data-types). **(CORE ONLY)**

#### Enable or disable replication (for some data types) **(CORE ONLY)**

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

DANGER: **Warning:**
Features not on this list, or with **No** in the **Replicated** column,
are not replicated on the **secondary** node. Failing over without manually
replicating data from those features will cause the data to be **lost**.
If you wish to use those features on a **secondary** node, or to execute a failover
successfully, you must replicate their data using some other means.

| Feature                                                                                                        | Replicated (added in GitLab version)                                               | Verified (added in GitLab version)                        | Object Storage replication (see [Geo with Object Storage](object_storage.md)) | Notes                                                                                                                                                                                                                                                                                                                      |
|:---------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------|:----------------------------------------------------------|:-------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Application data in PostgreSQL](../../postgresql/index.md)                                                    | **Yes** (10.2)                                                                     | **Yes** (10.2)                                            | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Project repository](../../..//user/project/repository/)                                                       | **Yes** (10.2)                                                                     | **Yes** (10.7)                                            | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Project wiki repository](../../../user/project/wiki/)                                                         | **Yes** (10.2)                                                                     | **Yes** (10.7)                                            | No                                                                                   |
| [Group wiki repository](../../../user/group/index.md#group-wikis)     | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)                                                                  | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)           | No                                                                                   |                                                                                                                                                                                                                                                                                                                                 |
| [Uploads](../../uploads.md)                                                                                    | **Yes** (10.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | No                                                                                   | Verified only on transfer or manually using [Integrity Check Rake Task](../../raketasks/check.md) on both nodes and comparing the output between them.                                                                                                                                                                     |
| [LFS objects](../../lfs/index.md)                                                                              | **Yes** (10.2)                                                                     | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/8922)  | Via Object Storage provider if supported. Native Geo support (Beta).                 | Verified only on transfer or manually using [Integrity Check Rake Task](../../raketasks/check.md) on both nodes and comparing the output between them. GitLab versions 11.11.x and 12.0.x are affected by [a bug that prevents any new LFS objects from replicating](https://gitlab.com/gitlab-org/gitlab/-/issues/32696). |
| [Personal snippets](../../../user/snippets.md#personal-snippets)                                               | **Yes** (10.2)                                                                     | **Yes** (10.2)                                            | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Project snippets](../../../user/snippets.md#project-snippets)                                                 | **Yes** (10.2)                                                                     | **Yes** (10.2)                                            | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [CI job artifacts (other than Job Logs)](../../../ci/pipelines/job_artifacts.md)                               | **Yes** (10.4)                                                                     | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/8923)  | Via Object Storage provider if supported. Native Geo support (Beta) .                | Verified only manually using [Integrity Check Rake Task](../../raketasks/check.md) on both nodes and comparing the output between them                                                                                                                                                                                     |
| [Job logs](../../job_logs.md)                                                                                  | **Yes** (10.4)                                                                     | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/8923)  | Via Object Storage provider if supported. Native Geo support (Beta).                 | Verified only on transfer or manually using [Integrity Check Rake Task](../../raketasks/check.md) on both nodes and comparing the output between them                                                                                                                                                                      |
| [Object pools for forked project deduplication](../../../development/git_object_deduplication.md)              | **Yes**                                                                            | No                                                        | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Container Registry](../../packages/container_registry.md)                                                     | **Yes** (12.3)                                                                     | No                                                        | No                                                                                | Disabled by default. See [instructions](docker_registry.md) to enable.                                                                                                                                                                                                                                                                                                                             |
| [Content in object storage (beta)](object_storage.md)                                                          | **Yes** (12.4)                                                                     | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/13845) | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Project designs repository](../../../user/project/issues/design_management.md)                                | **Yes** (12.7)                                                                     | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/32467) | Via Object Storage provider if supported. Native Geo support (Beta).                 |                                                                                                                                                                                                                                                                                                                            |
| [NPM Registry](../../../user/packages/npm_registry/index.md)                                                   | **Yes** (13.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [Maven Repository](../../../user/packages/maven_repository/index.md)                                           | **Yes** (13.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [Conan Repository](../../../user/packages/conan_repository/index.md)                                           | **Yes** (13.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [NuGet Repository](../../../user/packages/nuget_repository/index.md)                                           | **Yes** (13.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [PyPI Repository](../../../user/packages/pypi_repository/index.md)                                             | **Yes** (13.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [Composer Repository](../../../user/packages/composer_repository/index.md)                                     | **Yes** (13.2)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [Generic packages](../../../user/packages/generic_packages/index.md)                                | **Yes** (13.5)                                                                     | [No](https://gitlab.com/groups/gitlab-org/-/epics/1817)   | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_package_file_replication`, enabled by default                                                                                                                                                                                                                                                     |
| [Versioned Terraform State](../../terraform_state.md)                                                          | **Yes** (13.5)                                                                     | No                                                        | Via Object Storage provider if supported. Native Geo support (Beta).                 | Behind feature flag `geo_terraform_state_version_replication`, enabled by default                                                                                                                                                                                                                                          |
| [External merge request diffs](../../merge_request_diffs.md)                                                   | **Yes** (13.5)                          | No                                                        |  Via Object Storage provider if supported. Native Geo support (Beta).                 |  Behind feature flag `geo_merge_request_diff_replication`, enabled by default                                                                                                                                                                                                                                                                                                                          |
| [Versioned snippets](../../../user/snippets.md#versioned-snippets)                                             | [**Yes** (13.7)](https://gitlab.com/groups/gitlab-org/-/epics/2809)                            | [No](https://gitlab.com/groups/gitlab-org/-/epics/2810)   | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Server-side Git hooks](../../server_hooks.md)                                                                 | [No](https://gitlab.com/groups/gitlab-org/-/epics/1867)                            | No                                                        | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [Elasticsearch integration](../../../integration/elasticsearch.md)                                             | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/1186)                           | No                                                        | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [GitLab Pages](../../pages/index.md)                                                                           | [No](https://gitlab.com/groups/gitlab-org/-/epics/589)                             | No                                                        | No                                                                                   |                                                                                                                                                                                                                                                                                                                            |
| [CI Pipeline Artifacts](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/pipeline_artifact.rb) | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)                         | No                                                        | Via Object Storage provider if supported. Native Geo support (Beta).                 | Persists additional artifacts after a pipeline completes                                                                                                                                                                                                                                                                   |
| [Dependency proxy images](../../../user/packages/dependency_proxy/index.md)                                    | [No](https://gitlab.com/gitlab-org/gitlab/-/issues/259694)                         | No                                                        | No                                                                                   | Blocked on [Geo: Secondary Mimicry](https://gitlab.com/groups/gitlab-org/-/epics/1528). Note that replication of this cache is not needed for Disaster Recovery purposes because it can be recreated from external sources.                                                                                                |
| [Vulnerability Export](../../../user/application_security/security_dashboard/#export-vulnerabilities)          | [Not planned](https://gitlab.com/groups/gitlab-org/-/epics/3111)                   | No                                                        | Via Object Storage provider if supported. Native Geo support (Beta).                 | Not planned because they are ephemeral and sensitive. They can be regenerated on demand.                                                                                                                                                                                                                                   |

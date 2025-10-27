---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zoekt
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags/_index.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
- Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.

{{< /history >}}

{{< alert type="warning" >}}

This feature is in [beta](../../policy/development_stages_support.md#beta) and subject to change without notice.
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).
To provide feedback on this feature, leave a comment on
[issue 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920).

{{< /alert >}}

Zoekt is an open-source search engine designed specifically to search for code.

With this integration, you can use [exact code search](../../user/search/exact_code_search.md)
instead of [advanced search](../../user/search/advanced_search.md) to search for code in GitLab.
You can use exact match and regular expression modes to search for code in a group or repository.

## Install Zoekt

Prerequisites:

- You must have administrator access to the instance.

To [enable exact code search](#enable-exact-code-search) in GitLab,
you must have at least one Zoekt node connected to the instance.
The following installation methods are supported for Zoekt:

- [Zoekt chart](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/)
  (as a standalone chart or subchart of the GitLab Helm chart)
- [GitLab Operator](https://docs.gitlab.com/operator/) (with `gitlab-zoekt.install=true`)

The following installation methods are available for testing, not for production use:

- [Docker Compose](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/tree/main/example/docker-compose)
- [Ansible playbook](https://gitlab.com/gitlab-org/search-team/code-search/ansible-gitlab-zoekt)

## Enable exact code search

Prerequisites:

- You must have administrator access to the instance.
- You must [install Zoekt](#install-zoekt).

To enable [exact code search](../../user/search/exact_code_search.md) in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. Select the **Enable indexing** and **Enable searching** checkboxes.
1. Select **Save changes**.

## Check indexing status

{{< history >}}

- Stopping indexing when Zoekt node storage exceeds the critical watermark [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/504945) in GitLab 17.7 [with a flag](../../administration/feature_flags/_index.md) named `zoekt_critical_watermark_stop_indexing`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/505334) in GitLab 18.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/505334) in GitLab 18.1. Feature flag `zoekt_critical_watermark_stop_indexing` removed.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

Indexing performance depends on the CPU and memory limits on the Zoekt indexer nodes.
To check indexing status:

{{< tabs >}}

{{< tab title="GitLab 17.10 and later" >}}

Run this Rake task:

```shell
gitlab-rake gitlab:zoekt:info
```

To have the data refresh automatically every 10 seconds, run this task instead:

```shell
gitlab-rake "gitlab:zoekt:info[10]"
```

{{< /tab >}}

{{< tab title="GitLab 17.9 and earlier" >}}

In a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session), run these commands:

```ruby
Search::Zoekt::Index.group(:state).count
Search::Zoekt::Repository.group(:state).count
Search::Zoekt::Task.group(:state).count
```

{{< /tab >}}

{{< /tabs >}}

### Sample output

The `gitlab:zoekt:info` Rake task returns an output similar to the following:

```console
Exact Code Search
GitLab version:                           18.4.0
Enable indexing:                          yes
Enable searching:                         yes
Pause indexing:                           no
Index root namespaces automatically:      yes
Cache search results for five minutes:    yes
Indexing CPU to tasks multiplier:         1.0
Number of parallel processes per indexing task: 1
Number of namespaces per indexing rollout: 32
Offline nodes automatically deleted after: 20m
Indexing timeout per project:             30m
Maximum number of files per project to be indexed: 500000
Retry interval for failed namespaces:    1d

Nodes
# Number of Zoekt nodes and their status
Node count:                               2 (online: 2, offline: 0)
Last seen at:                             2025-09-15 22:58:09 UTC (less than a minute ago)
Max schema_version:                       2531
Storage reserved / usable:                71.1 MiB / 124 GiB (0.06%)
Storage indexed / reserved:               42.7 MiB / 71.1 MiB (60.0%)
Storage used / total:                     797 GiB / 921 GiB (86.54%)
Online node watermark levels:            2
  - low: 2

Indexing status
Group count:                              8
# Number of enabled namespaces and their status
EnabledNamespace count:                   8 (without indices: 0, rollout blocked: 0, with search disabled: 0)
Replicas count:                           8
  - ready: 8
Indices count:                            8
  - ready: 8
Indices watermark levels:                 8
  - healthy: 8
Repositories count:                       10
  - ready: 10
Tasks count:                              10
  - done: 10
Tasks pending/processing by type:         (none)

Feature Flags (Non-Default Values)
Feature flags:                            none

Feature Flags (Default Values)
- zoekt_cross_namespace_search:           disabled
- zoekt_debug_delete_repo_logging:        disabled
- zoekt_load_balancer:                    disabled
- zoekt_rollout_worker:                   enabled
- zoekt_search_meta_project_ids:          disabled
- zoekt_traversal_id_queries:             enabled

Node Details
Node 1 - test-zoekt-hostname-1:
  Status:                                 Online
  Last seen at:                           2025-09-15 22:58:09 UTC (less than a minute ago)
  Disk utilization:                       86.54%
  Unclaimed storage:                      62 GiB
  # Zoekt build version on the node. Must match GitLab version.
  Zoekt version:                          2025.09.14-v1.4.4-30-g0e7414a
  Schema version:                         2531
Node 2 - test-zoekt-hostname-2:
  Status:                                 Online
  Last seen at:                           2025-09-15 22:58:09 UTC (less than a minute ago)
  Disk utilization:                       86.54%
  Unclaimed storage:                      62 GiB
  Zoekt version:                          2025.09.14-v1.4.4-30-g0e7414a
  Schema version:                         2531
```

## Run a health check

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203671) in GitLab 18.4.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

Run a health check to understand the status of your Zoekt infrastructure, including:

- Online and offline nodes
- Indexing and search settings
- Search API endpoints
- JSON web token generation

To run a health check, execute the following task:

```shell
gitlab-rake gitlab:zoekt:health
```

This task provides:

- The overall status: `HEALTHY`, `DEGRADED`, or `UNHEALTHY`
- Recommendations for resolving detected issues
- Exit codes for automation and monitoring integrations: `0=healthy`, `1=degraded`, or `2=unhealthy`

### Run checks automatically

To run health checks automatically every 10 seconds, execute the following task:

```shell
gitlab-rake "gitlab:zoekt:health[10]"
```

The output includes colored status indicators and shows:

- Online and offline node counts, storage usage warnings, and connectivity issues
- Core settings validation and namespace and repository indexing statuses
- The overall status including a combined health assessment: `HEALTHY`, `DEGRADED`, or `UNHEALTHY`
- Recommendations for resolving issues

## Pause indexing

Prerequisites:

- You must have administrator access to the instance.

To pause indexing for [exact code search](../../user/search/exact_code_search.md):

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. Select the **Pause indexing** checkbox.
1. Select **Save changes**.

When you pause indexing for exact code search, all changes in your repository are queued.
To resume indexing, clear the **Pause indexing for exact code search** checkbox.

## Index root namespaces automatically

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/455533) in GitLab 17.1.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can index both existing and new root namespaces automatically.
To index all root namespaces automatically:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. Select the **Index root namespaces automatically** checkbox.
1. Select **Save changes**.

When you enable this setting, GitLab creates indexing tasks for all projects in:

- All groups and subgroups
- Any new root namespace

After a project is indexed, GitLab creates only incremental indexing when a repository change is detected.

When you disable this setting:

- Existing root namespaces remain indexed.
- New root namespaces are no longer indexed.

## Cache search results

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/523213) in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can cache search results for better performance.
This feature is enabled by default and caches results for five minutes.

To cache search results:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. Select the **Cache search results for five minutes** checkbox.
1. Select **Save changes**.

## Set concurrent indexing tasks

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481725) in GitLab 17.4.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can set the number of concurrent indexing tasks for a Zoekt node relative to its CPU capacity.

A higher multiplier means more tasks can run concurrently, which would
improve indexing throughput at the cost of increased CPU usage.
The default value is `1.0` (one task per CPU core).

You can adjust this value based on the node's performance and workload.
To set the number of concurrent indexing tasks:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Indexing CPU to tasks multiplier** text box, enter a value.

   For example, if a Zoekt node has `4` CPU cores and the multiplier is `1.5`,
   the number of concurrent tasks for the node is `6`.

1. Select **Save changes**.

## Set the number of parallel processes per indexing task

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/539526) in GitLab 18.1.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can set the number of parallel processes per indexing task.

A higher number would improve indexing time at the cost of increased CPU and memory usage.
The default value is `1` (one process per indexing task).

You can adjust this value based on the node's performance and workload.
To set the number of parallel processes per indexing task:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Number of parallel processes per indexing task** text box, enter a value.
1. Select **Save changes**.

## Set the number of namespaces per indexing rollout

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536175) in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can set the number of namespaces per `RolloutWorker` job for initial indexing.
The default value is `32`.
You can adjust this value based on the node's performance and workload.

To set the number of namespaces per indexing rollout:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Number of namespaces per indexing rollout** text box,
   enter a number greater than zero.
1. Select **Save changes**.

## Define when offline nodes are automatically deleted

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/487162) in GitLab 17.5.
- **Delete offline nodes after 12 hours** checkbox [updated](https://gitlab.com/gitlab-org/gitlab/-/issues/536178) to **Offline nodes automatically deleted after** text box in GitLab 18.1.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can delete offline Zoekt nodes automatically after a specific period of time
along with their related indices, repositories, and tasks.
The default value is `12h` (12 hours).

Use this setting to manage your Zoekt infrastructure and prevent orphaned resources.
To define when offline nodes are automatically deleted:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Offline nodes automatically deleted after** text box, enter a value
   (for example, `30m` (30 minutes), `2h` (two hours), or `1d` (one day)).
   To disable automatic deletion, set to `0`.
1. Select **Save changes**.

## Define the indexing timeout for a project

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581) in GitLab 18.2.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can define the indexing timeout for a project.
The default value is `30m` (30 minutes).

To define the indexing timeout for a project:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Indexing timeout per project** text box, enter a value
   (for example, `30m` (30 minutes), `2h` (two hours), or `1d` (one day)).
1. Select **Save changes**.

## Set the maximum number of files in a project to be indexed

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/539526) in GitLab 18.2.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can set the maximum number of files in a project that can be indexed.
Projects with more files than this limit in the default branch are not indexed.

The default value is `500,000`.

You can adjust this value based on the node's performance and workload.
To set the maximum number of files in a project to be indexed:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Maximum number of files per project to be indexed** text box, enter a number greater than zero.
1. Select **Save changes**.

## Define the retry interval for failed namespaces

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581) in GitLab 17.10.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

You can define the retry interval for namespaces that previously failed.
The default value is `1d` (one day).
A value of `0` means failed namespaces never retry.

To define the retry interval for failed namespaces:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search configuration**.
1. In the **Retry interval for failed namespaces** text box, enter a value
   (for example, `30m` (30 minutes), `2h` (two hours), or `1d` (one day)).
1. Select **Save changes**.

## Run Zoekt on a separate server

{{< history >}}

- Authentication for Zoekt [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389749) in GitLab 16.3.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

To run Zoekt on a different server than GitLab:

1. [Change the Gitaly listening interface](../../administration/gitaly/configure_gitaly.md#change-the-gitaly-listening-interface).
1. [Install Zoekt](#install-zoekt).

## Sizing recommendations

The following recommendations might be over-provisioned for some deployments.
You should monitor your deployment to ensure:

- No out-of-memory events occur.
- CPU throttling is not excessive.
- Indexing performance meets your requirements.

Adjust resources based on your specific workload characteristics, including:

- Repository size and complexity
- Number of active developers
- Frequency of code changes
- Indexing patterns

### Nodes

For optimal performance, proper sizing of Zoekt nodes is crucial.
Sizing recommendations differ between Kubernetes and VM deployments
due to how resources are allocated and managed.

#### Kubernetes deployments

The following table shows recommended resources for Kubernetes deployments
based on index storage requirements:

| Disk   | Webserver CPU | Webserver memory  | Indexer CPU | Indexer memory |
|--------|---------------|-------------------|-------------|----------------|
| 128 GB | 1             | 16 GiB            | 1           | 6 GiB  |
| 256 GB | 1.5           | 32 GiB            | 1           | 8 GiB  |
| 512 GB | 2             | 64 GiB            | 1           | 12 GiB |
| 1 TB   | 3             | 128 GiB           | 1.5         | 24 GiB |
| 2 TB   | 4             | 256 GiB           | 2           | 32 GiB |

To manage resources more granularly, you can allocate
CPU and memory separately to different containers.

For Kubernetes deployments:

- Do not set CPU limits for Zoekt containers.
  CPU limits might cause unnecessary throttling during indexing bursts,
  which would significantly impact performance.
  Instead, rely on resource requests to guarantee minimum CPU availability
  and ensure containers use additional CPU when available and needed.
- Set appropriate memory limits to prevent resource contention
  and out-of-memory conditions.
- Use high-performance storage classes for better indexing performance.
  GitLab.com uses `pd-balanced` on GCP, which balances performance and cost.
  Equivalent options include `gp3` on AWS and `Premium_LRS` on Azure.

#### VM and bare metal deployments

The following table shows recommended resources for VM and bare metal deployments
based on index storage requirements:

| Disk   | VM size  | Total CPU | Total memory | AWS          | GCP             | Azure |
|--------|----------|-----------|--------------|--------------|-----------------|-------|
| 128 GB | Small    | 2 cores   | 16 GB        | `r5.large`   | `n1-highmem-2`  | `Standard_E2s_v3`  |
| 256 GB | Medium   | 4 cores   | 32 GB        | `r5.xlarge`  | `n1-highmem-4`  | `Standard_E4s_v3`  |
| 512 GB | Large    | 4 cores   | 64 GB        | `r5.2xlarge` | `n1-highmem-8`  | `Standard_E8s_v3`  |
| 1 TB   | X-Large  | 8 cores   | 128 GB       | `r5.4xlarge` | `n1-highmem-16` | `Standard_E16s_v3` |
| 2 TB   | 2X-Large | 16 cores  | 256 GB       | `r5.8xlarge` | `n1-highmem-32` | `Standard_E32s_v3` |

You can allocate these resources only to the entire node.

For VM and bare metal deployments:

- Monitor CPU, memory, and disk usage to identify bottlenecks.
  Both webserver and indexer processes share the same CPU and memory resources.
- Consider using SSD storage for better indexing performance.
- Ensure adequate network bandwidth for data transfer between GitLab and Zoekt nodes.

### Storage

Storage requirements for Zoekt vary significantly based on repository characteristics,
including the number of large and binary files.

As a starting point, you can estimate your Zoekt storage to be half your Gitaly storage.
For example, if your Gitaly storage is 1 TB, you might need approximately 500 GB of Zoekt storage.

To monitor the use of Zoekt nodes, see [check indexing status](#check-indexing-status).
If namespaces are not being indexed due to low disk space, consider adding or scaling up nodes.

## Security and authentication

Zoekt implements a multi-layered authentication system to secure communication
between GitLab, Zoekt indexer, and Zoekt webserver components.
Authentication is enforced across all communication channels.

All authentication methods use the GitLab Shell secret.
Failed authentication attempts return `401 Unauthorized` responses.

### Zoekt indexer to GitLab

The Zoekt indexer authenticates to GitLab with JSON web tokens (JWT)
to retrieve indexing tasks and send completion callbacks.

This method uses `.gitlab_shell_secret` for signing and verification.
Tokens are sent in the `Gitlab-Shell-Api-Request` header.
Endpoints include:

- `GET /internal/search/zoekt/:uuid/heartbeat` for task retrieval
- `POST /internal/search/zoekt/:uuid/callback` for status updates

This method ensures secure polling for task distribution and
status reporting between Zoekt indexer nodes and GitLab.

### GitLab to the Zoekt webserver

#### JWT authentication

{{< history >}}

- JWT authentication [introduced](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/releases/v1.0.0) in GitLab Zoekt 1.0.0.

{{< /history >}}

GitLab authenticates to the Zoekt webserver with JSON web tokens (JWT)
to execute search queries.
JWT tokens provide time-limited, cryptographically signed authentication
consistent with other GitLab authentication patterns.

This method uses `Gitlab::Shell.secret_token` and the HS256 algorithm (HMAC with SHA-256).
Tokens are sent in the `Authorization: Bearer <jwt_token>` header
and expire in five minutes to limit exposure.

Endpoints include `/webserver/api/search` and `/webserver/api/v2/search`.
JWT claims are the issuer (`gitlab`) and the audience (`gitlab-zoekt`).

#### Basic authentication

GitLab authenticates to the Zoekt webserver with HTTP basic authentication
through NGINX to execute search queries.
Basic authentication is used primarily in GitLab Helm chart and Kubernetes deployments.

This method uses the username and password configured in Kubernetes secrets.
Endpoints include `/webserver/api/search` and `/webserver/api/v2/search`
on the Zoekt webserver.

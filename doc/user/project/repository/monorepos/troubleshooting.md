---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting monorepo performance
---

Review these suggestions for performance problems with monorepos.

## Slowness during `git clone` or `git fetch`

There are a few key causes of slowness with clones and fetches.

### High CPU utilization

If the CPU utilization on your Gitaly nodes is high, you can also check
how much CPU is taken up from clones by [filtering on certain values](observability.md#cpu-and-memory).

In particular, the `command.cpu_time_ms` field can indicate how
much CPU is being taken up by clones and fetches.

In most cases, the bulk of server load is generated from `git-pack-objects`
processes, which is initiated during clones and fetches. Monorepos are often very busy
and CI/CD systems send a lot of clone and fetch commands to the server.

High CPU utilization is a common cause of slow performance.
The following non-mutually exclusive causes are possible:

- [Too many clones for Gitaly to handle](#cause-too-many-large-clones).
- [Poor read distribution on Gitaly Cluster](#cause-poor-read-distribution).

#### Cause: too many large clones

You might have too many large clones for Gitaly to handle. Gitaly can struggle to keep up
because of a number of factors:

- The size of a repository.
- The volume of clones and fetches.
- Lack of CPU capacity.

To help Gitaly process many large clones, you might need to reduce the burden on Gitaly servers through some optimization strategies
such as:

- Turn on [pack-objects-cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)
  to reduce the work that `git-pack-objects` has to do.
- Change [Git strategy](_index.md#git-strategy)
  in CI/CD settings from `clone` to `fetch` or `none`.
- [Stop fetching tags](_index.md#git-fetch-extra-flags),
  unless your tests require them.
- [Use shallow clones](_index.md#shallow-cloning)
  whenever possible.

The other option is to increase CPU capacity on Gitaly servers.

#### Cause: poor read distribution

You might have poor read distribution on Gitaly Cluster.

To observe if most read traffic is going to the primary Gitaly node instead of
getting distributed across the cluster, use the
[read distribution Prometheus metric](observability.md#read-distribution).

If the secondary Gitaly nodes aren't receiving much traffic, it might be that
the secondary nodes are perpetually out of sync. This problem is exacerbated in
a monorepo.

Monorepos are often both large and busy. This leads to two effects. Firstly,
monorepos are pushed to often and have lots of CI jobs running. There can be
times when write operations such as deleting a branch fails a proxy call to the
secondary nodes. This triggers a replication job in Gitaly Cluster so that
the secondary node will catch up eventually.

The replication job is essentially a `git fetch` from the secondary node to the
primary node, and because monorepos are often very large, this fetch can take a
long time.

If the next call fails before the previous replication job completes, and this
keeps happening, you can end up in a state where your monorepo is constantly
behind in its secondaries. This leads to all traffic going to the primary node.

One reason for these failed proxied writes is a known issue with the Git
`$GIT_DIR/packed-refs` file. The file must be locked to
remove an entry in the file, which can lead to a race condition that causes a
delete to fail when concurrent deletes happen.

Engineers at GitLab have developed mitigations to try to batch reference deletions.

Turn on the following [feature flags](../../../../administration/feature_flags.md) to allow GitLab to batch ref deletions.
These feature flags do not need downtime to enable.

- `merge_request_cleanup_ref_worker_async`
- `pipeline_cleanup_ref_worker_async`
- `pipeline_delete_gitaly_refs_in_batches`
- `merge_request_delete_gitaly_refs_in_batches`

[Epic 4220](https://gitlab.com/groups/gitlab-org/-/epics/4220) proposes to add RefTable support in GitLab,
which is considered a long-term solution.

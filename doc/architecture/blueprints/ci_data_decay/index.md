---
stage: none
group: unassigned
comments: false
description: 'CI/CD data time decay'
---

# CI/CD data time decay

## Summary

GitLab CI/CD is one of the most data and compute intensive components of GitLab.
Since its [initial release in November 2012](https://about.gitlab.com/blog/2012/11/13/continuous-integration-server-from-gitlab/),
the CI/CD subsystem has evolved significantly. It was [integrated into GitLab in September 2015](https://about.gitlab.com/releases/2015/09/22/gitlab-8-0-released/)
and has become [one of the most beloved CI/CD solutions](https://about.gitlab.com/blog/2017/09/27/gitlab-leader-continuous-integration-forrester-wave/).

On February 1st, 2021, GitLab.com surpassed 1 billion CI/CD builds, and the number of
builds [continues to grow exponentially](../ci_scale/index.md).

GitLab CI/CD has come a long way since the initial release, but the design of
the data storage for pipeline builds remains almost the same since 2012. In
2021 we started working on database decomposition and extracting CI/CD data to
ia separate database. Now we want to improve the architecture of GitLab CI/CD
product to enable further scaling.

*Disclaimer: The following contain information related to upcoming products,
features, and functionality.

It is important to note that the information presented is for informational
purposes only. Please do not rely on this information for purchasing or
planning purposes.

As with all projects, the items mentioned in this document and linked pages are
subject to change or delay. The development, release and timing of any
products, features, or functionality remain at the sole discretion of GitLab
Inc.*

## Goals

**Implement a new architecture of CI/CD data storage to enable scaling.**

## Challenges

There are more than two billion rows describing CI/CD builds in GitLab.com's
database. This data represents a sizable portion of the whole data stored in
PostgreSQL database running on GitLab.com.

This volume contributes to significant performance problems, development
challenges and is often related to production incidents.

We also expect a [significant growth in the number of builds executed on
GitLab.com](../ci_scale/index.md) in the upcoming years.

## Opportunity

CI/CD data is subject to
[time-decay](https://about.gitlab.com/company/team/structure/working-groups/database-scalability/time-decay.html)
because, usually, pipelines that are a few months old are not frequently
accessed or are even not relevant anymore. Restricting access to processing
pipelines that are older than a few months might help us to move this data out
of the primary database, to a different storage, that is more performant and
cost effective.

It is already possible to prevent processing builds [that have been
archived](../../../user/admin_area/settings/continuous_integration.md#archive-jobs).
When a build gets archived it will not be possible to retry it, but we still do
keep all the processing metadata in the database, and it consumes resources
that are scarce in the primary database.

In order to improve performance and make it easier to scale CI/CD data storage
we might want to follow these three tracks described below.

![pipeline data time decay](pipeline_data_time_decay.png)

<!-- markdownlint-disable MD029 -->

1. Partition builds queuing tables
2. Archive CI/CD data into partitioned database schema
3. Migrate archived builds metadata out of primary database

<!-- markdownlint-enable MD029 -->

### Migrate archived builds metadata out of primary database

Once a build (or a pipeline) gets archived, it is no longer possible to resume
pipeline processing in such pipeline. It means that all the metadata, we store
in PostgreSQL, that is needed to efficiently and reliably process builds can be
safely moved to a different data store.

Currently, storing pipeline processing data is expensive as this kind of CI/CD
data represents a significant portion of data stored in CI/CD tables. Once we
restrict access to processing archived pipelines, we can move this metadata to
a different place - preferably object storage - and make it accessible on
demand, when it is really needed again (for example for compliance or auditing purposes).

We need to evaluate whether moving data is the most optimal solution. We might
be able to use de-duplication of metadata entries and other normalization
strategies to consume less storage while retaining ability to query this
dataset. Technical evaluation will be required to find the best solution here.

Epic: [Migrate archived builds metadata out of primary database](https://gitlab.com/groups/gitlab-org/-/epics/7216).

### Archive CI/CD data into partitioned database schema

After we move CI/CD metadata to a different store, the problem of having
billions of rows describing pipelines, builds and artifacts, remains. We still
need to keep reference to the metadata we store in object storage and we still
do need to be able to retrieve this information reliably in bulk (or search
through it).

It means that by moving data to object storage we might not be able to reduce
the number of rows in CI/CD tables. Moving data to object storage should help
with reducing the data size, but not the quantity of entries describing this
data. Because of this limitation, we still want to partition CI/CD data to
reduce the impact on the database (indices size, auto-vacuum time and
frequency).

Our intent here is not to move this data out of our primary database elsewhere.
What want to divide very large database tables, that store CI/CD data, into
multiple smaller ones, using PostgreSQL partitioning features.

There are a few approaches we can take to partition CI/CD data. A promising one
is using list-based partitioning where a partition number is assigned a
pipeline, and gets propagated to all resources that are related to this
pipeline. We assign the partition number based on when the pipeline was created
or when we observed the last processing activity in it. This is very flexible
because we can extend this partitioning strategy at will; for example with this
strategy we can assign an arbitrary partition number based on multiple
partitioning keys, combining time-decay-based partitioning with tenant-based
partitioning on the application level.

Partitioning rarely accessed data should also follow the policy defined for
builds archival, to make it consistent and reliable.

Epic: [Archive CI/CD data into partitioned database schema](https://gitlab.com/groups/gitlab-org/-/epics/5417).

### Partition builds queuing tables

While working on the [CI/CD Scale](../ci_scale/index.md) blueprint, we have
introduced a [new architecture for queuing CI/CD builds](https://gitlab.com/groups/gitlab-org/-/epics/5909#note_680407908)
for execution.

This allowed us to significantly improve performance. We still consider the new
solution as an intermediate mechanism, needed before we start working on the
next iteration. The following iteration that should improve the architecture of
builds queuing even more (it might require moving off the PostgreSQL fully or
partially).

In the meantime we want to ship another iteration, an intermediate step towards
more flexible and reliable solution. We want to partition the new queuing
tables, to reduce the impact on the database, to improve reliability and
database health.

Partitioning of CI/CD queuing tables does not need to follow the policy defined
for builds archival. Instead we should leverage a long-standing policy saying
that builds created more 24 hours ago need to be removed from the queue. This
business rule is present in the product since the inception of GitLab CI.

Epic: [Partition builds queuing tables](https://gitlab.com/gitlab-org/gitlab/-/issues/347027).

## Principles

All the three tracks we will use to implement CI/CD time decay pattern are
associated with some challenges. As we progress with the implementation we will
need to solve many problems and devise many implementation details to make this
successful.

Below, we documented a few foundational principles to make it easier for
everyone to understand the vision described in this architectural blueprint.

### Removing pipeline data

While it might be tempting to simply remove old or archived data from our
databases this should be avoided. It is usually not desired to permanently
remove user data unless consent is given to do so. We can, however, move data
to a different data store, like object storage.

Archived data can still be needed sometimes (for example for compliance or
auditing reasons). We want to be able to retrieve this data if needed, as long
as permanent removal has not been requested or approved by a user.

### Accessing pipeline data in the UI

Implementing CI/CD data time-decay through partitioning might be challenging
when we still want to make it possible for users to access data stored in many
partitions.

We want to retain simplicity of accessing pipeline data in the UI. It will
require some backstage changes in how we reference pipeline data from other
resources, but we don't want to make it more difficult for users to find their
pipelines in the UI.

We may need to add "Archived" tab on the pipelines / builds list pages, but we
should be able to avoid additional steps / clicks when someone wants to view
pipeline status or builds associated with a merge request or a deployment.

We also may need to disable search in the "Archived" tab on pipelines / builds
list pages.

### Accessing pipeline data through the API

We accept the possible necessity of building a separate API endpoint /
endpoints needed to access pipeline data through the API.

In the new API users might need to provide a time range in which the data has
been created to search through their pipelines / builds. In order to make it
efficient it might be necessary to restrict access to querying data residing in
more than two partitions at once. We can do that by supporting time ranges
spanning the duration that equals to the builds archival policy.

It is possible to still allow users to use the old API to access archived
pipelines data, although a user provided partition identifier may be required.

## Iterations

All three tracks can be worked on in parallel:

1. [Migrate archived build metadata to object storage](https://gitlab.com/groups/gitlab-org/-/epics/7216).
1. [Partition CI/CD data that have been archived](https://gitlab.com/groups/gitlab-org/-/epics/5417).
1. [Partition CI/CD queuing tables using list partitioning](https://gitlab.com/gitlab-org/gitlab/-/issues/347027)

## Status

In progress.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Grzegorz Bizon          |
| Engineering Leader           | Cheryl Li               |
| Product Manager              | Jackie Porter           |
| Architecture Evolution Coach | Kamil Trzciński         |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   | Cheryl Li              |
| Product                      | Jackie Porter          |
| Engineering                  | Grzegorz Bizon         |

Domain experts:

| Area                         | Who
|------------------------------|------------------------|
| Verify / Pipeline execution  | Fabio Pitino           |
| Verify / Pipeline execution  | Marius Bobin           |
| PostgreSQL Database          | Andreas Brandl         |

<!-- vale gitlab.Spelling = YES -->

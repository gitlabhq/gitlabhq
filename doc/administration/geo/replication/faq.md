---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo Frequently Asked Questions
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

## What are the minimum requirements to run Geo?

The requirements are listed [on the index page](../_index.md#requirements-for-running-geo)

## How does Geo know which projects to sync?

On each **secondary** site, there is a read-only replicated copy of the GitLab database.
A **secondary** site also has a tracking database where it stores which projects have been synced.
Geo compares the two databases to find projects that are not yet tracked.

At the start, this tracking database is empty, so Geo tries to update from every project that it can see in the GitLab database.

For each project to sync:

1. Geo issues a `git fetch geo --mirror` to get the latest information from the **primary** site.
   If there are no changes, the sync is fast. Otherwise, it has to pull the latest commits.
1. The **secondary** site updates the tracking database to store the fact that it has synced projects by name.
1. Repeat until all projects are synced.

When someone pushes a commit to the **primary** site, it generates an event in the GitLab database that the repository has changed.
The **secondary** site sees this event, marks the project in question as dirty, and schedules the project to be resynced.

To ensure that problems with pipelines (for example, syncs failing too many times or jobs being lost) don't permanently stop projects syncing, Geo also periodically checks the tracking database for projects that are marked as dirty. This check happens when
the number of concurrent syncs falls below `repos_max_capacity` and there are no new projects waiting to be synced.

Geo also has a checksum feature which runs a SHA256 sum across all the Git references to the SHA values.
If the refs don't match between the **primary** site and the **secondary** site, then the **secondary** site marks that project as dirty and try to resync it.
So even if we have an outdated tracking database, the validation should activate and find discrepancies in the repository state and resync.

## Can you use Geo in a disaster recovery situation?

Yes, but there are limitations to what we replicate (see
[What data is replicated to a **secondary** site?](#what-data-is-replicated-to-a-secondary-site)).

Read the documentation for [Disaster Recovery](../disaster_recovery/_index.md).

## What data is replicated to a **secondary** site?

We replicate the whole rails database, project repositories, LFS objects, generated
attachments, avatars and more. This means information such as user accounts,
issues, merge requests, groups, and project data are available for
query.

For a comprehensive list of data replicated by Geo, see the [supported Geo data types page](datatypes.md).

## Can I `git push` to a **secondary** site?

Pushing directly to a **secondary** site (for both HTTP and SSH, including Git LFS) is supported.

## How long does it take to have a commit replicated to a **secondary** site?

All replication operations are asynchronous and are queued to be dispatched. Therefore, it depends on a lot of
factors such as the amount of traffic, how big your commit is, the
connectivity between your sites, and your hardware.

## What if the SSH server runs at a different port?

That's totally fine. We use HTTP(s) to fetch repository changes from the **primary** site to all **secondary** sites.

## Can I make a container registry for a secondary site to mirror the primary?

Yes, however, we only support this for Disaster Recovery scenarios. See [container registry for a **secondary** site](container_registry.md).

## Can you sign in to a secondary site?

Yes, but secondary sites receive all authentication data (like user accounts and logins) from the primary instance. This means you are re-directed to the primary for authentication and then routed back.

## Do all Geo sites need to be the same as the primary?

No, Geo sites can be based on different reference architectures. For example, you can have the primary site based on a 3K reference architecture, one secondary site based 3K reference architecture, and another one based on a 1K reference architecture.

## Does Geo replicate archived projects?

Yes, provided they are not excluded through [selective sync](../replication/selective_synchronization.md).

## Does Geo replicate personal projects?

Yes, provided they are not excluded through [selective sync](../replication/selective_synchronization.md).

## Are delayed deletion projects replicated to secondary sites?

Yes, projects scheduled for deletion by [delayed deletion](../../settings/visibility_and_access_controls.md#delayed-project-deletion), but are yet to be permanently deleted, are replicated to secondary sites.

## What happens to my secondary sites with when my primary site goes down?

When a primary site goes down,
[your secondary will not be accessible through the UI](../secondary_proxy/_index.md#behavior-of-secondary-sites-when-the-primary-geo-site-is-down)
unless your restore the services on your primary site or you perform a promotion
on your secondary site.

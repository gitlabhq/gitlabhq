---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Selective synchronization
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Geo supports selective synchronization, which allows administrators to choose
which projects should be synchronized by **secondary** sites.
A subset of projects can be chosen, either by group or by storage shard. The
former is ideal for replicating data belonging to a subset of users, while the
latter is more suited to progressively rolling out Geo to a large GitLab
instance.

NOTE:
Geo's synchronization logic is outlined in the [documentation](../_index.md). Both the solution and the documentation is subject to change from time to time. You must independently determine your legal obligations in regard to privacy and cybersecurity laws, and applicable trade control law on an ongoing basis.

Selective synchronization:

1. Does not restrict permissions from **secondary** sites.
1. Does not prevent users from viewing, interacting with, cloning, and pushing to project repositories that are not included in the selective sync.
   - For more details, see [Geo proxying for secondary sites](../secondary_proxy/_index.md).
1. Does not hide project metadata from **secondary** sites.
   - Since Geo relies on PostgreSQL replication, all project metadata
     gets replicated to **secondary** sites, but repositories that have not been
     selected will not exist on the secondary site.
1. Does not reduce the number of events generated for the Geo event log.
   - The **primary** site generates events as long as any **secondary** sites are present.
     Selective synchronization restrictions are implemented on the **secondary** sites,
     not the **primary** site.

## Git operations on unreplicated repositories

Git clone, pull, and push operations over HTTP(S) and SSH are supported for repositories that
exist on the **primary** site but not on **secondary** sites. This situation can occur
when:

- Selective synchronization does not include the project attached to the repository.
- The repository is actively being replicated but has not completed yet.

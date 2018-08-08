# Geo Frequently Asked Questions

## Can I use Geo in a disaster recovery situation?

Yes, but there are limitations to what we replicate (see
[What data is replicated to a secondary node?](#what-data-is-replicated-to-a-secondary-node)).

Read the documentation for [Disaster Recovery](../disaster_recovery/index.md).

## What data is replicated to a secondary node?

We currently replicate project repositories, LFS objects, generated
attachments / avatars and the whole database. This means user accounts,
issues, merge requests, groups, project data, etc., will be available for
query. We currently don't replicate artifact data (`shared/folder`).

## Can I git push to a secondary node?

No. All writing operations (this includes `git push`) must be done in your
primary node.

## How long does it take to have a commit replicated to a secondary node?

All replication operations are asynchronous and are queued to be dispatched in
a batched request every 10 minutes. Besides that, it depends on a lot of other
factors including the amount of traffic, how big your commit is, the
connectivity between your nodes, your hardware, etc.

## What if the SSH server runs at a different port?

We send the clone url from the primary server to any secondaries, so it
doesn't matter. If primary is running on port `2200`, clone url will reflect
that.

## Is this possible to set up a Docker Registry for a secondary node that mirrors the one on a primary node?

Yes. See [Docker Registry for a secondary Geo node](docker_registry.md).

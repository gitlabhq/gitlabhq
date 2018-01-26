# Geo Frequently Asked Questions

## Can I use Geo in a disaster recovery situation?

There are limitations to what we replicate (see
[What data is replicated to a secondary node?](#what-data-is-replicated-to-a-secondary-node)).
In an extreme data-loss situation you can make a secondary Geo into your
primary, but this is not officially supported yet.

If you still want to proceed, see our step-by-step instructions on how to
manually [promote a secondary node](disaster-recovery.md) into primary.

## I followed the disaster recovery instructions and now two-factor auth is broken!

The setup instructions for GitLab Geo prior to 10.5 failed to replicate the
`otp_key_base` secret, which used to encrypt the two-factor authentication
secrets stored in the database. If it differs between primary and secondary
nodes, users with two-factor authentication enabled won't be able to log in
after a DR failover.

If you still have access to the old primary node, you can follow the
instructions in the [Upgrading to GitLab 10.5](updating_the_geo_nodes.md#upgrading-to-gitlab-105)
section to resolve the error. Otherwise, the secret is lost and you'll need to
[reset two-factor authentication for all users](../security/two_factor_authentication.md#disabling-2fa-for-everyone).

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

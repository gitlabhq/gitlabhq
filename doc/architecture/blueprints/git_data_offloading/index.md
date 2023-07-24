---
status: proposed
creation-date: "2023-05-19"
authors: [ "@jcai-gitlab", "@toon" ]
coach: [ ]
approvers: [ ]
owning-stage: "~devops::systems"
---

# Offload data to cheaper storage

## Summary

Managing Git data storage costs is a critical part of our business. Offloading
Git data to cheaper storage can save on storage cost.

## Motivation

At GitLab, we keep most Git data stored on SSDs to keep data access fast. This
makes sense for data that we frequently need to access. However, given that
storage costs scale with data growth, we can be a lot smarter about what kinds
of data we keep on SSDs and what kinds of data we can afford to offload to
cheaper storage.

For example, large files (or in Git nomenclature, "blobs") are not frequently
modified since they are usually non-text files (images, videos, binaries, etc).
Often, [Git LFS](https://git-lfs.com/) is used for repositories that contain
these large blobs in order to avoid having to push a large file onto the Git
server. However, this relies on client side setup.

Or, if a project is "stale" and hasn't been accessed in a long time, there is no
need to keep paying for fast storage for that project.

Instead, we can choose to put **all** blobs of that stale project onto cheaper
storage. This way, the application still has access to the commit history and
trees so the project browsing experience is not affected, but all files are on
slower storage since they are rarely accessed.

If we had a way to separate Git data into different categories, we could then
offload certain data to a secondary location that is cheaper. For example, we
could separate large files that may not be accessed as frequently from the rest
of the Git data and save it to an HDD rather than an SDD mount.

## Requirements

There are a set of requirements and invariants that must be given for any
particular solution.

### Saves storage cost

Ultimately, this solution needs to save on storage cost. Separating out certain
Git data for cheaper storage can go towards this savings.

We need to evaluate the solution's added cost against the projected savings from
offloading data to cheaper storage. Here are some criteria to consider:

- How much money would we save if all large blobs larger than X were put on HDD?
- How much money would we save if all stale projects had their blobs on HDD?
- What's the operational overhead for running the offloading mechanism in terms
  of additional CPU/Memory cost?
- What's the network overhead? e.g. is there an extra roundtrip to a different
  node via the network to retrieve large blobs.
- Access cost, e.g. when blobs would be stored in an object store.

### Opaque to downstream consumers of Gitaly

This feature is purely storage optimization and, except for potential
performance slowdown, shouldn't affect downstream consumers of Gitaly. For
example, the GitLab application should not have to change any of its logic in
order to support this feature.

This feature should be completely invisible to any callers of Gitaly. Rails or
any consumer should not need to know about this or manage it in any way.

### Operationally Simple

When working with Git data, we want to keep things as simple as possible to
minimize risk of repository corruption. Keep things operationally simple and
keep moving pieces outside of Git itself to a minimum. Any logic that modifies
repository data should be upstreamed in Git itself.

## Proposal

We will maintain a separate object database for each repository connected
through the [Git alternates mechansim](https://git-scm.com/docs/gitrepository-layout#Documentation/gitrepository-layout.txt-objects).
We can choose to filter out certain Git objects for this secondary object
database (ODB).

Place Git data into this secondary ODB based on a filter. We have
options based on [filters in Git](https://git-scm.com/docs/git-rev-list#Documentation/git-rev-list.txt---filterltfilter-specgt).

We can choose to place large blobs based on some limit into a secondary ODB, or
we can choose to place all blobs onto the secondary ODB.

## Design and implementation details

### Git

We need to add a feature to `git-repack(1)` that will allow us to segment
different kinds of blobs into different object databases. We're tracking this
effort in [this issue](https://gitlab.com/gitlab-org/git/-/issues/159).

### Gitaly

During Gitaly housekeeping, we can do the following:

1. Use `git-repack(1)` to write packfiles into both the main repository's object
   database, and a secondary object database. Each repository has its own
   secondary object database for offloading blobs based on some criteria.
1. Ensure the `.git/objects/info/alternates` file points to the secondary
   object database from step (1).

### Criteria

Whether objects are offloaded to another object database can be determined based
on one or many of the following criteria.

#### By Tier

Free projects might have many blobs offloaded to cheaper storage, while Ultimate
projects have all their objects placed on the fastest storage.

#### By history

If a blob was added a long time ago and is not referred by any recent commit it
can get offloaded, while new blobs remain on the main ODB.

#### By size

Large blobs are a quick win to reduce the expensive storage size, so they might
get prioritized to move to cheaper storage.

#### Frequency of Access

Frequently used project might remain fully on fast storage, while inactive
projects might have their blob offloaded.

### Open Questions

#### How do we delete objects?

When we want to delete an unreachable object, the repack would need to be aware
of both ODBs and be able to evict unreachable objects regardless of whether
the objects are in the main ODB or in the secondary ODB. This picture is
complicated if the main ODB also has an [object pool](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/object_pools.md)
ODB, since we wouldn't ever want to delete an object from the pool ODB.

#### Potential Solution: Modify Git to delete an object from alternates

We would need to modify repack to give it the ability to delete unreachable
objects in alternate ODBs. We could add repack configs `repack.alternates.*`
that tell it how to behave with alternate directories. For example, we could
have `repack.alternates.explodeUnreachable`, which indicates to repack that it
should behave like `-A` in any alternate ODB it is linked to.

#### How does this work with object pools?

When we use alternates, how does this interact with object pools? Does the
object pool also offload data to secondary storage? Does the object pool member?
In the most complex case this means that a single repository has four different
object databases, which may increase complexity.

Possibly we can mark some packfiles as "keep", using the
[--keep-pack](https://git-scm.com/docs/git-pack-objects#Documentation/git-pack-objects.txt---keep-packltpack-namegt)
and
[--honor-pack-keep](https://git-scm.com/docs/git-pack-objects#Documentation/git-pack-objects.txt---honor-pack-keep)
options.

#### Potential Solution: Do not allow object pools to offload their blobs

For the sake of not adding too much complexity, we could decide that object
pools will not offload their blobs. Instead, we can design housekeeping to
offload blobs from the repository before deduplicating with the object pool.
Theoretically, this means that offloaded blobs will not end up in the object
pool.

#### How will this work with Raft + WAL?

How will this mechanism interact with Raft and the write-ahead log?

The WAL uses hard-links and copy-free moves, to avoid slow copy operations. But
that does not work across different file systems. At some point repacks and such
will likely also go through the log. Transferring data between file systems can
lead to delays in transaction processing.

Ideally we keep the use of an alternate internal to the node and not have to
leak this complexity to the rest of the cluster. This is a challenge, given we
have to consider available space when making placement decisions. It's possible
to keep this internal by only showing the lower capacity of the two storages,
but that could also lead to inefficient storage use.

## Problems with the design

### Added complexity

The fact that we are adding another object pool to the mix adds complexity to
the system, and especially with repository replication since we are adding yet
another place to replicate data to.

### Possible change in cost over time

The cost of the different storage types might change over time. To anticipate
for this, it should be easy to adapt to such changes.

### More points of failure

Having some blobs on a separate storage device adds one more failure scenario
where the device hosting the large blobs may fail.

## Alternative Solutions

### Placing entire projects onto cheaper storage

Instead of placing Git data onto cheaper storage, the Rails application could
choose to move a project in its entirety to a mounted HDD drive.

#### Possible optimization

Giving these machines with cheaper storage extra RAM might help to deal with the
slow read/write speeds due to the use of page cache. It's not sure though this
will turn out to be cheaper overall.

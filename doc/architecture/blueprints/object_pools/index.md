---
status: proposed
creation-date: "2023-03-30"
authors: [ "@pks-gitlab" ]
coach: [ ]
approvers: [ ]
owning-stage: "~devops::systems"
participating-stages: [ "~devops::create" ]
---

# Iterate on the design of object pools

## Summary

Forking repositories is at the heart of many modern workflows for projects
hosted in GitLab. As most of the objects between a fork and its upstream project
will typically be the same, this opens up potential for optimizations:

- Creating forks can theoretically be lightning fast if we reuse much of the
  parts of the upstream repository.

- We can save on storage space by deduplicating objects which are shared.

This architecture is currently implemented with object pools which hold objects
of the primary repository. But the design of object pools has organically grown
and is nowadays showing its limits.

This blueprint explores how we can iterate on the design of object pools to fix
long standing issues with it. Furthermore, the intent is to arrive at a design
that lets us iterate more readily on the exact implementation details of object
pools.

## Motivation

The current design of object pools is showing problems with scalability in
various different ways. For a large part the problems come from the fact that
object pools have organically grown and that we learned as we went by.

It is proving hard to fix the overall design of object pools because there is no
clear ownership. While Gitaly provides the low-level building blocks to make
them work, it does not have enough control over them to be able to iterate on
their implementation details.

There are thus two major goals: taking ownership of object pools so that it
becomes easier to iterate on the design, and fixing scalability issues once we
can iterate.

### Lifecycle ownership

While Gitaly provides the interfaces to manage object pools, the actual life
cycle of them is controlled by the client. A typical lifecycle of an object pool
looks as following:

1. An object pool is created via `CreateObjectPool()`. The caller provides the
   path where the object pool shall be created as well as the origin repository
   from which the repository shall be created.

1. The origin repository needs to be linked to the object pool explicitly by
   calling `LinkRepositoryToObjectPool()`.

1. The object pool needs to be regularly updated via `FetchIntoObjectPool()`
   that fetches all changes from the primary pool member into the object pool.

1. To create forks, the client needs to call `CreateFork()` followed by
   `LinkRepositoryToObjectPool()`.

1. Repositories of forks are unlinked by calling `DisconnectGitAlternates()`.
   This will reduplicate objects.

1. The object pool is deleted via `DeleteObjectPool()`.

This lifecycle is complex and leaks a lot of implementation details to the
caller. This was originally done in part to give the Rails side control and
management over Git object visibility. GitLab project visibility rules are
complex and not a Gitaly concern. By exposing these details Rails can control
when pool membership links are created and broken. It is not clear at the
current point in time how the complete system works and its limits are not
explicitly documented.

In addition to the complexity of the lifecycle we also have multiple sources of
truth for pool membership. Gitaly never tracks the set of members of a pool
repository but can only tell for a specific repository that it is part of said
pool. Consequently, Rails is forced to maintain this information in a database,
but it is hard to maintain that information without becoming stale.

### Repository maintenance

Related to the lifecycle ownership issues is the issue of repository
maintenance. As mentioned, keeping an object pool up to date requires regular
calls to `FetchIntoObjectPool()`. This is leaking implementation details to the
client, but was done to give the client control over syncing the primary
repository with its object pool. With this control, private repositories can be
prevented from syncing and consquently leaking objects to other repositories in
the fork network.

We have had good success with moving repository maintenance into Gitaly so that
clients do not need to know about on-disk details. Ideally, we would do the same
for repositories that are the primary member of an object pool: if we optimize
its on-disk state, we will also automatically update the object pool.

There are two issues that keep us from doing so:

- Gitaly does not know about the relationship between an object pool and its
  members.

- Updating object pools is expensive.

By making Gitaly the single source of truth for object pool memberships we would
be in a position to fix both issues.

### Fast forking

In the current implementation, Rails first invokes `CreateFork()` which results
in a complete `git-clone(1)` being performed to generate the fork repository.
This is followed by `LinkRepositoryToObjectPool()` to link the fork with the
object pool. It is not until housekeeping is performed on the fork repository
that objects are deduplicated. This is not only leaking implementation details
to clients, but it also keeps us from reaping the full potential benefit of
object pools.

In particular, creating forks is a lot slower than it could be since a clone is
always performed before linking. If the steps of creating the fork and linking
the fork to the pool repository were unified, the initial clone could be
avoided.

### Clustered object pools

Gitaly Cluster and object pools development overlapped. Consequently they are
known to not work well together. Praefect does neither ensure that repositories
with object pools have their object pools present on all nodes, nor does it
ensure that object pools are in a known state. If at all, object pools only work
by chance.

The current state has led to cases where object pools were missing or had
different contents per node. This can result in inconsistently observed state in
object pool members and writes that depend on the object pool's contents to
fail.

One way object pools might be handled for clustered Gitaly could be to have the
pool repositories duplicated on nodes that contain repositories dependent on
them. This would allow members of a fork network to exist of different nodes. To
make this work, repository replciation would have to be aware of object pools
and know when it needs to duplicate them onto a particular node.

## Requirements

There are a set of requirements and invariants that must be given for any
particular solution.

### Private upstream repositories should not leak objects to forks

When a project has a visibility setting that is not public, the objects in the
repository should not be fetched into an object pool. An object pool should only
ever contain objects from the upstream repository that were at one point public.
This prevents private upstream repositories from having objects leaked to forks
through a shared object pool.

### Forks cannot sneak objects into upstream projects

It should not be possible to make objects uploaded in a fork repository
accessible in the upstream repository via a shared object pool. Otherwise
potentially unauthorized users would be able to "sneak in" objects into
repositories by simply forking them.

Despite leading to confusion, this could also serve as a mechanism to corrupt
upstream repositories by introducing objects that are known to be broken.

### Object pool lifetime exceeds upstream repository lifetime

If the upstream repository gets deleted, its object pool should remain in place
to provide continued deduplication of shared objects between the other
repositories in the fork network. Thus it can be said that the lifetime of the
object pool is longer than the lifetime of the upstream repository. An object
pool should only be deleted if there are no longer any repositories referencing
it.

### Object lifetime

By deduplicating objects in a fork network, repositories become dependent on the
object pool. Missing objects in the pooled repository could lead to corruption
of repositories in the fork network. Therefore, objects in the pooled repository
must continue to exist as long as there are repositories referencing them.

Without a mechanism to accurately determine if a pooled object is referenenced
by one of more repositories, all objects in the pooled repository must remain.
Only when there are no repositories referencing the object pool can the pooled
repository, and therfore all its objects, be removed.

### Object sharing

An object that is deduplicated will become accessible from all forks of a
particular repository, even if it has never been reachable in any of the forks.
The consequence is that any write to an object pool immediately influences all
of its members.

We need to be mindful of this property when repositories connected to an object
pool are replicated. As the user-observable state should be the same on all
replicas, we need to ensure that both the repository and its object pool are
consistent across the different nodes.

## Proposal

In the current design, management of object pools mostly happens on the client
side as they need to manage their complete lifecyclethem. This requires Rails to
store the object pool relationships in the Rails database, perform fine-grained
management of every single step of an object pool's life, and perform periodic
Sidekiq jobs to enforce state by calling idempotent Gitaly RPCs. This design
significantly increases complexity of an already-complex mechanism.

Instead of handling the full lifecycle of object pools on the client-side, this
document proposes to instead encapsulate the object pool lifecycle management
inside of Gitaly. Instead of performing low-level actions to maintain object
pools, clients would only need to tell Gitaly about updated relationships
between a repository and its object pool.

This brings us multiple advantages:

- The inherent complexity of the lifecycle management is encapsulated in a
  single place, namely Gitaly.

- Gitaly is in a better position to iterate on the low-level technical design of
  object pools in case we find a better solution compared to "alternates" in the
  future.

- We can ensure better interplay between Gitaly Cluster, object pools and
  repository housekeeping.

- Gitaly becomes the single source of truth for object pool relationships and
  can thus start to manage it better.

Overall, the goal is to raise the abstraction level so that clients need to
worry less about the technical details while Gitaly is in a better position to
iterate on them.

### Move lifecycle management of pools into Gitaly

The lifecycle management of object pools is leaking too many details to the
client, and by doing so makes parts things both hard to understand and
inefficient.

The current solution relies on a set of fine-grained RPCs that manage the
relationship between repositories and their object pools. Instead, we are aiming
for a simplified approach that only exposes the high-level concept of forks to
the client. This will happen in the form of three RPCs:

- `ForkRepository()` will create a fork of a given repository. If the upstream
  repository does not yet have an object pool, Gitaly will create it. It will
  then create the new repository and automatically link it to the object pool.
  The upstream repository will be recorded as primary member of the object pool,
  the fork will be recorded as a secondary member of the object pool.

- `UnforkRepository()` will remove a repository from the object pool it is
  connected to. This will stop deduplication of objects. For the primary object
  pool member this also means that Gitaly will stop pulling new objects into the
  object pool.

- `GetObjectPool()` returns the object pool for a given repository. The pool
  description will contain information about the pool's primary object pool
  member as well as all secondary object pool members.

Furthermore, the following changes will be implemented:

- `RemoveRepository()` will remove the repository from its object pool. If it
  was the last object pool member, the pool will be removed.

- `OptimizeRepository()`, when executed on the primary object pool member, will
  also update and optimize the object pool.

- `ReplicateRepository()` needs to be aware of object pools and replicate them
  correctly. Repositories shall be linked to and unlink from object pools as
  required. While this is a step towards fixing the Praefect world, which may
  seem redundant given that we plan to deprecate Praefect anyway, this RPC call
  is also used for other use cases like repository rebalancing.

With these changes, Gitaly will have much tighter control over the lifecycle of
object pools. Furthermore, as it starts to track the membership of repositories
in object pools it can become the single source of truth for fork networks.

### Fix inefficient maintenance of object pools

In order to update object pools, Gitaly performs a fetch of new objects from the
primary object pool member into the object pool. This fetch is inefficient as it
needs to needlessly negotiate objects that are new in the primary object pool
member. But given that objects are deduplicated already in the primary object
pool member it means that it should only have objects in its object database
that do not yet exist in the object pool. Consequently, we should be able to
skip the negotiation completely and instead link all objects into the object
pool that exist in the source repository.

In the current design, these objects are kept alive by creating references to
the just-fetched objects. If the fetch deleted references or force-updated any
references, then it may happen that previously-referenced objects become
unreferenced. Gitaly thus creates keep-around references so that they cannot
ever be deleted. Furthermore, those references are required in order to properly
replicate object pools as the replication is reference-based.

These two things can be solved in different ways:

- We can set the `preciousObjects` repository extension. This will instruct all
  versions of Git which understand this extension to never delete any objects
  even if `git-prune(1)` or similar commands were executed. Versions of Git that
  do not understand this extension would refuse to work in this repository.

- Instead of replicating object pools via `git-fetch(1)`, we can instead
  replicate them by sending over all objects part of the object database.

Taken together this means that we can stop writing references in object pools
altogether. This leads to efficient updates of object pools by simply linking
all new objects into place, and it fixes issues we have seen with unbounded
growth of references in object pools.

## Design and implementation details

<!--

This section intentionally left blank. I first want to reach consensus on the
bigger picture I'm proposing in this blueprint before I iterate and fill in the
lower-level design and implementation details.

-->

## Problems with the design

As mentioned before, object pools are not a perfect solution. This section goes
over the most important issues.

### Complexity of lifecycle management

Even though the lifecycle of object pools becomes easier to handle once it is
fully owned by Gitaly, it is still complex and needs to be considered in many
ways. Handling object pools in combination with their repositories is not an
atomic operation as any action by necessity spans over at least two different
resources.

### Performance issues

As object pools deduplicate objects, the end result is that object pool members
never have the full closure of objects in a single packfile. This is not
typically an issue for the primary object pool member, which by definition
cannot diverge from the object pool's contents. But secondary object pool
members can and often will diverge from the original contents of the upstream
repository.

This leads to two different sets of reachable objects in secondary object pool
members. Unfortunately, due to limitations in Git itself, this precludes the use
of a subset of optimizations:

- Packfiles cannot be reused as efficiently when serving fetches to serve
  already-deltified objects. This requires Git to recompute deltas on the fly
  for object pool members which have diverged from object pools.

- Packfile bitmaps can only exist in object pools as it is not possible nor
  easily feasible for these bitmaps to cover multiple object databases. This
  requires Git to traverse larger parts of the object graph for many operations
  and especially when serving fetches.

### Dependent writes across repositories

The design of object pools introduces significant complexity into the Raft world
where we use a write-ahead log for all changes to repositories. In the ideal
case, a Raft-based design would only need to care about the write-ahead log of a
single repository when considering requests. But with object pools, we are
forced to consider both reads and writes for a pooled repository to be dependent
on all writes in its object pool having been applied.

## Alternative Solutions

The proposed solution is not obviously the best choice as it has issues both
with complexity (management of the lifecycle) and performance (inefficiently
served fetches for pool members).

This section explores alternatives to object pools and why they have not been
chosen as the new target architecture.

### Stop using object pools altogether

An obvious way to avoid all of the complexity is to stop using object pools
altogether. While it is charming from an engineering point of view as we can
significantly simplify the architecture, it is not a viable approach from the
product perspective as it would mean that we cannot support efficient forking
workflows.

### Primary repository as object pool

Instead of creating an explicit object pool repository, we could just use the
upstream repository as an alternate object database of all forks. This avoids a
lot of complexity around managing the lifetime of the object pool, at least
superficially. Furthermore, it circumvents the issue of how to update object
pools as it will always match the contents of the upstream repository.

It has a number of downsides though:

- Normal repositories can now have different states, where some of the
  repositories are allowed to prune objects and others aren't. This introduces a
  source of uncertainty and makes it easy to accidentally delete objects in a
  normal repository and thus corrupt its forks.

- When upstream repositories go private we must stop updating objects which are
  supposed to be deduplicated across members of the fork network. This means
  that we would ultimately still be forced to create object pools once this
  happens in order to freeze the set of deduplicated objects at the point in
  time where the repository goes private.

- Deleting repositories becomes more complex as we need to take into account
  whether a repository is linked to by forks.

### Reference namespaces

With `gitnamespaces(7)`, Git provides a mechanism to partition references into
different sets of namespaces. This allows us to serve all forks from a single
repository that contains all objects.

One neat property is that we have the global view of objects referenced by all
forks together in a single object database. We can thus easily perform shared
housekeeping across all forks at once, including deletion of objects that are
not used by any of the forks anymore. Regarding objects, this is likely to be
the most efficient solution we could potentially aim for.

There are again some downsides though:

- Calculating usage quotas must by necessity use actual reachability of objects
  into account, which is expensive to compute. This is not a showstopper, but
  something to keep in mind.

- One stated requirement is that it must not be possible to make objects
  reachable in other repositories from forks. This property could theoretically
  be enforced by only allowing access to reachable objects. That way an object
  can only be accessed through virtual repository if the object is reachable from
  its references. Reachability checks are too compute heavy for this to be practical.

- Even though references are partitioned, large fork networks would still easily
  end up with multiple millions of references. It is unclear what the impact on
  performance would be.

- The blast radius for any repository-level attacks significantly increases as
  you would not only impact your own repository, but also all forks.

- Custom hooks would have to be isolated for each of the virtual repositories.
  Since the execution of Git hooks is controled it should be possible to handle
  this for each of the namespaces.

### Filesystem-based deduplication

The idea of deduplicating objects on the filesystem level was floating around at
several points in time. While it would be nice if we could shift the burden of
this to another component, it is likely not easy to implement due to the nature
of how Git works.

The most important contributing factor to repository sizes are Git objects.
While it would be possible to store the objects in their loose representation
and thus deduplicate on that level, this is infeasible:

- Git would not be able to deltify objects, which is an extremely important
  mechanism to reduce on-disk size. It is unlikely that the size reduction
  caused by deduplication would outweigh the size reduction gained from the
  deltification mechanism.

- Loose objects are significantly less efficient when accessing the repository.

- Serving fetches requires us to send a packfile to the client. Usually, Git is
  able to reuse large parts of already-existing packfiles, which significantly
  reduces the computational overhead.

Deduplicating on the loose-object level is thus infeasible.

The other unit that one could try to deduplicate is packfiles. But packfiles are
not deterministically generated by Git and will furthermore be different once
repositories start to diverge from each other. So packfiles are not a natural
fit for filesystem-level deduplication either.

An alternative could be to use hard links of packfiles across repositories. This
would cause us to duplicate storage space whenever any repository decides to
perform a repack of objects and would thus be unpredictable and hard to manage.

### Custom object backend

In theory, it would be possible to implement a custom object backend that allows
us to store objects in such a way that we can deduplicate them across forks.
There are several technical hurdles though that keep us from doing so without
significant upstream investments:

- Git is not currently designed to have different backends for objects. Accesses
  to files part of the object database are littered across the code base with no
  abstraction level. This is in contrast to the reference database, which has at
  least some level of abstraction.

- Implementing a custom object backend would likely necessitate a fork of the
  Git project. Even if we had the resources to do so, it would introduce a major
  risk factor due to potential incompatibilities with upstream changes. It would
  become impossible to use vanilla Git, which is often a requirement that exists
  in the context of Linux distributions that package GitLab.

Both the initial and the operational risk of ongoing maintenance are too high to
really justify this approach for now. We might revisit this approach in the
future.

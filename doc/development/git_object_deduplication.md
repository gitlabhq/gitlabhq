# How Git object deduplication works in GitLab

When a GitLab user [forks a project](../workflow/forking_workflow.md),
GitLab creates a new Project with an associated Git repository that is a
copy of the original project at the time of the fork. If a large project
gets forked often, this can lead to a quick increase in Git repository
storage disk use. To counteract this problem, we are adding Git object
deduplication for forks to GitLab. In this document, we will describe how
GitLab implements Git object deduplication.

## Enabling Git object deduplication via feature flags

As of GitLab 11.9, Git object deduplication in GitLab is in beta. In this
document, you can read about the caveats of enabling the feature. Also,
note that Git object deduplication is limited to forks of public
projects on hashed repository storage.

You can enable deduplication globally by setting the `object_pools`
feature flag to `true`:

``` {.ruby}
Feature.enable(:object_pools)
```

Or just for forks of a specific project:

``` {.ruby}
fork_parent = Project.find(MY_PROJECT_ID)
Feature.enable(:object_pools, fork_parent)
```

To check if a project uses Git object deduplication, look in a Rails
console if `project.pool_repository` is present.

## Pool repositories

### Understanding Git alternates

At the Git level, we achieve deduplication by using [Git
alternates](https://git-scm.com/docs/gitrepository-layout#gitrepository-layout-objects).
Git alternates is a mechanism that lets a repository borrow objects from
another repository on the same machine.

If we want repository A to borrow from repository B, we first write a
path that resolves to `B.git/objects` in the special file
`A.git/objects/info/alternates`. This establishes the alternates link.
Next, we must perform a Git repack in A. After the repack, any objects
that are duplicated between A and B will get deleted from A. Repository
A is now no longer self-contained, but it still has its own refs and
configuration. Objects in A that are not in B will remain in A. For this
to work, it is of course critical that **no objects ever get deleted from
B** because A might need them.

### Git alternates in GitLab: pool repositories

GitLab organizes this object borrowing by creating special **pool
repositories** which are hidden from the user. We then use Git
alternates to let a collection of project repositories borrow from a
single pool repository. We call such a collection of project
repositories a pool. Pools form star-shaped networks of repositories
that borrow from a single pool, which will resemble (but not be
identical to) the fork networks that get formed when users fork
projects.

At the Git level, pool repositories are created and managed using Gitaly
RPC calls. Just like with normal repositories, the authority on which
pool repositories exist, and which repositories borrow from them, lies
at the Rails application level in SQL.

In conclusion, we need three things for effective object deduplication
across a collection of GitLab project repositories at the Git level:

1.  A pool repository must exist.
2.  The participating project repositories must be linked to the pool
    repository via their respective `objects/info/alternates` files.
3.  The pool repository must contain Git object data common to the
    participating project repositories.

### Deduplication factor

The effectiveness of Git object deduplication in GitLab depends on the
amount of overlap between the pool repository and each of its
participants. As of GitLab 11.9, we have a somewhat optimistic system.
The only data that will be deduplicated is the data in the source
project repository at the time the pool repository is created. That is,
the data in the source project at the time of the first fork *after* the
deduplication feature has been enabled.

When we enable the object deduplication feature for
gitlab.com/gitlab-org/gitlab-ce, which is about 1GB at the time of
writing, all new forks of that project would be 1GB smaller than they
would have been without Git object deduplication. So even in its current
optimistic form, we expect Git object deduplication in GitLab to make a
difference.

However, if a lot of Git objects get added to the project repositories
in a pool after the pool repository was created these new Git objects
will currently (GitLab 11.9) not get deduplicated. Over time, the
deduplication factor of the pool will get worse and worse.

As an extreme example, if we create an empty repository A, and fork that
to repository B, behind the scenes we get an object pool P with no
objects in it at all. If we then push 1GB of Git data to A, and push the
same Git data to B, it will not get deduplicated, because that data was
not in A at the time P was created.

This also matters in less extreme examples. Consider a pool P with
source project A and 500 active forks B1, B2,...,B500. Suppose,
optimistically, that the forks are fully deduplicated at the start of
our scenario. Now some time passes and 200MB of new Git data gets added
to project A. Because of the forking workflow, this data makes also its way
into the forks B1, ..., B500. That means we would now have 100GB of Git
data sitting around (500 \* 200MB) across the forks, that could have
been deduplicated. But because of the way we do deduplication this new
data will not be deduplicated.

> TODO Add periodic maintenance of object pools to prevent gradual loss
> of deduplication over time.
> https://gitlab.com/groups/gitlab-org/-/epics/524

## SQL model

As of GitLab 11.8, project repositories in GitLab do not have their own
SQL table. They are indirectly identified by columns on the `projects`
table. In other words, the only way to look up a project repository is to
first look up its project, and then call `project.repository`.

With pool repositories we made a fresh start. These live in their own
`pool_repositories` SQL table. The relations between these two tables
are as follows:

-   a `Project` belongs to at most one `PoolRepository`
    (`project.pool_repository`)
-   as an automatic consequence of the above, a `PoolRepository` has
    many `Project`s
-   a `PoolRepository` has exactly one "source `Project`"
    (`pool.source_project`)

### Assumptions

-   All repositories in a pool must use [hashed
    storage](../administration/repository_storage_types.md). This is so
    that we don't have to ever worry about updating paths in
    `object/info/alternates` files.
-   All repositories in a pool must be on the same Gitaly storage shard.
    The Git alternates mechanism relies on direct disk access across
    multiple repositories, and we can only assume direct disk access to
    be possible within a Gitaly storage shard.
-   All project repositories in a pool must have "Public" visibility in
    GitLab at the time they join. There are gotchas around visibility of
    Git objects across alternates links. This restriction is a defense
    against accidentally leaking private Git data.
-   The only two ways to remove a member project from a pool are (1) to
    delete the project or (2) to move the project to another Gitaly
    storage shard.

### Creating pools and pool memberships

-   When a pool gets created, it must have a source project. The initial
    contents of the pool repository are a Git clone of the source
    project repository.
-   The occasion for creating a pool is when an existing eligible
    (public, hashed storage, non-forked) GitLab project gets forked and
    this project does not belong to a pool repository yet. The fork
    parent project becomes the source project of the new pool, and both
    the fork parent and the fork child project become members of the new
    pool.
-   Once project A has become the source project of a pool, all future
    eligible forks of A will become pool members.
-   If the fork source is itself a fork, the resulting repository will
    neither join the repository nor will a new pool repository be
    seeded.

    eg:

    Suppose fork A is part of a pool repository, any forks created off
    of fork A *will not* be a part of the pool repository that fork A is
    a part of.

    Suppose B is a fork of A, and A does not belong to an object pool.
    Now C gets created as a fork of B. C will not be part of a pool
    repository.

> TODO should forks of forks be deduplicated?
> https://gitlab.com/gitlab-org/gitaly/issues/1532

### Consequences

-   If a normal Project participating in a pool gets moved to another
    Gitaly storage shard, its "belongs to PoolRepository" relation must
    be broken. Because of the way moving repositories between shard is
    implemented, we will automatically get a fresh self-contained copy
    of the project's repository on the new storage shard.
-   If the source project of a pool gets moved to another Gitaly storage
    shard or is deleted, we may have to break the "PoolRepository has
    one source Project" relation?

> TODO What happens, or should happen, if a source project changes
> visibility, is deleted, or moves to another storage shard?
> https://gitlab.com/gitlab-org/gitaly/issues/1488

## Consistency between the SQL pool relation and Gitaly

As far as Gitaly is concerned, the SQL pool relations make two types of
claims about the state of affairs on the Gitaly server: pool repository
existence, and the existence of an alternates connection between a
repository and a pool.

### Pool existence

If GitLab thinks a pool repository exists (i.e. it exists according to
SQL), but it does not on the Gitaly server, then certain RPC calls that
take the object pool as an argument will fail.

> TODO What happens if SQL says the pool repo exists but Gitaly says it
> does not? https://gitlab.com/gitlab-org/gitaly/issues/1533

If GitLab thinks a pool does not exist, while it does exist on disk,
that has no direct consequences on its own. However, if other
repositories on disk borrow objects from this unknown pool repository
then we risk data loss, see below.

### Pool relation existence

There are three different things that can go wrong here.

#### 1. SQL says repo A belongs to pool P but Gitaly says A has no alternate objects

In this case, we miss out on disk space savings but all RPC's on A itself
will function fine. As long as Git can find all its objects, it does not
matter exactly where those objects are.

#### 2. SQL says repo A belongs to pool P1 but Gitaly says A has alternate objects in pool P2

If we are not careful, this situation can lead to data loss. During some
operations (repository maintenance), GitLab will try to re-link A to its
pool P1. If this clobbers the existing link to P2, then A will loose Git
objects and become invalid.

Also, keep in mind that if GitLab's database got messed up, it may not
even know that P2 exists.

> TODO Ensure that Gitaly will not clobber existing, unexpected
> alternates links. https://gitlab.com/gitlab-org/gitaly/issues/1534

#### 3. SQL says repo A does not belong to any pool but Gitaly says A belongs to P

This has the same data loss possibility as scenario 2 above.

## Git object deduplication and GitLab Geo

When a pool repository record is created in SQL on a Geo primary, this
will eventually trigger an event on the Geo secondary. The Geo secondary
will then create the pool repository in Gitaly. This leads to an
"eventually consistent" situation because as each pool participant gets
synchronized, Geo will eventuall trigger garbage collection in Gitaly on
the secondary, at which stage Git objects will get deduplicated.

> TODO How do we handle the edge case where at the time the Geo
> secondary tries to create the pool repository, the source project does
> not exist? https://gitlab.com/gitlab-org/gitaly/issues/1533

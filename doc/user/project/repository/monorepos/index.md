---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Managing monorepos
---

Monorepos have become a regular part of development team workflows. While they have many advantages, monorepos can present performance challenges
when using them in GitLab. Therefore, you should know:

- What repository characteristics can impact performance.
- Some tools and steps to optimize monorepos.

## Impact on performance

Because GitLab is a Git-based system, it is subject to similar performance
constraints as Git when it comes to large repositories that are gigabytes in
size.

Monorepos can be large for [many reasons](https://about.gitlab.com/blog/2022/09/06/speed-up-your-monorepo-workflow-in-git/#characteristics-of-monorepos).

Large repositories pose a performance risk when used in GitLab, especially if a large monorepo receives many clones or pushes a day, which is common for them.

### Git performance issues with large repositories

Git uses [packfiles](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)
to store its objects so that they take up as little space as
possible. Packfiles are also used to transfer objects when cloning,
fetching, or pushing between a Git client and a Git server. Using packfiles is
usually good because it reduces the amount of disk space and network
bandwidth required.

However, creating packfiles requires a lot of CPU and memory to compress object
content. So when repositories are large, every Git operation
that requires creating packfiles becomes expensive and slow as more
and bigger objects need to be processed and transferred.

### Consequences for GitLab

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is our Git storage service built
on top of [Git](https://git-scm.com/). This means that any limitations of
Git are experienced in Gitaly, and in turn by end users of GitLab.

Monorepos can also impact notably on hardware, in some cases hitting limitations such as vertical scaling and network or disk bandwidth limits.

## Optimize GitLab settings

You should use as many of the following strategies as possible to minimize
fetches on the Gitaly server.

### Rationale

The most resource intensive operation in Git is the
[`git-pack-objects`](https://git-scm.com/docs/git-pack-objects)
process, which is responsible for creating packfiles after figuring out
all of the commit history and files to send back to the client.

The larger the repository, the more commits, files, branches, and tags that a
repository has and the more expensive this operation is. Both memory and CPU
are heavily utilized during this operation.

Most `git clone` or `git fetch` traffic (which results in starting a `git-pack-objects` process on the server) often come from automated
continuous integration systems such as GitLab CI/CD or other CI/CD systems.
If there is a high amount of such traffic, hitting a Gitaly server with many
clones for a large repository is likely to put the server under significant
strain.

### Gitaly pack-objects cache

Turn on the [Gitaly pack-objects cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache),
which reduces the work that the server has to do for clones and fetches.

#### Rationale

The [pack-objects cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)
caches the data that the `git-pack-objects` process produces. This response
is sent back to the Git client initiating the clone or fetch. If several
fetches are requesting the same set of refs, Git on the Gitaly server doesn't have
to re-generate the response data with each clone or fetch call, but instead serves
that data from an in-memory cache that Gitaly maintains.

This can help immensely in the presence of a high rate of clones for a single
repository.

For more information, see [Pack-objects cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache).

### Reduce concurrent clones in CI/CD

CI/CD loads tend to be concurrent because pipelines are [scheduled during set times](../../../../ci/pipelines/pipeline_efficiency.md#reduce-how-often-jobs-run).
As a result, the Git requests against the repositories can spike notably during
these times and lead to reduced performance for both CI/CD and users alike.

Reduce CI/CD pipeline concurrency by [staggering them](../../../../ci/pipelines/schedules.md#view-and-optimize-pipeline-schedules)
to run at different times.
For example, a set running at one time and another set running several minutes
later.

### Shallow cloning

In your CI/CD systems, set the
[`--depth`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt)
option in the `git clone` or `git fetch` call.

GitLab and GitLab Runner perform a [shallow clone](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)
by default.

If possible, set the clone depth with a small number like 10. Shallow clones make Git request only
the latest set of changes for a given branch, up to desired number of commits.

This significantly speeds up fetching of changes from Git repositories,
especially if the repository has a very long backlog consisting of a number
of big files because we effectively reduce amount of data transfer.

The following GitLab CI/CD pipeline configuration example sets the `GIT_DEPTH`.

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

#### Avoid shallow clones for development

Avoid shallow clones for development because they greatly increase the time it takes to push changes. Shallow clones
work well with CI/CD jobs because the repository contents aren't changed after being checked out.

Instead, for local development use
[partial clones](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt) to:

1. Filter out blobs:

   ```shell
   git clone --filter=blob:none
   ```

1. Filter out trees:

   ```shell
   git clone --filter=tree:0
   ```

For more information, see [Reduce clone size](../../../../topics/git/clone.md#reduce-clone-size).

### Git strategy

Use `git fetch` instead of `git clone` on CI/CD systems if it's possible to keep
a working copy of the repository.

By default, GitLab is configured to use the [`fetch` Git strategy](../../../../ci/runners/configure_runners.md#git-strategy),
which is recommended for large repositories.

#### Rationale

`git clone` gets the entire repository from scratch, whereas `git fetch` only
asks the server for references that do not already exist in the repository.
Naturally, `git fetch` causes the server to do less work. `git-pack-objects`
doesn't have to go through all branches and tags and roll everything up into a
response that gets sent over. Instead, it only has to worry about a subset of
references to pack up. This strategy also reduces the amount of data to transfer.

### Git clone path

[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories) allows you to
control where you clone your repositories. This can have implications if you
heavily use big repositories with a fork-based workflow.

A fork, from the perspective of GitLab Runner, is stored as a separate repository
with a separate worktree. That means that GitLab Runner cannot optimize the usage
of worktrees and you might have to instruct GitLab Runner to use that.

In such cases, ideally you want to make the GitLab Runner executor be used only
for the given project and not shared across different projects to make this
process more efficient.

The [`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories) must be
in the directory set in `$CI_BUILDS_DIR`. You can't pick any path from disk.

### Git clean flags

[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags) allows you to control
whether or not you require the `git clean` command to be executed for each CI/CD
job. By default, GitLab ensures that:

- You have your worktree on the given SHA.
- Your repository is clean.

[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags) is disabled when set
to `none`. On very big repositories, this might be desired because `git clean`
is disk I/O intensive. Controlling that with `GIT_CLEAN_FLAGS: -ffdx -e .build/`
(for example) allows you to control and disable removal of some
directories in the worktree between subsequent runs, which can speed-up
the incremental builds. This has the biggest effect if you re-use existing
machines and have an existing worktree that you can re-use for builds.

For exact parameters accepted by
[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags), see the documentation
for [`git clean`](https://git-scm.com/docs/git-clean). The available parameters
are dependent on the Git version.

### Git fetch extra flags

[`GIT_FETCH_EXTRA_FLAGS`](../../../../ci/runners/configure_runners.md#git-fetch-extra-flags) allows you
to modify `git fetch` behavior by passing extra flags.

For example, if your project contains a large number of tags that your CI/CD jobs don't rely on,
you could add [`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags)
to the extra flags to make your fetches faster and more compact.

Also in the case where your repository does _not_ contain a lot of
tags, `--no-tags` can [make a big difference in some cases](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/746).
If your CI/CD builds do not depend on Git tags, setting `--no-tags` is worth trying.

For more information, see the [`GIT_FETCH_EXTRA_FLAGS` documentation](../../../../ci/runners/configure_runners.md#git-fetch-extra-flags).

### Configure Gitaly negotiation timeouts

You might experience a `fatal: the remote end hung up unexpectedly` error when attempting to fetch or archive:

- Large repositories.
- Many repositories in parallel.
- The same large repository in parallel.

You can attempt to mitigate this issue by increasing the default negotiation timeout values. For more information, see
[Configure the negotiation timeouts](../../../../administration/settings/gitaly_timeouts.md#configure-the-negotiation-timeouts).

## Optimize your repository

Another avenue to keeping GitLab scalable with your monorepo is to optimize the
repository itself.

### Profiling repositories

Large repositories generally experience performance issues in Git. Knowing why
your repository is large can help you develop mitigation strategies to avoid
performance problems.

You can use [`git-sizer`](https://github.com/github/git-sizer) to get a snapshot
of repository characteristics and discover problem aspects of your monorepo.

To get a _full_ clone of your repository, you need a full Git mirror or bare clone to
ensure all Git references are present. To profile your repository:

1. [Install `git-sizer`](https://github.com/github/git-sizer?tab=readme-ov-file#getting-started).
1. Get a full clone of your repository:

   ```shell
   git clone --mirror <git_repo_url>
   ```

   After cloning, the repository will be in the bare Git format that is compatible with `git-sizer`.
1. Run `git-sizer` with all statistics in the directory of your Git repository:

   ```shell
   git-sizer -v
   ```

After processing, the output of `git-sizer` should look like the following with a level of concern
on each aspect of the repository:

```shell
Processing blobs: 1652370
Processing trees: 3396199
Processing commits: 722647
Matching commits to trees: 722647
Processing annotated tags: 534
Processing references: 539
| Name                         | Value     | Level of concern               |
| ---------------------------- | --------- | ------------------------------ |
| Overall repository size      |           |                                |
| * Commits                    |           |                                |
|   * Count                    |   723 k   | *                              |
|   * Total size               |   525 MiB | **                             |
| * Trees                      |           |                                |
|   * Count                    |  3.40 M   | **                             |
|   * Total size               |  9.00 GiB | ****                           |
|   * Total tree entries       |   264 M   | *****                          |
| * Blobs                      |           |                                |
|   * Count                    |  1.65 M   | *                              |
|   * Total size               |  55.8 GiB | *****                          |
| * Annotated tags             |           |                                |
|   * Count                    |   534     |                                |
| * References                 |           |                                |
|   * Count                    |   539     |                                |
|                              |           |                                |
| Biggest objects              |           |                                |
| * Commits                    |           |                                |
|   * Maximum size         [1] |  72.7 KiB | *                              |
|   * Maximum parents      [2] |    66     | ******                         |
| * Trees                      |           |                                |
|   * Maximum entries      [3] |  1.68 k   | *                              |
| * Blobs                      |           |                                |
|   * Maximum size         [4] |  13.5 MiB | *                              |
|                              |           |                                |
| History structure            |           |                                |
| * Maximum history depth      |   136 k   |                                |
| * Maximum tag depth      [5] |     1     |                                |
|                              |           |                                |
| Biggest checkouts            |           |                                |
| * Number of directories  [6] |  4.38 k   | **                             |
| * Maximum path depth     [7] |    13     | *                              |
| * Maximum path length    [8] |   134 B   | *                              |
| * Number of files        [9] |  62.3 k   | *                              |
| * Total size of files    [9] |   747 MiB |                                |
| * Number of symlinks    [10] |    40     |                                |
| * Number of submodules       |     0     |                                |
```

In this example, a few items are raised with a high level of concern. See the
following sections for information on solving:

- A large number of references.
- Large blobs.

### Large number of references

[References in Git](https://git-scm.com/book/en/v2/Git-Internals-Git-References)
are branch and tag names that point to a particular commit. You can use the `git for-each-ref`
command to list all references present in a repository. A large
number of references in a repository can have detrimental impact on the command's
performance. To understand why, we need to understand how Git stores references
and uses them.

In general, Git stores all references as loose files in the `.git/refs` folder of
the repository. As the number of references grows, the seek time to find a
particular reference in the folder also increases. Therefore, every time Git has
to parse a reference, there is an increased latency due to the added seek time
of the file system.

To resolve this issue, Git uses [pack-refs](https://git-scm.com/docs/git-pack-refs). In short, instead of storing each
reference in a single file, Git creates a single `.git/packed-refs` file that
contains all the references for that repository. This file reduces storage space
while also increasing performance because seeking within a single file is faster
than seeking a file within a directory. However, creating and updating new references
is still done through loose files and are not added to the `packed-refs` file. To
recreate the `packed-refs` file, run `git pack-refs`.

Gitaly runs `git pack-refs` during [housekeeping](../../../../administration/housekeeping.md#heuristical-housekeeping)
to move loose references into `packed-refs` files. While this is very beneficial
for most repositories, write-heavy repositories still have the problem that:

- Creating or updating references creates new loose files.
- Deleting references involves modifying the existing `packed-refs` file
  altogether to remove the existing reference.

These problems still cause the same performance issues.

In addition, fetches and clones from repositories includes the transfer
of missing objects from the server to the client. When there are numerous
references, Git iterates over all references and walks the internal graph
structure for each reference to find the missing objects to transfer to
the client. Iteration and walking are CPU-intensive operations that increase
the latency of these commands.

In repositories with a lot of activity, this often causes a domino effect because
every operation is slower and each operation stalls subsequent operations.

#### Mitigation strategies

To mitigate the effects of a large number of references in a monorepo:

- Create an automated process for cleaning up old branches.
- If certain references don't need to be visible to the client, hide them using the
  [`transfer.hideRefs`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-transferhideRefs)
  configuration setting. Because Gitaly ignores any on-server Git configuration, you must change the Gitaly configuration
  itself in `/etc/gitlab/gitlab.rb`:

  ```ruby
  gitaly['configuration'] = {
    # ...
    git: {
      # ...
      config: [
        # ...
        { key: "transfer.hideRefs", value: "refs/namespace_to_hide" },
      ],
    },
  }
  ```

In Git 2.42.0 and later, different Git operations can skip over hidden references
when doing an object graph walk.

### Large blobs

Blobs are the [Git objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)
that are used to store and manage the content of the files that users
have committed into Git repositories.

#### Issues with large blobs

Large blobs can be problematic for Git because Git does not handle
large binary data efficiently. Blobs over 10 MB in the `git-sizer` output
probably means that there is large binary data in your repository.

While source code can usually be efficiently compressed, binary data
is often already compressed. This means that Git is unlikely to be
successful when it tries to compress large blobs when creating packfiles.
This results in larger packfiles and higher CPU, memory, and bandwidth
usage on both Git clients and servers.

On the client side, because Git stores blob content in both packfiles
(usually under `.git/objects/pack/`) and regular files (in
[worktrees](https://git-scm.com/docs/git-worktree)), much more disk
space is usually required than for source code.

#### Use LFS for large blobs

Store binary or blob files (for example, packages, audio, video, or graphics)
as Large File Storage (LFS) objects. With LFS, the objects are stored externally, such as in Object
Storage, which reduces the number and size of objects in the repository. Storing
objects in external Object Storage can improve performance.

For more information, refer to the [Git LFS documentation](../../../../topics/git/lfs/_index.md).

### Reference architectures

Large repositories tend to be found in larger organizations with many users. The
GitLab Test Platform and Support teams provide several [reference architectures](../../../../administration/reference_architectures/_index.md) that
are the recommended way to deploy GitLab at scale.

In these types of setups, the GitLab environment used should match a reference
architecture to improve performance.

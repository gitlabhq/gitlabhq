---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Improving monorepo performance
---

A monorepo is a repository that contains sub-projects. A single application often
contains interdependent projects. For example, a backend, a web frontend, an iOS application, and an Android
application. Monorepos are common, but they can present performance risks. Some common problems:

- Large binary files.
- Many files with long histories.
- Many simultaneous clones and pushes.
- Vertical scaling limits.
- Network bandwidth limits.
- Disk bandwidth limits.

GitLab is itself based in Git. Its Git storage service, [Gitaly](https://gitlab.com/gitlab-org/gitaly),
experiences the performance constraints associated with monorepos. What we've learned can help
you manage your own monorepo better.

- What repository characteristics can impact performance.
- Some tools and steps to optimize monorepos.

## Optimize Gitaly for monorepos

Git compresses objects into [packfiles](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)
to use less space. When you clone, fetch, or push, Git uses packfiles. They reduce disk space
and network bandwidth, but packfile creation requires much CPU and memory.

Massive monorepos have more commits, files, branches, and tags than smaller repositories. When the objects
become larger, and take longer to transfer, packfile creation becomes more expensive
and slower. In Git, the [`git-pack-objects`](https://git-scm.com/docs/git-pack-objects) process is
the most resource intensive operation, because it:

1. Analyzes the commit history and files.
1. Determines which files to send back to the client.
1. Creates packfiles.

Traffic from `git clone` and `git fetch` starts a `git-pack-objects` process on the server.
Automated continuous integration systems, like GitLab CI/CD, can cause much of this traffic.
High amounts of automated CI/CD traffic send many clone and fetch requests, and can strain your
Gitaly server.

Use these strategies to decrease load on your Gitaly server.

### Enable the Gitaly `pack-objects` cache

Enable the [Gitaly `pack-objects` cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache),
which reduces server load for clones and fetches.

When a Git client sends a clone or fetch request, the data produced by `git-pack-objects` can be
cached for reuse. If your monorepo is cloned frequently, enabling
[Gitaly `pack-objects` cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache),
reduces server load. When enabled, Gitaly maintains an in-memory cache instead of regenerating
response data for each clone or fetch call.

For more information, see
[Pack-objects cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache).

### Configure Git bundle URIs

Create and store [Git bundles](https://git-scm.com/docs/bundle-uri) on third-party storage with low
latency, like a CDN. Git downloads packages from your bundle first, then fetches any remaining objects
and references from your Git remote. This approach bootstraps your object database faster and reduces
load on Gitaly.

- It speeds up clones and fetches for users with a poor network connection to your GitLab server.
- It reduces the load on servers that run CI/CD jobs by pre-loading bundles.

To learn more, see [Bundle URIs](../../../../administration/gitaly/bundle_uris.md).

### Configure Gitaly negotiation timeouts

When attempting to fetch or archive repositories, `fatal: the remote end hung up unexpectedly` errors
can happen if you have:

- Large repositories.
- Many repositories in parallel.
- The same large repository in parallel.

To mitigate this issue, increase the
[default negotiation timeout values](../../../../administration/settings/gitaly_timeouts.md#configure-the-negotiation-timeouts).

### Size your hardware correctly

Monorepos are usually for larger organizations with many users. To support your monorepo,
your GitLab environment should match one of the
[reference architectures](../../../../administration/reference_architectures/_index.md)
provided by the GitLab Test Platform and Support teams. These architectures are the recommended
way to deploy GitLab at scale while maintaining performance.

### Reduce the number of Git references

In Git, [references](https://git-scm.com/book/en/v2/Git-Internals-Git-References)
are branch and tag names that point to specific commits. Git stores references as loose files in the
`.git/refs` folder of your repository. To see all references in your repository,
run `git for-each-ref`.

When the number of references in your repository grows, the seek time needed to
find a specific reference also grows. Each time Git parses a reference, the increased seek time
leads to increased latency.

To fix this problem, Git uses [pack-refs](https://git-scm.com/docs/git-pack-refs) to create a single
`.git/packed-refs` file containing all references for that repository. This method reduces the storage
space needed for refs. It also decreases seek time, because seeking in a single file is faster than seeking
through all files in a directory.

Git handles newly created or updated references with loose files. They are not cleaned up and added to the
`.git/packed-refs` file until you run `git pack-refs`. Gitaly runs `git pack-refs` during
[housekeeping](../../../../administration/housekeeping.md#heuristical-housekeeping). While this helps
many repositories, write-heavy repositories still have these performance problems:

- Creating or updating references creates new loose files.
- Deleting references requires editing the existing `packed-refs` file to remove the existing reference.

Git iterates through all references when you fetch or clone a repository. The server reviews ("walks")
the internal graph structure of each reference, finds any missing objects, and sends them to the client.
The iteration and walking processes are CPU-intensive, and increase latency. This latency can cause
a domino effect in repositories with a lot of activity. Each operation is slower, and each operation
stalls later operations.

To mitigate the effects of a large number of references in a monorepo:

- Create an automated process for cleaning up old branches.
- If certain references don't need to be visible to the client, hide them using the
  [`transfer.hideRefs`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-transferhideRefs)
  configuration setting. Gitaly ignores any on-server Git configuration, so you must change the Gitaly
  configuration itself in `/etc/gitlab/gitlab.rb`:

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

### Schedule repository optimization tasks

The way data is stored in the object database of a Git repository can become inefficient over time, which slows down Git operations. You can
[schedule Gitaly to run a daily background task](../../../../administration/housekeeping.md#configure-scheduled-housekeeping) with a maximum duration to clean up
these items and improve performance.

## Optimize CI/CD for monorepos

To keep GitLab scalable with your monorepo, optimize how your CI/CD jobs interact with your
repository. Large, long pipelines are common pain points for monorepos. In the pipeline configuration for your monorepo, use
[build rules](../../../../ci/yaml/_index.md#rules) that detect the type of changes made and:

- Skip unnecessary jobs.
- Run only relevant jobs in child pipelines.

### Reduce concurrent clones in CI/CD

Reduce CI/CD pipeline concurrency by
[staggering your scheduled pipelines](../../../../ci/pipelines/schedules.md#distribute-pipeline-schedules-to-prevent-system-load)
to run at different times. Even a few minutes apart can help.

CI/CD loads are often concurrent, because pipelines are
[scheduled at specific times](../../../../ci/pipelines/pipeline_efficiency.md#reduce-how-often-jobs-run).
Git requests to your repository can spike during these times, and affect performance for CI/CD processes
and users.

### Use shallow clones and filters in CI/CD processes

For `git clone` and `git fetch` calls in your CI/CD systems, the amount of data
transferred can be limited with these options:

- [`--depth`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt)
- [`--filter`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterfilter-spec)

#### Shallow clone in CI/CD

The `--depth` filter creates a so-called _shallow clone_.
GitLab and GitLab Runner perform a
[shallow clone](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)
by default.

The clone depth can be configured in the GitLab CI/CD pipeline configuration
with `GIT_DEPTH`, for example:

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

#### Partial clone in CI/CD

You create a _partial clone_ by using the `--filter` option. To pass this argument
to `git-clone`, set the `GIT_CLONE_EXTRA_FLAGS` variable. For example, to limit the
maximum size of blobs to 1MB, add:

```yaml
variables:
  GIT_CLONE_EXTRA_FLAGS: --filter=blob:limit=1m
```

### Filter out paths and object types

To filter out objects of specific types, or from specific paths, use the `git sparse-checkout` option.
For more information, see [filter by file path](../../../../topics/git/clone.md#filter-by-file-path).

### Use `git fetch` in CI/CD operations

If it's possible to keep a working copy of the repository available, use `git fetch` instead of
`git clone` on CI/CD systems. `git fetch` requires less work from the server:

- `git clone` requests the entire repository from scratch. `git-pack-objects` must process and send
  all branches and tags.
- `git fetch` requests only the Git references missing from the repository. `git-pack-objects`
  processes only a subset of the total Git references. This strategy also reduces the total data transferred.

By default, GitLab uses the
[`fetch` Git strategy](../../../../ci/runners/configure_runners.md#git-strategy) recommended for large repositories.

### Set a `git clone` path

If your monorepo is used with a fork-based workflow, consider setting
[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories) to control
where you clone your repository.

Git stores forks as separate repositories with separate worktrees. GitLab Runner cannot optimize
the use of worktrees. Configure and use the GitLab Runner executor only for the given project.
To make the process more efficient, don't share it across different projects.

The [`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories) must be
in the directory set in `$CI_BUILDS_DIR`. You can't pick any path from disk.

### Disable `git clean` on CI/CD jobs

The `git clean` command removes untracked files from the working tree. In large repositories, it uses
a lot of disk I/O. If you reuse existing machines, and can reuse an existing worktree, consider
disabling it on CI/CD jobs. For example, `GIT_CLEAN_FLAGS: -ffdx -e .build/` can avoid deleting directories
from the worktree between runs. This can speed up incremental builds.

To disable `git clean` on CI/CD jobs, set
[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags) to `none` for them.

By default, GitLab ensures that:

- You have your worktree on the given SHA.
- Your repository is clean.

For exact parameters accepted by `GIT_CLEAN_FLAGS`, see the Git documentation for
[`git clean`](https://git-scm.com/docs/git-clean). The available parameters depend on your Git version.

### Change `git fetch` behavior with flags

Change the behavior of `git fetch` to exclude any data your CI/CD jobs do not need. If your project contains
many tags, and your CI/CD jobs do not need them, use `GIT_FETCH_EXTRA_FLAGS` to set
[`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags). This setting
can make your fetches faster and more compact.

Even if your repository does not contain many tags, `--no-tags` can improve performance in some cases.
For more information, see [issue 746](https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/746)
and the [`GIT_FETCH_EXTRA_FLAGS` Git documentation](../../../../ci/runners/configure_runners.md#git-fetch-extra-flags).

### Use long polling for runners

Runners periodically poll a GitLab instance for new CI/CD jobs. The polling interval depends on both:

- The `check_interval` setting.
- The number of runners configured in your runner configuration file.
 
If your server handles many runners, this polling can cause performance issues on the GitLab instance such as longer
queuing times and higher CPU usage. Long polling holds job requests from runners until a new job is ready.

For configuration instructions, see [long polling](../../../../ci/runners/long_polling.md).

## Optimize Git for monorepos

To keep GitLab scalable with your monorepo, optimize the repository itself.

### Avoid shallow clones for development

Avoid shallow clones for development. Shallow clones greatly increase the time needed to push changes.
Shallow clones work well with CI/CD jobs, because repository contents aren't changed after checkout.

For local development, use
[partial clones](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt) instead, to:

- Filter out blobs, with `git clone --filter=blob:none`
- Filter out trees, with `git clone --filter=tree:0`

For more information, see [Reduce clone size](../../../../topics/git/clone.md#reduce-clone-size).

### Profile your repository to find problems

Large repositories generally experience performance issues in Git. The
[`git-sizer`](https://github.com/github/git-sizer) project profiles your repository, and helps you understand
potential problems. It can help you develop mitigation strategies to prevent performance problems.
Analyzing your repository requires a full Git mirror or bare clone, to ensure all Git references
are present.

To profile your repository with `git-sizer`:

1. [Install `git-sizer`](https://github.com/github/git-sizer?tab=readme-ov-file#getting-started).
1. Run this command to clone your repository in the bare Git format compatible with `git-sizer`:

   ```shell
   git clone --mirror <git_repo_url>
   ```

1. In the directory of your Git repository, run `git-sizer` with all statistics:

   ```shell
   git-sizer -v
   ```

After processing, the output of `git-sizer` should look like this example. Each row includes a
**Level of concern** for that aspect of the repository. Higher levels of concern are shown with more
asterisks. Items with extremely high levels of concern are shown with exclamation marks. In this example,
a few items have a high level of concern:

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

### Use Git LFS for large binary files

Store binary files (like packages, audio, video, or graphics) as Git Large File Storage (Git LFS) objects.

When users commit files into Git, Git uses the blob
[object type](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects) to store and manage their content.
Git does not handle large binary data efficiently, so large blobs are problematic for Git. If `git-sizer`
reports blobs of over 10 MB, you usually have large binary files in your repository. Large binary files
cause problems for both server and client:

- For the server: unlike text-based source code, binary data is often already compressed.
  Git can't compress binary data further, which leads to large packfiles. Large packfiles
  require more CPU, memory, and bandwidth to create and send.
- For the client: Git stores blob content in both packfiles (usually in `.git/objects/pack/`) and
  regular files (in [worktrees](https://git-scm.com/docs/git-worktree)), binary files require far more
  space than text-based source code.

Git LFS stores objects externally, such as in object storage. Your Git repository contains a pointer
to the object's location, rather than the binary file itself. This can improve repository performance.
For more information, see the [Git LFS documentation](../../../../topics/git/lfs/_index.md).

## Related topics

- [Configure Gitaly](../../../../administration/gitaly/configure_gitaly.md)

---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Managing monorepos

Monorepos have become a regular part of development team workflows. While they have many advantages, monorepos can present performance challenges
when using them in GitLab. Therefore, you should know:

- What repository characteristics can impact performance.
- Some tools and steps to optimize monorepos.

## Impact on performance

Because GitLab is a Git-based system, it is subject to similar performance
constraints as Git when it comes to large repositories that are gigabytes in
size.

Monorepos can be large for [many reasons](https://about.gitlab.com/blog/2022/09/06/speed-up-your-monorepo-workflow-in-git/#characteristics-of-monorepos).

Large repositories pose a performance risk performance when used in GitLab, especially if a large monorepo receives many clones or pushes a day, which is common for them.

Git itself has performance limitations when it comes to handling
monorepos.

Monorepos can also impact notably on hardware, in some cases hitting limitations such as vertical scaling and network or disk bandwidth limits.

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is our Git storage service built
on top of [Git](https://git-scm.com/). This means that any limitations of
Git are experienced in Gitaly, and in turn by end users of GitLab.

## Profiling repositories

Large repositories generally experience performance issues in Git. Knowing why
your repository is large can help you develop mitigation strategies to avoid
performance problems.

You can use [`git-sizer`](https://github.com/github/git-sizer) to get a snapshot
of repository characteristics and discover problem aspects of your monorepo.

For example:

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

- A high number of references.
- Large blobs.

### Large number of references

A reference in Git (a branch or tag) is used to refer to a commit. Each
reference is stored as an individual file. If you are curious, you can go
to any `.git` directory and look under the `refs` directory.

A large number of references can cause performance problems because, with more references,
object walks that Git does are larger for various operations such as clones, pushes, and
housekeeping tasks.

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

### Using LFS for large blobs

Because Git is built to handle text data, it doesn't handle large
binary files efficiently.

Therefore, you should store binary or blob files (for example, packages, audio, video, or graphics)
as Large File Storage (LFS) objects. With LFS, the objects are stored externally, such as in Object
Storage, which reduces the number and size of objects in the repository. Storing
objects in external Object Storage can improve performance.

To analyze if a repository has large objects, you can use a tool like
[`git-sizer`](https://github.com/github/git-sizer) for detailed analysis. This
tool shows details about what makes up the repository, and highlights any areas
of concern. If any large objects are found, you can then remove them with a tool
such as [`git filter-repo`](reducing_the_repo_size_using_git.md).

For more information, refer to the [Git LFS documentation](../../../topics/git/lfs/index.md).

## Optimizing large repositories for GitLab

Other than modifying your workflow and the actual repository, you can take other
steps to maximize performance of monorepos with GitLab.

### Gitaly pack-objects cache

For very active repositories with a large number of references and files, consider using the
[Gitaly pack-objects cache](../../../administration/gitaly/configure_gitaly.md#pack-objects-cache).
The pack-objects cache:

- Benefits all repositories on your GitLab server.
- Automatically works for forks.

You should always:

- Fetch incrementally. Do not clone in a way that recreates all of the worktree.
- Use shallow clones to reduce data transfer. Be aware that this puts more burden on GitLab instance because of higher CPU impact.

Control the clone directory if you heavily use a fork-based workflow. Optimize
`git clean` flags to ensure that you remove or keep data that might affect or
speed-up your build.

For more information, see [Pack-objects cache](../../../administration/gitaly/configure_gitaly.md#pack-objects-cache).

### Reduce concurrent clones in CI/CD

Large repositories tend to be monorepos. This usually means that these
repositories get a lot of traffic not only from users, but from CI/CD.

CI/CD loads tend to be concurrent because pipelines are scheduled during set times.
As a result, the Git requests against the repositories can spike notably during
these times and lead to reduced performance for both CI/CD and users alike.

You should reduce CI/CD pipeline concurrency by staggering them to run at different times. For example, a set running at one time and another set running several
minutes later.

#### Shallow cloning

GitLab and GitLab Runner perform a [shallow clone](../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)
by default.

Ideally, you should always use `GIT_DEPTH` with a small number
like 10. This instructs GitLab Runner to perform shallow clones.
Shallow clones make Git request only the latest set of changes for a given branch,
up to desired number of commits as defined by the `GIT_DEPTH` variable.

This significantly speeds up fetching of changes from Git repositories,
especially if the repository has a very long backlog consisting of a number
of big files because we effectively reduce amount of data transfer.
The following pipeline configuration example makes the runner shallow clone to fetch only a given branch.
The runner does not fetch any other branches nor tags.

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

#### Git strategy

By default, GitLab is configured to use the [`fetch` Git strategy](../../../ci/runners/configure_runners.md#git-strategy),
which is recommended for large repositories.
This strategy reduces the amount of data to transfer and
does not really impact the operations that you might do on a repository from CI/CD.

#### Git clone path

[`GIT_CLONE_PATH`](../../../ci/runners/configure_runners.md#custom-build-directories) allows you to
control where you clone your repositories. This can have implications if you
heavily use big repositories with a fork-based workflow.

A fork, from the perspective of GitLab Runner, is stored as a separate repository
with a separate worktree. That means that GitLab Runner cannot optimize the usage
of worktrees and you might have to instruct GitLab Runner to use that.

In such cases, ideally you want to make the GitLab Runner executor be used only
for the given project and not shared across different projects to make this
process more efficient.

The [`GIT_CLONE_PATH`](../../../ci/runners/configure_runners.md#custom-build-directories) must be
in the directory set in `$CI_BUILDS_DIR`. You can't pick any path from disk.

#### Git clean flags

[`GIT_CLEAN_FLAGS`](../../../ci/runners/configure_runners.md#git-clean-flags) allows you to control
whether or not you require the `git clean` command to be executed for each CI/CD
job. By default, GitLab ensures that:

- You have your worktree on the given SHA.
- Your repository is clean.

[`GIT_CLEAN_FLAGS`](../../../ci/runners/configure_runners.md#git-clean-flags) is disabled when set
to `none`. On very big repositories, this might be desired because `git
clean` is disk I/O intensive. Controlling that with `GIT_CLEAN_FLAGS: -ffdx
-e .build/` (for example) allows you to control and disable removal of some
directories in the worktree between subsequent runs, which can speed-up
the incremental builds. This has the biggest effect if you re-use existing
machines and have an existing worktree that you can re-use for builds.

For exact parameters accepted by
[`GIT_CLEAN_FLAGS`](../../../ci/runners/configure_runners.md#git-clean-flags), see the documentation
for [`git clean`](https://git-scm.com/docs/git-clean). The available parameters
are dependent on the Git version.

#### Git fetch extra flags

[`GIT_FETCH_EXTRA_FLAGS`](../../../ci/runners/configure_runners.md#git-fetch-extra-flags) allows you
to modify `git fetch` behavior by passing extra flags.

For example, if your project contains a large number of tags that your CI/CD jobs don't rely on,
you could add [`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags)
to the extra flags to make your fetches faster and more compact.

Also in the case where you repository does _not_ contain a lot of
tags, `--no-tags` can [make a big difference in some cases](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/746).
If your CI/CD builds do not depend on Git tags, setting `--no-tags` is worth trying.

For more information, see the [`GIT_FETCH_EXTRA_FLAGS` documentation](../../../ci/runners/configure_runners.md#git-fetch-extra-flags).

#### Fork-based workflow

Following the guidelines above, let's imagine that we want to:

- Optimize for a big project (more than 50k files in directory).
- Use forks-based workflow for contributing.
- Reuse existing worktrees. Have preconfigured runners that are pre-cloned with repositories.
- Runner assigned only to project and all forks.

Let's consider the following two examples, one using `shell` executor and
other using `docker` executor.

##### `shell` executor example

Let's assume that you have the following [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).

```toml
concurrent = 4

[[runners]]
  url = "GITLAB_URL"
  token = "TOKEN"
  executor = "shell"
  builds_dir = "/builds"
  cache_dir = "/cache"

  [runners.custom_build_dir]
    enabled = true
```

This `config.toml`:

- Uses the `shell` executor,
- Specifies a custom `/builds` directory where all clones are stored.
- Enables the ability to specify `GIT_CLONE_PATH`,
- Runs at most 4 jobs at once.

##### `docker` executor example

Let's assume that you have the following [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).

```toml
concurrent = 4

[[runners]]
  url = "GITLAB_URL"
  token = "TOKEN"
  executor = "docker"
  builds_dir = "/builds"
  cache_dir = "/cache"

  [runners.docker]
    volumes = ["/builds:/builds", "/cache:/cache"]
```

This `config.toml`:

- Uses the `docker` executor,
- Specifies a custom `/builds` directory on disk where all clones are stored.
   We host mount the `/builds` directory to make it reusable between subsequent runs
   and be allowed to override the cloning strategy.
- Doesn't enable the ability to specify `GIT_CLONE_PATH` as it is enabled by default.
- Runs at most 4 jobs at once.

##### Our `.gitlab-ci.yml`

Once we have the executor configured, we need to fine tune our `.gitlab-ci.yml`.

Our pipeline is most performant if we use the following `.gitlab-ci.yml`:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_NAME

build:
  script: ls -al
```

This YAML setting configures a custom clone path. This path makes it possible to re-use worktrees
between the parent project and forks because we use the same clone path for all forks.

Why use `$CI_CONCURRENT_ID`? The main reason is to ensure that worktrees used are not conflicting
between projects. The `$CI_CONCURRENT_ID` represents a unique identifier within the given executor.
When we use it to construct the path, this directory does not conflict
with other concurrent jobs running.

### Store custom clone options in `config.toml`

Ideally, all job-related configuration should be stored in `.gitlab-ci.yml`.
However, sometimes it is desirable to make these schemes part of the runner's configuration.

In the above example of forks, making this configuration discoverable for users may be preferred,
but this brings administrative overhead as the `.gitlab-ci.yml` needs to be updated for each branch.
In such cases, it might be desirable to keep the `.gitlab-ci.yml` clone path agnostic, but make it
a configuration of the runner.

We can extend our [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
with the following specification that is used by the runner if `.gitlab-ci.yml` does not override it:

```toml
concurrent = 4

[[runners]]
  url = "GITLAB_URL"
  token = "TOKEN"
  executor = "docker"
  builds_dir = "/builds"
  cache_dir = "/cache"

  environment = [
    "GIT_CLONE_PATH=$CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_NAME"
  ]

  [runners.docker]
    volumes = ["/builds:/builds", "/cache:/cache"]
```

This makes the cloning configuration to be part of the given runner
and does not require us to update each `.gitlab-ci.yml`.

### Reference architectures

Large repositories tend to be found in larger organisations with many users. The GitLab Quality Engineering and Support teams provide several [reference architectures](../../../administration/reference_architectures/index.md) that are the recommended way to deploy GitLab at scale.

In these types of setups, the GitLab environment used should match a reference architecture to improve performance.

### Gitaly Cluster

Gitaly Cluster can notably improve large repository performance because it holds multiple replicas of the repository across several nodes.
As a result, Gitaly Cluster can load balance read requests against those replicas and is fault-tolerant.

Though Gitaly Cluster is recommended for large repositories, it is a large solution with additional complexity of setup and management. Refer to the
[Gitaly Cluster documentation for more information](../../../administration/gitaly/index.md), specifically the
[Before deploying Gitaly Cluster](../../../administration/gitaly/index.md#before-deploying-gitaly-cluster) section.

### Keep GitLab up to date

You should keep GitLab updated to the latest version where possible to benefit from performance improvements and fixes are added continuously to GitLab.

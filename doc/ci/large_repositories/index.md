---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Optimizing GitLab for large repositories

Large repositories consisting of more than 50k files in a worktree
often require special consideration because of
the time required to clone and check out.

GitLab and GitLab Runner handle this scenario well
but require optimized configuration to efficiently perform its
set of operations.

The general guidelines for handling big repositories are simple.
Each guideline is described in more detail in the sections below:

- Always fetch incrementally. Do not clone in a way that results in recreating all of the worktree.
- Always use shallow clone to reduce data transfer. Be aware that this puts more burden
  on GitLab instance due to higher CPU impact.
- Control the clone directory if you heavily use a fork-based workflow.
- Optimize `git clean` flags to ensure that you remove or keep data that might affect or speed-up your build.

## Shallow cloning

> Introduced in GitLab Runner 8.9.

GitLab and GitLab Runner perform a [shallow clone](../pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)
by default.

Ideally, you should always use `GIT_DEPTH` with a small number
like 10. This instructs GitLab Runner to perform shallow clones.
Shallow clones make Git request only the latest set of changes for a given branch,
up to desired number of commits as defined by the `GIT_DEPTH` variable.

This significantly speeds up fetching of changes from Git repositories,
especially if the repository has a very long backlog consisting of number
of big files as we effectively reduce amount of data transfer.

The following example makes the runner shallow clone to fetch only a given branch;
it does not fetch any other branches nor tags.

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

## Git strategy

> Introduced in GitLab Runner 8.9.

By default, GitLab is configured to use the [`fetch` Git strategy](../runners/configure_runners.md#git-strategy),
which is recommended for large repositories.
This strategy reduces the amount of data to transfer and
does not really impact the operations that you might do on a repository from CI.

## Git clone path

> Introduced in GitLab Runner 11.10.

[`GIT_CLONE_PATH`](../runners/configure_runners.md#custom-build-directories) allows you to
control where you clone your sources. This can have implications if you
heavily use big repositories with fork workflow.

Fork workflow from GitLab Runner's perspective is stored as a separate repository
with separate worktree. That means that GitLab Runner cannot optimize the usage
of worktrees and you might have to instruct GitLab Runner to use that.

In such cases, ideally you want to make the GitLab Runner executor be used only
for the given project and not shared across different projects to make this
process more efficient.

The [`GIT_CLONE_PATH`](../runners/configure_runners.md#custom-build-directories) has to be
within the `$CI_BUILDS_DIR`. Currently, it is impossible to pick any path
from disk.

## Git clean flags

> Introduced in GitLab Runner 11.10.

[`GIT_CLEAN_FLAGS`](../runners/configure_runners.md#git-clean-flags) allows you to control
whether or not you require the `git clean` command to be executed for each CI
job. By default, GitLab ensures that you have your worktree on the given SHA,
and that your repository is clean.

[`GIT_CLEAN_FLAGS`](../runners/configure_runners.md#git-clean-flags) is disabled when set
to `none`. On very big repositories, this might be desired because `git
clean` is disk I/O intensive. Controlling that with `GIT_CLEAN_FLAGS: -ffdx
-e .build/` (for example) allows you to control and disable removal of some
directories within the worktree between subsequent runs, which can speed-up
the incremental builds. This has the biggest effect if you re-use existing
machines and have an existing worktree that you can re-use for builds.

For exact parameters accepted by
[`GIT_CLEAN_FLAGS`](../runners/configure_runners.md#git-clean-flags), see the documentation
for [`git clean`](https://git-scm.com/docs/git-clean). The available parameters
are dependent on Git version.

## Git fetch extra flags

> [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4142) in GitLab Runner 13.1.

[`GIT_FETCH_EXTRA_FLAGS`](../runners/configure_runners.md#git-fetch-extra-flags) allows you
to modify `git fetch` behavior by passing extra flags.

For example, if your project contains a large number of tags that your CI jobs don't rely on,
you could add [`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags)
to the extra flags to make your fetches faster and more compact.

Also in the case where you repository does _not_ contain a lot of
tags, `--no-tags` can [make a big difference in some
cases](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/746).
If your CI builds do not depend on Git tags it is worth trying.

See the [`GIT_FETCH_EXTRA_FLAGS` documentation](../runners/configure_runners.md#git-fetch-extra-flags)
for more information.

## Fork-based workflow

> Introduced in GitLab Runner 11.10.

Following the guidelines above, let's imagine that we want to:

- Optimize for a big project (more than 50k files in directory).
- Use forks-based workflow for contributing.
- Reuse existing worktrees. Have preconfigured runners that are pre-cloned with repositories.
- Runner assigned only to project and all forks.

Let's consider the following two examples, one using `shell` executor and
other using `docker` executor.

### `shell` executor example

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

### `docker` executor example

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

### Our `.gitlab-ci.yml`

Once we have the executor configured, we need to fine tune our `.gitlab-ci.yml`.

Our pipeline is most performant if we use the following `.gitlab-ci.yml`:

```yaml
variables:
  GIT_DEPTH: 10
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_NAME

build:
  script: ls -al
```

The above configures a:

- Shallow clone of 10, to speed up subsequent `git fetch` commands.
- Custom clone path to make it possible to re-use worktrees between parent project and all forks
  because we use the same clone path for all forks.

Why use `$CI_CONCURRENT_ID`? The main reason is to ensure that worktrees used are not conflicting
between projects. The `$CI_CONCURRENT_ID` represents a unique identifier within the given executor.
When we use it to construct the path, this directory does not conflict
with other concurrent jobs running.

### Store custom clone options in `config.toml`

Ideally, all job-related configuration should be stored in `.gitlab-ci.yml`.
However, sometimes it is desirable to make these schemes part of the runner's configuration.

In the above example of Forks, making this configuration discoverable for users may be preferred,
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
    "GIT_DEPTH=10",
    "GIT_CLONE_PATH=$CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_NAME"
  ]

  [runners.docker]
    volumes = ["/builds:/builds", "/cache:/cache"]
```

This makes the cloning configuration to be part of the given runner
and does not require us to update each `.gitlab-ci.yml`.

## Pre-clone step

For very active repositories with a large number of references and files, you can also
optimize your CI jobs by seeding repository data with GitLab Runner's [`pre_clone_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section).

See [our development documentation](../../development/pipelines.md#pre-clone-step) for
an overview of how we implemented this approach on GitLab.com for the main GitLab repository.

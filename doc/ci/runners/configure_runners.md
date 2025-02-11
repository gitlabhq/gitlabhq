---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configuring runners
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This document describes how to configure runners in the GitLab UI.

If you need to configure runners on the machine where you installed GitLab Runner, see
[the GitLab Runner documentation](https://docs.gitlab.com/runner/configuration/).

## Set the maximum job timeout

You can specify a maximum job timeout for each runner to prevent projects
with longer job timeouts from using the runner. The maximum job timeout is
used if it is shorter than the job timeout defined in the project.

To set a runner's maximum timeout, set the `maximum_timeout` parameter in the REST API endpoint [`PUT /runners/:id`](../../api/runners.md#update-runners-details).

### For an instance runner

Prerequisites:

- You must be an administrator.

You can override the job timeout for instance runners on GitLab Self-Managed.

On GitLab.com, you cannot override the job timeout for GitLab hosted instance runners and must use the [project defined timeout](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) instead.

To set the maximum job timeout:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. To the right of the runner, you want to edit, select **Edit** (**{pencil}**).
1. In the **Maximum job timeout** field, enter a value in seconds. The minimum value is 600 seconds (10 minutes).
1. Select **Save changes**.

### For a group runner

Prerequisites:

- You must have the Owner role for the group.

To set the maximum job timeout:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build > Runners**.
1. To the right of the runner you want to edit, select **Edit** (**{pencil}**).
1. In the **Maximum job timeout** field, enter a value in seconds. The minimum value is 600 seconds (10 minutes).
1. Select **Save changes**.

### For a project runner

Prerequisites:

- You must have the Owner role for the project.

To set the maximum job timeout:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. To the right of the runner you want to edit, select **Edit** (**{pencil}**).
1. In the **Maximum job timeout** field, enter a value in seconds. The minimum value is 600 seconds (10 minutes). If not defined, the [job timeout for the project](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) is used instead.
1. Select **Save changes**.

## How maximum job timeout works

**Example 1 - Runner timeout bigger than project timeout**

1. You set the _maximum job timeout_ for a runner to 24 hours.
1. You set the _CI/CD Timeout_ for a project to **2 hours**.
1. You start a job.
1. The job, if running longer, times out after **2 hours**.

**Example 2 - Runner timeout not configured**

1. You remove the _maximum job timeout_ configuration from a runner.
1. You set the _CI/CD Timeout_ for a project to **2 hours**.
1. You start a job.
1. The job, if running longer, times out after **2 hours**.

**Example 3 - Runner timeout smaller than project timeout**

1. You set the _maximum job timeout_ for a runner to **30 minutes**.
1. You set the _CI/CD Timeout_ for a project to 2 hours.
1. You start a job.
1. The job, if running longer, times out after **30 minutes**.

## Set `script` and `after_script` timeouts

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4335) in GitLab Runner 16.4.

To control the amount of time `script` and `after_script` runs before it terminates, specify a timeout value in the `.gitlab-ci.yml` file.

For example, you can specify a timeout to terminate a long-running `script` early. This ensures artifacts and caches can still be uploaded
before the [job timeout](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) is exceeded.
The timeout values for `script` and `after_script` must be less than the job timeout.

- To set a timeout for `script`, use the job variable `RUNNER_SCRIPT_TIMEOUT`.
- To set a timeout for `after_script`, and override the default of 5 minutes, use the job variable `RUNNER_AFTER_SCRIPT_TIMEOUT`.

Both of these variables accept [Go's duration format](https://pkg.go.dev/time#ParseDuration) (for example, `40s`, `1h20m`, `2h` `4h30m30s`).

For example:

```yaml
job-with-script-timeouts:
  variables:
    RUNNER_SCRIPT_TIMEOUT: 15m
    RUNNER_AFTER_SCRIPT_TIMEOUT: 10m
  script:
    - "I am allowed to run for min(15m, remaining job timeout)."
  after_script:
    - "I am allowed to run for min(10m, remaining job timeout)."

job-artifact-upload-on-timeout:
  timeout: 1h                           # set job timeout to 1 hour
  variables:
     RUNNER_SCRIPT_TIMEOUT: 50m         # only allow script to run for 50 minutes
  script:
    - long-running-process > output.txt # will be terminated after 50m

  artifacts: # artifacts will have roughly ~10m to upload
    paths:
      - output.txt
    when: on_failure # on_failure because script termination after a timeout is treated as a failure
```

## Protecting sensitive information

The security risks are greater when using instance runners as they are available by default to all groups and projects in a GitLab instance.
The runner executor and file system configuration affects security. Users with access to the runner host environment can view the code that runner executed and the runner authentication.
For example, users with access to the runner authentication token can clone
a runner and submit false jobs in a vector attack. For more information, see [Security Considerations](https://docs.gitlab.com/runner/security/).

## Configuring long polling

To reduce job queueing times and load on your GitLab server, configure [long polling](long_polling.md).

## Using instance runners in forked projects

When a project is forked, the job settings related to jobs are copied. If you have instance runners
configured for a project and a user forks that project, the instance runners serve jobs of this project.

Due to a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/364303), if the runner settings
of the forked project does not match the new project namespace, the following message displays:
`An error occurred while forking the project. Please try again.`.

To work around this issue, ensure that the instance runner settings are consistent in the forked project and the new namespace.

- If instance runners are **enabled** on the forked project, then this should also be **enabled** on the new namespace.
- If instance runners are **disabled** on the forked project, then this should also be **disabled** on the new namespace.

## Reset the runner registration token for a project (deprecated)

WARNING:
The option to pass a runner registration token and support for certain configuration arguments was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6. They are scheduled for removal
in GitLab 18.0. Use runner authentication tokens instead. For more information, see
[Migrating to the new runner registration workflow](new_creation_workflow.md).

If you think that a registration token for a project was revealed, you should
reset it. A registration token can be used to register another runner for the project.
That new runner may then be used to obtain the values of secret variables or to clone project code.

To reset the registration token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. To the right of **New project runner**, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Reset registration token**.
1. Select **Reset token**.

After you reset the registration token, it is no longer valid and does not register
any new runners to the project. You should also update the registration token in tools
you use to provision and register new values.

## Authentication token security

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30942) in GitLab 15.3 [with a flag](../../administration/feature_flags.md) named `enforce_runner_token_expires_at`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/377902) in GitLab 15.5. Feature flag `enforce_runner_token_expires_at` removed.

Each runner uses a [runner authentication token](../../api/runners.md#registration-and-authentication-tokens)
to connect to and authenticate with a GitLab instance.

To help prevent the token from being compromised, you can have the
token rotate automatically at specified intervals. When the tokens are rotated,
they are updated for each runner, regardless of the runner's status (`online` or `offline`).

No manual intervention should be required, and no running jobs should be affected.
For more information about token rotation, see
[Runner authentication token does not update when rotated](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated).

If you need to manually update the runner authentication token, you can run a
command to [reset the token](https://docs.gitlab.com/runner/commands/#gitlab-runner-reset-token).

### Reset the runner configuration authentication token

If a runner's authentication token is exposed, an attacker could use it to [clone the runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

To reset the runner configuration authentication token:

1. Delete the runner:
   - [Delete an instance runner](runners_scope.md#delete-instance-runners).
   - [Delete a group runner](runners_scope.md#delete-a-group-runner).
   - [Delete a project runner](runners_scope.md#delete-a-project-runner).
1. Create a new runner so that it is assigned a new runner authentication token:
   - [Create an instance runner](runners_scope.md#create-an-instance-runner-with-a-runner-authentication-token).
   - [Create a group runner](runners_scope.md#create-a-group-runner-with-a-runner-authentication-token).
   - [Create a project runner](runners_scope.md#create-a-project-runner-with-a-runner-authentication-token).
1. Optional. To verify that the previous runner authentication token has been revoked, use the [Runners API](../../api/runners.md#verify-authentication-for-a-registered-runner).

To reset runner configuration authentication tokens, you can also use the [Runners API](../../api/runners.md).

### Automatically rotate runner authentication tokens

You can specify an interval to rotate runner authentication tokens.
Regularly rotating runner authentication tokens helps minimize the risk of unauthorized access to your GitLab instance through compromised tokens.

Prerequisites:

- Runners must use [GitLab Runner 15.3 or later](https://docs.gitlab.com/runner/#gitlab-runner-versions).
- You must be an administrator.

To automatically rotate runner authentication tokens:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Set a **Runners expiration** time for runners, leave empty for no expiration.
1. Select **Save changes**.

Before the interval expires, runners automatically request a new runner authentication token.
For more information about token rotation, see
[Runner authentication token does not update when rotated](new_creation_workflow.md#runner-authentication-token-does-not-update-when-rotated).

## Prevent runners from revealing sensitive information

To ensure runners don't reveal sensitive information, you can configure them to only run jobs
on [protected branches](../../user/project/repository/branches/protected.md), or jobs that have [protected tags](../../user/project/protected_tags.md).

Runners configured to run jobs on protected branches cannot run jobs in [merge request pipelines](../pipelines/merge_request_pipelines.md).

### For an instance runner

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. To the right of the runner you want to protect, select **Edit** (**{pencil}**).
1. Select the **Protected** checkbox.
1. Select **Save changes**.

### For a group runner

Prerequisites:

- You must have the Owner role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build > Runners**.
1. To the right of the runner you want to protect, select **Edit** (**{pencil}**).
1. Select the **Protected** checkbox.
1. Select **Save changes**.

### For a project runner

Prerequisites:

- You must have the Owner role for the project.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. To the right of the runner you want to protect, select **Edit** (**{pencil}**).
1. Select the **Protected** checkbox.
1. Select **Save changes**.

## Control jobs that a runner can run

You can use [tags](../yaml/_index.md#tags) to control the jobs a runner can run.
For example, you can specify the `rails` tag for runners that have the dependencies to run
Rails test suites.

GitLab CI/CD tags are different to Git tags. GitLab CI/CD tags are associated with runners.
Git tags are associated with commits.

### For an instance runner

Prerequisites:

- You must be an administrator.

To control the jobs that an instance runner can run:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. To the right of the runner you want to edit, select **Edit** (**{pencil}**).
1. Set the runner to run tagged or untagged jobs:
   - To run tagged jobs, in the **Tags** field, enter the job tags separated with a comma. For example, `macos`, `rails`.
   - To run untagged jobs, select the **Run untagged jobs** checkbox.
1. Select **Save changes**.

### For a group runner

Prerequisites:

- You must have the Owner role for the group.

To control the jobs that a group runner can run:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Build > Runners**.
1. To the right of the runner you want to edit, select **Edit** (**{pencil}**).
1. Set the runner to run tagged or untagged jobs:
   - To run tagged jobs, in the **Tags** field, enter the job tags separated with a comma. For example, `macos`, `ruby`.
   - To run untagged jobs, select the **Run untagged jobs** checkbox.
1. Select **Save changes**.

### For a project runner

Prerequisites:

- You must have the Owner role for the project.

To control the jobs that a project runner can run:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. To the right of the runner you want to edit, select **Edit** (**{pencil}**).
1. Set the runner to run tagged or untagged jobs:
   - To run tagged jobs, in the **Tags** field, enter the job tags separated with a comma. For example, `macos`, `ruby`.
   - To run untagged jobs, select the **Run untagged jobs** checkbox.
1. Select **Save changes**.

### How the runner uses tags

#### Runner runs only tagged jobs

The following examples illustrate the potential impact of the runner being set
to run only tagged jobs.

Example 1:

1. The runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has a `hello` tag is executed and stuck.

Example 2:

1. The runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has a `docker` tag is executed and run.

Example 3:

1. The runner is configured to run only tagged jobs and has the `docker` tag.
1. A job that has no tags defined is executed and stuck.

#### Runner is allowed to run untagged jobs

The following examples illustrate the potential impact of the runner being set
to run tagged and untagged jobs.

Example 1:

1. The runner is configured to run untagged jobs and has the `docker` tag.
1. A job that has no tags defined is executed and run.
1. A second job that has a `docker` tag defined is executed and run.

Example 2:

1. The runner is configured to run untagged jobs and has no tags defined.
1. A job that has no tags defined is executed and run.
1. A second job that has a `docker` tag defined is stuck.

#### A runner and a job have multiple tags

The selection logic that matches the job and runner is based on the list of `tags`
defined in the job.

The following examples illustrate the impact of a runner and a job having multiple tags. For a runner to be
selected to run a job, it must have all of the tags defined in the job script block.

Example 1:

1. The runner is configured with the tags `[docker, shell, gpu]`.
1. The job has the tags `[docker, shell, gpu]` and is executed and run.

Example 2:

1. The runner is configured with the tags `[docker, shell, gpu]`.
1. The job has the tags `[docker, shell,]` and is executed and run.

Example 3:

1. The runner is configured with the tags `[docker, shell]`.
1. The job has the tags `[docker, shell, gpu]` and is not executed.

### Use tags to run jobs on different platforms

You can use tags to run different jobs on different platforms. For
example, if you have an OS X runner with tag `osx` and a Windows runner with tag
`windows`, you can run a job on each platform.

Update the `tags` field in the `.gitlab-ci.yml`:

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```

### Use CI/CD variables in tags

In the `.gitlab-ci.yml` file, use [CI/CD variables](../variables/_index.md) with `tags` for dynamic runner selection:

```yaml
variables:
  KUBERNETES_RUNNER: kubernetes

  job:
    tags:
      - docker
      - $KUBERNETES_RUNNER
    script:
      - echo "Hello runner selector feature"
```

## Configure runner behavior with variables

You can use [CI/CD variables](../variables/_index.md) to configure runner Git behavior
globally or for individual jobs:

- [`GIT_STRATEGY`](#git-strategy)
- [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy)
- [`GIT_CHECKOUT`](#git-checkout)
- [`GIT_CLEAN_FLAGS`](#git-clean-flags)
- [`GIT_FETCH_EXTRA_FLAGS`](#git-fetch-extra-flags)
- [`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags)
- [`GIT_SUBMODULE_FORCE_HTTPS`](#rewrite-submodule-urls-to-https)
- [`GIT_DEPTH`](#shallow-cloning) (shallow cloning)
- [`GIT_SUBMODULE_DEPTH`](#git-submodule-depth)
- [`GIT_CLONE_PATH`](#custom-build-directories) (custom build directories)
- [`TRANSFER_METER_FREQUENCY`](#artifact-and-cache-settings) (artifact/cache meter update frequency)
- [`ARTIFACT_COMPRESSION_LEVEL`](#artifact-and-cache-settings) (artifact archiver compression level)
- [`CACHE_COMPRESSION_LEVEL`](#artifact-and-cache-settings) (cache archiver compression level)
- [`CACHE_REQUEST_TIMEOUT`](#artifact-and-cache-settings) (cache request timeout)
- [`RUNNER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`RUNNER_AFTER_SCRIPT_TIMEOUT`](#set-script-and-after_script-timeouts)
- [`AFTER_SCRIPT_IGNORE_ERRORS`](#ignore-errors-in-after_script)

You can also use variables to configure how many times a runner
[attempts certain stages of job execution](#job-stages-attempts).

When using the Kubernetes executor, you can use variables to
[override Kubernetes CPU and memory allocations for requests and limits](https://docs.gitlab.com/runner/executors/kubernetes/index.html#overwrite-container-resources).

### Git strategy

The `GIT_STRATEGY` variable configures how the build directory is prepared and
repository content is fetched. You can set this variable globally or per job
in the [`variables`](../yaml/_index.md#variables) section.

```yaml
variables:
  GIT_STRATEGY: clone
```

Possible values are `clone`, `fetch`, `none`, and `empty`. If you do not specify a value,
jobs use the [project's pipeline setting](../pipelines/settings.md#choose-the-default-git-strategy).

`clone` is the slowest option. It clones the repository from scratch for every
job, ensuring that the local working copy is always pristine.
If an existing worktree is found, it is removed before cloning.

`fetch` is faster as it re-uses the local working copy (falling back to `clone`
if it does not exist). `git clean` is used to undo any changes made by the last
job, and `git fetch` is used to retrieve commits made after the last job ran.

However, `fetch` does require access to the previous worktree. This works
well when using the `shell` or `docker` executor because these
try to preserve worktrees and try to re-use them by default.

This has limitations when using the [Docker Machine executor](https://docs.gitlab.com/runner/executors/docker_machine.html).

A Git strategy of `none` also re-uses the local working copy, but skips all Git
operations usually done by GitLab. GitLab Runner pre-clone scripts are also skipped,
if present. This strategy could mean you need to add `fetch` and `checkout` commands
to [your `.gitlab-ci.yml` script](../yaml/_index.md#script).

It can be used for jobs that operate exclusively on artifacts, like a deployment job.
Git repository data may be present, but it's likely out of date. You should only
rely on files brought into the local working copy from cache or artifacts. Be
aware that cache and artifact files from previous pipelines might still be present.

Unlike `none`, the `empty` Git strategy deletes and then re-creates
a dedicated build directory before downloading cache or artifact files.
With this strategy, the GitLab Runner hook scripts are still run
(if provided) to allow for further behavior customization.
Use the `empty` Git strategy when:

- You do not need the repository data to be present.
- You want a clean, controlled, or customized starting state every time a job runs.

### Git submodule strategy

The `GIT_SUBMODULE_STRATEGY` variable is used to control if / how
[Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) are included when fetching the code before a build. You can set them
globally or per-job in the [`variables`](../yaml/_index.md#variables) section.

The three possible values are `none`, `normal`, and `recursive`:

- `none` means that submodules are not included when fetching the project
  code. This setting matches the default behavior in versions before 1.10.

- `normal` means that only the top-level submodules are included. It's
  equivalent to:

  ```shell
  git submodule sync
  git submodule update --init
  ```

- `recursive` means that all submodules (including submodules of submodules)
  are included. This feature needs Git v1.8.1 and later. When using a
  GitLab Runner with an executor not based on Docker, make sure the Git version
  meets that requirement. It's equivalent to:

  ```shell
  git submodule sync --recursive
  git submodule update --init --recursive
  ```

For this feature to work correctly, the submodules must be configured
(in `.gitmodules`) with either:

- the HTTP(S) URL of a publicly-accessible repository, or
- a relative path to another repository on the same GitLab server. See the
  [Git submodules](git_submodules.md) documentation.

You can provide additional flags to control advanced behavior using [`GIT_SUBMODULE_UPDATE_FLAGS`](#git-submodule-update-flags).

### Git checkout

The `GIT_CHECKOUT` variable can be used when the `GIT_STRATEGY` is set to either
`clone` or `fetch` to specify whether a `git checkout` should be run. If not
specified, it defaults to true. You can set them globally or per-job in the
[`variables`](../yaml/_index.md#variables) section.

If set to `false`, the runner:

- when doing `fetch` - updates the repository and leaves the working copy on
  the current revision,
- when doing `clone` - clones the repository and leaves the working copy on the
  default branch.

If `GIT_CHECKOUT` is set to `true`, both `clone` and `fetch` work the same way.
The runner checks out the working copy of a revision related
to the CI pipeline:

```yaml
variables:
  GIT_STRATEGY: clone
  GIT_CHECKOUT: "false"
script:
  - git checkout -B master origin/master
  - git merge $CI_COMMIT_SHA
```

### Git clean flags

The `GIT_CLEAN_FLAGS` variable is used to control the default behavior of
`git clean` after checking out the sources. You can set it globally or per-job in the
[`variables`](../yaml/_index.md#variables) section.

`GIT_CLEAN_FLAGS` accepts all possible options of the [`git clean`](https://git-scm.com/docs/git-clean)
command.

`git clean` is disabled if `GIT_CHECKOUT: "false"` is specified.

If `GIT_CLEAN_FLAGS` is:

- Not specified, `git clean` flags default to `-ffdx`.
- Given the value `none`, `git clean` is not executed.

For example:

```yaml
variables:
  GIT_CLEAN_FLAGS: -ffdx -e cache/
script:
  - ls -al cache/
```

### Git fetch extra flags

Use the `GIT_FETCH_EXTRA_FLAGS` variable to control the behavior of
`git fetch`. You can set it globally or per-job in the [`variables`](../yaml/_index.md#variables) section.

`GIT_FETCH_EXTRA_FLAGS` accepts all options of the [`git fetch`](https://git-scm.com/docs/git-fetch) command. However, `GIT_FETCH_EXTRA_FLAGS` flags are appended after the default flags that can't be modified.

The default flags are:

- [`GIT_DEPTH`](#shallow-cloning).
- The list of [refspecs](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec).
- A remote called `origin`.

If `GIT_FETCH_EXTRA_FLAGS` is:

- Not specified, `git fetch` flags default to `--prune --quiet` along with the default flags.
- Given the value `none`, `git fetch` is executed only with the default flags.

For example, the default flags are `--prune --quiet`, so you can make `git fetch` more verbose by overriding this with just `--prune`:

```yaml
variables:
  GIT_FETCH_EXTRA_FLAGS: --prune
script:
  - ls -al cache/
```

The configuration above results in `git fetch` being called this way:

```shell
git fetch origin $REFSPECS --depth 50  --prune
```

Where `$REFSPECS` is a value provided to the runner internally by GitLab.

### Sync or exclude specific submodules from CI jobs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/2249) in GitLab Runner 14.0.

Use the `GIT_SUBMODULE_PATHS` variable to control which submodules have to be synced or updated.
You can set it globally or per-job in the [`variables`](../yaml/_index.md#variables) section.

The path syntax is the same as [`git submodule`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-ltpathgt82308203):

- To sync and update specific paths:

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
  ```

- To exclude specific paths:

  ```yaml
  variables:
     GIT_SUBMODULE_PATHS: ":(exclude)submoduleA :(exclude)submoduleB"
  ```

WARNING:
Git ignores nested paths. To ignore a nested submodule, exclude
the parent submodule and then manually clone it in the job's scripts. For example,
 `git clone <repo> --recurse-submodules=':(exclude)nested-submodule'`. Make sure
to wrap the string in single quotes so the YAML can be parsed successfully.

### Git submodule update flags

Use the `GIT_SUBMODULE_UPDATE_FLAGS` variable to control the behavior of `git submodule update`
when [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) is set to either `normal` or `recursive`.
You can set it globally or per-job in the [`variables`](../yaml/_index.md#variables) section.

`GIT_SUBMODULE_UPDATE_FLAGS` accepts all options of the
[`git submodule update`](https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt-update--init--remote-N--no-fetch--no-recommend-shallow-f--force--checkout--rebase--merge--referenceltrepositorygt--depthltdepthgt--recursive--jobsltngt--no-single-branch--ltpathgt82308203)
subcommand. However, `GIT_SUBMODULE_UPDATE_FLAGS` flags are appended after a few default flags:

- `--init`, if [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) was set to `normal` or `recursive`.
- `--recursive`, if [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) was set to `recursive`.
- [`GIT_DEPTH`](#shallow-cloning). See the default value below.

Git honors the last occurrence of a flag in the list of arguments, so manually
providing them in `GIT_SUBMODULE_UPDATE_FLAGS` overrides these default flags.

You can use this variable to fetch the latest remote `HEAD` instead of the tracked commit in the repository.
You can also use it to speed up the checkout by fetching submodules in multiple parallel jobs.

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_UPDATE_FLAGS: --remote --jobs 4
script:
  - ls -al .git/modules/
```

The configuration above results in `git submodule update` being called this way:

```shell
git submodule update --init --depth 50 --recursive --remote --jobs 4
```

WARNING:
You should be aware of the implications for the security, stability, and reproducibility of
your builds when using the `--remote` flag. In most cases, it is better to explicitly track
submodule commits as designed, and update them using an auto-remediation/dependency bot.

### Rewrite submodule URLs to HTTPS

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198) in GitLab Runner 15.11.

Use the `GIT_SUBMODULE_FORCE_HTTPS` variable to force a rewrite of all Git and SSH submodule URLs to HTTPS.
You can clone submodules that use absolute URLs on the same GitLab instance, even if they were
configured with a Git or SSH protocol.

```yaml
variables:
  GIT_SUBMODULE_STRATEGY: recursive
  GIT_SUBMODULE_FORCE_HTTPS: "true"
```

When enabled, GitLab Runner uses a [CI/CD job token](../jobs/ci_job_token.md) to clone the submodules.
The token uses the permissions of the user executing the job and does not require SSH credentials.

### Shallow cloning

You can specify the depth of fetching and cloning using `GIT_DEPTH`.
`GIT_DEPTH` does a shallow clone of the repository and can significantly speed up cloning.
It can be helpful for repositories with a large number of commits or old, large binaries. The value is
passed to `git fetch` and `git clone`.

Newly-created projects automatically have a
[default `git depth` value of `50`](../pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone).

If you use a depth of `1` and have a queue of jobs or retry
jobs, jobs may fail.

Git fetching and cloning is based on a ref, such as a branch name, so runners
can't clone a specific commit SHA. If multiple jobs are in the queue, or
you retry an old job, the commit to be tested must be in the cloned
Git history. Setting too small a value for `GIT_DEPTH` can make
it impossible to run these old commits and `unresolved reference` is displayed in
job logs. You should then reconsider changing `GIT_DEPTH` to a higher value.

Jobs that rely on `git describe` may not work correctly when `GIT_DEPTH` is
set because only part of the Git history is present.

To fetch or clone only the last 3 commits:

```yaml
variables:
  GIT_DEPTH: "3"
```

You can set it globally or per-job in the [`variables`](../yaml/_index.md#variables) section.

### Git submodule depth

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3651) in GitLab Runner 15.5.

Use the `GIT_SUBMODULE_DEPTH` variable to specify the depth of fetching and cloning submodules
when [`GIT_SUBMODULE_STRATEGY`](#git-submodule-strategy) is set to either `normal` or `recursive`.
You can set it globally or for a specific job in the [`variables`](../yaml/_index.md#variables) section.

When you set the `GIT_SUBMODULE_DEPTH` variable, it overwrites the [`GIT_DEPTH`](#shallow-cloning) setting
for the submodules only.

To fetch or clone only the last 3 commits:

```yaml
variables:
  GIT_SUBMODULE_DEPTH: 3
```

### Custom build directories

By default, GitLab Runner clones the repository in a unique subpath of the
`$CI_BUILDS_DIR` directory. However, your project might require the code in a
specific directory (Go projects, for example). In that case, you can specify
the `GIT_CLONE_PATH` variable to tell the runner the directory to clone the
repository in:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/project-name

test:
  script:
    - pwd
```

The `GIT_CLONE_PATH` must always be inside `$CI_BUILDS_DIR`. The directory set in `$CI_BUILDS_DIR`
is dependent on executor and configuration of [runners.builds_dir](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
setting.

This can only be used when `custom_build_dir` is enabled in the
[runner's configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscustom_build_dir-section).

#### Handling concurrency

An executor that uses a concurrency greater than `1` might lead
to failures. Multiple jobs might be working on the same directory if the `builds_dir`
is shared between jobs.

The runner does not try to prevent this situation. It's up to the administrator
and developers to comply with the requirements of runner configuration.

To avoid this scenario, you can use a unique path in `$CI_BUILDS_DIR`, because runner
exposes two additional variables that provide a unique `ID` of concurrency:

- `$CI_CONCURRENT_ID`: Unique ID for all jobs running in the given executor.
- `$CI_CONCURRENT_PROJECT_ID`: Unique ID for all jobs running in the given executor and project.

The most stable configuration that should work well in any scenario and on any executor
is to use `$CI_CONCURRENT_ID` in the `GIT_CLONE_PATH`. For example:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/project-name

test:
  script:
    - pwd -P
```

The `$CI_CONCURRENT_PROJECT_ID` should be used in conjunction with `$CI_PROJECT_PATH`.
`$CI_PROJECT_PATH` provides a path of a repository in the `group/subgroup/project` format.
For example:

```yaml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_PATH

test:
  script:
    - pwd -P
```

#### Nested paths

The value of `GIT_CLONE_PATH` expands once. You cannot nest variables
in this value.

For example, you define both the variables below in your
`.gitlab-ci.yml` file:

```yaml
variables:
  GOPATH: $CI_BUILDS_DIR/go
  GIT_CLONE_PATH: $GOPATH/src/namespace/project
```

The value of `GIT_CLONE_PATH` is expanded once into
`$CI_BUILDS_DIR/go/src/namespace/project`, and results in failure
because `$CI_BUILDS_DIR` is not expanded.

### Ignore errors in `after_script`

You can use [`after_script`](../yaml/_index.md#after_script) in a job to define an array of commands
that should run after the job's `before_script` and `script` sections. The `after_script` commands
run regardless of the script termination status (failure or success).

By default, GitLab Runner ignores any errors that happen when `after_script` runs.
To set the job to fail immediately on errors when `after_script` runs, set the
`AFTER_SCRIPT_IGNORE_ERRORS` CI/CD variable to `false`. For example:

```yaml
variables:
  AFTER_SCRIPT_IGNORE_ERRORS: false
```

### Job stages attempts

You can set the number of attempts that the running job tries to execute
the following stages:

| Variable                        | Description                                            |
|---------------------------------|--------------------------------------------------------|
| `ARTIFACT_DOWNLOAD_ATTEMPTS`    | Number of attempts to download artifacts running a job |
| `EXECUTOR_JOB_SECTION_ATTEMPTS` | The number of attempts to run a section in a job after a [`No Such Container`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4450) error ([Docker executor](https://docs.gitlab.com/runner/executors/docker.html) only). |
| `GET_SOURCES_ATTEMPTS`          | Number of attempts to fetch sources running a job      |
| `RESTORE_CACHE_ATTEMPTS`        | Number of attempts to restore the cache running a job  |

The default is one single attempt.

Example:

```yaml
variables:
  GET_SOURCES_ATTEMPTS: 3
```

You can set them globally or per-job in the [`variables`](../yaml/_index.md#variables) section.

## System calls not available on GitLab.com instance runners

GitLab.com instance runners run on CoreOS. This means that you cannot use some system calls, like `getlogin`, from the C standard library.

## Artifact and cache settings

Artifact and cache settings control the compression ratio of artifacts and caches.
Use these settings to specify the size of the archive produced by a job.

- On a slow network, uploads might be faster for smaller archives.
- On a fast network where bandwidth and storage are not a concern, uploads might be faster using the fastest compression ratio, despite the archive produced being larger.

For [GitLab Pages](../../user/project/pages/_index.md) to serve
[HTTP Range requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests), artifacts
should use the `ARTIFACT_COMPRESSION_LEVEL: fastest` setting, as only uncompressed zip archives
support this feature.

A meter can be enabled to provide the rate of transfer for uploads and downloads.

You can set a maximum time for cache upload and download with the `CACHE_REQUEST_TIMEOUT` setting.
Use this setting when slow cache uploads substantially increase the duration of your job.

```yaml
variables:
  # output upload and download progress every 2 seconds
  TRANSFER_METER_FREQUENCY: "2s"

  # Use fast compression for artifacts, resulting in larger archives
  ARTIFACT_COMPRESSION_LEVEL: "fast"

  # Use no compression for caches
  CACHE_COMPRESSION_LEVEL: "fastest"

  # Set maximum duration of cache upload and download
  CACHE_REQUEST_TIMEOUT: 5
```

| Variable                        | Description                                            |
|---------------------------------|--------------------------------------------------------|
| `TRANSFER_METER_FREQUENCY`      | Specify how often to print the meter's transfer rate. It can be set to a duration (for example, `1s` or `1m30s`). A duration of `0` disables the meter (default). When a value is set, the pipeline shows a progress meter for artifact and cache uploads and downloads. |
| `ARTIFACT_COMPRESSION_LEVEL`    | To adjust compression ratio, set to `fastest`, `fast`, `default`, `slow`, or `slowest`. This setting works with the Fastzip archiver only, so the GitLab Runner feature flag [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags) must also be enabled. |
| `CACHE_COMPRESSION_LEVEL`       | To adjust compression ratio, set to `fastest`, `fast`, `default`, `slow`, or `slowest`. This setting works with the Fastzip archiver only, so the GitLab Runner feature flag [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags) must also be enabled. |
| `CACHE_REQUEST_TIMEOUT`         | Configure the maximum duration of cache upload and download operations for a single job in minutes. Default is `10` minutes. |

## Artifact provenance metadata

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28940) in GitLab Runner 15.1.

Runners can generate and produce provenance metadata for all build artifacts.

To enable artifact provenance data, set the `RUNNER_GENERATE_ARTIFACTS_METADATA` environment
variable to `true`. You can set the variable as global or for individual jobs:

```yaml
variables:
  RUNNER_GENERATE_ARTIFACTS_METADATA: "true"

job1:
  variables:
    RUNNER_GENERATE_ARTIFACTS_METADATA: "true"
```

The metadata renders in a plain text `.json` file stored with the artifact. The
filename is `{ARTIFACT_NAME}-metadata.json`. `ARTIFACT_NAME` is the
[name for the artifact](../jobs/job_artifacts.md#with-an-explicitly-defined-artifact-name)
defined in the `.gitlab-ci.yml` file. If the name is not defined, the default filename is
`artifacts-metadata.json`.

### Provenance metadata format

The provenance metadata is generated in the [in-toto attestation format](https://github.com/in-toto/attestation) for spec version [1.0](https://github.com/in-toto/attestation/tree/v1.0/spec).

To use an SLSA v1.0 statement, set the `SLSA_PROVENANCE_SCHEMA_VERSION=v1` variable in the `.gitlab-ci.yml` file.

The following fields are populated by default:

| Field  | Value  |
| ------ | ------ |
| `_type` | `https://in-toto.io/Statement/v0.1` |
| `subject.name` | The filename of the artifact. |
| `subject.digest.sha256` | The artifact's `sha256` checksum. |
| `predicateType` | `https://slsa.dev/provenance/v0.2` |
| `predicate.buildType` | `https://gitlab.com/gitlab-org/gitlab-runner/-/blob/{GITLAB_RUNNER_VERSION}/PROVENANCE.md`. For example v15.0.0 |
| `predicate.builder.id` | A URI pointing to the runner details page, for example `https://gitlab.com/gitlab-com/www-gitlab-com/-/runners/3785264`. |
| `predicate.invocation.configSource.uri` | ``https://gitlab.example.com/.../{PROJECT_NAME}`` |
| `predicate.invocation.configSource.digest.sha256` | The repository's `sha256` checksum. |
| `predicate.invocation.configSource.entryPoint` | The name of the CI job that triggered the build. |
| `predicate.invocation.environment.name` | The name of the runner. |
| `predicate.invocation.environment.executor` | The runner executor. |
| `predicate.invocation.environment.architecture` | The architecture on which the CI job is run. |
| `predicate.invocation.parameters` | The names of any CI/CD or environment variables that were present when the build command was run. The value is always represented as an empty string to avoid leaking any secrets. |
| `metadata.buildStartedOn` | The time when the build was started. `RFC3339` formatted. |
| `metadata.buildEndedOn` | The time when the build ended. Because metadata generation happens during the build, this time is slightly earlier than the one reported in GitLab. `RFC3339` formatted. |
| `metadata.reproducible` | Whether the build is reproducible by gathering all the generated metadata. Always `false`. |
| `metadata.completeness.parameters` | Whether the parameters are supplied. Always `true`. |
| `metadata.completeness.environment` | Whether the builder's environment is reported. Always `true`. |
| `metadata.completeness.materials` | Whether the build materials are reported. Always `false`. |

An example of provenance metadata that the GitLab Runner might generate is as follows:

```yaml
{
 "_type": "https://in-toto.io/Statement/v0.1",
 "predicateType": "https://slsa.dev/provenance/v1",
 "subject": [
  {
   "name": "build/pico_w/wifi/blink/picow_blink.uf2",
   "digest": {
    "sha256": "f5a381a3fdf095a88fb928094f0e38cf269d226b07414369e8906d749634c090"
   }
  },
  {
   "name": "build/pico_w/wifi/blink/picow_blink.0.1.148-2-new-feature49.cosign.bundle",
   "digest": {
    "sha256": "f8762bf0b3ea1b88550b755323bf04417c2bbe9e50010cfcefc1fa877e2b52a6"
   }
  },
  {
   "name": "build/pico_w/wifi/blink/pico-examples-3a.0.1.148-2-new-feature49.tar.gz",
   "digest": {
    "sha256": "104674887da894443ab55918d81b0151dc7abb2472e5dafcdd78e7be71098af1"
   }
  },
  {
   "name": "build/pico_w/wifi/blink/pico-examples-3a.0.1.148-2-new-feature49.tar.gz.cosign.bundle",
   "digest": {
    "sha256": "33f3f7a19779a2d189dc03b420eb0be199a38404e8c1a24b2c8731bdfa3a30fb"
   }
  }
 ],
 "predicate": {
  "buildDefinition": {
   "buildType": "https://gitlab.com/gitlab-org/gitlab-runner/-/blob/761ae5dd/PROVENANCE.md",
   // All other CI variable names are listed here. Values are always represented as empty strings to avoid leaking secrets and to comply with SLSA.
   "externalParameters": {
    "CI": "",
    "CI_API_GRAPHQL_URL": "",
    "CI_API_V4_URL": "",
    "CI_COMMIT_AUTHOR": "",
    "CI_COMMIT_BEFORE_SHA": "",
    "CI_COMMIT_BRANCH": "",
    "CI_COMMIT_DESCRIPTION": "",
    "CI_COMMIT_MESSAGE": "",
    "CI_COMMIT_REF_NAME": "",
    "CI_COMMIT_REF_PROTECTED": "",
    "CI_COMMIT_REF_SLUG": "",
    "CI_COMMIT_SHA": "",
    "CI_COMMIT_SHORT_SHA": "",
    "CI_COMMIT_TIMESTAMP": "",
    "CI_COMMIT_TITLE": "",
    "CI_CONFIG_PATH": "",
    "CI_DEFAULT_BRANCH": "",
    "CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX": "",
    "CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX": "",
    "CI_DEPENDENCY_PROXY_PASSWORD": "",
    "CI_DEPENDENCY_PROXY_SERVER": "",
    "CI_DEPENDENCY_PROXY_USER": "",
    "CI_JOB_ID": "",
    "CI_JOB_NAME": "",
    "CI_JOB_NAME_SLUG": "",
    "CI_JOB_STAGE": "",
    "CI_JOB_STARTED_AT": "",
    "CI_JOB_TOKEN": "",
    "CI_JOB_URL": "",
    "CI_NODE_TOTAL": "",
    "CI_OPEN_MERGE_REQUESTS": "",
    "CI_PAGES_DOMAIN": "",
    "CI_PAGES_URL": "",
    "CI_PIPELINE_CREATED_AT": "",
    "CI_PIPELINE_ID": "",
    "CI_PIPELINE_IID": "",
    "CI_PIPELINE_NAME": "",
    "CI_PIPELINE_SOURCE": "",
    "CI_PIPELINE_URL": "",
    "CI_PROJECT_CLASSIFICATION_LABEL": "",
    "CI_PROJECT_DESCRIPTION": "",
    "CI_PROJECT_ID": "",
    "CI_PROJECT_NAME": "",
    "CI_PROJECT_NAMESPACE": "",
    "CI_PROJECT_NAMESPACE_ID": "",
    "CI_PROJECT_PATH": "",
    "CI_PROJECT_PATH_SLUG": "",
    "CI_PROJECT_REPOSITORY_LANGUAGES": "",
    "CI_PROJECT_ROOT_NAMESPACE": "",
    "CI_PROJECT_TITLE": "",
    "CI_PROJECT_URL": "",
    "CI_PROJECT_VISIBILITY": "",
    "CI_REGISTRY": "",
    "CI_REGISTRY_IMAGE": "",
    "CI_REGISTRY_PASSWORD": "",
    "CI_REGISTRY_USER": "",
    "CI_REPOSITORY_URL": "",
    "CI_RUNNER_DESCRIPTION": "",
    "CI_RUNNER_ID": "",
    "CI_RUNNER_TAGS": "",
    "CI_SERVER_FQDN": "",
    "CI_SERVER_HOST": "",
    "CI_SERVER_NAME": "",
    "CI_SERVER_PORT": "",
    "CI_SERVER_PROTOCOL": "",
    "CI_SERVER_REVISION": "",
    "CI_SERVER_SHELL_SSH_HOST": "",
    "CI_SERVER_SHELL_SSH_PORT": "",
    "CI_SERVER_URL": "",
    "CI_SERVER_VERSION": "",
    "CI_SERVER_VERSION_MAJOR": "",
    "CI_SERVER_VERSION_MINOR": "",
    "CI_SERVER_VERSION_PATCH": "",
    "CI_TEMPLATE_REGISTRY_HOST": "",
    "COSIGN_YES": "",
    "DS_EXCLUDED_ANALYZERS": "",
    "DS_EXCLUDED_PATHS": "",
    "DS_MAJOR_VERSION": "",
    "DS_SCHEMA_MODEL": "",
    "GITLAB_CI": "",
    "GITLAB_FEATURES": "",
    "GITLAB_USER_EMAIL": "",
    "GITLAB_USER_ID": "",
    "GITLAB_USER_LOGIN": "",
    "GITLAB_USER_NAME": "",
    "GitVersion_FullSemVer": "",
    "GitVersion_LegacySemVer": "",
    "GitVersion_Major": "",
    "GitVersion_MajorMinorPatch": "",
    "GitVersion_Minor": "",
    "GitVersion_Patch": "",
    "GitVersion_SemVer": "",
    "RUNNER_GENERATE_ARTIFACTS_METADATA": "",
    "SAST_EXCLUDED_ANALYZERS": "",
    "SAST_EXCLUDED_PATHS": "",
    "SAST_IMAGE_SUFFIX": "",
    "SCAN_KUBERNETES_MANIFESTS": "",
    "SECRETS_ANALYZER_VERSION": "",
    "SECRET_DETECTION_EXCLUDED_PATHS": "",
    "SECRET_DETECTION_IMAGE_SUFFIX": "",
    "SECURE_ANALYZERS_PREFIX": "",
    "SIGSTORE_ID_TOKEN": "",
    "entryPoint": "create_generic_package",
    "source": "https://gitlab.com/dsanoy-demo/experiments/pico-examples-3a"
   },
   "internalParameters": {
    "architecture": "amd64",
    "executor": "docker+machine",
    "job": "7211908025",
    "name": "green-6.saas-linux-small-amd64.runners-manager.gitlab.com/default"
   },
   "resolvedDependencies": [
    {
     "uri": "https://gitlab.com/dsanoy-demo/experiments/pico-examples-3a",
     "digest": {
      "sha256": "7e1aeac4e6c07138769b638d4926f429692d0124"
     }
    }
   ]
  },
  "runDetails": {
   "builder": {
    "id": "https://gitlab.com/dsanoy-demo/experiments/pico-examples-3a/-/runners/32976645",
    "version": {
     "gitlab-runner": "761ae5dd"
    }
   },
   "metadata": {
    "invocationID": "7211908025",
    "startedOn": "2024-06-28T09:56:44Z",
    "finishedOn": "2024-06-28T09:56:58Z"
   }
  }
 }
}
```

To verify compliance with the in-toto specification,
see the [in-toto statement](https://in-toto.io/Statement/v0.1).

## Staging directory

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3403) in GitLab Runner 15.0.

If you do not want to archive cache and artifacts in the system's default temporary directory, you can specify a different directory.

You might need to change the directory if your system's default temporary path has constraints.
If you use a fast disk for the directory location, it can also improve performance.

To change the directory, set `ARCHIVER_STAGING_DIR` as a variable in your CI job, or use a runner variable when you register the runner (`gitlab register --env ARCHIVER_STAGING_DIR=<dir>`).

The directory you specify is used as the location for downloading artifacts prior to extraction. If the `fastzip` archiver is
used, this location is also used as scratch space when archiving.

## Configure `fastzip` to improve performance

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3130) in GitLab Runner 15.0.

To tune `fastzip`, ensure the [`FF_USE_FASTZIP`](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags) flag is enabled.
Then use any of the following environment variables.

| Variable                        | Description                                            |
|---------------------------------|--------------------------------------------------------|
| `FASTZIP_ARCHIVER_CONCURRENCY`  | The number of files to be concurrently compressed. Default is the number of CPUs available. |
| `FASTZIP_ARCHIVER_BUFFER_SIZE`  | The buffer size allocated per concurrency for each file. Data exceeding this number moves to scratch space. Default is 2 MiB.  |
| `FASTZIP_EXTRACTOR_CONCURRENCY` | The number of files to be concurrency decompressed. Default is the number of CPUs available. |

Files in a zip archive are appended sequentially. This makes concurrent compression challenging. `fastzip` works around
this limitation by compressing files concurrently to disk first, and then copying the result back to zip archive
sequentially.

To avoid writing to disk and reading the contents back for smaller files, a small buffer per concurrency is used. This setting
can be controlled with `FASTZIP_ARCHIVER_BUFFER_SIZE`. The default size for this buffer is 2 MiB, therefore, a
concurrency of 16 allocates 32 MiB. Data that exceeds the buffer size is written to and read back from disk.
Therefore, using no buffer, `FASTZIP_ARCHIVER_BUFFER_SIZE: 0`, and only scratch space is a valid option.

`FASTZIP_ARCHIVER_CONCURRENCY` controls how many files are compressed concurrency. As mentioned above, this setting
therefore can increase how much memory is being used. It can also increase the temporary data written to the scratch space.
The default is the number of CPUs available, but given the memory ramifications, this may not always be the best
setting.

`FASTZIP_EXTRACTOR_CONCURRENCY` controls how many files are decompressed at once. Files from a zip archive can natively
be read from concurrency, so no additional memory is allocated in addition to what the extractor requires. This
defaults to the number of CPUs available.

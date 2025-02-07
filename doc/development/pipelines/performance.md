---
stage: none
group: Engineering Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: CI configuration performance
---

## Interruptible pipelines

By default, all jobs are [interruptible](../../ci/yaml/_index.md#interruptible), except the
`dont-interrupt-me` job which runs automatically on `main`, and is `manual`
otherwise.

If you want a running pipeline to finish even if you push new commits to a merge
request, be sure to start the `dont-interrupt-me` job before pushing.

## Git fetch caching

Because GitLab.com uses the [pack-objects cache](../../administration/gitaly/configure_gitaly.md#pack-objects-cache),
concurrent Git fetches of the same pipeline ref are deduplicated on
the Gitaly server (always) and served from cache (when available).

This works well for the following reasons:

- The pack-objects cache is enabled on all Gitaly servers on GitLab.com.
- The CI/CD [Git strategy setting](../../ci/pipelines/settings.md#choose-the-default-git-strategy) for `gitlab-org/gitlab` is **Git clone**,
  causing all jobs to fetch the same data, which maximizes the cache hit ratio.
- We use [shallow clone](../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone) to avoid downloading the full Git
  history for every job.

### Fetch repository via artifacts instead of cloning/fetching from Gitaly

Lately we see errors from Gitaly look like this: (see [the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435456))

```plaintext
fatal: remote error: GitLab is currently unable to handle this request due to load.
```

While GitLab.com uses [pack-objects cache](../../administration/gitaly/configure_gitaly.md#pack-objects-cache),
sometimes the load is still too heavy for Gitaly to handle, and
[thundering herds](https://gitlab.com/gitlab-org/gitlab/-/issues/423830) can
also be a concern that we have a lot of jobs cloning the repository around
the same time.

To mitigate and reduce loads for Gitaly, we changed some jobs to fetch the
repository from artifacts in a job instead of all cloning from Gitaly at once.

For now this applies to most of the RSpec jobs, which has the most concurrent
jobs in most pipelines. This also slightly improved the speed because fetching
from the artifacts is also slightly faster than cloning, at the cost of saving
more artifacts for each pipeline.

Based on the numbers on 2023-12-20 at [Fetch repo from artifacts for RSpec jobs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140330),
the extra storage cost was about 280M for each pipeline, and we save 15 seconds
for each RSpec jobs.

We do not apply this to jobs having no other job dependencies because we don't
want to delay any jobs from starting.

This behavior can be controlled by variable `CI_FETCH_REPO_GIT_STRATEGY`:

- Set to `none` means jobs using `.repo-from-artifacts` fetch repository from
  artifacts in job `clone-gitlab-repo` rather than cloning.
- Set to `clone` means jobs using `.repo-from-artifacts` clone repository
  as usual. Job `clone-gitlab-repo` does not run in this case.

To disable it, set `CI_FETCH_REPO_GIT_STRATEGY` to `clone`. To enable it,
set `CI_FETCH_REPO_GIT_STRATEGY` to `none`.

## Caching strategy

1. All jobs must only pull caches by default.
1. All jobs must be able to pass with an empty cache. In other words, caches are only there to speed up jobs.
1. We currently have several different cache definitions defined in
   [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml),
   with fixed keys:
   - `.setup-test-env-cache`
   - `.ruby-cache`
   - `.static-analysis-cache`
   - `.rubocop-cache`
   - `.ruby-gems-coverage-cache`
   - `.ruby-node-cache`
   - `.qa-cache`
   - `.yarn-cache`
   - `.assets-compile-cache` (the key includes `${NODE_ENV}` so it's actually two different caches).
1. These cache definitions are composed of [multiple atomic caches](../../ci/caching/_index.md#use-multiple-caches).
1. Only the following jobs, running in 2-hourly `maintenance` scheduled pipelines, are pushing (that is, updating) to the caches:
   - `update-setup-test-env-cache`, defined in [`.gitlab/ci/rails.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rails.gitlab-ci.yml).
   - `update-gitaly-binaries-cache`, defined in [`.gitlab/ci/rails.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rails.gitlab-ci.yml).
   - `update-rubocop-cache`, defined in [`.gitlab/ci/rails.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rails.gitlab-ci.yml).
   - `update-qa-cache`, defined in [`.gitlab/ci/qa.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/qa.gitlab-ci.yml).
   - `update-assets-compile-production-cache`, defined in [`.gitlab/ci/frontend.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml).
   - `update-assets-compile-test-cache`, defined in [`.gitlab/ci/frontend.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml).
   - `update-storybook-yarn-cache`, defined in [`.gitlab/ci/frontend.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml).
1. These jobs can also be forced to run in merge requests with the `pipeline:update-cache` label (this can be useful to warm the caches in a MR that updates the cache keys).

## Artifacts strategy

We limit the artifacts that are saved and retrieved by jobs to the minimum to reduce the upload/download time and costs, as well as the artifacts storage.

## Components caching

Some external components (GitLab Workhorse and frontend assets) of GitLab need to be built from source as a preliminary step for running tests.

## `cache-workhorse`

In [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79766), and then
[this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96297),
we introduced a new `cache-workhorse` job that:

- runs automatically for all GitLab.com `gitlab-org/gitlab` scheduled pipelines
- runs automatically for any `master` commit that touches the `workhorse/` folder
- is manual for GitLab.com's `gitlab-org`'s MRs that touches caching-related files

This job tries to download a generic package that contains GitLab Workhorse binaries needed in the GitLab test suite (under `tmp/tests/gitlab-workhorse`).

- If the package URL returns a 404:
  1. It runs `scripts/setup-test-env`, so that the GitLab Workhorse binaries are built.
  1. It then creates an archive which contains the binaries and upload it [as a generic package](https://gitlab.com/gitlab-org/gitlab/-/packages/).
- Otherwise, if the package already exists, it exits the job successfully.

We also changed the `setup-test-env` job to:

1. First download the GitLab Workhorse generic package build and uploaded by `cache-workhorse`.
1. If the package is retrieved successfully, its content is placed in the right folder (for example, `tmp/tests/gitlab-workhorse`), preventing the building of the binaries when `scripts/setup-test-env` is run later on.
1. If the package URL returns a 404, the behavior doesn't change compared to the current one: the GitLab Workhorse binaries are built as part of `scripts/setup-test-env`.

NOTE:
The version of the package is the workhorse tree SHA (for example, `git rev-parse HEAD:workhorse`).

## `cache-assets`

In [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96297),
we introduced three new `cache-assets:test`, `cache-assets:test as-if-foss`,
and `cache-assets:production` jobs that:

- never run unless `$CACHE_ASSETS_AS_PACKAGE == "true"`
- runs automatically for all GitLab.com `gitlab-org/gitlab` scheduled pipelines
- runs automatically for any `master` commit that touches the assets-related folders
- is manual for GitLab.com's `gitlab-org`'s MRs that touches caching-related files

This job tries to download a generic package that contains GitLab compiled assets
needed in the GitLab test suite (under `app/assets/javascripts/locale/**/app.js`,
and `public/assets`).

- If the package URL returns a 404:
  1. It runs `bin/rake gitlab:assets:compile`, so that the GitLab assets are compiled.
  1. It then creates an archive which contains the assets and uploads it [as a generic package](https://gitlab.com/gitlab-org/gitlab/-/packages/).
     The package version is set to the assets folders' hash sum.
- Otherwise, if the package already exists, it exits the job successfully.

## `compile-*-assets`

We also changed the `compile-test-assets`,
and `compile-production-assets` jobs to:

1. First download the "native" cache assets, which contain:
   - The [compiled assets](https://gitlab.com/gitlab-org/gitlab/-/blob/a6910c9086bb28e553f5e747ec2dd50af6da3c6b/.gitlab/ci/global.gitlab-ci.yml#L86-87).
   - A [`cached-assets-hash.txt` file](https://gitlab.com/gitlab-org/gitlab/-/blob/a6910c9086bb28e553f5e747ec2dd50af6da3c6b/.gitlab/ci/global.gitlab-ci.yml#L85)
     containing the `SHA256` hexdigest of all the source files on which the assets depend on.
     This list of files is a pessimistic list and the assets might not depend on
     some of these files. At worst we compile the assets more often, which is better than
     using outdated assets.

     The file is [created after assets are compiled](https://gitlab.com/gitlab-org/gitlab/-/blob/a6910c9086bb28e553f5e747ec2dd50af6da3c6b/.gitlab/ci/frontend.gitlab-ci.yml#L83).
1. We then we compute the `SHA256` hexdigest of all the source files the assets depend on, **for the current checked out branch**. We [store the hexdigest in the `GITLAB_ASSETS_HASH` variable](https://gitlab.com/gitlab-org/gitlab/-/blob/a6910c9086bb28e553f5e747ec2dd50af6da3c6b/.gitlab/ci/frontend.gitlab-ci.yml#L27).
1. If `$CACHE_ASSETS_AS_PACKAGE == "true"`, we download the generic package built and uploaded by [`cache-assets:*`](#cache-assets).
   - If the cache is up-to-date for the checked out branch, we download the native cache
     **and** the cache package. We could optimize that by not downloading
     the genetic package but the native cache is actually very often outdated because it's
     rebuilt only every 2 hours.
1. We [run the `assets_compile_script` function](https://gitlab.com/gitlab-org/gitlab/-/blob/a6910c9086bb28e553f5e747ec2dd50af6da3c6b/.gitlab/ci/frontend.gitlab-ci.yml#L35),
   which [itself runs](https://gitlab.com/gitlab-org/gitlab/-/blob/c023191ef412e868ae957f3341208a41ca678403/scripts/utils.sh#L76)
   the [`assets:compile` Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/c023191ef412e868ae957f3341208a41ca678403/lib/tasks/gitlab/assets.rake#L80-109).

   This task is responsible for deciding if assets need to be compiled or not.
   It [compares the `HEAD` `SHA256` hexdigest from `$GITLAB_ASSETS_HASH` with the `master` hexdigest from `cached-assets-hash.txt`](https://gitlab.com/gitlab-org/gitlab/-/blob/c023191ef412e868ae957f3341208a41ca678403/lib/tasks/gitlab/assets.rake#L86).
1. If the hashes are the same, we don't compile anything. If they're different, we compile the assets.

## Stripped binaries

By default, `setup-test-env` creates an artifact which contains stripped
binaries to [save storage and speed-up artifact downloads](https://gitlab.com/gitlab-org/gitlab/-/issues/442029#note_1775193538) of subsequent CI jobs.

To make debugging a crash from stripped binaries easier comment line with
`strip_executable_binaries` in the `setup-test-job` job and start a new pipeline.

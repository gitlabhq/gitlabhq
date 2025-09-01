---
stage: none
group: Engineering Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

Caches in GitLab CI/CD pipelines must follow these criteria:

- **Pull-push vs pull-only configuration**: Jobs in the `sync` stage (which runs at the start of pipelines) responsible for populating cache use pull-push configuration, while jobs that consume cache use pull-only configuration to be branch agnostic and populate cache for specific branch pipeline runs.
- **File-specific checksums**: All cache keys should be coupled to their file-specific checksums to ensure caches are invalidated correctly when dependencies change.
- **Language version coupling**: Cache keys should include respective language-specific versions where applicable to ensure language version upgrades invalidate cache appropriately.
- **Sync stage placement**: Cache update jobs should be defined in the `sync` stage to run at the very start of the pipeline.
- **Reusable definitions**: Reusable cache key definitions are placed in `.gitlab/ci/global.gitlab-ci.yml` file for consistency across the project.

### Exception for pull-push default

Some caches are only pushed from the default branch and pulled in non-default branch pipelines. Such caches must use `unprotect: true` to be pulled correctly in non-default branch pipelines.

### Complex checksum calculation

In cases when cache keys require complex multiple file checksum calculation, a specific job should be added in the `sync` stage which calculates the cache checksum and makes it available via environment variable by saving it as a dotenv type report artifact. This ensures that all subsequent jobs can use the pre-calculated checksum for consistent cache key generation across the pipeline.

## Artifacts strategy

We limit the artifacts that are saved and retrieved by jobs to the minimum to reduce the upload/download time and costs, as well as the artifacts storage.

## Stripped binaries

By default, `setup-test-env` creates an artifact which contains stripped
binaries to [save storage and speed-up artifact downloads](https://gitlab.com/gitlab-org/gitlab/-/issues/442029#note_1775193538) of subsequent CI jobs.

To make debugging a crash from stripped binaries easier comment line with
`strip_executable_binaries` in the `setup_test_env` function in `scripts/gitlab_component_helpers.sh` shell script and start a new pipeline.

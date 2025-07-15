---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Release CLI tool
---

**The `release-cli` is in maintenance mode**.

The `release-cli` does not accept new features.
All new feature development happens in the `glab` CLI,
so you should use the [`glab` CLI](../../../editor_extensions/gitlab_cli/_index.md) whenever possible.
You can use [the feedback issue](https://gitlab.com/gitlab-org/cli/-/issues/7859) to share any comments.

## Switch from `release-cli` to `glab` CLI

- For API usage details, see [the `glab` CLI project documentation](https://gitlab.com/gitlab-org/cli).
- With a CI/CD job and the [`release`](../../../ci/yaml/_index.md#release) keyword,
  change the job's `image` to use the `cli:latest` image. For example:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the cli.'
```

## Fall back to `release-cli`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/524346) in GitLab 18.0, [with a flag](../../../administration/feature_flags/_index.md) named `ci_glab_for_release`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

CI/CD jobs that use the `release` keyword use a script that falls back to using `release-cli`
if the required `glab` version is not available on the runner. The fallback logic
is a safe-guard to ensure that projects that have not yet migrated to use `glab` CLI
can continue working.

This fallback is [scheduled to be removed](https://gitlab.com/gitlab-org/gitlab/-/issues/537919)
in GitLab 19.0 with the removal of `release-cli`.

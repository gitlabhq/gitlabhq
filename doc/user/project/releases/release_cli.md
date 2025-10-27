---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Release CLI tool (deprecated)
---

<!--- start_remove The following content will be removed on remove_date: '2026-06-19' -->

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/gitlab-org/cli/-/issues/7859) in GitLab 18.0
and is planned for removal in 20.0. Use the [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md) instead.

This change is a breaking change.

{{< /alert >}}

## Migrate from `release-cli` to `glab` CLI

To migrate from `release-cli` to `glab` CLI,
update your CI/CD job with the `release` keyword to use the `cli:latest` image:

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
    description: 'Release created using the CLI.'
```

For more information, see [`release`](../../../ci/yaml/_index.md#release).

## Fall back to `release-cli`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/524346) in GitLab 18.0, [with a flag](../../../administration/feature_flags/_index.md) named `ci_glab_for_release`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/537398) in GitLab 18.4. Feature flag `ci_glab_for_release` removed.

{{< /history >}}

CI/CD jobs that use the `release` keyword use a script that falls back to using `release-cli`
if the required `glab` version is not available on the runner. The fallback logic
is a safe-guard to ensure that projects that have not yet migrated to use `glab` CLI
can continue working.

This fallback is [scheduled to be removed](https://gitlab.com/gitlab-org/gitlab/-/issues/537919)
in GitLab 20.0 with the removal of `release-cli`.

<!--- end_remove -->

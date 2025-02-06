---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using Git submodules with GitLab CI/CD
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use [Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to keep
a Git repository as a subdirectory of another Git repository. You can clone another
repository into your project and keep your commits separate.

## Configure the `.gitmodules` file

When you use Git submodules, your project should have a file named `.gitmodules`.
You have multiple options to configure it to work in a GitLab CI/CD job.

### Using absolute URLs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198) in GitLab Runner 15.11.

For example, your generated `.gitmodules` configuration might look like the following if:

- Your project is located at `https://gitlab.com/secret-group/my-project`.
- Your project depends on `https://gitlab.com/group/project`, which you want
  to include as a submodule.
- You check out your sources with an SSH address like `git@gitlab.com:secret-group/my-project.git`.

```ini
[submodule "project"]
  path = project
  url = git@gitlab.com:group/project.git
```

In this case, use the [`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https) variable
to instruct GitLab Runner to convert the URL to HTTPS before it clones the submodules.

Alternatively, if you also use HTTPS locally, you can configure an HTTPS URL:

```ini
[submodule "project"]
  path = project
  url = https://gitlab.com/group/project.git
```

You do not need to configure additional variables in this case, but you need to use a
[personal access token](../../user/profile/personal_access_tokens.md) to clone it locally.

### Using relative URLs

WARNING:
If you use relative URLs, submodules may resolve incorrectly in forking workflows.
Use absolute URLs instead if you expect your project to have forks.

When your submodule is on the same GitLab server, you can also use relative URLs in
your `.gitmodules` file:

```ini
[submodule "project"]
  path = project
  url = ../../project.git
```

The above configuration instructs Git to automatically deduce the URL to
use when cloning sources. You can clone with HTTPS in all your CI/CD jobs, and you
can continue to use SSH to clone locally.

For submodules not located on the same GitLab server, always use the full URL:

```ini
[submodule "project-x"]
  path = project-x
  url = https://gitserver.com/group/project-x.git
```

## Use Git submodules in CI/CD jobs

To make submodules work correctly in CI/CD jobs:

1. You can set the `GIT_SUBMODULE_STRATEGY` variable to either `normal` or `recursive`
   to tell the runner to [fetch your submodules before the job](configure_runners.md#git-submodule-strategy):

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
   ```

1. For submodules located on the same GitLab server and configured with a Git or SSH URL, make sure
   you set the [`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https) variable.

1. Use `GIT_SUBMODULE_DEPTH` to configure the cloning depth of submodules independently of the [`GIT_DEPTH`](configure_runners.md#shallow-cloning) variable:

   ```yaml
   variables:
     GIT_SUBMODULE_DEPTH: 1
   ```

1. You can filter or exclude specific submodules to control which submodules are synchronized using
   [`GIT_SUBMODULE_PATHS`](configure_runners.md#sync-or-exclude-specific-submodules-from-ci-jobs).

   ```yaml
   variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
   ```

1. You can provide additional flags to control advanced checkout behavior using
   [`GIT_SUBMODULE_UPDATE_FLAGS`](configure_runners.md#git-submodule-update-flags).

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
     GIT_SUBMODULE_UPDATE_FLAGS: --jobs 4
   ```

If you use the [`CI_JOB_TOKEN`](../jobs/ci_job_token.md) to clone a submodule in a
pipeline job, the user executing the job must be assigned to a role that has
[permission](../../user/permissions.md#cicd) to trigger a pipeline
in the upstream submodule project. Additionally, [CI/CD job token access](../jobs/ci_job_token.md#control-job-token-access-to-your-project) must be properly configured in the upstream submodule project.

## Troubleshooting

### Can't find the `.gitmodules` file

The `.gitmodules` file might be hard to find because it is usually a hidden file.
You can check documentation for your specific OS to learn how to find and display
hidden files.

If there is no `.gitmodules` file, it's possible the submodule settings are in a
[`git config`](https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-config) file.

### `fatal: run_command returned non-zero status` error

This error can happen in a job when working with submodules and the `GIT_STRATEGY` is set to `fetch`.

Setting the `GIT_STRATEGY` to `clone` should resolve the issue.

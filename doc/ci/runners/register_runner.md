---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Generate runner tokens **(FREE)**

To register a runner, you can use either:

- An authentication token assigned to the runner when you create the runner in the UI. The runner uses the token to authenticate with GitLab when picking up jobs from the job queue.
- A registration token (deprecated).

## Generate an authentication token

Registration with an authentication token is available for all runners.

NOTE:
The token only displays in the UI for a short period of time during registration.

### For a shared runner

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383139) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_admin` [flag](../../administration/feature_flags.md)
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/389269) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flag](../../administration/feature_flags.md) named `create_runner_workflow_for_admin`.

Prerequisites:

- You must be an administrator.

To generate an authentication token for a shared runner:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **New instance runner**.
1. Select a platform.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the instructions to register the runner from the command line.

### For a group runner

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383143) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_namespace` [flag](../../administration/feature_flags.md). Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/393919) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flag](../../administration/feature_flags.md) named `create_runner_workflow_for_namespace`.

Prerequisites:

- You must have the Owner role for the group.

To generate an authentication token for a group runner:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **New group runner**.
1. Select a platform.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the instructions to register the runner from the command line.

### For a project runner

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383143) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_namespace` [flag](../../administration/feature_flags.md). Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/393919) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature,
ask an administrator to [disable the feature flag](../../administration/feature_flags.md) named `create_runner_workflow_for_namespace`.

Prerequisites:

- You must have the Maintainer role for the project.

To generate an authentication token for a project runner:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Select **New project runner**.
1. Select a platform.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the instructions to register the runner from the command line.

## Generate a registration token (deprecated)

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6. Authentication tokens
should be used instead to register runners. Registration tokens, and support for certain configuration arguments
will be disabled behind a feature flag in GitLab 16.6 and removed in GitLab 17.0. The configuration arguments disabled for `glrt-` tokens are `--locked`, `--access-level`, `--run-untagged`, `--maximum-timeout`, `--paused`, `--tag-list`, and `--maintenance-note`. This change is a breaking
change.

### For a shared runner

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **Register an instance runner**.
1. Copy the registration token.

### For a group runner

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **CI/CD > Runners**.
1. Copy the registration token.

### For a project runner

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand the **Runners** section.
1. Copy the registration token.

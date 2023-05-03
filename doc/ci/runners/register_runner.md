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

Registration with an authentication token is only available for shared runners. Support for project and group
runners is proposed in this [epic](https://gitlab.com/groups/gitlab-org/-/epics/7633).

### For a shared runner

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383139) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_admin` [flag](../../administration/feature_flags.md), disabled by default.

FLAG:
On self-managed GitLab, this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `create_runner_workflow_for_admin`.
On GitLab.com, this feature is available but can be configured by GitLab.com administrators only.

Prerequisites:

- You must be an administrator.

To generate an authentication token for a shared runner:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **New instance runner**.
1. Select a platform.
1. Optional. Enter a description.
1. Optional. Enter a maintenance note.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the instructions to register the runner from the command line.

NOTE:
The token only displays in the UI for a short period of time during registration,
and is then saved in `config.toml`.

## Generate a registration token (deprecated)

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6. Authentication tokens
will be used instead to register runners. Registration tokens, and support for certain configuration arguments
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

---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Register a shared runner **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383139) in GitLab 15.10. [Deployed behind the `create_runner_workflow_for_admin` flag](../../administration/feature_flags.md), disabled by default.

FLAG:
On self-managed GitLab, this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `create_runner_workflow_for_admin`.
On GitLab.com, this feature is available but can be configured by GitLab.com administrators only.

Prerequisites:

- You must be an administrator to register a shared runner.

To register a [shared runner](../runners/runners_scope.md#shared-runners):

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

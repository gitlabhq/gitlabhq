---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Security Configuration **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20711) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.

The Security Configuration page displays the configuration state of each security feature in the
current project. The page uses the project's latest default branch [CI pipeline](../../../ci/pipelines/index.md)
to determine each feature's configuration state. If a job with the expected security report artifact
exists in the pipeline, the feature is considered enabled.

You can only enable SAST from the Security Configuration page. Documentation links are included for
the other features. For details about configuring SAST, see [Configure SAST in the UI](../sast/index.md#configure-sast-in-the-ui).

NOTE: **Note:**
If the latest pipeline used [Auto DevOps](../../../topics/autodevops/index.md),
all security features are configured by default.

## View Security Configuration

To view a project's security configuration:

1. Go to the project's home page.
1. In the left sidebar, go to **Security & Configuration** > **Configuration**.

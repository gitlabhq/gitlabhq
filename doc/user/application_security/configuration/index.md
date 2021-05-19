---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Security Configuration **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20711) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6. **(ULTIMATE)**
> - SAST configuration was [enabled](https://gitlab.com/groups/gitlab-org/-/epics/3659) in 13.3 and [improved](https://gitlab.com/gitlab-org/gitlab/-/issues/232862) in 13.4. **(ULTIMATE)**
> - DAST Profiles feature was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40474) in 13.4. **(ULTIMATE)**
> - A simplified version was made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/294076) in GitLab 13.10.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

The Security Configuration page displays what security scans are available, links to documentation and also simple enablement tools for the current project.

To view a project's security configuration, go to the project's home page,
then in the left sidebar go to **Security & Compliance > Configuration**.

For each security control the page displays:

- **Security Control:** Name, description, and a documentation link.
- **Manage:** A management option or a documentation link.

## Status **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20711) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.

The status of each security control is determined by the project's latest default branch
[CI pipeline](../../../ci/pipelines/index.md).
If a job with the expected security report artifact exists in the pipeline, the feature's status is
_enabled_.

If the latest pipeline used [Auto DevOps](../../../topics/autodevops/index.md),
all security features are configured by default.

For SAST, click **View history** to see the `.gitlab-ci.yml` file's history.

## Manage **(ULTIMATE)**

You can configure the following security controls:

- Auto DevOps
  - Click **Enable Auto DevOps** to enable it for the current project. For more details, see [Auto DevOps](../../../topics/autodevops/index.md).
- SAST
  - Click either **Enable** or **Configure** to use SAST for the current project. For more details, see [Configure SAST in the UI](../sast/index.md#configure-sast-in-the-ui).
- DAST Profiles
  - Click **Manage** to manage the available DAST profiles used for on-demand scans. For more details, see [DAST on-demand scans](../dast/index.md#on-demand-scans).
- Secret Detection
  - Select **Configure via Merge Request** to create a merge request with the changes required to
    enable Secret Detection. For more details, see [Enable Secret Detection via an automatic merge request](../secret_detection/index.md#enable-secret-detection-via-an-automatic-merge-request).

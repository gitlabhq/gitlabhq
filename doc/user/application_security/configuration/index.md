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

## UI redesign

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326926) in 14.0 for GitLab Free and Premium, behind a feature flag, disabled by default.
> - Enabled on GitLab.com for Free & Premium.
> - Recommended for production use.
> - It can be enabled or disabled for a single project.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-ui-redesign). **(FREE SELF)**
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333109) in 14.1 for GitLab Ultimate, behind a feature flag, disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - It can be enabled or disabled for a single project.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-ui-redesign-for-ultimate). **(ULTIMATE SELF)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

The Security Configuration page has been redesigned in GitLab Free and Premium.
The same functionality exists as before, but presented in a more extensible
way.

For each security control the page displays:

- Its name, description and a documentation link.
- Whether or not it is available.
- A configuration button or a link to its configuration guide.

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
- Dependency Scanning
  - Select **Configure via Merge Request** to create a merge request with the changes required to
    enable Dependency Scanning. For more details, see [Enable Dependency Scanning via an automatic merge request](../dependency_scanning/index.md#enable-dependency-scanning-via-an-automatic-merge-request).

## Enable or disable UI redesign **(FREE SELF)**

The Security Configuration redesign is under development, but is ready for
production use. It is deployed behind a feature flag that is **disabled by
default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md) can enable it.

To enable it:

```ruby
# For the instance
Feature.enable(:security_configuration_redesign)
# For a single project
Feature.enable(:security_configuration_redesign, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:security_configuration_redesign)
# For a single project
Feature.disable(:security_configuration_redesign, Project.find(<project id>))
```

## Enable or disable UI redesign for Ultimate **(ULTIMATE SELF)**

The Security Configuration redesign is under development, and is not ready for
production use. It is deployed behind a feature flag that is **disabled by
default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md) can enable it.

To enable it:

```ruby
# For the instance
Feature.enable(:security_configuration_redesign_ee)
# For a single project
Feature.enable(:security_configuration_redesign_ee, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:security_configuration_redesign_ee)
# For a single project
Feature.disable(:security_configuration_redesign_ee, Project.find(<project id>))
```

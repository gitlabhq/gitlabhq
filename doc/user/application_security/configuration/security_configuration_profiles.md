---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Managing security configuration profiles
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19802) in GitLab 18.9.

{{< /history >}}

Security configuration profiles are centralized settings that define how and when security scanners run across your projects.
Use security configuration profiles to manage security scanners across your organization efficiently. A profile-based approach applies best practices with minimal manual setup.

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [Introducing security configuration profiles](https://www.youtube.com/watch?v=XYMKhhtRvwA).

When you apply a profile to a group, it is applied to each individual project within that group. Profiles are not attached to the group itself, and there is no inheritance between profiles or subgroups.

Use [default profiles](#default-profiles) to enable pre-configured security scanning within minutes and with minimal configuration.

## Configure security scanners

To assess and manage your profiles, use the [security inventory](../security_inventory/_index.md#view-the-security-inventory) for your group as your central dashboard.

### Review test coverage

To view a high-level status (**Enabled**, **Not Enabled**, or **Failed**) of scanners in the group like SAST, DAST, and secret detection:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. In the security inventory, review the **Test Coverage** column.

### Change individual project coverage

To configure a specific project:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Next to the project, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) and select **Manage tool coverage**.
1. Turn individual scanners on or off.

### Apply a profile to multiple projects

To save time, you can apply security settings to multiple projects at once:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Select multiple projects or an entire subgroup to apply the settings to.
1. Select the **Bulk Action** dropdown and choose **Manage security scanners**.
1. Choose **Apply default profile to all** to standardize your security posture across the selection.

## Default profiles

GitLab provides default profiles that are preconfigured scanner settings so you can enable security scanning with minimal configuration.

### Secret detection profile

When you apply the secret detection profile, you enable the recommended baseline protection for secrets across your entire development workflow. The profile activates the following scan triggers:

- **Push protection**: Scans all Git push events and blocks pushes where secrets are detected, preventing secrets from ever entering your codebase.
- **Merge Request Pipelines**: Automatically runs a scan each time new commits are pushed to a branch with an open merge request. Results are scoped to new vulnerabilities introduced by the merge request. Targets all branches.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete picture of your default branch's secret detection posture. Targets all branches.

### SAST profile

When you apply the SAST profile, you enable static application security testing across your projects using the recommended configuration. The profile activates the following scan triggers:

- **Merge Request Pipelines**: Automatically runs a SAST scan each time new commits are pushed to a branch with an open merge request. Results include only new vulnerabilities introduced by the merge request. Targets all branches.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete picture of your default branch's SAST posture. Targets the default branch.

### View details about a profile

To view technical details about the secret detection profile:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Select the **Secret Detection** profile.
1. Review the following information:
   - **Analyzer type**: The type of profile (for example, **Secret Detection**, **SAST**).
   - **Scan triggers**: The triggers that the profile supports (for example, **Push Protection**, **Merge Request Pipelines**, **Branch Pipelines**).
   - **Status**: Displays whether the profile is currently **Active** or **Disabled** for the current context using coverage status indicators.

## Coverage status indicators

The system uses visual cues in the inventory to indicate whether your projects are protected:

- **Solid green bar**: The scanner is fully enabled and active.
- **Gray/empty bar**: The scanner is not yet configured or enabled.
- **Partial bar**: Some protection is active (for example, some triggers available in the profile are enabled, but others are not).
- **Tooltips**: Hover over any coverage bar to see the **last scan** date for pipeline-based scans and specific pipeline status.

Unlike pipeline-based scans, push protection does not have a last scan date because it runs in real time during the push process.

## Troubleshooting

When working with security configuration profiles, you might encounter the following issues.

### No last scan date appears for push protection

Push protection is event-based, not schedule-based. It intercepts secrets in real time during the `git push` process. Because it is active at the moment of the `push` command, there is no last scan date like you would expect with pipeline-based scanners.

### Scanner status is active in the dashboard but not enabled in inventory tooltip

This can occur when a project uses legacy settings while also being assigned a new profile.

To resolve this issue:

1. Check the **Security Configuration** page for the most accurate current profile state.
1. If needed, remove legacy scanner configurations from your `.gitlab-ci.yml` file to rely solely on the profile-based configuration.

> [!note]
> The inventory tooltip is being refined to reflect the combined status of both legacy and profile-based settings.

### Understanding legacy versus profile-based configuration

If you're migrating from legacy scanner configuration to profile-based configuration, note the following differences:

- Legacy configuration: Requires manual edits to your YAML files or individual project settings to enable scanners.
- Profile-based configuration: Uses a centralized system where you can apply a default profile to multiple projects at once without modifying code.

Profile-based configuration is recommended for easier management and greater consistency across projects.

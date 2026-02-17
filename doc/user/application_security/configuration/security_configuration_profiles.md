---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

Profiles use inheritance.
Security attributes and coverage that you manage for a group can also apply to it's subgroups and projects, unless the coverage is changed for the individual subgroup or project. 

Use [default profiles](#default-profiles) to enable pre-configured security scanning within minutes and with minimal configuration.

## Configure security scanners

To assess and manage your profiles, use the [security inventory](../security_inventory/_index.md#view-the-security-inventory) for your group as your central dashboard.

### Review test coverage

To view a high-level status (**Enabled**, **Not Enabled**, or **Failed**) for scanners in the group like SAST, DAST, and secret detection:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Secure** > **Security inventory**.
1. In the security inventory, review the **Test Coverage** column. 

### Change individual project coverage

To configure a specific project:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Secure** > **Security inventory**.
1. Next to the project, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) and select **Manage tool coverage**.
1. Turn individual scanners on or off.

### Apply a profile to multiple projects

To save time, you can apply security settings to multiple projects at once:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Secure** > **Security inventory**.
1. Select multiple projects or an entire subgroup to apply the settings to. 
1. Select the **Bulk Action** dropdown and choose **Manage security scanners**.
1. Choose **Apply default profile to all** to standardize your security posture across the selection.

## Default profiles 

GitLab provides default profiles that are preconfigured scanner settings so you can enable security scanning with minimal configuration.

### Secret detection profile

When you apply the secret detection profile, a default profile, you enable the recommended baseline protection for secrets across your development workflow. Protection includes:

- Git push protection: Actively blocks secrets from being committed to your repositories in real-time during `git push`.

### Profile details

To view technical details about the secret detection profile:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Secure** > **Security inventory**.
1. Select the **Secret Detection** profile.
1. Review the following information:
   - **Analyzer Type**: The type of profile (for example, **Secret Detection**)
   - **Active Triggers**: The types of triggers that the profile supports (for example, **Git push events**).
   - **Status**: Displays whether the profile is currently **Active** or **Disabled** for the current context using coverage status indicators.

## Coverage status indicators

The system uses visual cues in the inventory to indicate whether your projects are protected:

- **Solid green bar**: The scanner is fully enabled and active.
- **Gray/empty bar**: The scanner is not yet configured or enabled.
- **Partial bar**: Some protection is active (for example, some scanners available in the profile are enabled, but others are not).
- **Tooltips**: Hover over any coverage bar to see the **last scan** date for pipeline-based scans and specific pipeline status.

> [!note]
> Unlike traditional scanners, Git push protection does not rely on a "last scan" date because it runs in real-time during the push process.

## Troubleshooting

When working with security configuration profiles, you might encounter the following issues.

### No last scan date appears for Git push protection

Git push protection is event-based, not schedule-based. It intercepts secrets in real-time during the `git push` process. Because it is active at the moment of the `push` command, there is no last scan date like you would expect with pipeline-based scanners.

### Scanner status is active in the dashboard but not enabled in inventory tooltip

This can occur when a project uses legacy settings while also being assigned a new profile.

To resolve this issue:

1. Check the Security Configuration page for the most accurate current profile state.
1. If needed, remove legacy scanner configurations from your `.gitlab-ci.yml` file to rely solely on the profile-based configuration.

> [!note]
> The inventory tooltip is being refined to reflect the combined status of both legacy and profile-based settings.

### Understanding legacy versus profile-based configuration

If you're migrating from legacy scanner configuration to profile-based configuration, note the following differences:

- Legacy configuration: Requires manual edits to your YAML files or individual project settings to enable scanners.
- Profile-based configuration: Uses a centralized system where you can apply a **Security Manager** or default profile to multiple projects at once without modifying code.

Profile-based configuration is recommended for easier management and greater consistency across projects.

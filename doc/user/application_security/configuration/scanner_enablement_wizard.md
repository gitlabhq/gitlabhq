---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Scanner Enablement Wizard
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21626) in GitLab 19.1 [with a feature flag](../../../administration/feature_flags/_index.md) named `group_security_configuration_scanners_tab`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Use the Scanner Enablement Wizard to apply [security configuration profiles](security_configuration_profiles.md)
to projects that lack scanner coverage. The wizard configures dependency scanning, SAST, and secret
detection, and updates the coverage shown in the [security inventory](../security_inventory/_index.md).

Prerequisites:

- To view scanner coverage, the Developer, Maintainer, or Owner role for the group.
- To enable scanners, the Security Manager, Maintainer, or Owner role for the group.

## View scanner coverage

The **Scanners** tab displays scanner coverage across all projects in a group.

To view scanner coverage:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Scanners** tab.

The tab displays the following cards:

| Card | Description |
|------|-------------|
| Unprotected projects | List of projects with no scanners enabled. |
| Scanners enabled | Count of all scanner types enabled in the group. |
| Needs attention | List of projects with scan failures. |
| Stale scans | List of projects with scans older than 90 days. |

Below the cards, a list of each scanner type indicates how many projects have the scanner active, failed, or not configured.

## View scanner details

To view the status of a scanner across the projects in the group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Scanners** tab.
1. Next to the scanner, select **View details**.

The scanner details page shows stat cards for the scanner (**Enabled**, **Not enabled**,
**Needs attention**, and **Stale**) and a table of every project in the group.

The table shows the following columns:

| Column | Description |
|--------|-------------|
| Project | Project name and path. |
| Source | If available, the name of the applied configuration profile. |
| Status | Current scanner status for the project. |
| Last scan | Time of the most recent scan. |
| Security attributes | Security attributes assigned to the project. Shown only if you can read security attributes. |

## Configure a scanner for projects

You can configure scanners that use profile-based configuration. To configure scanners from other sources, such
as security policies or CI/CD configuration, you must adjust them at their origin.

To configure a scanner for a project:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Scanners** tab.
1. Next to the scanner, select **View details**.
1. Next to a project select the vertical ellipsis ({{< icon name="ellipsis_v" >}}), then select an action:

   - **Enable profile-based scanning**: Applies the default profile to the project. Available when the
     project shows **No profile applied**.
   - **Disable profile-based scanning**: Removes the applied profile from the project.
   - **View project configuration**: Opens the security configuration page for the project.
   - **Troubleshoot failure**: Provides more details if the most recent scan failed or has a warning.

## Use the Scanner Enablement Wizard

The Scanner Enablement Wizard provides two approaches:

- **Quick setup**: Applies the GitLab default profiles to every uncovered project in the group.
- **Advanced setup**: Applies selected profiles to specific projects and scanners.

> [!note]
> The wizard does not configure DAST, container scanning, or IaC scanning. Configure these scanners
> through security policies or at the project level.

### Quick setup

Quick setup applies the GitLab default profiles to every uncovered project in the group.

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Scanners** tab.
1. Select **Enable scanners**.
1. Select **Quick setup**, then select **Start quick setup**.
1. On the **Review configuration** step, review the scanners and the projects they apply to.
1. Select **Apply configuration**.

After you apply a configuration, GitLab applies the profiles to projects in batches, which can take several
minutes. The confirmation step lists each scanner, its profile, and the number of items each profile
applies to.

### Advanced setup

Advanced setup applies only the selected profiles to specific projects and scanners. If you need to apply profiles
to more than 100 projects at once, use Quick setup.

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Scanners** tab.
1. Select **Enable scanners**.
1. Select **Advanced setup**, then select **Start advanced setup**.
1. On the **Select projects** step, select the projects to configure. Use the search and filters to find
   projects. The **Scanner coverage** column shows existing coverage. You can select up to 100 items.
1. On the **Select scanners** step, select the scanners to enable. For each scanner, select the
   configuration profile to apply.
1. On the **Review configuration** step, review the selected projects and scanners. To make changes,
   select the edit icon ({{< icon name="pencil" >}}) next to **Items** or **Scanners**.
1. Select **Apply configuration**.

After you apply a configuration, GitLab applies the profiles to projects in batches, which can take several
minutes. The confirmation step lists each scanner, its profile, and the number of items each profile
applies to.

## Related topics

- [Security configuration profiles](security_configuration_profiles.md)
- [Security inventory](../security_inventory/_index.md)
- [Security attributes](../attributes/_index.md)
- [Permissions and roles](../../permissions.md)

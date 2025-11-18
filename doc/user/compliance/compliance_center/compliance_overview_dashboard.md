---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance overview dashboard
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13909) in GitLab 18.2 with a flag named `compliance_group_dashboard`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/555804) in GitLab 18.3. Feature flag `compliance_group_dashboard` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

The compliance overview dashboard provides visual insights into your group's compliance posture through interactive
charts and metrics. It helps you quickly identify areas that need attention and track your overall compliance status.

The compliance overview dashboard displays four key areas of compliance monitoring:

- Compliance framework coverage.
- Failed requirements status.
- Failed controls status.
- Compliance frameworks that need attention.

## View the compliance overview dashboard

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance overview dashboard:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Compliance center**.
1. Select **Overview** to view the compliance dashboard.

## Compliance framework coverage

The framework coverage section provides an overview of how many projects in your group have compliance frameworks
assigned.

The framework coverage section displays:

- **Total projects**: The total number of projects in your group.
- **Covered projects**: Number of projects with at least one compliance framework assigned.
- **Coverage percentage**: Visual representation of framework coverage across your projects.

Below the summary metrics, you can see individual framework coverage including:

- Framework name with visual badge.
- Number of projects using each framework.
- Percentage of total projects covered by each framework.

## Failed requirements chart

The failed requirements chart visualizes the compliance status of requirements across your frameworks.

The failed requirements chart displays three categories:

- **Passed**: Requirements that are fully compliant (shown in blue).
- **Pending**: Requirements under review (shown in orange).
- **Failed**: Requirements not meeting compliance standards (shown in magenta).

## Failed controls chart

The failed controls chart provides a visual representation of control compliance status across your organization.

The failed controls chart displays three categories:

- **Passed**: Controls that meet compliance requirements (shown in blue).
- **Pending**: Controls awaiting evaluation (shown in orange).
- **Failed**: Controls that don't meet compliance requirements (shown in magenta).

## Frameworks table

The frameworks table highlights compliance frameworks that require immediate attention. This view helps you identify
frameworks with configuration issues or missing components.

The frameworks table displays:

- **Framework name**: The compliance framework with a visual badge.
- **Projects**: Number of projects using this framework (highlighted in red if zero).
- **Requirements**: Total number of requirements in the framework (highlighted in red if zero).
- **Requirements without controls**: Lists specific requirements that don't have associated controls.
- **Policies**: Security policies linked to the framework, including:
  - Scan execution policies.
  - Vulnerability management policies.
  - Scan result policies.
  - Pipeline execution policies.
- **Actions**: Edit framework button (visible to users with admin permissions).

---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security inventory
description: Group-level visibility of assets, scanner coverage, and vulnerabilities.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16484) in GitLab 18.2 with a flag named `security_inventory_dashboard`. Enabled by default. This feature is in [beta](../../../policy/development_stages_support.md)

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Use the security inventory to visualize which assets you need to secure and understand the actions you need to take to improve security. A common phrase in security is, "you can't secure what you can't see." The security inventory provides visibility into the security posture of your organization's top-level groups, helps you identify coverage gaps, and enables you to make efficient, risk-based prioritization decisions.

The security inventory shows:

- Your groups, subgroups, and projects.
- Security scanner coverage for each project, regardless of how the scanner is enabled. Security scanners include:
  - Static application security testing (SAST)
  - Dependency scanning
  - Container scanning
  - Secret detection
  - Dynamic application security testing (DAST)
  - Infrastructure-as-code (IaC) scanning
- The number of vulnerabilities in each group or project, sorted by severity level.

This feature is in beta. Track the development of the security inventory in [epic 16484](https://gitlab.com/groups/gitlab-org/-/epics/16484). Share [your feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/553062) with us as we continue to develop this feature. The security inventory is enabled by default.

## View the security inventory

Prerequisites:

- You must have at least the Developer role in the group to view the security inventory.

To view the security inventory:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure** > **Security inventory**.
1. Complete one of the following actions:
   - To view a group's subgroups, projects, and security assets, select the group.
   - To view a group or project's scanner coverage, search for the group or project.

## Filter projects in the security inventory

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/552224) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `security_inventory_filtering`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

You can filter projects in the security inventory to focus on specific areas of interest.
The following filters are available:

- **Vulnerability count**: Filter projects based on the number of identified vulnerabilities. For example, show projects with `critical vulnerabilities ≥ 10`.
- **Tool coverage**: Filter projects by the status of security analyzers (like **enabled**, **not enabled**, or **failed**). For example, show projects where `Advanced SAST = enabled`.
- **Project name**: Search for specific projects by name.

These filters help you narrow down results in large inventories and make it easier to identify projects that require immediate attention.

## Related topics

- [Security dashboard](../security_dashboard/_index.md)
- [Vulnerability reports](../vulnerability_report/_index.md)
- GraphQL references:
  - [AnalyzerGroupStatusType](../../../api/graphql/reference/_index.md#analyzergroupstatustype) - Counts for each analyzer status in the group and subgroups.
  - [AnalyzerProjectStatusType](../../../api/graphql/reference/_index.md#analyzerprojectstatustype) - Analyzer status (success/fail) for projects.
  - [VulnerabilityNamespaceStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitynamespacestatistictype) - Counts for each vulnerability severity in the group and its subgroups.
  - [VulnerabilityStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitystatistictype) - Counts for each vulnerability severity in the project.

## Troubleshooting

When working with the security inventory, you might encounter the following issues:

### Security inventory menu item missing

Some users do not have the required permissions to access the **Security inventory** menu item. The menu item only displays for groups when the authenticated user has at least the Developer role.

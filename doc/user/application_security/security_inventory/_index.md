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

The security inventory provides an overview of your organization's security posture.
It shows:

- Your groups, subgroups, and projects.
- Which security scanners are enabled in each project, including:
  - Static application security testing (SAST)
  - Dependency scanning
  - Container scanning
  - Secret detection
  - Dynamic application security testing (DAST)
  - Infrastructure-as-code (IaC) scanning
- The number of vulnerabilities in each group or project, sorted by security level.

Use the security inventory to visualize your assets, understand coverage gaps, and triage risks to your organization.

This feature is in beta. Track the development of the security inventory in [epic 16484](https://gitlab.com/groups/gitlab-org/-/epics/16484).

## Getting started

The security inventory is enabled by default.

Prerequisites:

- You must have at least the Developer role.

To view the security inventory:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Security inventory**.
1. Select a group to view its subgroups, projects, and security assets.

## Related topics

- [Security Dashboard](../security_dashboard/_index.md)
- [Vulnerability reports](../vulnerability_report/_index.md)

## Troubleshooting

When working with the security inventory, you might encounter the following issues.

### Inaccurate scanner coverage

Due to a known issue, scanner configuration data is still being backfilled.
As a result, the displayed container scanning and secret detection coverage might not be entirely accurate.
A fix for this issue is proposed in [issue 548281](https://gitlab.com/gitlab-org/gitlab/-/issues/548281).

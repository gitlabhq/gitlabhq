---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security attributes
description: Security attributes allows security teams to apply custom metadata labels to projects and groups, enabling them to filter and prioritize security risks based on business context.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/18010) in GitLab 18.5 with flags named `security_context_labels` and `security_categories_and_attributes`. Disabled by default. This feature is in [beta](../../../policy/development_stages_support.md)

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by feature flags.
For more information, see the history.

{{< /alert >}}

Security teams can now apply metadata specific their own organization and business needs to projects using security attributes.

Security attributes are organized by categories based on:

- Business impact
- Application
- Business unit,
- Internet exposure
- Location

By applying these attributes across your projects, you can much more quickly identify which projects require action based on your own organizations risk posture and business needs. With security attributes, you can:

- Identify projects that are mission critical and require stronger scan coverage.
- Review scan coverage for each application or business unit.
- Locate projects that contribute to publicly accessible and exposed applications.

This feature is in beta. Track the development of security attributes in [epic 18010](https://gitlab.com/groups/gitlab-org/-/epics/18010). Share [your feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/553062) with us as we continue to develop this feature. The security attributes feature is disabled by default.

## Manage security attributes for groups

Prerequisites:

- You must have at least the Maintainer role in the group to manage security attributes.

To manage security attributes for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure** > **Security configuration**.

## Manage security attributes for projects

Prerequisites:

- You must have at least the Maintainer role in the project to manage security attributes.

To manage security attributes for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.

## Related topics

- [Security inventory](../security_inventory/_index.md)
- [Security dashboard](../security_dashboard/_index.md)
- [Vulnerability reports](../vulnerability_report/_index.md)

## Troubleshooting

When working with the security attributes, you might encounter the following issues.

### Security configuration menu item missing

Some users do not have the required permissions to access the **Security configuration** menu item. The menu item only displays for groups when the authenticated user has the Maintainer role or higher.

To manage security attributes, ask a maintainer to complete the configuration changes or request the Maintainer role from your administrator, if necessary.

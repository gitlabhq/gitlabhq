---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security center
description: Configurable space to view vulnerabilities across multiple projects.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The security center is a configurable personal space with vulnerabilities data from multiple projects.
You can add up to 1,000 projects to the security center from any of the projects that you belong to.

{{< alert type="note" >}}

The **Project** list in the security center settings page displays a maximum of 100 projects.
To find projects that are not shown in the first 100 projects, use the search filter.

{{< /alert >}}

The security center displays:

- A security dashboard for the projects you've added.
- A [vulnerability report](../vulnerability_report/_index.md) for the projects you've added.
- A settings area to add or remove projects.

## View the security center

To view the security center:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Your work**.
1. Select **Security** > **Security dashboard**.

The security center is empty by default. You must add one or more projects that have been configured with at least one security scanner.

## Add projects to the security center

To add projects:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Your work**.
1. Expand **Security**.
1. Select **Settings**.
1. Use the **Search your projects** text box to search for and select projects.
1. Select **Add projects**.

After you add projects, the security dashboard and vulnerability report show the vulnerabilities found in those projects' default branches.

## Remove projects from the security center

The security center displays a maximum of 100 projects, so you might need to use the search function to remove a project. To remove projects:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Your work**.
1. Expand **Security**.
1. Select **Settings**.
1. Use the **Search your projects** text box to search for the project.
1. Select **Remove project from dashboard** ({{< icon name="remove" >}}).

After you remove projects, the security dashboard and vulnerability report no longer show the vulnerabilities found in those projects' default branches.

## Exporting

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/546219) in GitLab 18.2 [with a flag](../../../administration/feature_flags/_index.md) named `vulnerabilities_pdf_export`. Enabled by default.
- Generally available in 18.5. Feature flag `vulnerabilities_pdf_export` removed.

{{< /history >}}

You can export a PDF file that includes details of the vulnerabilities listed in the security dashboard.

Charts in the export include:

- Vulnerabilities over time
- Project security status
- Project's security dashboard

### Export details

To export the details of all vulnerabilities listed in the security dashboard, select **Export**.

When the exported details are available, GitLab sends you an email. To download the exported details, select the link in the email.

## Related topics

- [Security dashboard](../security_dashboard/_index.md)
- [Vulnerability reports](../vulnerability_report/_index.md)
- [Vulnerability page](../vulnerabilities/_index.md)

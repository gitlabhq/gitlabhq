---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance frameworks report
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422973) in GitLab 16.5 [with a flag](../../../administration/feature_flags.md) named `compliance_framework_report_ui`. Disabled by default.
- In GitLab 16.4 and earlier, **Compliance frameworks report** referred to what is now called **Compliance projects report**. The formally-named **Compliance frameworks report** was [renamed to **Compliance projects report**](https://gitlab.com/gitlab-org/gitlab/-/issues/422963) in GitLab 16.5.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140825) in GitLab 16.8.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/425242) in GitLab 16.10. Feature flag `compliance_framework_report_ui` removed.

{{< /history >}}

With the compliance frameworks report, you can see all the compliance frameworks in a group. Each row of the report shows:

- Framework name.
- Associated projects.

The default framework for the group has a **default** badge.

## View the compliance frameworks report

To view the compliance frameworks report:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.

## Create a new compliance framework

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To create a new compliance framework from the compliance frameworks report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Select the **New framework**.
1. Select **Create blank framework**.
1. Select the **Add framework** to create compliance framework.

## Edit a compliance framework

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To edit a compliance framework from the compliance frameworks report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Hover over framework and select **Edit the framework**.
1. Select the **Save changes** to edit compliance framework.

## Delete a compliance framework

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To delete a compliance framework from the compliance frameworks report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Hover over framework and select **Edit the framework**.
1. Select the **Delete framework** to delete compliance framework.

## Set and remove a compliance framework as default

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181500) in GitLab 17.10.

{{< /history >}}

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To set a compliance framework as [default](../compliance_frameworks.md#default-compliance-frameworks)] from the compliance frameworks report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Next to the compliance framework you want to set as default, select {{< icon name="pencil" >}} action.
1. Select the **Set as default** to set as default.

To remove a compliance framework as default from the compliance frameworks report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
1. Next to the compliance framework that is default, select {{< icon name="pencil" >}} action.
1. Select the **Remove as default** to remove as default.

## Export a report of compliance frameworks in a group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413736) in GitLab 16.11 [with a flag](../../../administration/feature_flags.md) named `compliance_frameworks_report_csv_export`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152644) in GitLab 17.1. Feature flag `compliance_frameworks_report_csv_export` removed.

{{< /history >}}

Exports the contents of a compliance frameworks report in a group. Reports are truncated at 15 MB to avoid a large email attachment.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export the standards adherence report for projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export framework report**.

A report is compiled and delivered to your email inbox as an attachment.

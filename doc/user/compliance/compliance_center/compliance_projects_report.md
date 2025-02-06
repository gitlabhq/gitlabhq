---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance projects report
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387910) in GitLab 15.10.
> - [Renamed from **compliance frameworks report**](https://gitlab.com/gitlab-org/gitlab/-/issues/422963) in GitLab 16.5.

With the compliance projects report, you can see the compliance frameworks that are applied to projects in a group or subgroup.
Each row of the report shows:

- Project name.
- Project path.
- Compliance framework labels if the project has one or more assigned.

The default framework for the group has a **default** badge.

## View the compliance projects report

Prerequisites:

- You must be an administrator or have the Owner role for the project or group.

To view the compliance projects report:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.

## Apply a compliance framework to projects in a group

> - Adding compliance frameworks using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383209) in GitLab 15.11.
> - Adding compliance frameworks without using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394795) in GitLab 16.0.
> - Ability to add compliance frameworks to subgroups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469004) in GitLab 17.2.

You can apply one or more compliance frameworks to projects in a group or subgroup.

Prerequisites:

- You must have the Owner role for the group.

To apply a compliance framework to one project in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Next to the project you want to add the compliance framework to, select **{pencil}** action.
1. Select one or more existing compliance frameworks or create a new one.

To apply a compliance framework to multiple projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Select multiple projects.
1. From the **Choose one bulk action** dropdown list, select **Apply framework to selected projects**.
1. Select framework to apply.
1. Select **Apply**.

## Remove a compliance framework from projects in a group

> - Removing compliance frameworks using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383209) in GitLab 15.11.
> - Removing compliance frameworks without using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394795) in GitLab 16.0.
> - Ability to remove compliance frameworks from subgroups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469004) in GitLab 17.2.

You can remove a compliance framework from projects in a group or subgroup.

Prerequisites:

- You must have the Owner role for the group.

To remove a compliance framework from one project in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Next to the compliance framework to remove from the project, select **{close}** on the framework label.

To remove a compliance framework from multiple projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Select multiple projects.
1. From the **Choose one bulk action** dropdown list, select **Remove framework from selected projects**.
1. Select **Remove**.

## Export a report of compliance frameworks on projects in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387912) in GitLab 16.0.

Export a report of compliance frameworks that are applied to projects in a group. Reports:

- Do not use filters on the framework report.
- Are truncated at 15 MB so the email attachment too large.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export a report of compliance frameworks on projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export list of project frameworks**.

A report is compiled and delivered to your email inbox as an attachment.

## Filter the compliance projects report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387911) in GitLab 15.11.

To filter the list of compliance frameworks:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. In the search field:
   1. Select the attribute you want to filter by.
   1. Select an operator.
   1. Select from the list of options or enter text for the search.
1. Select **Search**.

Repeat this process to filter by multiple attributes.

## Create a new compliance framework

You can create new compliance frameworks on top-level groups.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To create a new compliance framework from the compliance projects report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Select the **+ Add framework**.
1. Select the **Create a new framework**.
1. Select the **Add framework** to create compliance framework.

## Edit a compliance framework

You can edit compliance frameworks on top-level groups.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To edit a compliance framework from the compliance projects report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Hover over framework and select **Edit the framework**.
1. Select the **Save changes** to edit compliance framework.

## Delete a compliance framework

You can delete compliance frameworks from top-level groups.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To delete a compliance framework from the compliance projects report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Hover over framework and select **Edit the framework**.
1. Select the **Delete framework** to delete compliance framework.

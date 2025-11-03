---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import your project from FogBugz to GitLab
description: "Import projects from FogBugz to GitLab."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.

{{< /history >}}

Using the importer, you can import your FogBugz project to GitLab.com
or to GitLab Self-Managed.

The importer imports all of your cases and comments with the original
case numbers and timestamps. You can also map FogBugz users to GitLab
users.

## Prerequisites

{{< history >}}

- Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

{{< /history >}}

- [FogBugz import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The FogBugz import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.

## Import project from FogBugz

To import your project from FogBugz:

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Import project**.
1. Select **FogBugz**.
1. Enter your FogBugz URL, email address, and password.
1. Create a mapping from FogBugz users to GitLab users. For each FogBugz user:
   - To map a FogBugz account to a full name, without mapping it to a GitLab account, leave the **GitLab User**
     text box empty. This mapping adds the user's full name to the description of all issues and comments, but
     assigns the issues and comments to the project creator.
   - To map a FogBugz account to a GitLab account, in **GitLab User**, select the GitLab user
     you want to associate issues and comments with.
1. When all users are mapped, select **Continue to the next step**.
1. For each project you want to import, select **Import**.
1. After the import finishes, select the link to go to the project
   dashboard. Follow the directions to push your existing repository.
1. To import a project:
   - For the first time: Select **Import**.
   - Again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.

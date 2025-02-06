---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import your project from FogBugz to GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.

Using the importer, you can import your FogBugz project to GitLab.com
or to GitLab Self-Managed.

The importer imports all of your cases and comments with the original
case numbers and timestamps. You can also map FogBugz users to GitLab
users.

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- [FogBugz import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The FogBugz import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.

## Import project from FogBugz

To import your project from FogBugz:

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Import project**.
1. Select **FogBugz**.
1. Enter your FogBugz URL, email address, and password.
1. Create a mapping from FogBugz users to GitLab users.
   ![User Map](img/fogbugz_import_user_map_v8.png)
1. For the projects you want to import, select **Import**.
   ![Import Project](img/fogbugz_import_select_project_v8.png)
1. After the import finishes, select the link to go to the project
   dashboard. Follow the directions to push your existing repository.
1. To import a project:
   - For the first time: Select **Import**.
   - Again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.

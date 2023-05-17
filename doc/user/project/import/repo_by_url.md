---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import project from repository by URL **(FREE)**

You can import your existing repositories by providing the Git URL.

## Prerequisites

> Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- [Repository by URL import source](../../admin_area/settings/visibility_and_access_controls.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Repository by URL import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.

## Import project by URL

1. In GitLab, on the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select the **Import project** tab.
1. Select **Repository by URL**.
1. Enter a **Git repository URL**.
1. Complete the remaining fields.
1. Select **Create project**.

Your newly created project is displayed.

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](index.md#automate-group-and-project-import).

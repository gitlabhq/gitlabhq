---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Control GitLab Duo context exclusion
---

## Exclude context from GitLab Duo

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17124) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `use_duo_context_exclusion`. Disabled by default.

{{< /history >}}

You can control which project content is included as context for GitLab Duo. Use this to protect sensitive information such as password files and configuration files.

### Manage GitLab Duo context exclusions

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **GitLab Duo**, in the **GitLab Duo Content Exclusions section**, select **Manage exclusions**.
1. Specify which project files and directories are excluded from GitLab Duo context, and select **Save exclusions**.
1. Optional. To delete an existing exclusion, select **Delete** ({{< icon name="remove" >}}) for the appropriate exclusion.
1. Select **Save changes**.

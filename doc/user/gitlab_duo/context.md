---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo (Classic) contextual awareness
---

Different information is available to help GitLab Duo Chat (Classic) make decisions and offer suggestions.

Information can be available:

- Always.
- Based on your location (the context changes when you navigate).
- When referenced explicitly. For example, you mention the information by URL, ID, or file path.

## Always available

- GitLab documentation.
- General programming knowledge, best practices, and language specifics.
- Content in the file you're viewing or editing, including code before and after your cursor.
- When using Chat in the GitLab UI, the current page title and URL.
- The `/refactor`, `/fix`, `/tests`, and `/explain` slash commands have access to the latest
  Repository X-Ray report from [Code Suggestions](../duo_agent_platform/code_suggestions/repository_xray.md)
  or [Code Suggestions (Classic)](../project/repository/code_suggestions/repository_xray.md).

## Based on location

When you have any of these resources open, GitLab Duo knows about them.

- Files you've told Chat about, by either:
  - Providing a direct file path.
  - In your IDE, including with the `/include` command.
- Code selected in a file.
- Issues (GitLab Duo Enterprise only).
- Epics (GitLab Duo Enterprise only).
- [Other work item types](../work_items/_index.md#work-item-types) (GitLab Duo Enterprise only).

> [!note]
> In the IDEs, secrets and sensitive values that match known formats are redacted before
> they are sent to GitLab Duo Chat.

In the UI, when you're in a merge request, GitLab Duo also knows about:

- The merge request itself (GitLab Duo Enterprise only).
- Commits in the merge request (GitLab Duo Enterprise only).
- The merge request pipeline's CI/CD jobs (GitLab Duo Enterprise only).

### When referenced explicitly

All of the resources that are available based on your location
are also available when you refer to them explicitly by their ID or URL.

## Exclude context from Code Review (Classic)

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Pro or Enterprise

{{< /details >}}
{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17124) in GitLab 18.2 [with a flag](../../administration/feature_flags/_index.md) named `use_duo_context_exclusion`. Disabled by default.
- Changed to beta in GitLab 18.4.
- Enabled by default in GitLab 18.5.

{{< /history >}}

You can exclude the project content used as context by Code Review (Classic).
Exclude context to protect sensitive information, like password and configuration files.

To specify content that Code Review (Classic) excludes:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Under **GitLab Duo**, in the **GitLab Duo context exclusions** section, select **Manage exclusions**.
1. Specify which project files and directories are excluded from GitLab Duo context, and select **Save exclusions**.
1. Optional. To delete an existing exclusion, select **Delete** ({{< icon name="remove" >}}) for the appropriate exclusion.
1. Select **Save changes**.

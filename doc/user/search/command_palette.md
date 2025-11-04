---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Command palette
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 16.2 [with a flag](../../administration/feature_flags/_index.md) named `command_palette`. Enabled by default.
- Feature flag `command_palette` removed in GitLab 16.4.

{{< /history >}}

You can use command palette to narrow down the scope of your search or to
find an object more quickly.

## Open the command palette

To open the command palette:

1. On the left sidebar, select **Search or go to** or use the <kbd>/</kbd> key to enable. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Type one of the special characters:

   - <kbd>></kbd> - Create a new object or find a menu item.
   - <kbd>@</kbd> - Search for a user.
   - <kbd>:</kbd> - Search for a project.
   - <kbd>~</kbd> - Search for project files in the default repository branch.

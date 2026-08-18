---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Emoji reactions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you're collaborating online, you get fewer opportunities for high-fives
and thumbs-ups. React with emoji on:

- [Issues](project/issues/_index.md).
- [Tasks](tasks.md).
- [Merge requests](project/merge_requests/_index.md) and [snippets](snippets.md).
- [Epics](group/epics/_index.md).
- [Objectives and key results](okrs.md).
- [Wiki pages](project/wiki/_index.md).
- Anywhere else you can have a comment thread.

![Emoji reaction picker with various categories, including search box.](img/award_emoji_select_v14_6.png)

Emoji reactions make it much easier to give and receive feedback without a long
comment thread.

"Thumbs up" and "thumbs down" emoji are used to calculate an issue or merge request's position when
[sorting by popularity](project/issues/sorting_issue_lists.md#sorting-by-popularity).

For more information, see the [emoji reactions API](../api/emoji_reactions.md).

## Emoji reactions for comments

Emoji reactions can also be applied to individual comments when you want to
celebrate an accomplishment or agree with an opinion.

To add an emoji reaction:

1. In the upper-right corner of the comment, select the smile ({{< icon name="slight-smile" >}}).
1. Select an emoji from the emoji picker.

To remove an emoji reaction, select the emoji again.

## Custom emoji

Custom emoji show in the emoji picker everywhere you can react with emoji.

To add an emoji reaction to a comment or description:

1. Select **Add reaction** ({{< icon name="slight-smile" >}}).
1. Select the GitLab logo ({{< icon name="tanuki" >}}) or scroll down to the **Custom** section.
1. Select an emoji from the emoji picker.

![Custom emoji section in the reaction picker.](img/custom_emoji_reactions_v16_2.png)

To use them in a text box, type the filename between two colons.
For example, `:thank-you:`.

### Upload custom emoji to a group

Upload your custom emoji to a group to use them in all its subgroups and projects.

Prerequisites:

- You must at least have the developer role for the group.

To upload custom emoji:

1. On a description or a comment, select **Add reaction** ({{< icon name="slight-smile" >}}).
1. At the bottom of the emoji picker, select **Create new emoji**.
1. Enter a name and URL for the custom emoji.
1. Select **Save**.

You can also upload custom emoji to a GitLab instance with the GraphQL API.
For more information, see [use custom emoji with GraphQL](../api/graphql/custom_emoji.md).

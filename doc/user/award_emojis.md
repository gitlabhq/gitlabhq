---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Emoji reactions **(FREE)**

> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/409884) from "award emojis" to "emoji reactions" in GitLab 16.0.
> - Reacting with emojis on work items (such as tasks, objectives, and key results) [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393599) in GitLab 16.0.

When you're collaborating online, you get fewer opportunities for high-fives
and thumbs-ups. React with emojis on:

- [Issues](project/issues/index.md).
- [Tasks](tasks.md).
- [Merge requests](project/merge_requests/index.md),
[snippets](snippets.md).
- [Epics](../user/group/epics/index.md).
- [Objectives and key results](okrs.md).
- Anywhere else you can have a comment thread.

![Emoji reactions](img/award_emoji_select_v14_6.png)

Emoji reactions make it much easier to give and receive feedback without a long
comment thread.

For information on the relevant API, see [Emoji reactions API](../api/award_emoji.md).

## Sort issues and merge requests on vote count

You can quickly sort issues and merge requests by the number of votes ("thumbs up" and "thumbs down" emoji) they
have received. The sort options can be found in the dropdown list as "Most
popular" and "Least popular".

![Votes sort options](img/award_emoji_votes_sort_options.png)

The total number of votes is not summed up. An issue with 18 upvotes and 5
downvotes is considered more popular than an issue with 17 upvotes and no
downvotes.

## Emoji reactions for comments

Emoji reactions can also be applied to individual comments when you want to
celebrate an accomplishment or agree with an opinion.

To add an emoji reaction:

1. In the upper-right corner of the comment, select the smile (**{slight-smile}**).
1. Select an emoji from the emoji picker.

To remove an emoji reaction, select the emoji again.

## Custom emojis

You can upload custom emojis to a GitLab instance with the GraphQL API.
For more information, see [Use custom emojis with GraphQL](../api/graphql/custom_emoji.md).

Custom emojis don't show in the emoji picker.
To use them in a text box, type the filename without the extension and surrounded by colons.
For example, for a file named `thank-you.png`, type `:thank-you:`.

For a list of custom emojis available for GitLab.com, see
[the `custom_emoji` project](https://gitlab.com/custom_emoji/custom_emoji/-/tree/main/img).

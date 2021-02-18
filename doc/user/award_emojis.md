---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Award emoji **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1825) in GitLab 8.2.
> - GitLab 9.0 [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9570) the usage of native emoji if the platform
>   supports them and falls back to images or CSS sprites. This change greatly
>   improved award emoji performance overall.

When you're collaborating online, you get fewer opportunities for high-fives
and thumbs-ups. Emoji can be awarded to [issues](project/issues/index.md), [merge requests](project/merge_requests/index.md),
[snippets](snippets.md), and anywhere you can have a thread.

![Award emoji](img/award_emoji_select.png)

Award emoji make it much easier to give and receive feedback without a long
comment thread.

For information on the relevant API, see [Award Emoji API](../api/award_emoji.md).

## Sort issues and merge requests on vote count

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/2781) in GitLab 8.5.

You can quickly sort issues and merge requests by the number of votes they
have received. The sort options can be found in the dropdown menu as "Most
popular" and "Least popular".

![Votes sort options](img/award_emoji_votes_sort_options.png)

The total number of votes is not summed up. An issue with 18 upvotes and 5
downvotes is considered more popular than an issue with 17 upvotes and no
downvotes.

## Award emoji for comments

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/4291) in GitLab 8.9.

Award emoji can also be applied to individual comments when you want to
celebrate an accomplishment or agree with an opinion.

To:

- Add an award emoji, click the smile in the top right of the comment and pick an emoji from the dropdown.
- Remove an award emoji, click the emoji again.

![Picking an emoji for a comment](img/award_emoji_comment_picker.png)

![An award emoji has been applied to a comment](img/award_emoji_comment_awarded.png)

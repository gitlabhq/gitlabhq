---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Moderate users

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/155) in GitLab 15.8.

This is the group-level documentation. For self-managed instances, see the [administration documentation](../../administration/moderate_users.md).

A group Owner can moderate user access by banning and unbanning users.
You should ban a user when you want to block them from the group.

A banned user:

- Cannot access the group or any of repositories.
- Cannot use [slash commands](../project/integrations/gitlab_slack_application.md#slash-commands).
- Does not occupy a [seat](../free_user_limit.md).

## Unban a user

To unban a user with the GraphQL API, see [`Mutation.namespaceBanDestroy`](../../api/graphql/reference/index.md#mutationnamespacebandestroy).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo on unbanning a user at the group level, see [Namespace level ban - Unbanning a user](https://www.youtube.com/watch?v=mTQVbP3MQrs).

Prerequisites:

- In the top-level group, you must have the Owner role.

To unban a user:

1. Go to the top-level group.
1. On the left sidebar, select **Manage > Members**.
1. Select the **Banned** tab.
1. For the account you want to unban, select **Unban**.

## Ban a user

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo on banning a user at the group level, see [Namespace level ban - Banning a user](https://youtu.be/1rbi1uEJmOI).

Prerequisites:

- In the top-level group, you must have the Owner role.
- In the top-level group, if the user you want to ban has the Owner role, you must [demote the user](manage.md#change-the-owner-of-a-group).

To manually ban a user:

1. Go to the top-level group.
1. On the left sidebar, select **Manage > Members**.
1. Next to the member you want to ban, select the vertical ellipsis (**{ellipsis_v}**).
1. From the dropdown list, select **Ban member**.

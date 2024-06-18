---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Moderate users

This section describes how to moderate users at the group level. For self-managed instances, see the [administration documentation](../../administration/moderate_users.md).

If you have the Owner role for the group, to moderate user access you can [approve](manage.md#user-cap-for-groups), ban, or automatically remove dormant members.

## Ban and unban users

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/155) in GitLab 15.8 [with a flag](../../administration/feature_flags.md) named `limit_unique_project_downloads_per_namespace_user`. Disabled by default.

A group Owner can moderate user access by banning and unbanning users.
You should ban a user when you want to block them from the group.

A banned user:

- Cannot access the group or any of repositories.
- Cannot use [slash commands](../project/integrations/gitlab_slack_application.md#slash-commands).
- Does not occupy a [seat](../free_user_limit.md).

### Unban a user

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

### Ban a user

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

## Automatically remove dormant members

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461339) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `group_remove_dormant_members`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Prerequisites:

- You must have the Owner role for the group.

You can enable automatic removal of group members who either:

- Were added to the group more than a week ago and have no activity in the group.
- Have no activity in the group for a specified period of time. The default and minimum is 90 days. Activities involve:
  - Git HTTP/SSH activities, such as `clone` and `push`.
  - Visiting pages related to dashboards, projects, issues, merge requests, settings, and so on.
  - Using the API in the scope of the group.
  - Using the GraphQL API in the scope of the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. Scroll to **Dormant members**.
1. Select the **Remove dormant members after a period of inactivity** checkbox.
1. In the **Days of inactivity before removal** field, enter the number of days before removal. The minimum is 90 days.
1. Select **Save changes**.

After the member has reached the days of inactivity and is removed from the group:

- They still have access to GitLab.com.
- They do not have access to the group.
- Contributions made to the group are still assigned to the removed member.

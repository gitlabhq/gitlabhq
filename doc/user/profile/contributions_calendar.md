---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Contributions calendar
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The contributions calendar displays a [user's events](#user-contribution-events) from the past 12 months.
This includes contributions made in forked and [private](#show-private-contributions-on-your-user-profile-page) repositories.

![Contributions calendar](img/contributions_calendar_v15_6.png)

The gradient color of the tiles represents the number of contributions made per day. The gradient ranges from blank (0 contributions) to dark blue (more than 30 contributions).

NOTE:
The contribution calendar only displays contributions from the last 12 months, but issue [24264](https://gitlab.com/gitlab-org/gitlab/-/issues/24264) proposes to change this to more than 12 months. General improvements to the user profile are proposed in issue [8488](https://gitlab.com/groups/gitlab-org/-/epics/8488).

## User contribution events

GitLab tracks the following contribution events:

| Event | Contribution |
| ----- | ------------ |
| `approved` | Merge request |
| `closed` | [Epic](../group/epics/_index.md), Issue, Merge request, Milestone, Work item |
| `commented` on any `Noteable` record. | Alert, Commit, Design, Issue, Merge request, Snippet |
| `created` | Design, Epic, Issue, Merge request, Milestone, Project, Wiki page, Work item |
| `destroyed` | Design, Milestone, Wiki page |
| `expired` | Project membership |
| `joined` | Project membership |
| `left` | Project membership |
| `merged` | Merge request |
| `pushed` commits to (or deleted commits from) a repository, individually or in bulk. | Project |
| `reopened` | Epic, Issue, Merge request, Milestone |
| `updated` | Design, Wiki page |

### View daily contributions

To view your daily contributions:

1. On the left sidebar, select your avatar.
1. Select your name from the dropdown list.
1. In the contributions calendar:
   - To view the number of contributions for a specific day, hover over a tile.
   - To view all contributions for a specific day, select a tile. A list displays all contributions and the time they were made.

### Show private contributions on your user profile page

The contributions calendar graph and recent activity list displays your
[contribution actions](#user-contribution-events) to private projects.

To view private contributions:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. In the **Main settings** section, select the **Include private contributions on my profile** checkbox.
1. Select **Update profile settings**.

## User activity

### Follow a user's activity

You can follow users whose activity you're interested in.
In [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/360755),
the maximum number of users you can follow is 300.

To follow a user, either:

- From a user's profile, select **Follow**.
- Hover over a user's name, and select **Follow** ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76050)
  in GitLab 15.0).

To view the activity of users you follow:

1. In the GitLab menu, select **Activity**.
1. Select the **Followed users** tab.

### Retrieve user activity as a feed

GitLab provides RSS feeds of user activity. To subscribe to the
RSS feed of a user's activity:

1. Go to the [user's profile](_index.md#access-your-user-profile).
1. In the upper-right corner, select the feed symbol (**{rss}**) to display the results as an RSS feed in Atom format.

The URL of the result contains both a feed token, and
the user's activity that you're authorized to view.
You can add this URL to your feed reader.

### Reset the user activity feed token

Feed tokens are sensitive and can reveal information from confidential issues.
If you think your feed token has been exposed, you should reset it.

To reset your feed token:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Scroll down. In the **Feed token** section, select the
   **reset this token** link.
1. On the confirmation dialog, select **OK**.

A new token is generated.

### Event time period limit

GitLab removes user activity events older than 3 years from the events table for performance reasons.

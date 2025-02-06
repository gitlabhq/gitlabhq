---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User Cohorts
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can analyze your users' GitLab activities over time.

How do you interpret the user cohorts table? Let's review an example with the
following user cohorts:

![User cohort table showing retention and inactivity metrics, highlighting March and April 2020.](img/cohorts_v13_9_a.png)

For the cohort of March 2020, three users were added to this server and have
been active since this month. One month later (April 2020), two users are still
active. Five months later (August 2020), one user from this cohort is still
active, or 33% of the original cohort of three that joined in March.

The **Inactive users** column shows the number of users who were added during
the month, but who never had any activity in the instance.

How do we measure the activity of users? GitLab considers a user active if:

- The user signs in.
- The user has Git activity (whether push or pull).
- The user visits pages related to dashboards, projects, issues, or merge requests.
- The user uses the API.
- The user uses the GraphQL API.

## View user cohorts

To view user cohorts:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Select the **Cohorts** tab.

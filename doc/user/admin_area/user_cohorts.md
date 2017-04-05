# Cohorts

> **Notes:**
- [Introduced][ce-23361] in GitLab 9.1.

As a benefit of having the [usage ping active](settings/usage_statistics.md),
GitLab lets you analyze the user's activities of your GitLab installation.
Under [LINK], when the usage ping is active, GitLab will show the monthly
cohorts of new users and their activities over time.

How do we read the user cohorts table? Let's take an example with the following
user cohorts.

![User cohort example](img/cohorts.png)

For the cohort of June 2016, 163 users have been created on this server. One
month after, in July 2016, 155 users (or 95% of the June cohort) are still
active. Two months after, 139 users (or 85%) are still active. 9 months after,
we can see that only 6% of this cohort are still active.

How do we measure the activity of users? GitLab considers a user active if:
* the user signs in
* the user has a git activity (whether push or pull).

### Setup

1. Activate the usage ping as defined in [LINK]
2. Go to [LINK] to see the user cohorts of the server

[ce-23361]: https://gitlab.com/gitlab-org/gitlab-ce/issues/23361

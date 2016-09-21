# Usage statistics

GitLab Inc. will periodically collect information about your instance in order
to perform various actions.

All statistics are opt-in and you can always disable them from the admin panel.

## Version check

GitLab can inform you when an update is available and the importance of it.

No information other than the GitLab version and the instance's domain name
are collected.

In the **Overview** tab you can see if your GitLab version is up to date. There
are three cases: 1) you are up to date (green), 2) there is an update available
(yellow) and 3) your version is vulnerable and a security fix is released (red).

In any case, you will see a message informing you of the state and the
importance of the update.

If enabled, the version status will also be shown in the help page (`/help`)
for all signed in users.

## Usage data

> [Introduced][ee-557] in GitLab Enterprise Edition 8.10. More statistics
[were added][ee-735] in GitLab Enterprise Edition 8.12.

GitLab Inc. can collect non-sensitive information about how Enterprise Edition
customers use their GitLab instance upon the activation of a ping feature
located in the admin panel (`/admin/application_settings`).

You can see the **exact** JSON payload that your instance sends to GitLab Inc.
in the "Usage statistics" section of the admin panel.

Nothing qualitative is collected. Only quantitative. Meaning, no project name,
author name, nature of comments, name of labels, etc.

This is done mainly for the following reasons:

- to have a better understanding on how our users use our product
- to provide more tools for the customer success team to help customers onboard
  better.

The total number of the following is sent back to GitLab Inc.:

- Comments
- Groups
- Users
- Projects
- Issues
- Labels
- CI builds
- Snippets
- Milestones
- Todos
- Pushes
- Merge requests
- Environments
- Triggers
- Deploy keys
- Pages
- Project Services
- Issue Boards
- CI Runners
- Deployments
- Geo Nodes
- LDAP Groups
- LDAP Keys
- LDAP Users
- LFS objects
- Protected branches
- Releases
- Remote mirrors
- Web hooks

## Privacy policy

GitLab Inc. does **not** collect any sensitive information, like project names
or the content of the comments. GitLab Inc. does not disclose or otherwise make
available any of the data collected on a customer specific basis.

Read more in about the [Privacy policy](https://about.gitlab.com/privacy).

[ee-557]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/557
[ee-735]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/735

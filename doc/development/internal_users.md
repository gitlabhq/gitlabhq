---
description: "Internal users documentation."
type: concepts, reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Internal users

GitLab uses internal users (sometimes referred to as "bots") to perform
actions or functions that cannot be attributed to a regular user.

These users are created programatically throughout the codebase itself when
necessary, and do not count towards a license limit.

They are used when a traditional user account would not be applicable, for
example when generating alerts or automatic review feedback.

Technically, an internal user is a type of user, but they have reduced access
and a very specific purpose. They cannot be used for regular user actions,
such as authentication or API requests.

They have email addresses and names which can be attributed to any actions
they perform.

For example, when we [migrated](https://gitlab.com/gitlab-org/gitlab/-/issues/216120)
GitLab Snippets to [Versioned Snippets](../user/snippets.md#versioned-snippets)
in GitLab 13.0, we used an internal user to attribute the authorship of
snippets to itself when a snippet's author wasn't available for creating
repository commits, such as when the user has been disabled, so the Migration
Bot was used instead.

For this bot:

- The name was set to `GitLab Migration Bot`.
- The email was set to `noreply+gitlab-migration-bot@{instance host}`.

Other examples of internal users:

- [Alert Bot](../operations/metrics/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [Support Bot](../user/project/service_desk.md#support-bot-user)
- Visual Review Bot

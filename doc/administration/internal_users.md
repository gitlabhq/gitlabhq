---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Internal users
---

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584) in GitLab 15.4, bots are indicated with a badge in user listings.

GitLab uses internal users (sometimes referred to as "bots") to perform actions or functions that cannot be attributed
to a regular user.

Internal users:

- Are created programmatically and do not count towards a license limit.
- Are used when a traditional user account isn't applicable. For example, when generating alerts or automatic review
  feedback.
- Have reduced access and a very specific purpose. They cannot be used for regular user actions, such as authentication
  or API requests.
- Have email addresses and names that can be attributed to any actions they perform.

Internal users are sometimes created as part of feature development. For example, the GitLab Migration Bot for
[migrating](https://gitlab.com/gitlab-org/gitlab/-/issues/216120) from GitLab Snippets to
[Versioned Snippets](../user/snippets.md#versioned-snippets). GitLab Migration Bot was used as the author of snippets
when a snippet's original author wasn't available. For example, when the user was disabled.

Other examples of internal users:

- [GitLab Automation Bot](../user/group/iterations/_index.md#gitlab-automation-bot-user)
- [GitLab Security Bot](#gitlab-security-bot)
- [GitLab Security Policy Bot](#gitlab-security-policy-bot)
- [Alert Bot](../operations/incident_management/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [Support Bot](../user/project/service_desk/configure.md#support-bot-user)
- [Placeholder User](../user/project/import/_index.md#placeholder-users) created during imports
- Visual Review Bot
- Resource access tokens, including [project access tokens](../user/project/settings/project_access_tokens.md)
  and [group access tokens](../user/group/settings/group_access_tokens.md), which are
  `project_{project_id}_bot_{random_string}` and `group_{group_id}_bot_{random_string}` users with a `PersonalAccessToken`.

## GitLab Admin Bot

[GitLab Admin Bot](https://gitlab.com/gitlab-org/gitlab/-/blob/1d38cfdbed081f8b3fa14b69dd743440fe85081b/lib/users/internal.rb#L104)
is an internal user that cannot be accessed or modified by regular users and is responsible for many tasks including:

- Applying [default compliance frameworks](../user/group/compliance_frameworks.md#default-compliance-frameworks) to
  projects.
- [Automatically deactivating dormant users](moderate_users.md#automatically-deactivate-dormant-users).
- [Automatically deleting unconfirmed users](moderate_users.md#automatically-delete-unconfirmed-users).
- [Deleting inactive projects](inactive_project_deletion.md).
- [Locking users](../security/unlock_user.md).

## GitLab Security Bot

GitLab Security Bot is an internal user responsible for commenting on merge requests that violate a
[security policy](../user/application_security/policies/_index.md).

## GitLab Security Policy Bot

GitLab Security Policy Bot is an internal user responsible for triggering scheduled pipelines
defined in [security policies](../user/application_security/policies/_index.md). This account is
created in every project on which a security policy is enforced.

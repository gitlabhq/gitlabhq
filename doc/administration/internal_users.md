---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Internal users
description: Enable automated system operations through internal bot users for GitLab functionality.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584) in GitLab 15.4, bots are indicated with a badge in user listings.

{{< /history >}}

Internal users (also called "bots") are system accounts that GitLab creates automatically to perform
specific background actions. GitLab uses them when a regular user account is not applicable, such as when
generating alerts or automatic review feedback. Internal users have usernames and email addresses, so their
actions can be attributed to them. They do not count towards a license limit and cannot be created manually.

Internal users have limited access and cannot be used directly for many actions such as authentication.
Some bots have access to make API requests, but most cannot.

Internal users are sometimes created as part of feature development. For example, the GitLab Migration Bot for
[migrating](https://gitlab.com/gitlab-org/gitlab/-/issues/216120) from GitLab Snippets to
[Versioned Snippets](../user/snippets.md#versioned-snippets). This bot was assigned as the snippet author
when the original author was not available.

Other examples of internal users:

- [GitLab Automation Bot](../user/group/iterations/_index.md#gitlab-automation-bot-user)
- [GitLab Security Bot](#gitlab-security-bot)
- [GitLab Security Policy Bot](#gitlab-security-policy-bot)
- [Alert Bot](../operations/incident_management/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [Support Bot](../user/project/service_desk/configure.md#support-bot-user)
- [Placeholder User](../user/import/mapping/post_migration_mapping.md#placeholder-users) created during imports
- Visual Review Bot
- Resource access tokens, including [project access tokens](../user/project/settings/project_access_tokens.md)
  and [group access tokens](../user/group/settings/group_access_tokens.md), which are
  `project_{project_id}_bot_{random_string}` and `group_{group_id}_bot_{random_string}` users with a `PersonalAccessToken`.

## GitLab Admin Bot

[GitLab Admin Bot](https://gitlab.com/gitlab-org/gitlab/-/blob/1d38cfdbed081f8b3fa14b69dd743440fe85081b/lib/users/internal.rb#L104)
is an internal user that cannot be accessed or modified by regular users and is responsible for many tasks including:

- Applying [default compliance frameworks](../user/compliance/compliance_frameworks/_index.md#default-compliance-frameworks) to
  projects.
- [Automatically deactivating dormant users](moderate_users.md#automatically-deactivate-dormant-users).
- [Automatically deleting unconfirmed users](moderate_users.md#automatically-delete-unconfirmed-users).
- [Deleting dormant projects](dormant_project_deletion.md).
- [Locking users](../security/unlock_user.md).

## GitLab Security Bot

GitLab Security Bot is an internal user responsible for commenting on merge requests that violate a
[security policy](../user/application_security/policies/_index.md).

## GitLab Security Policy Bot

{{< history >}}

- [API access granted](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235671) in GitLab 19.1.

{{< /history >}}

GitLab Security Policy Bot is an internal user responsible for triggering scheduled pipelines
defined in [security policies](../user/application_security/policies/_index.md#gitlab-security-policy-bot-user).
This account is created in every project with a security policy enforced.

For scheduled pipeline execution policies, this bot can read CI/CD configuration from private
projects when project owners explicitly allow access.

In GitLab 19.1 and later, the bot can access the API to perform actions such as downloading artifacts from earlier
pipeline stages as part of scheduled pipeline execution policies. To limit the risks of API access, the bot can
only access endpoints permitted by its role in the projects it is a member of.

Bot access has these limits:

- The target project must enable **Security policy bot access**.
- The requested file path must match the project's allowed file patterns.
- The bot project must be in the allowed group hierarchy. If no group is configured, GitLab uses
  the root ancestor group.

To set up Security Policy Bot access, see
[scheduled pipeline execution policies](../user/application_security/policies/scheduled_pipeline_execution_policies.md#option-2-allow-security-policy-bot-access-to-private-or-internal-projects).

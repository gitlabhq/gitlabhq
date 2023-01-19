---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
---

# Responding to security incidents **(FREE SELF)**

When a security incident occurs, you should follow the processes defined by your organization. However, you might consider some
additional steps. These suggestions are intended to supplement existing security incident response processes within your organization.

## Suspected compromised user account

If you suspect that a user account or bot account has been compromised, consider taking the following steps:

- [Block the user](../user/admin_area/moderate_users.md#block-a-user) to mitigate any current risk.
- [Review the audit events](../administration/audit_events.md) available to you to identify any suspicious account behavior. For
  example:
  - Suspicious sign-in events.
  - Creation or deletion of personal access tokens, project access tokens, and group access tokens.
  - Creation or deletion of SSH or GPG keys.
  - Creation, modification, or deletion of two-factor authentication.
  - Changes to repositories.
  - Changes to group or project configurations.
  - Addition or modification of runners.
  - Addition or modification of webhooks or Git hooks.
- Reset any credentials the user might have had access to. For example, users with at least the Maintainer role can view protected
  [CI/CD variables](../ci/variables/index.md) and [runner registration tokens](token_overview.md#runner-registration-tokens-deprecated).
- [Reset the user's password](reset_user_password.md).
- Get the user to [enable two factor authentication](../user/profile/account/two_factor_authentication.md) (2FA), and consider [enforcing 2FA at the instance or group level](two_factor_authentication.md)
- After completing an investigation and mitigating impacts, unblock the user.

## Suspected compromised instance **(FREE SELF)**

Self-managed GitLab customers and administrators are responsible for:

- The security of their underlying hosts.
- Keeping GitLab itself up to date.

It is important to [regularly update GitLab](../policy/maintenance.md), update your operating system and its software, and harden your
hosts in accordance with vendor guidance.

If you suspect that your GitLab instance has been compromised, consider taking the following steps:

- [Review the audit events](../administration/audit_events.md) available to you for suspicious account behavior.
- [Review all users](../user/admin_area/moderate_users.md) (including the Administrative root user), and follow the steps in [Suspected compromised user account](#suspected-compromised-user-account) if necessary.
- Review the [Credentials Inventory](../user/admin_area/credentials_inventory.md), if available to you.
- Change any sensitive credentials, variables, tokens, and secrets. For example, those located in instance configuration, database,
  CI/CD pipelines, or elsewhere.
- Upgrade to the latest version of GitLab and adopt a plan to upgrade after every security patch release.

In addition, the suggestions below are common steps taken in incident response plans when servers are compromised by malicious actors.

WARNING:
Use these suggestions at your own risk.

- Save any server state and logs to a write-once location, for later investigation.
- Look for unrecognized background processes.
- Check for open ports on the system.
- Rebuild the host from a known-good backup or from scratch, and apply all the latest security patches.
- Review network logs for uncommon traffic.
- Establish network monitoring and network-level controls.
- Restrict inbound and outbound network access to authorized users and servers only.
- Ensure all logs are routed to an independent write-only datastore.

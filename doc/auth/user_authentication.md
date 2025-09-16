---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User authentication
description: Passwords, two-factor authentication, SSH keys, access tokens, credentials inventory.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab provides multiple authentication methods to secure how users can access their account and
interact with repositories. Use passwords with optional two-factor authentication for web-based
access, SSH keys for Git operations, and various types of access tokens for API interactions
and automation.

On GitLab Self-Managed and GitLab Dedicated, administrators can configure how authentication
works, monitor credential usage, and implement security policies to protect their instance.
Users can manage how they authenticate, review active sessions, and configure additional
security measures like two-factor authentication.

## Password authentication

{{< cards >}}

- [User passwords](../user/profile/user_passwords.md)
- [Password storage](../security/password_storage.md)
- [Compromised password detection](../security/compromised_password_detection.md)
- [Password length limits](../security/password_length_limits.md)
- [Passwords for integrated authentication methods](../security/passwords_for_integrated_authentication_methods.md)

{{< /cards >}}

## Credentials management

{{< cards >}}

- [Credentials inventory for administrators](../administration/credentials_inventory.md)
- [Credentials inventory for groups](../user/group/credentials_inventory.md)

{{< /cards >}}

## Two-factor authentication

{{< cards >}}

- [Two-factor authentication](../user/profile/account/two_factor_authentication.md)
- [Two-factor authentication for administrators](../security/two_factor_authentication.md)
- [Two-factor authentication troubleshooting](../user/profile/account/two_factor_authentication_troubleshooting.md)

{{< /cards >}}

## SSH key authentication

{{< cards >}}

- [SSH keys](../user/ssh.md)
- [SSH key restrictions](../security/ssh_keys_restrictions.md)
- [SSH troubleshooting](../user/ssh_troubleshooting.md)

{{< /cards >}}

## Access tokens

{{< cards >}}

- [Access tokens](../security/tokens/_index.md)
- [Personal access tokens](../user/profile/personal_access_tokens.md)
- [Group access tokens](../user/group/settings/group_access_tokens.md)
- [Project access tokens](../user/project/settings/project_access_tokens.md)
- [Token troubleshooting](../security/tokens/token_troubleshooting.md)

{{< /cards >}}

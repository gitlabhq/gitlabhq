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

{{< cards >}}

- [User passwords](../user/profile/user_passwords.md)
- [Two-factor authentication](../user/profile/account/two_factor_authentication.md)
- [Credentials inventory](../administration/credentials_inventory.md)
- [SSH keys](../user/ssh.md)
- [Access tokens](../security/tokens/_index.md)
- [Smart card authentication](../administration/auth/smartcard.md)
- [Account email verification](../security/email_verification.md)

{{< /cards >}}

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compromised password detection
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188723) in GitLab 18.0 [with a flag](../administration/feature_flags/_index.md) named `notify_compromised_passwords`. Disabled by default.
- Enabled on GitLab.com in GitLab 18.1. Feature flag `notify_compromised_passwords` removed.

{{< /history >}}

GitLab can notify you if your GitLab.com credentials are compromised as part of a data breach on another service or platform. GitLab credentials are encrypted and GitLab itself does not have direct access to them.

When a compromised credential is detected, GitLab displays a security banner and sends an email alert that includes instructions on how to change your password and strengthen your account security.

Compromised password detection is unavailable when authenticating [with an external provider](../administration/auth/_index.md), or if your account is already [locked](unlock_user.md).

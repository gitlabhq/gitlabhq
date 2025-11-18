---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Make new users confirm email
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab can be configured to require confirmation of a user's email address when
the user signs up. When this setting is enabled, the user is unable to sign in until
they confirm their email address.

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Sign-up restrictions** and look for the **Email confirmation settings** options.

## Confirmation token expiry

By default, a user can confirm their account within 24 hours after the confirmation email was sent.
After 24 hours, the confirmation token becomes invalid.

## Automatically delete unconfirmed users

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When email confirmation is turned on, administrators can enable the setting to
[automatically delete unconfirmed users](../administration/moderate_users.md#automatically-delete-unconfirmed-users).

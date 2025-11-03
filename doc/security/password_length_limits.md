---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom password length limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

By default, GitLab supports passwords with the following lengths:

- Minimum: 8 characters
- Maximum: 128 characters

You can only change the minimum password length. Changing the minimum length does not affect existing user passwords.
Existing users are not asked to reset their password to adhere to the new limits. The new limit restriction applies only
during new user sign-ups and when an existing user performs a password reset.

## Modify minimum password length

The user password length is set to a minimum of 8 characters by default.

To change the minimum password length using GitLab UI:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Sign-up restrictions**.
1. Enter a **Minimum password length** value greater than or equal to `8`.
1. Select **Save changes**.

---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Terms of Service and Privacy Policy
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

An administrator can enforce acceptance of a terms of service and privacy policy.
When this option is enabled, new and existing users must accept the terms.

When enabled, you can view the Terms of Service at the `-/users/terms` page on the instance,
for example `https://gitlab.example.com/-/users/terms`.

The link `Terms and privacy` will become visible in the help menu if any
terms are defined.

## Enforce a Terms of Service and Privacy Policy

To enforce acceptance of a Terms of Service and Privacy Policy:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand the **Terms of Service and Privacy Policy** section.
1. Check the **All users must accept the Terms of Service and Privacy Policy to access GitLab** checkbox.
1. Input the text of the **Terms of Service and Privacy Policy**. You can use [Markdown](../../user/markdown.md)
   in this text box.
1. Select **Save changes**.

For each update to the terms, a new version is stored. When a user accepts or declines the terms,
GitLab records which version they accepted or declined.

Existing users must accept the terms on their next GitLab interaction.
If an authenticated user declines the terms, they are signed out.

When enabled, it adds a mandatory checkbox to the sign up page for new users:

![Sign-up form with a mandatory terms acceptance checkbox](img/sign_up_terms_v11_0.png)

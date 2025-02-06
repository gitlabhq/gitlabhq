---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terms of Service and Privacy Policy
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

An administrator can enforce acceptance of a terms of service and privacy policy.
When this option is enabled, new and existing users must accept the terms.

When enabled, you can view the Terms of Service at the `-/users/terms` page on the instance,
for example `https://gitlab.example.com/-/users/terms`.

The link `Terms and privacy` will become visible in the help menu if any
terms are defined.

## Enforce a Terms of Service and Privacy Policy

To enforce acceptance of a Terms of Service and Privacy Policy:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
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

![Sign up form](img/sign_up_terms_v11_0.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

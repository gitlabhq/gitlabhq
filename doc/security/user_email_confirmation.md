---
type: howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# User email confirmation at sign-up

GitLab can be configured to require confirmation of a user's email address when
the user signs up. When this setting is enabled, the user is unable to sign in until
they confirm their email address.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > General** (`/admin/application_settings/general`).
1. Expand the **Sign-up restrictions** section and look for the **Send confirmation email on sign-up** option.

## Confirmation token expiry

By default, a user can confirm their account within 24 hours after the confirmation email was sent.
After 24 hours, the confirmation token becomes invalid.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

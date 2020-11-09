---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Sign-up restrictions **(CORE ONLY)**

You can enforce the following restrictions on sign ups:

- Disable new sign ups.
- Require administrator approval for new sign ups.
- Require user email confirmation.
- Allow or deny sign ups using specific email domains.

## Disable new sign ups

By default, any user visiting your GitLab domain can sign up for an account. For customers running
public-facing GitLab instances, we **highly** recommend that you consider disabling new sign ups if
you do not expect public users to sign up for an account.

To disable sign ups:

1. Go to **Admin Area > Settings > General** and expand **Sign-up restrictions**.
1. Clear the **Sign-up enabled** checkbox, then select **Save changes**.

## Require administrator approval for new sign ups

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4491) in GitLab 13.5.

When this setting is enabled, any user visiting your GitLab domain and signing up for a new account must be explicitly [approved](../approving_users.md#approving-a-user) by an administrator before they can start using their account. This setting is only applicable if sign ups are enabled.

To require administrator approval for new sign ups:

1. Go to **Admin Area > Settings > General** and expand **Sign-up restrictions**.
1. Select the **Require admin approval for new sign-ups** checkbox, then select **Save changes**.

## Require email confirmation

You can send confirmation emails during sign up and require that users confirm
their email address before they are allowed to sign in.

To enforce confirmation of the email address used for new sign ups:

1. Go to **Admin Area > Settings > General** and expand **Sign-up restrictions**.
1. Select the **Enable email restrictions for sign ups** checkbox, then select **Save changes**.

## Minimum password length limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20661) in GitLab 12.6

You can [change](../../../security/password_length_limits.md#modify-minimum-password-length-using-gitlab-ui)
the minimum number of characters a user must have in their password using the GitLab UI.

## Allow or deny sign ups using specific email domains

You can specify an inclusive or exclusive list of email domains which can be used for user sign up.

These restrictions are only applied during sign up from an external user. An administrator can add a
user through the admin panel with a disallowed domain. Also, note that the users can change their
email addresses to disallowed domains after sign up.

### Allowlist email domains

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/598) in GitLab 7.11.0

You can restrict users only to sign up using email addresses matching the given
domains list.

### Denylist email domains

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5259) in GitLab 8.10.

You can block users from signing up when using an email addresses of specific domains. This can
reduce the risk of malicious users creating spam accounts with disposable email addresses.

### Create email domain allowlist or denylist

To create an email domain allowlist or denylist:

1. Go to **Admin Area > Settings > General** and expand **Sign-up restrictions**.
1. For the allowlist, you must enter the list manually. For the denylist, you can enter the list
   manually or upload a `.txt` file that contains list entries.

   Both the allowlist and denylist accept wildcards. For example, you can use
`*.company.com` to accept every `company.com` subdomain, or `*.io` to block all
domains ending in `.io`. Domains must be separated by a whitespace,
semicolon, comma, or a new line.

   ![Domain Denylist](img/domain_denylist.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

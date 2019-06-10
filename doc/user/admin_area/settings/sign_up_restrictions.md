---
type: reference
---

# Sign-up restrictions

You can block email addresses of specific domains, or whitelist only some
specific domains via the **Application Settings** in the Admin area.

>**Note**: These restrictions are only applied during sign-up. An admin is
able to add a user through the admin panel with a disallowed domain. Also
note that the users can change their email addresses after signup to
disallowed domains.

## Whitelist email domains

> [Introduced][ce-598] in GitLab 7.11.0

You can restrict users to only signup using email addresses matching the given
domains list.

## Blacklist email domains

> [Introduced][ce-5259] in GitLab 8.10.

With this feature enabled, you can block email addresses of a specific domain
from creating an account on your GitLab server. This is particularly useful to
prevent spam. Disposable email addresses are usually used by malicious users to
create dummy accounts and spam issues.

## Settings

This feature can be activated via the **Application Settings** in the Admin area,
and you have the option of entering the list manually, or uploading a file with
the list.

Both whitelist and blacklist accept wildcards, so for example, you can use
`*.company.com` to accept every `company.com` subdomain, or `*.io` to block all
domains ending in `.io`. Domains should be separated by a whitespace,
semicolon, comma, or a new line.

![Domain Blacklist](img/domain_blacklist.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

[ce-5259]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5259
[ce-598]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/598

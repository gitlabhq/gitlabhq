# Sign-up restrictions

## Blacklist email domains

> [Introduced][ce-5259] in GitLab 8.10.

With this feature enabled, you can block email addresses of a specific domain
from creating an account on your GitLab server. This is particularly useful to
prevent spam. Disposable email addresses are usually used by malicious users to
create dummy accounts and spam issues.

This feature can be activated via the **Application Settings** in the Admin area,
and you have the option of entering the list manually, or uploading a file with
the list.

The blacklist accepts wildcards, so you can use `*.test.com` to block every
`test.com` subdomain, or `*.io` to block all domains ending in `.io`. Domains
should be separated by a whitespace, semicolon, comma, or a new line.

![Domain Blacklist](img/domain_blacklist.png)

[ce-5259]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5259

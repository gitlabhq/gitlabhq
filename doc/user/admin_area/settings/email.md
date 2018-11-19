# Email

## Custom logo

The logo in the header of some emails can be customized, see the [logo customization section](../../../customization/branded_page_and_email_header.md).

## Custom hostname for private commit emails

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22560) in GitLab 11.5.

This configuration option sets the email hostname for [private commit emails](../../profile/index.md#private-commit-email),
and it's, by default, set to `users.noreply.YOUR_CONFIGURED_HOSTNAME`.

In order to change this option:

1. Go to **Admin area > Settings** (`/admin/application_settings`).
1. Under the **Email** section, change the **Custom hostname (for private commit emails)** field.
1. Hit **Save** for the changes to take effect.

NOTE: **Note**: Once the hostname gets configured, every private commit email using the previous hostname, will not get
recognized by GitLab. This can directly conflict with certain [Push rules](https://docs.gitlab.com/ee/push_rules/push_rules.html) such as
`Check whether author is a GitLab user` and `Check whether committer is the current authenticated user`.

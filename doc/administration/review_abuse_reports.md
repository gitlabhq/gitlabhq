---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Review abuse reports

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

View and resolve abuse reports from GitLab users.

GitLab administrators can view and [resolve](#resolving-abuse-reports) abuse
reports in the Admin Area.

## Receive notification of abuse reports by email

To receive notifications of new abuse reports by email:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Reporting**.
1. Expand the **Abuse reports** section.
1. Provide an email address and select **Save changes**.

The notification email address can also be set and retrieved
[using the API](../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls).

## Reporting abuse

To find out more about reporting abuse, see
[abuse reports user documentation](../user/report_abuse.md).

## Resolving abuse reports

> - **Trust user** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131102) in GitLab 16.4.

To access abuse reports:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Abuse Reports**.

There are four ways to resolve an abuse report, with a button for each method:

- Remove user & report. This:
  - [Deletes the reported user](../user/profile/account/delete_account.md) from the
    instance.
  - Removes the abuse report from the list.
- [Block user](#blocking-users).
- Remove report. This:
  - Removes the abuse report from the list.
  - Removes access restrictions for the reported user.
- Trust user. This:
  - Allows the user to create issues, notes, snippets, and merge requests without being blocked for spam.
  - Prevents abuse reports from being created for this user.

The following is an example of the **Abuse Reports** page:

![abuse-reports-page-image](img/abuse_reports_page_v13_11.png)

### Blocking users

A blocked user cannot sign in or access any repositories, but all of their data
remains.

Blocking a user:

- Leaves them in the abuse report list.
- Changes the **Block user** button to a disabled **Already blocked** button.

The user is notified with the following message:

```plaintext
Your account has been blocked. If you believe this is in error, contact a staff member.
```

After blocking, you can still either:

- Remove the user and report if necessary.
- Remove the report.

The following is an example of a blocked user listed on the **Abuse Reports**
page:

![abuse-report-blocked-user-image](img/abuse_report_blocked_user.png)

NOTE:
Users can be [blocked](../api/users.md#block-user) and
[unblocked](../api/users.md#unblock-user) using the GitLab API.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

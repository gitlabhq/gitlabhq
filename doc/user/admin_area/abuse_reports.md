---
type: reference, howto
---

# Abuse reports

View and resolve abuse reports from GitLab users.

GitLab administrators can view and [resolve](#resolving-abuse-reports) abuse
reports in the Admin Area.

## Reporting abuse

To find out more about reporting abuse, see [abuse reports user
documentation](../abuse_reports.md).

## Resolving abuse reports

To access abuse reports, go to **Admin Area > Abuse Reports**.

There are 3 ways to resolve an abuse report, with a button for each method:

- Remove user & report. This will:
  - [Delete the reported user](../profile/account/delete_account.md) from the
    instance.
  - Remove the abuse report from the list.
- [Block user](#blocking-users).
- Remove report. This will:
  - Remove the abuse report from the list.
  - Remove access restrictions for the reported user.

The following is an example of the **Abuse Reports** page:

![abuse-reports-page-image](img/abuse_reports_page.png)

### Blocking users

A blocked user cannot log in or access any repositories, but all of their data
remains.

Blocking a user:

- Leaves them in the abuse report list.
- Changes the **Block user** button to a disabled **Already blocked** button.

The user will be notified with the
[following message](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/app/workers/email_receiver_worker.rb#L38):

```text
Your account has been blocked. If you believe this is in error, contact a staff member.
```

After blocking, you can still either:

- Remove the user and report if necessary.
- Remove the report.

The following is an example of a blocked user listed on the **Abuse Reports**
page:

![abuse-report-blocked-user-image](img/abuse_report_blocked_user.png)

NOTE: **Note:**
Users can be [blocked](../../api/users.md#block-user) and
[unblocked](../../api/users.md#unblock-user) using the GitLab API.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

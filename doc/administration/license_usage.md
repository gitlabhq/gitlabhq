---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: License usage
description: View and export usage associated with your GitLab license.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can view the usage associated with your GitLab license
and export the license usage file with the following information:

- License key
- Licensee email
- License start date (UTC)
- License end date (UTC)
- Company
- Timestamp the file was generated at and exported (UTC)
- Table of historical user counts for each day in the period:
  - Timestamp the count was recorded (UTC)
  - Billable user count

> [!note]
> A custom format is used for [dates](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) and [times](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13) in CSV files.

## Export license usage

Prerequisites:

- You must be an administrator.

You can export your license usage into a CSV file.

This file contains the information GitLab uses to manually process
[quarterly reconciliations](../subscriptions/quarterly_reconciliation.md)
and [renewals](../subscriptions/manage_subscription.md#renew-subscription). If your instance is firewalled or an
offline environment, you must provide GitLab with this information.

> [!warning]
> Do not open the license usage file. If you open the file, failures might occur when [you submit your license usage data](license_file.md#submit-license-usage-data).

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Subscription**.
1. In the upper-right corner, select **Export license usage file**.

## Export a usage report

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/258909) in GitLab 19.6 [with a feature flag](feature_flags/_index.md) named `billable_usage_export`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

If your instance is in an offline environment, it cannot send usage data to GitLab.
Export a usage report instead, and upload it to the Customers Portal
within three days after the end of each month.

The usage report is a JSON file that covers one subscription term,
from the term start date up to the last completed day.
The report contains:

- Your license key and instance details, like the instance ID, hostname, and GitLab version
- The report start and end dates, and date and time when the report was generated (UTC)
- Daily usage totals for each usage meter, like GitLab Duo Agent Platform flows and Secrets Manager
- The highest billable user count for each day
- The days with no recorded data. The report marks these days as unknown, not as zero usage.

The report contains only daily totals.
It does not attribute usage to users, and contains no usernames, email addresses, or user IDs.

Each report covers the whole term, so if a report is not uploaded,
the next report includes the same usage.
GitLab records each day once, so days you've already uploaded are not counted twice.

When the usage report is available, **Export usage report** replaces
**Export license usage file** on the **Subscription** page.

Prerequisites:

- Administrator access.
- An instance activated with an offline license or a license file.

To export a usage report:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Subscription**.
1. In the upper-right corner, select **Export usage report**.
1. Optional. If your subscription has renewed, from the **Subscription term** dropdown list,
   select the term to export. Export the previous term if you did not upload its last month.
1. Review the report contents, then select **Export JSON**.
1. Upload the downloaded file to the Customers Portal.

---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: License usage
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

{{< alert type="note" >}}

A custom format is used for [dates](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) and [times](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13) in CSV files.

{{< /alert >}}

## Export license usage

Prerequisites:

- You must be an administrator.

You can export your license usage into a CSV file.

This file contains the information GitLab uses to manually process
[quarterly reconciliations](../subscriptions/quarterly_reconciliation.md)
and [renewals](../subscriptions/manage_subscription.md#renew-subscription). If your instance is firewalled or an
offline environment, you must provide GitLab with this information.

{{< alert type="warning" >}}

Do not open the license usage file. If you open the file, failures might occur when [you submit your license usage data](license_file.md#submit-license-usage-data).

{{< /alert >}}

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Subscription**.
1. In the upper-right corner, select **Export license usage file**.

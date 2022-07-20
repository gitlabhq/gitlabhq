---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

<!-- To promote the workflow described in license.md, this page is not included in global left nav. -->

# Activate GitLab EE with a license file or key

If you receive a license file from GitLab (for example, for a trial), you can
upload it to your instance or add it during installation. The license file is
a base64-encoded ASCII text file with a `.gitlab-license` extension.

The first time you sign in to your GitLab instance, a note with a
link to the **Add license** page should be displayed.

Otherwise, to add your license:

1. Sign in to GitLab as an administrator.
1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. In the **Add License** area, add a license by either uploading the file or entering the key.
1. Select the **Terms of Service** checkbox.
1. Select **Add license**.

## Add your license file during installation

You can import a license file when you install GitLab.

- **For installations from source**
  - Place the `Gitlab.gitlab-license` file in the `config/` directory.
  - To specify a custom location and filename for the license, set the
    `GITLAB_LICENSE_FILE` environment variable with the path to the file:

    ```shell
    export GITLAB_LICENSE_FILE="/path/to/license/file"
    ```

- **For Omnibus package**
  - Place the `Gitlab.gitlab-license` file in the `/etc/gitlab/` directory.
  - To specify a custom location and filename for the license, add this entry to `gitlab.rb`:

    ```ruby
    gitlab_rails['initial_license_file'] = "/path/to/license/file"
    ```

WARNING:
These methods only add a license at the time of installation. To renew or upgrade
a license, add the license in the **Admin Area** in the web user interface.

## Submit license usage data

If you use a license file or key to activate your instance in an offline environment, you must submit your license
usage data monthly.
To submit the data, [export your license usage](../../subscriptions/self_managed/index.md#export-your-license-usage)
and send it by email to the renewals service, `renewals-service@customers.gitlab.com`.

If you don't submit your data each month after your subscription start date, an email is sent to the address
associated with your subscription and a banner displays to remind you to submit your data. The banner displays
in the **Admin Area** on the **Dashboard** and on the **Subscription** pages. You can only dismiss it until the
following month after you submit your license usage data.

## What happens when your license expires

Fifteen days before the license expires, a notification banner with the upcoming expiration
date displays to GitLab administrators.

When your license expires, GitLab locks features, like Git pushes
and issue creation. Your instance becomes read-only and
an expiration message displays to all administrators. You have a 14-day grace period
before this occurs.

To resume functionality, activate a new subscription.

To go back to Free features, [delete all expired licenses](#remove-a-license).

## Remove a license

To remove a license from a self-managed instance:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Subscription**.
1. Select **Remove license**.

Repeat these steps to remove all licenses, including those applied in the past.

## View license details and history

To view your license details:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Subscription**.

You can add and view more than one license, but only the latest license in
the current date range is the active license.

When you add a future-dated license, it doesn't take effect until its applicable date.
You can view all active subscriptions in the **Subscription history** table.

You can also [export](../../subscriptions/self_managed/index.md) your license usage information to a CSV file.

NOTE:
In GitLab 13.6 and earlier, a banner about an expiring license may continue to display
when you add a new license. This happens when the start date of the new license
is in the future and the expiring one is still active.
The banner disappears after the new license becomes active.

## Troubleshooting

### No Subscription area in the Admin Area

You cannot add your license because there is no **Subscription** area.
This issue might occur if:

- You're running GitLab Community Edition. Before you add your license, you
  must [upgrade to Enterprise Edition](../../update/index.md#community-to-enterprise-edition).
- You're using GitLab.com. You cannot add a self-managed license to GitLab.com.
  To use paid features on GitLab.com, [purchase a separate subscription](../../subscriptions/gitlab_com/index.md).

### Users exceed license limit upon renewal

GitLab displays a message prompting you to purchase
additional users. This issue occurs if you add a license that does not have enough
users to cover the number of users in your instance.

To fix this issue, purchase additional seats to cover those users.
For more information, read the [licensing FAQ](https://about.gitlab.com/pricing/licensing-faq/).

In GitLab 14.2 and later, for instances that use a license file, the following
rules apply:

- If the users over license are less than or equal to 10% of the users in the license
  file, the license is applied and you pay the overage in the next renewal.
- If the users over license are more than 10% of the users in the license file,
  you cannot apply the license without purchasing more users.

For example, if you purchase a license for 100 users, you can have 110 users when you add
your license. However, if you have 111 users, you must purchase more users before you can add
the license.

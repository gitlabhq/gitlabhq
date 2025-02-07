---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Activate GitLab EE with a license file or key
---

If you receive a license file from GitLab (for example, for a trial), you can
upload it to your instance or add it during installation. The license file is
a base64-encoded ASCII text file with a `.gitlab-license` extension.

The first time you sign in to your GitLab instance, a note with a
link to the **Add license** page should be displayed.

Otherwise, add your license in the Admin area.

## Add license in the Admin area

1. Sign in to GitLab as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. In the **Add License** area, add a license by either uploading the file or entering the key.
1. Select the **Terms of Service** checkbox.
1. Select **Add license**.

## Activate subscription during installation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114572) in GitLab 16.0.

To activate your subscription during installation, set the `GITLAB_ACTIVATION_CODE` environment variable with the activation code:

```shell
export GITLAB_ACTIVATION_CODE=your_activation_code
```

## Add license file during installation

If you have a license, you can also import it when you install GitLab.

- For self-compiled installations:
  - Place the `Gitlab.gitlab-license` file in the `config/` directory.
  - To specify a custom location and filename for the license, set the
    `GITLAB_LICENSE_FILE` environment variable with the path to the file:

    ```shell
    export GITLAB_LICENSE_FILE="/path/to/license/file"
    ```

- For Linux package installations:
  - Place the `Gitlab.gitlab-license` file in the `/etc/gitlab/` directory.
  - To specify a custom location and filename for the license, add this entry to `gitlab.rb`:

    ```ruby
    gitlab_rails['initial_license_file'] = "/path/to/license/file"
    ```

- For Helm Charts installations, use [the `global.gitlab.license` configuration keys](https://docs.gitlab.com/charts/installation/command-line-options.html#basic-configuration).

WARNING:
These methods only add a license at the time of installation. To renew or upgrade
a license, add the license in the **Admin area** in the web user interface.

## Submit license usage data

If you use a license file or key to activate your instance in an offline environment, you are encouraged to submit your license
usage data monthly to simplify future purchases and renewals.
To submit the data, [export your license usage](../subscriptions/self_managed/_index.md#export-your-license-usage)
and send it by email to the renewals service, `renewals-service@customers.gitlab.com`. **You must not open the license
usage file before you send it**. Otherwise, the file's content could be manipulated by the used program (for example,
timestamps could be converted to another format) and cause failures when the file is being processed.

If you don't submit your data each month after your subscription start date, an email is sent to the address
associated with your subscription and a banner displays to remind you to submit your data. The banner displays
in the **Admin** area on the **Dashboard** and on the **Subscription** pages, and can be dismissed after
the usage file has been downloaded. You can only dismiss it until the
following month after you submit your license usage data.

## What happens when your license expires

Fifteen days before the license expires, a notification banner with the upcoming expiration
date displays to GitLab administrators.

Licenses expire at the start of the expiration date, 00:00 server time.

When your license expires, GitLab locks features, like Git pushes
and issue creation. Your instance becomes read-only and
an expiration message displays to all administrators. You have a 14-day grace period
before this occurs.

For example, if a license has a start date of January 1, 2024 and an end date of January 1, 2025:

- It expires at 11:59:59 PM server time December 31, 2024.
- It is considered expired from 12:00:00 AM server time January 1, 2025.
- The grace period of 14 days starts at 12:00:00 AM server time January 1, 2025 and ends at 11:59:59 PM server time January 14, 2025.
- Your instance becomes read-only at 12:00:00 AM server time January 15, 2025.

To resume functionality, [renew your subscription](../subscriptions/self_managed/_index.md#renew-subscription-manually).

If the license has been expired for more than 30 days, you must purchase a [new subscription](../subscriptions/self_managed/_index.md) to resume functionality.

To go back to Free features, [delete all expired licenses](#remove-a-license).

## Remove a license

To remove a license from a GitLab Self-Managed instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.
1. Select **Remove license**.

Repeat these steps to remove all licenses, including those applied in the past.

## View license details and history

To view your license details:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.

You can add and view more than one license, but only the latest license in
the current date range is the active license.

When you add a future-dated license, it doesn't take effect until its applicable date.
You can view all active subscriptions in the **Subscription history** table.

You can also [export](../subscriptions/self_managed/_index.md) your license usage information to a CSV file.

## License commands in the Rails console

The following commands can be run in the [Rails console](operations/rails_console.md#starting-a-rails-console-session).

WARNING:
Any command that changes data directly could be damaging if not run correctly, or under the right conditions.
We highly recommend running them in a test environment with a backup of the instance ready to be restored, just in case.

### See current license information

```ruby
# License information (name, company, email address)
License.current.licensee

# Plan:
License.current.plan

# Uploaded:
License.current.created_at

# Started:
License.current.starts_at

# Expires at:
License.current.expires_at

# Is this a trial license?
License.current.trial?

# License ID for lookup on CustomersDot
License.current.license_id

# License data in Base64-encoded ASCII format
License.current.data

# Confirm the current billable seat count excluding guest users. This is useful for customers who use an Ultimate subscription tier where Guest seats are not counted.
User.active.without_bots.excluding_guests_and_requests.count

```

#### Interaction with licenses that start in the future

```ruby
# Future license data follows the same format as current license data it just uses a different modifier for the License prefix
License.future_dated
```

### Check if a project feature is available on the instance

Features listed in [`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb).

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

#### Check if a project feature is available in a project

Features listed in [`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb).

```ruby
p = Project.find_by_full_path('<group>/<project>')
p.feature_available?(:jira_dev_panel_integration)
```

### Add a license through the console

#### Using a `key` variable

```ruby
key = "<key>"
license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

#### Using a license file

```ruby
license_file = File.open("/tmp/Gitlab.license")

key = license_file.read.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"

license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

These snippets can be saved to a file and executed [using the Rails Runner](operations/rails_console.md#using-the-rails-runner) so the
license can be applied through shell automation scripts.

This is needed for example in a known edge-case with
[expired license and multiple LDAP servers](auth/ldap/ldap-troubleshooting.md#expired-license-causes-errors-with-multiple-ldap-servers).

### Remove licenses

To clean up the [License History table](license_file.md#view-license-details-and-history):

```ruby
TYPE = :trial?
# or :expired?

License.select(&TYPE).each(&:destroy!)

# or even License.all.each(&:destroy!)
```

## Troubleshooting

### No Subscription area in the Admin area

You cannot add your license because there is no **Subscription** area.
This issue might occur if:

- You're running GitLab Community Edition. Before you add your license, you
  must [upgrade to Enterprise Edition](../update/_index.md#community-to-enterprise-edition).
- You're using GitLab.com. You cannot add a GitLab Self-Managed license to GitLab.com.
  To use paid features on GitLab.com, [purchase a separate subscription](../subscriptions/gitlab_com/_index.md).

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

### `Start GitLab Ultimate trial` still displays after adding license

To fix this issue, restart [Puma or your entire GitLab instance](restart_gitlab.md).

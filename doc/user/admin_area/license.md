---
stage: Growth
group: Conversion
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Activate GitLab Enterprise Edition (EE) **(PREMIUM SELF)**

When you install a new GitLab instance without a license, it only has the Free features
enabled. To enable all features of GitLab Enterprise Edition (EE), activate
your instance with an activation code or a license file. When [the license expires](#what-happens-when-your-license-expires),
some functionality is locked.

## Verify your GitLab edition

To activate your instance, make sure you are running GitLab Enterprise Edition (EE).

To verify the edition, sign in to GitLab and select
**Help** (**{question-o}**) > **Help**. The GitLab edition and version are listed
at the top of the page.

If you are running GitLab Community Edition (CE), upgrade your installation to GitLab
EE. For more details, see [Upgrading between editions](../../update/index.md#upgrading-between-editions).
If you have questions or need assistance upgrading from GitLab CE to EE,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

## Activate GitLab EE with an activation code

In GitLab Enterprise Edition 14.1 and later, you need an activation code to activate
your instance. To get an activation code you have to [purchase a license](https://about.gitlab.com/pricing/).
The activation code is a 24-character alphanumeric string you receive in a confirmation email.
You can also sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in)
to copy the activation code to your clipboard.

To activate your instance with an activation code:

1. Sign in to your GitLab self-managed instance.
1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Subscription**.
1. Enter the activation code in **Activation code**.
1. Read and accept the terms of service.
1. Select **Activate**.

## Activate GitLab EE with a license file

If you receive a license file from GitLab (for example, for a trial), you can
upload it to your instance or add it during installation. The license file is
a base64-encoded ASCII text file with a `.gitlab-license` extension.

## Upload your license

The first time you sign in to your GitLab instance, a note with a
link to the **Upload license** page should be displayed.

Otherwise, to upload your license:

1. Sign in to GitLab as an administrator.
1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings**.
1. In the **License file** area, select **Upload a license**.
1. Upload a license:
   - For a file, either:
     - Select **Upload `.gitlab-license` file**, then **Choose File** and
       select the license file from your local machine.
     - Drag and drop the license file to the **Drag your license file here** area.
   - For plain text, select **Enter license key** and paste the contents in
     **License key**.
1. Select the **Terms of Service** checkbox.
1. Select **Upload License**.

## Add your license during installation

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
a license, upload the license in the **Admin Area** in the web user interface.

## What happens when your license expires

Fifteen days before the license expires, a notification banner with the upcoming expiration
date displays to GitLab administrators.

When your license expires, GitLab locks features, like Git pushes
and issue creation. Your instance becomes read-only and
an expiration message displays to all administrators. You have a 14-day grace period
before this occurs.

To resume functionality, [upload a new license](#upload-your-license).

To go back to Free features, [delete all expired licenses](#remove-a-license-file).

## Remove a license file

To remove a license file from a self-managed instance:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Subscription**.
1. Select **Remove license**.

Repeat these steps to remove all licenses, including those applied in the past.

## View license details and history

To view your license details:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Subscription**.

You can upload and view more than one license, but only the latest license in
the current date range is the active license.

When you upload a future-dated license, it doesn't take effect until its applicable date.
You can view all active subscriptions in the **Subscription history** table.

You can also [export](../../subscriptions/self_managed/index.md) your license usage information to a CSV file.

NOTE:
In GitLab 13.6 and earlier, a banner about an expiring license may continue to display
when you upload a new license. This happens when the start date of the new license
is in the future and the expiring one is still active.
The banner disappears after the new license becomes active.

## Troubleshooting

### No Subscription area in the Admin Area

You cannot upload your license because there is no **Subscription** area.
This issue might occur if:

- You're running GitLab Community Edition. Before you upload your license, you
  must [upgrade to Enterprise Edition](../../update/index.md#community-to-enterprise-edition).
- You're using GitLab.com. You cannot upload a self-managed license to GitLab.com.
  To use paid features on GitLab.com, [purchase a separate subscription](../../subscriptions/gitlab_com/index.md).

### Users exceed license limit upon renewal

GitLab displays a message prompting you to purchase
additional users. This issue occurs if you upload a license that does not have enough
users to cover the number of users in your instance.

To fix this issue, purchase additional seats to cover those users.
For more information, read the [licensing FAQ](https://about.gitlab.com/pricing/licensing-faq/).

In GitLab 14.2 and later, for instances that use a license file, the following
rules apply:

- If the users over license are less than or equal to 10% of the users in the license
  file, the license is applied and you pay the overage in the next renewal.
- If the users over license are more than 10% of the users in the license file,
  you cannot apply the license without purchasing more users.

For example, if you purchase a license for 100 users, you can have 110 users when you activate
your license. However, if you have 111 users, you must purchase more users before you can activate
the license.

### Cannot activate instance due to connectivity error

In GitLab 14.1 and later, to activate your subscription with an activation code,
your GitLab instance must be connected to the internet.

If you have an offline or airgapped environment,
[upload a license file](license.md#activate-gitlab-ee-with-a-license-file) instead.

If you have questions or need assistance activating your instance,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

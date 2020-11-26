---
stage: Growth
group: Conversion
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Activate GitLab EE with a license **(STARTER ONLY)**

To activate all GitLab Enterprise Edition (EE) functionality, you need to upload
a license. It's only possible to activate GitLab Enterprise Edition, so first verify which edition
you are running. To verify, sign in to GitLab and browse to `/help`. The GitLab edition and version
are listed at the top of the **Help** page.

If you are running GitLab Community Edition (CE), upgrade your installation to
GitLab Enterprise Edition (EE). For more details, see [Upgrading between editions](../../update/README.md#upgrading-between-editions).
If you have questions or need assistance upgrading from GitLab CE to EE please [contact GitLab Support](https://about.gitlab.com/support/#contact-support).

The license is a base64-encoded ASCII text file with a `.gitlab-license`
extension. You can obtain the file by [purchasing a license](https://about.gitlab.com/pricing/)
or by signing up for a [free trial](https://about.gitlab.com/free-trial/).

After you've received your license from GitLab Inc., you can upload it
by **signing into your GitLab instance as an admin** or adding it at
installation time.

As of GitLab Enterprise Edition 9.4.0, a newly-installed instance without an
uploaded license only has the Core features active. A trial license
activates all Ultimate features, but after
[the trial expires](#what-happens-when-your-license-expires), some functionality
is locked.

## Uploading your license

The very first time you visit your GitLab EE installation signed in as an admin,
you should see a note urging you to upload a license with a link that takes you
to **Admin Area > License**.

Otherwise, you can:

1. Navigate manually to the **Admin Area** by clicking the wrench (**{admin}**) icon in the menu bar.

1. Navigate to the **License** tab, and click **Upload New License**.

   ![License Admin Area](img/license_admin_area.png)

   - *If you've received a `.gitlab-license` file,* you should have already downloaded
     it in your local machine. You can then upload it directly by choosing the
     license file and clicking the **Upload license** button. In the image below,
     the selected license file is named `GitLab.gitlab-license`.

     ![Upload license](img/license_upload.png)

   - *If you've received your license as plain text,* select the
     **Enter license key** option, copy the license, paste it into the **License key**
     field, and click **Upload license**.

## Add your license at install time

A license can be automatically imported at install time by placing a file named
`Gitlab.gitlab-license` in `/etc/gitlab/` for Omnibus GitLab, or `config/` for source installations.

You can also specify a custom location and filename for the license:

- Source installations should set the `GITLAB_LICENSE_FILE` environment
  variable with the path to a valid GitLab Enterprise Edition license.

  ```shell
  export GITLAB_LICENSE_FILE="/path/to/license/file"
  ```

- Omnibus GitLab installations should add this entry to `gitlab.rb`:

  ```ruby
  gitlab_rails['initial_license_file'] = "/path/to/license/file"
  ```

CAUTION: **Caution:**
These methods only add a license at the time of installation. Use the
**{admin}** **Admin Area** in the web user interface to renew or upgrade licenses.

---

After the license is uploaded, all GitLab Enterprise Edition functionality
is active until the end of the license period. When that period ends, the
instance will [fall back](#what-happens-when-your-license-expires) to Core-only
functionality.

You can review the license details at any time in the **License** section of the
**Admin Area**.

![License details](img/license_details.png)

## Notification before the license expires

One month before the license expires, a message informing about the expiration
date is displayed to GitLab admins. Make sure that you update your
license, otherwise you miss all the paid features if your license expires.

## What happens when your license expires

In case your license expires, GitLab locks down some features like Git pushes,
and issue creation, and displays a message to all admins to inform of the expired license.

To get back all the previous functionality, you must upload a new license.
To fall back to having only the Core features active, you must delete the
expired license(s).

### Remove a license

To remove a license from a self-managed instance:

1. In the top navigation bar, click the **{admin}** wrench icon to navigate to the [Admin Area](index.md).
1. Click **License** in the left sidebar.
1. Click **Remove License**.

## License history

You can upload and view more than one license, but only the latest license in the current date
range is used as the active license. When you upload a future-dated license, it
doesn't take effect until its applicable date.

## Troubleshooting

### There is no License tab in the Admin Area

If you originally installed Community Edition rather than Enterprise Edition you must
[upgrade to Enterprise Edition](../../update/README.md#community-to-enterprise-edition)
before uploading your license.

GitLab.com users can't upload and use a self-managed license. If you
want to use paid features on GitLab.com, you can
[purchase a separate subscription](../../subscriptions/gitlab_com/index.md).

### Users exceed license limit upon renewal

If you've added new users to your GitLab instance prior to renewal, you may need to
purchase additional seats to cover those users. If this is the case, and a license
without enough users is uploaded, GitLab displays a message prompting you to purchase
additional users. More information on how to determine the required number of users
and how to add additional seats can be found in the
[licensing FAQ](https://about.gitlab.com/pricing/licensing-faq/).

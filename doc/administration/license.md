---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Activate GitLab Enterprise Edition (EE)
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

When you install a new GitLab instance without a license, only Free features
are enabled. To enable more features in GitLab Enterprise Edition (EE), activate
your instance with an activation code.

## Activate GitLab EE

Prerequisites:

- You must [purchase a subscription](https://about.gitlab.com/pricing/).
- You must be running GitLab Enterprise Edition (EE).
- Your instance must be connected to the internet.

To activate your instance with an activation code:

1. Copy the activation code, a 24-character alphanumeric string, from either:
   - Your subscription confirmation email.
   - The [Customers Portal](https://customers.gitlab.com/customers/sign_in), on the **Manage Purchases** page.
1. Sign in to your instance.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.
1. Paste the activation code in **Activation code**.
1. Read and accept the terms of service.
1. Select **Activate**.

The subscription is activated.

### Using one activation code for multiple instances

You can use a single activation code or license key for multiple GitLab Self-Managed instances if the users are:

- Identical to your licensed production instance.
- A subset of your licensed production instance.

The activation code is valid for these instances, regardless of how users are configured in groups and projects.

### For scaled architectures

To activate your instance in a scaled architecture:

- Upload the license file to one application instance only.

The license is stored in the database and is replicated to all instances.

### For GitLab Geo

To activate your instance when using GitLab Geo:

- Upload the license to your primary Geo instance.

The license is stored in the database and is replicated to all instances.

### For offline environments

To activate your instance for an offline environment:

- [Activate GitLab EE with a license file or key](license_file.md).

If you have questions or need assistance activating your instance,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

When [the license expires](license_file.md#what-happens-when-your-license-expires),
some functionality is locked.

## Verify your GitLab edition

To verify the edition, sign in to GitLab and select
**Help** (**{question-o}**) > **Help**. The GitLab edition and version are listed
at the top of the page.

If you are running GitLab Community Edition (CE), you can upgrade your installation to GitLab
EE. For more details, see [Upgrading between editions](../update/_index.md#upgrading-between-editions).

If you have questions or need assistance,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

## Troubleshooting

When activating your paid subscription features on GitLab Self-Managed instances, you might encounter the following issues.

### Error: `An error occurred while adding your subscription`

This issue might occur after you enter your activation code.

To find more details about the error, you can use your browser's developer tools:

1. To open developer tools, right-click on a page and select **Inspect**.
1. Select the **Network** tab.
1. In GitLab, retry the activation code.
1. In the **Network** tab, select the `graphql` entry.
1. Select the **Response** tab, and check for an error similar to:

      ```plaintext
      [{"data":{"gitlabSubscriptionActivate":{"errors":["<error> returned=1 errno=0 state=error: <error>"],"license":null,"__typename":"GitlabSubscriptionActivatePayload"}}}]
      ```

To resolve the issue:

- If the GraphQL response includes `only get, head, options, and trace methods are allowed in silent mode`, disable [silent mode](silent_mode/_index.md#disable-silent-mode) for your instance.

If you are unable to determine the issue, contact [GitLab Support](https://about.gitlab.com/support/portal/) and provide the GraphQL response in your description of the issue.

### Cannot activate instance due to connectivity error

When activating your instance, you may encounter connectivity issues preventing connection to GitLab servers.
This can be caused by:

- **Firewall settings**:
  - To confirm that your GitLab instance can establish an encrypted connection to `https://customers.gitlab.com` on port 443, use the following curl command:

    ```shell
    curl --verbose "https://customers.gitlab.com/"
    ```

  - If the curl command returns an error, either:
    - Check your firewall or proxy. The domain `https://customers.gitlab.com` is
      fronted by Cloudflare. Ensure your firewall or proxy allows traffic to the Cloudflare
      [IPv4](https://www.cloudflare.com/ips-v4/) and
      [IPv6](https://www.cloudflare.com/ips-v6/) ranges for activation to work.
    - [Configure a proxy](https://docs.gitlab.com/omnibus/settings/environment-variables.html)
      in `gitlab.rb` to point to your server.

    Contact your network administrator to make changes to an existing proxy or firewall.
  - If an SSL inspection appliance is used, you must add the appliance's root CA certificate to `/etc/gitlab/trusted-certs` on your instance, then run `gitlab-ctl reconfigure`.

- **Customers Portal is not operational**:
  - Check for any active disruptions to the Customers Portal on [status](https://status.gitlab.com/).

- **An offline environment**:
  - If you are unable to configure your setup to allow connection to GitLab servers, contact your Sales Representative to request an [Offline license](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-an-offline-cloud-license).

    For assistance finding your sales representative you can contact [GitLab support](https://about.gitlab.com/support/#contact-support).

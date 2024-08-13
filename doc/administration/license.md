---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Activate GitLab Enterprise Edition (EE)

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

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
1. Sign in to your GitLab self-managed instance.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.
1. Paste the activation code in **Activation code**.
1. Read and accept the terms of service.
1. Select **Activate**.

The subscription is activated.

### Using one activation code for multiple instances

You can use one activation code or license key for multiple self-managed instances if the users on
these instances are the same or are a subset of your licensed production instance. This means that if
you have a licensed production instance of GitLab, and other instances with the same list of users, the
production activation code applies, even if these users are configured in different groups and projects.

### Uploading licenses for scaled architectures

In a scaled architecture, upload the license file to one application instance only. The license is stored in the
database and is replicated to all your application instances so that you do not need to upload the license to all instances.

### Uploading licenses for GitLab Geo

When using GitLab Geo, you only need to upload the license to your primary Geo instance. The license is stored in the database and is replicated to all instances.

If you have an offline environment,
[activate GitLab EE with a license file or key](license_file.md) instead.

If you have questions or need assistance activating your instance,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

When [the license expires](../administration/license_file.md#what-happens-when-your-license-expires),
some functionality is locked.

## Verify your GitLab edition

To verify the edition, sign in to GitLab and select
**Help** (**{question-o}**) > **Help**. The GitLab edition and version are listed
at the top of the page.

If you are running GitLab Community Edition, you can upgrade your installation to GitLab
EE. For more details, see [Upgrading between editions](../update/index.md#upgrading-between-editions).
If you have questions or need assistance upgrading from GitLab Community Edition (CE) to EE,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

## Troubleshooting

## `An error occurred while adding your subscription`

This might occur when you activate your subscription. You can use Chrome developer tools to find more information about the type of error.

1. To open your browser developer tools, right-click in a page in your browser and select **Inspect**.
1. In your browser developer tools, select the **Network** tab.
1. In GitLab, retry the activation code.
1. In the browser developer tools, in the **Network** tab, select the **graphql** entry.
1. Select the **Response** tab.

There should be an error similar to the following that you can use to determine the issue:

```plaintext
[{"data":{"gitlabSubscriptionActivate":{"errors":["<error> returned=1 errno=0 state=error: <error>"],"license":null,"__typename":"GitlabSubscriptionActivatePayload"}}}]
```

- If `only get, head, options, and trace methods are allowed in silent mode` is in the GraphQL **Response**, your instance has [Silence mode enabled](../administration/silent_mode/index.md) and should be disabled.
- If you are unable to determine the issue, please contact [GitLab Support](https://about.gitlab.com/support/portal/) and provide the GraphQL response in your description of the issue.

### Cannot activate instance due to connectivity error

This error occurs when you use an activation code to activate your instance, but your instance is unable to connect to the GitLab servers.

You may have connectivity issues due to the following reasons:

- **Firewall settings**:
  - Confirm that GitLab instance can establish an encrypted connection to `https://customers.gitlab.com` on port 443.

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

- **You have an offline environment**:
  - If you are unable to configure your setup to allow connection to GitLab servers, contact your Sales Representative to request an [Offline license](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-an-offline-cloud-license).

    For assistance finding your sales representative you can contact [GitLab support](https://about.gitlab.com/support/#contact-support).

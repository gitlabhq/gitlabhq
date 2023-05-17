---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Activate GitLab Enterprise Edition (EE) **(PREMIUM SELF)**

When you install a new GitLab instance without a license, only Free features
are enabled. To enable more features in GitLab Enterprise Edition (EE), activate
your instance with an activation code.

## Activate GitLab EE

In GitLab Enterprise Edition 14.1 and later, you need an activation code to activate
your instance.

Prerequisite:

- You must [purchase a subscription](https://about.gitlab.com/pricing/).
- You must be running GitLab Enterprise Edition (EE).
- You must have GitLab 14.1 or later.
- Your instance must be connected to the internet.

To activate your instance with an activation code:

1. Copy the activation code, a 24-character alphanumeric string, from either:
   - Your subscription confirmation email.
   - The [Customers Portal](https://customers.gitlab.com/customers/sign_in), on the **Manage Purchases** page.
1. Sign in to your GitLab self-managed instance.
1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Subscription**.
1. Paste the activation code in **Activation code**.
1. Read and accept the terms of service.
1. Select **Activate**.

The subscription is activated.

If you have an offline environment,
[activate GitLab EE with a license file or key](license_file.md) instead.

If you have questions or need assistance activating your instance,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

When [the license expires](license_file.md#what-happens-when-your-license-expires),
some functionality is locked.

## Verify your GitLab edition

To verify the edition, sign in to GitLab and select
**Help** (**{question-o}**) > **Help**. The GitLab edition and version are listed
at the top of the page.

If you are running GitLab Community Edition, you can upgrade your installation to GitLab
EE. For more details, see [Upgrading between editions](../../update/index.md#upgrading-between-editions).
If you have questions or need assistance upgrading from GitLab Community Edition (CE) to EE,
[contact GitLab Support](https://about.gitlab.com/support/#contact-support).

## Troubleshooting

### Cannot activate instance due to connectivity error

This error occurs when you use an activation code to activate your instance, but your instance is unable to connect to the GitLab servers.

You may have connectivity issues due to the following reasons:

- **You have an offline environment**:
  - Configure your setup to allow connection to GitLab servers. If connection to GitLab servers is not possible, contact your Sales Representative to request a license key. You can also contact [GitLab support](https://about.gitlab.com/support/#contact-support) if you need help finding your Sales Representative.
- **Customers Portal is not operational**:
  - To check for performance or service disruptions, check the Customers Portal [status](https://status.gitlab.com/).
- **Firewall settings**:
  - Check if your GitLab instance has an encrypted connection to `customers.gitlab.com` (with IP addresses 172.64.146.11 and 104.18.41.245) on port 443:

   ```shell
   curl --verbose "https://customers.gitlab.com/"
   ```

  - If the curl command returns a failure, either:
    - [Configure a proxy](https://docs.gitlab.com/omnibus/settings/environment-variables.html) in `gitlab.rb` to point to your server.
    - Contact your network administrator to make changes to the proxy.
  - If an SSL inspection appliance is used, you must add the appliance's root CA certificate to `/etc/gitlab/trusted-certs` on the server, then run `gitlab-ctl reconfigure`.
  
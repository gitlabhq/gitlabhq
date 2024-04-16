---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Jira Cloud app administration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

NOTE:
This page contains administrator documentation for the GitLab for Jira Cloud app. For user documentation, see [GitLab for Jira Cloud app](../../integration/jira/connect-app.md).

With the [GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud) app, you can connect GitLab and Jira Cloud to sync development information in real time. You can view this information in the [Jira development panel](../../integration/jira/development_panel.md).

You can use the GitLab for Jira Cloud app to link top-level groups or subgroups. It's not possible to directly link projects or personal namespaces.

To set up the GitLab for Jira Cloud app on your self-managed instance, do one of the following:

- [Connect the GitLab for Jira Cloud app](#connect-the-gitlab-for-jira-cloud-app) (GitLab 15.7 and later).
- [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

After you set up the app, you can use the [project toolchain](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-project-toolchain-in-jira/)
developed and maintained by Atlassian to [link GitLab repositories to Jira projects](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature).
The project toolchain does not affect how development information is synced between GitLab and Jira Cloud.

For Jira Data Center or Jira Server, use the [Jira DVCS connector](../../integration/jira/dvcs/index.md) developed and maintained by Atlassian.

## Set up OAuth authentication

You must set up OAuth authentication to:

- [Connect the GitLab for Jira Cloud app](#connect-the-gitlab-for-jira-cloud-app).
- [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

To create an OAuth application on your self-managed instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Applications**.
1. Select **New application**.
1. In **Redirect URI**:
   - If you're installing the app from the official marketplace listing, enter `https://gitlab.com/-/jira_connect/oauth_callbacks`.
   - If you're installing the app manually, enter `<instance_url>/-/jira_connect/oauth_callbacks` and replace `<instance_url>` with the URL of your instance.
1. Clear the **Trusted** and **Confidential** checkboxes.

   NOTE:
   You must clear these checkboxes to avoid errors.
1. In **Scopes**, select the `api` checkbox only.
1. Select **Save application**.
1. Copy the **Application ID** value.
1. On the left sidebar, select **Settings > General**.
1. Expand **GitLab for Jira App**.
1. Paste the **Application ID** value into **Jira Connect Application ID**.
1. Select **Save changes**.

## Jira user requirements

> - Support for the `org-admins` group [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420687) in GitLab 16.6.

In your [Atlassian organization](https://admin.atlassian.com), you must ensure that the Jira user that is used to set up the GitLab for Jira Cloud app is a member of
either:

- The Organization Administrators (`org-admins`) group. Newer Atlassian organizations are using
  [centralized user management](https://support.atlassian.com/user-management/docs/give-users-admin-permissions/#Centralized-user-management-content),
  which contains the `org-admins` group. Existing Atlassian organizations are being migrated to centralized user management.
  If available, you should use the `org-admins` group to indicate which Jira users can manage the GitLab for Jira app. Alternatively you can use the
  `site-admins` group.
- The Site Administrators (`site-admins`) group. The `site-admins` group was used under
  [original user management](https://support.atlassian.com/user-management/docs/give-users-admin-permissions/#Original-user-management-content).

If necessary:

1. [Create your preferred group](https://support.atlassian.com/user-management/docs/create-groups/).
1. [Edit the group](https://support.atlassian.com/user-management/docs/edit-a-group/) to add your Jira user as a member of it.
1. If you customized your global permissions in Jira, you might also need to grant the
   [`Browse users and groups` permission](https://confluence.atlassian.com/jirakb/unable-to-browse-for-users-and-groups-120521888.html) to the Jira user.

## Connect the GitLab for Jira Cloud app

> - Introduced in GitLab 15.7.

You can link your self-managed instance after you install the GitLab for Jira Cloud app from the marketplace.
Jira apps can only link to one URL per marketplace listing. The official listing links to GitLab.com.

With this method:

- GitLab.com serves as a proxy for Jira traffic from your instance.
- It's not possible to create branches from Jira Cloud.
  For more information, see [issue 391432](https://gitlab.com/gitlab-org/gitlab/-/issues/391432).

[Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually) if:

- Your instance does not meet the [prerequisites](#prerequisites).
- You do not want to use the official marketplace listing.
- You want to create branches from Jira Cloud.

### Prerequisites

- The instance must be publicly available.
- The instance must be on GitLab version 15.7 or later.
- You must set up [OAuth authentication](#set-up-oauth-authentication).
- If your instance uses HTTPS, your GitLab certificate must be publicly trusted or contain the full chain certificate.
- Your network must allow inbound and outbound connections between GitLab and Jira. For self-managed instances that are behind a
  firewall and cannot be directly accessed from the internet:
  - Open your firewall and allow inbound traffic from [Atlassian IP addresses](https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/#Outgoing-Connections) only.
  - Set up an internet-facing [reverse proxy](#using-a-reverse-proxy) in front of your self-managed instance.
  - Add [GitLab IP addresses](../../user/gitlab_com/index.md#ip-range) to the allowlist of your firewall.
- The Jira user that installs and configures the app must meet certain [requirements](#jira-user-requirements).

### Set up your instance

[Prerequisites](#prerequisites)

To set up your self-managed instance for the GitLab for Jira Cloud app in GitLab 15.7 and later:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **GitLab for Jira App**.
1. In **Jira Connect Proxy URL**, enter `https://gitlab.com`.
1. Select **Save changes**.

### Link your instance

[Prerequisites](#prerequisites)

To link your self-managed instance to the GitLab for Jira Cloud app:

1. Install the [GitLab for Jira Cloud app](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).
1. [Configure the GitLab for Jira Cloud app](../../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app).
1. Optional. [Check if Jira Cloud is now linked](#check-if-jira-cloud-is-linked).

#### Check if Jira Cloud is linked

You can use the [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session)
to check if Jira Cloud is linked to:

- A specific group:

  ```ruby
  JiraConnectSubscription.where(namespace: Namespace.by_path('group/subgroup'))
  ```

- A specific project:

  ```ruby
  Project.find_by_full_path('path/to/project').jira_subscription_exists?
  ```

- Any group:

  ```ruby
  installation = JiraConnectInstallation.find_by_base_url("https://customer_name.atlassian.net")
  installation.subscriptions
  ```

## Install the GitLab for Jira Cloud app manually

If you do not want to [use the official marketplace listing](#connect-the-gitlab-for-jira-cloud-app),
install the GitLab for Jira Cloud app manually.

You must install each Jira Cloud app from a single location. Jira fetches a
[manifest file](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/)
from the location you provide. The manifest file describes the app to the system.

To support your self-managed instance with Jira Cloud, do one of the following:

- [Install the app in development mode](#install-the-app-in-development-mode).
- [Create a marketplace listing](#create-a-marketplace-listing).

### Prerequisites

- The instance must be publicly available.
- You must set up [OAuth authentication](#set-up-oauth-authentication).
- Your network must allow inbound and outbound connections between GitLab and Jira. For self-managed instances that are behind a
  firewall and cannot be directly accessed from the internet:
  - Open your firewall and allow inbound traffic from [Atlassian IP addresses](https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/#Outgoing-Connections) only.
  - Set up an internet-facing [reverse proxy](#using-a-reverse-proxy) in front of your self-managed instance.
  - Add [GitLab IP addresses](../../user/gitlab_com/index.md#ip-range) to the allowlist of your firewall.
- The Jira user that installs and configures the app must meet certain [requirements](#jira-user-requirements).

### Install the app in development mode

[Prerequisites](#prerequisites-1)

To configure your Jira instance so you can install apps from outside the marketplace:

1. Sign in to your Jira instance as an administrator.
1. [Enable development mode](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-3--enable-development-mode-in-your-site)
   on your Jira instance.
1. Sign in to GitLab as an administrator.
1. [Install GitLab from your Jira instance](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-3--install-and-test-your-app):
   1. On your Jira instance, go to **Apps > Manage Apps** and select **Upload app**.
   1. In **App descriptor URL**, provide the full URL to your manifest file based
      on your instance configuration.

      By default, your manifest file is located at `/-/jira_connect/app_descriptor.json`.
      For example, if your GitLab self-managed instance domain is `app.pet-store.cloud`,
      your manifest file is located at `https://app.pet-store.cloud/-/jira_connect/app_descriptor.json`.

   1. Select **Upload**.
   1. Select **Get started** to configure the integration.
1. [Disable development mode](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-3--enable-development-mode-in-your-site)
   on your Jira instance.

In **Apps > Manage Apps**, **GitLab for Jira Cloud** is now visible.
You can also select **Get started** to [configure the GitLab for Jira Cloud app](../../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app).

If a GitLab upgrade makes changes to the app descriptor, you must reinstall the app.

### Create a marketplace listing

[Prerequisites](#prerequisites-1)

If you do not want to [use development mode](#install-the-app-in-development-mode), you can create your own marketplace listing.
This way, you can install the GitLab for Jira Cloud app from the Atlassian Marketplace.

To create a marketplace listing:

1. Register as an Atlassian Marketplace vendor.
1. List your application with the application descriptor URL.
   - Your manifest file is located at: `https://your.domain/your-path/-/jira_connect/app_descriptor.json`
   - You should list your application as `private` because public
     applications can be viewed and installed by any user.
1. Generate test license tokens for your application.

Like the GitLab.com marketplace listing, this method uses
[automatic updates](../../integration/jira/connect-app.md#update-the-gitlab-for-jira-cloud-app).

For more information about creating a marketplace listing, see the
[Atlassian documentation](https://developer.atlassian.com/platform/marketplace/listing-connect-apps/#create-your-marketplace-listing).

## Configure your GitLab instance to serve as a proxy

A GitLab instance can serve as a proxy for other GitLab instances through the GitLab for Jira Cloud app.
You might want to use a proxy if you're managing multiple GitLab instances but only want to
[manually install](#install-the-gitlab-for-jira-cloud-app-manually) the app once.

To configure your GitLab instance to serve as a proxy:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **GitLab for Jira App**.
1. Select **Enable public key storage**.
1. Select **Save changes**.
1. [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

Other GitLab instances that use the proxy must configure the following settings to point to the proxy instance:

- [**Jira Connect Proxy URL**](#set-up-your-instance)
- [**Redirect URI**](#set-up-oauth-authentication)

## Security considerations

The GitLab for Jira Cloud app connects GitLab and Jira. Data must be shared between the two applications, and access must be granted in both directions.

### Using GitLab.com as a proxy

When you use [GitLab.com as a proxy](#configure-your-gitlab-instance-to-serve-as-a-proxy),
the Jira access token is shared with GitLab.com.

The Jira access token is stored on GitLab.com because the token must be used to verify
incoming requests from Jira before the requests are sent to your self-managed instance.
The token is encrypted and is not used to access data in Jira.
Any data from your self-managed instance is sent directly to Jira.

### Access to GitLab through OAuth

GitLab does not share an access token with Jira. However, users must authenticate through OAuth to configure the app.

An access token is retrieved through a [PKCE](https://www.rfc-editor.org/rfc/rfc7636) OAuth flow and stored only on the client side.
The app frontend that initializes the OAuth flow is a JavaScript application that's loaded from GitLab through an iframe on Jira.

The OAuth application must have the `api` scope, which grants complete read and write access to the API.
This access includes all groups and projects, the container registry, and the package registry.
However, the GitLab for Jira Cloud app only uses this access to:

- Display groups to link.
- Link groups.

Access through OAuth is only needed for the time a user configures the GitLab for Jira Cloud app. For more information, see [Access token expiration](../../integration/oauth_provider.md#access-token-expiration).

## Using a reverse proxy

To use the GitLab for Jira Cloud app on a self-managed instance that cannot be accessed
from the internet, the self-managed instance must be accessible from Jira Cloud.
You can use a reverse proxy, but keep the following in mind:

- When you [connect the GitLab for Jira Cloud app](#connect-the-gitlab-for-jira-cloud-app),
  use a client with access to both the internal GitLab FQDN and the reverse proxy FQDN.
- When you [install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually),
  use the reverse proxy FQDN for **Redirect URI** to [set up OAuth authentication](#set-up-oauth-authentication).
- The reverse proxy must meet the prerequisites for your installation method:
  - [Prerequisites for connecting the GitLab for Jira Cloud app](#prerequisites).
  - [Prerequisites for installing the GitLab for Jira Cloud app manually](#prerequisites-1).
- The [Jira development panel](../../integration/jira/development_panel.md) might link
  to the internal GitLab FQDN or GitLab.com instead of the reverse proxy FQDN.
  For more information, see [issue 434085](https://gitlab.com/gitlab-org/gitlab/-/issues/434085).
- To secure the reverse proxy on the public internet, allow inbound traffic from
  [Atlassian IP addresses](https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/#Outgoing-Connections) only.

### External NGINX

This server block is an example of how to configure a reverse proxy for GitLab that works with Jira Cloud:

```json
server {
  listen *:80;
  server_name gitlab.mycompany.com;
  server_tokens off;
  location /.well-known/acme-challenge/ {
    root /var/www/;
  }
  location / {
    return 301 https://gitlab.mycompany.com:443$request_uri;
  }
}
server {
  listen *:443 ssl;
  server_tokens off;
  server_name gitlab.mycompany.com;
  ssl_certificate /etc/letsencrypt/live/gitlab.mycompany.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/gitlab.mycompany.com/privkey.pem;
  ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
  ssl_protocols  TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers off;
  ssl_session_cache  shared:SSL:10m;
  ssl_session_tickets off;
  ssl_session_timeout  1d;
  access_log "/var/log/nginx/proxy_access.log";
  error_log "/var/log/nginx/proxy_error.log";
  location / {
    proxy_pass https://gitlab.internal;
    proxy_hide_header upgrade;
    proxy_set_header Host             gitlab.mycompany.com:443;
    proxy_set_header X-Real-IP        $remote_addr;
    proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
  }
}
```

In this example:

- Replace `gitlab.mycompany.com` with the reverse proxy FQDN
  and `gitlab.internal` with the internal GitLab FQDN.
- Set `ssl_certificate` and `ssl_certificate_key` to a valid certificate
  (the example uses [Certbot](https://certbot.eff.org/)).
- Set the `Host` proxy header to the reverse proxy FQDN
  to ensure GitLab and Jira Cloud can connect successfully.

You must use the reverse proxy FQDN only to connect Jira Cloud to GitLab.
You must continue to access GitLab from the internal GitLab FQDN.
If you access GitLab from the reverse proxy FQDN, GitLab might not work as expected.
For more information, see [issue 21319](https://gitlab.com/gitlab-org/gitlab/-/issues/21319).

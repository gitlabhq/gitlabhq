---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for Jira Cloud app administration
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

> [!note]
> This page contains administrator documentation for the GitLab for Jira Cloud app. For user documentation, see [GitLab for Jira Cloud app](../../integration/jira/connect-app.md).

With the [GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud) app, you can connect GitLab and Jira Cloud to sync development information in real time. You can view this information in the [Jira development panel](../../integration/jira/development_panel.md).

To set up the GitLab for Jira Cloud app on your GitLab Self-Managed instance, do one of the following:

- [Install the GitLab for Jira Cloud app from the Atlassian Marketplace](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace) (GitLab 15.7 and later).
- [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see:

- [Installing the GitLab for Jira Cloud app from the Atlassian Marketplace for a GitLab Self-Managed instance](https://youtu.be/RnDw4PzmdW8?list=PL05JrBw4t0Koazgli_PmMQCER2pVH7vUT)
  <!-- Video published on 2024-10-30 -->
- [Installing the GitLab for Jira Cloud app manually for a GitLab Self-Managed instance](https://youtu.be/fs02xS8BElA?list=PL05JrBw4t0Koazgli_PmMQCER2pVH7vUT)
  <!-- Video published on 2024-10-30 -->

The videos above show the older [Universal Plugin Manager interface](https://community.atlassian.com/forums/Community-Announcements-articles/Cloud-admins-we-re-making-app-management-easier/ba-p/2806285) which might be unavailable on newer Jira Cloud instances.
The following instructions cover both old and new app management interfaces.

If you [install the GitLab for Jira Cloud app from the Atlassian Marketplace](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace),
you can use the [project toolchain](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-connections-feature/) developed and maintained
by Atlassian to [link GitLab repositories to Jira projects](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature).
The project toolchain does not affect how development information is synced between GitLab and Jira Cloud.

For Jira Data Center or Jira Server, use the [Jira DVCS connector](../../integration/jira/dvcs/_index.md) developed and maintained by Atlassian.

## Set up OAuth authentication

Whether you want to install the GitLab for Jira Cloud app [from the Atlassian Marketplace](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace) or [manually](#install-the-gitlab-for-jira-cloud-app-manually), you must create an OAuth application.

Prerequisites:

- Administrator access.

To create an OAuth application on your GitLab Self-Managed instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Applications**.
1. Select **New application**.
1. In **Redirect URI**:
   - If you're installing the app from the Atlassian Marketplace listing, enter `https://gitlab.com/-/jira_connect/oauth_callbacks`.
   - If you're installing the app manually, enter `<instance_url>/-/jira_connect/oauth_callbacks` and replace `<instance_url>` with the URL of your instance.
1. Clear the **Trusted** and **Confidential** checkboxes.

   > [!note]
   > You must clear these checkboxes to avoid [sign in errors](jira_cloud_app_troubleshooting.md#error-failed-to-sign-in-to-gitlab).

1. In **Scopes**, select the `api` checkbox only.
1. Select **Save application**.
1. Copy the **Application ID** value.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab for Jira App**.
1. Paste the **Application ID** value into **Jira Connect Application ID**.
1. Select **Save changes**.

## Jira user requirements

{{< history >}}

- Support for the `org-admins` group [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420687) in GitLab 16.6.

{{< /history >}}

In your [Atlassian organization](https://admin.atlassian.com), you must ensure that the Jira user that is used to set up the GitLab for Jira Cloud app is a member of
either:

- The Organization Administrators (`org-admins`) group. Newer Atlassian organizations are using
  [centralized user management](https://support.atlassian.com/user-management/docs/give-users-admin-permissions/#Centralized-user-management-content),
  which contains the `org-admins` group. Existing Atlassian organizations are being migrated to centralized user management.
  If available, you should use the `org-admins` group to indicate which Jira users can manage the GitLab for Jira Cloud app. Alternatively you can use the
  `site-admins` group.
- The Site Administrators (`site-admins`) group. The `site-admins` group was used under
  [original user management](https://support.atlassian.com/user-management/docs/give-users-admin-permissions/#Original-user-management-content).

If necessary:

1. [Create your preferred group](https://support.atlassian.com/user-management/docs/create-groups/).
1. [Edit the group](https://support.atlassian.com/user-management/docs/edit-a-group/) to add your Jira user as a member of it.
1. If you customized your global permissions in Jira, you might also need to grant the
   [`Browse users and groups` permission](https://confluence.atlassian.com/jirakb/unable-to-browse-for-users-and-groups-120521888.html) to the Jira user.

## Install the GitLab for Jira Cloud app from the Atlassian Marketplace

{{< history >}}

- Introduced in GitLab 15.7.

{{< /history >}}

You can use the official GitLab for Jira Cloud app from the Atlassian Marketplace with your GitLab Self-Managed instance.

With this method:

- GitLab.com [handles the install and uninstall lifecycle events](#gitlabcom-handling-of-app-lifecycle-events) sent from Jira Cloud and forwards them to your GitLab instance. All data from your GitLab Self-Managed instance is still sent directly to Jira Cloud.
- GitLab.com [handles branch creation links](#gitlabcom-handling-of-branch-creation) by redirecting them to your instance.
- With any version of GitLab prior to 17.2 it is not possible to create branches from Jira Cloud on GitLab Self-Managed instances.
  For more information, see [issue 391432](https://gitlab.com/gitlab-org/gitlab/-/issues/391432).

Alternatively, you might want to [install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually) if:

- Your instance does not meet the [prerequisites](#prerequisites).
- You do not want to use the official Atlassian Marketplace listing.
- You do not want GitLab.com to [handle the app lifecycle events](#gitlabcom-handling-of-app-lifecycle-events) or to know that your instance has installed the app.
- You do not want GitLab.com to [redirect branch creation links](#gitlabcom-handling-of-branch-creation) to your instance.

### Prerequisites

- The instance must be publicly available.
- The instance must be on GitLab version 15.7 or later.
- You must set up [OAuth authentication](#set-up-oauth-authentication).
- Your GitLab instance must use HTTPS and your GitLab certificate must be publicly trusted or contain the full chain certificate.
- Your network configuration must allow:
  - Outbound connections from your GitLab Self-Managed instance to Jira Cloud ([Atlassian IP addresses](https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/#Outgoing-Connections))
  - Inbound and outbound connections between your GitLab Self-Managed instance and GitLab.com ([GitLab.com IP addresses](../../user/gitlab_com/_index.md#ip-range))
  - For instances behind a firewall:
    1. Set up an internet-facing [reverse proxy](#using-a-reverse-proxy) in front of your GitLab Self-Managed instance.
    1. Configure the reverse proxy to allow inbound connections from GitLab.com ([GitLab.com IP addresses](../../user/gitlab_com/_index.md#ip-range))
    1. Ensure your GitLab Self-Managed instance can still make the outbound connections described previously.
- The Jira user that installs and configures the app must meet certain [requirements](#jira-user-requirements).

### Set up your instance for Atlassian Marketplace installation

[Prerequisites](#prerequisites)

To set up your GitLab Self-Managed instance for Atlassian Marketplace installation in GitLab 15.7 and later:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab for Jira App**.
1. In **Jira Connect Proxy URL**, enter `https://gitlab.com` to install the app from the Atlassian Marketplace.
1. Select **Save changes**.

### Link your instance

[Prerequisites](#prerequisites)

To link your GitLab Self-Managed instance to the GitLab for Jira Cloud app:

1. Install the [GitLab for Jira Cloud app](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).
1. [Configure the GitLab for Jira Cloud app](../../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app).
1. Optional. [Check if Jira Cloud is now linked](#check-if-jira-cloud-is-linked).

#### Check if Jira Cloud is linked

You can use the [Rails console](../operations/rails_console.md#starting-a-rails-console-session)
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

{{< history >}}

- Connect-based manual install method [removed](https://gitlab.com/gitlab-org/gitlab-jira-forge/-/work_items/9) in GitLab 19.0.

{{< /history >}}

> [!warning]
> The previous manual install method relied on Atlassian Connect development mode. Atlassian
> [disabled Connect-based private installs on 2026-03-31](https://www.atlassian.com/blog/developer/announcing-connect-end-of-support-timeline-and-next-steps).
> If you previously installed the app manually with the **App descriptor URL** workflow,
> migrate to the Forge-based install described in this section.

Install the GitLab for Jira Cloud app manually if you cannot
[use the official Atlassian Marketplace listing](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace).
For example, if:

- Your instance does not meet the [Marketplace prerequisites](#prerequisites).
- You do not want GitLab.com to [handle app lifecycle events](#gitlabcom-handling-of-app-lifecycle-events) or to know that your instance has installed the app.
- You do not want GitLab.com to [redirect branch creation links](#gitlabcom-handling-of-branch-creation) to your instance.

The manual install method is now based on [Atlassian Forge](https://developer.atlassian.com/platform/forge/).
You publish a private copy of the [GitLab for Jira Cloud Forge app](https://gitlab.com/gitlab-org/gitlab-jira-forge)
under your own Atlassian developer account, pointed at your GitLab Self-Managed or GitLab Dedicated instance.

### Prerequisites

- The instance must be publicly available over HTTPS, with a publicly trusted certificate.
- You must set up [OAuth authentication](#set-up-oauth-authentication).
- Your network configuration must allow:
  - Inbound HTTPS connections from Jira Cloud to `<instance_url>/-/jira_connect` ([Atlassian IP addresses](https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/#Outgoing-Connections)).
  - Outbound HTTPS connections from your GitLab instance to `*.atlassian.net` to push development data to Jira.
  - For instances behind a firewall:
    1. Set up an internet-facing [reverse proxy](#using-a-reverse-proxy) in front of your GitLab Self-Managed instance.
    1. Configure the reverse proxy to allow inbound connections from Jira Cloud.
    1. Ensure your GitLab Self-Managed instance can still make the outbound connections described previously.
- Fully air-gapped instances cannot use the integration. The outbound path to `*.atlassian.net` is required for the development panel and other Jira-side surfaces.
- The Jira user that installs and configures the app must meet certain [requirements](#jira-user-requirements).
- An Atlassian developer account and an [Atlassian API token](https://id.atlassian.com/manage-profile/security/api-tokens) for the Forge CLI.
- A machine with [Node.js 22 LTS](https://nodejs.org/), the [Forge CLI](https://developer.atlassian.com/platform/forge/getting-started/), `envsubst`, `git`, and `curl`.

### Set up your instance for manual installation

[Prerequisites](#prerequisites-1)

To set up your GitLab Self-Managed instance for manual installation:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab for Jira App**.
1. Leave **Jira Connect Proxy URL** blank to install the app manually.
1. Select **Save changes**.

### Publish a private Forge app

To publish a private copy of the GitLab for Jira Cloud Forge app and install it on your Jira site:

1. Clone the [`gitlab-jira-forge`](https://gitlab.com/gitlab-org/gitlab-jira-forge) repository:

   ```shell
   git clone --depth 1 https://gitlab.com/gitlab-org/gitlab-jira-forge.git
   cd gitlab-jira-forge
   ```

1. Export the required environment variables. Replace the example values
   with your GitLab instance URL, Jira site, and Atlassian credentials:

   ```shell
   export GITLAB_URL=https://gitlab.example.com
   export JIRA_SITE=acme.atlassian.net
   export FORGE_EMAIL=admin@example.com
   export FORGE_API_TOKEN=<your-atlassian-api-token>
   ```

1. Run the wrapper script to register, deploy, and install the app:

   ```shell
   ./scripts/install-self-managed.sh
   ```

   The wrapper:
   - Verifies the required tools and variables.
   - Runs `forge register` on first use to create a Forge app under your Atlassian account.
   - Generates `manifest.yml` from the template, pinned to your `GITLAB_URL`.
   - Runs `forge deploy -e production`.
   - Runs `forge install --site $JIRA_SITE --product jira`.

   The script caches the registered `APP_ID` in `.env.self-managed`. Back up this file:
   if you lose it, you must re-register the app, which forces all installed Jira sites to re-install.

For step-by-step instructions, manual `forge` commands, troubleshooting, and the upgrade workflow, see the
[Self-managed install guide](https://gitlab.com/gitlab-org/gitlab-jira-forge/-/blob/main/docs/self-managed-install.md)
in the `gitlab-jira-forge` repository.

After the app is installed, [configure the GitLab for Jira Cloud app](../../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)
in Jira to link your GitLab namespaces.

### Update the manually installed app

To pull upstream manifest changes into your private Forge app, re-run the wrapper with `--update`:

```shell
./scripts/install-self-managed.sh --update
```

The script fast-forwards the local clone, regenerates the manifest, and redeploys the app.
For more information about minor and major version upgrades, see
[Upgrading](https://gitlab.com/gitlab-org/gitlab-jira-forge/-/blob/main/docs/self-managed-install.md#upgrading)
in the self-managed install guide.

## Connect multiple GitLab instances

Use the GitLab for Jira app to connect multiple GitLab instances to a single Jira Cloud instance.
The installation methods depend on which instances you want to connect.

Prerequisites:

- Each instance requires separate OAuth authentication.
- You must meet the prerequisites for each installation method.

For GitLab.com + GitLab Self-Managed:

- On GitLab.com: Use the Atlassian Marketplace installation.
- On GitLab Self-managed instances: Install the app manually.

For multiple GitLab Self-Managed instances:

- On the first instance, either: Use the Atlassian Marketplace installation or install the app manually.
- On other instances: Install the app manually.

Jira Cloud displays a GitLab for Jira Cloud app for each installation.

Only one GitLab instance per organization can use the official Atlassian Marketplace listing.

## Configure your GitLab instance to serve as a proxy

> [!note]
> For most users, this configuration is not necessary. To Jira Cloud with multiple instances,
> you can connect each instance with the GitLab for Jira Cloud app.

A GitLab instance can serve as a proxy for other GitLab instances through the GitLab for Jira Cloud app.
You might want to use a proxy if you're managing multiple GitLab instances but only want to
[manually install](#install-the-gitlab-for-jira-cloud-app-manually) the app once.

To configure your GitLab instance to serve as a proxy:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab for Jira App**.
1. Select **Enable public key storage**.
1. Select **Save changes**.
1. [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

Other GitLab instances that use the proxy must configure the following settings to point to the proxy instance:

- [**Jira Connect Proxy URL**](#set-up-your-instance-for-atlassian-marketplace-installation)
- [**Redirect URI**](#set-up-oauth-authentication)

## Security considerations

The following security considerations are specific to administering the app.
For considerations related to using the app, see
[security considerations](../../integration/jira/connect-app.md#security-considerations).

### GitLab.com handling of app lifecycle events

When you [Install the GitLab for Jira Cloud app from the Atlassian Marketplace](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace),
GitLab.com receives [lifecycle events](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#lifecycle) from Jira.
These events are limited to when the app is installed in or uninstalled from your Jira Project.

In the install event, GitLab.com receives a **secret token** from Jira.
GitLab.com stores this token encrypted with `AES256-GCM` to later verify incoming lifecycle events from Jira.

GitLab.com then forwards the token to your GitLab Self-Managed instance so your instance can authenticate its [requests to Jira](../../integration/jira/connect-app.md#data-sent-from-gitlab-to-jira) with the same token.
Your GitLab Self-Managed instance is also notified that the GitLab for Jira Cloud app has been installed or uninstalled.

When [data is sent](../../integration/jira/connect-app.md#data-sent-from-gitlab-to-jira) from your GitLab Self-Managed instance to the Jira development panel,
it is sent from your GitLab Self-Managed instance directly to Jira and not to GitLab.com.
GitLab.com does not use the token to access data in your Jira project.
Your GitLab Self-Managed instance uses the token to [access the data](../../integration/jira/connect-app.md#gitlab-access-to-jira).

For more information about the lifecycle events and payloads that GitLab.com receives,
see the [Atlassian documentation](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#lifecycle).

```mermaid
sequenceDiagram
accTitle: Dataflow of the GitLab for Jira Cloud app installed from the Atlassian Marketplace
accDescr: How GitLab.com handles lifecycle events when the GitLab for Jira Cloud app was installed from the Atlassian Marketplace

    participant Jira
    participant Your instance
    participant GitLab.com
    Jira->>+GitLab.com: App install/uninstall event
    GitLab.com->>-Your instance: App install/uninstall event
    Your instance->>Jira: Your development data
```

### GitLab.com handling of branch creation

When you have
[installed the GitLab for Jira Cloud app from the Atlassian Marketplace](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace),
the links to create a branch from the development panel initially send the user to GitLab.com.

Jira sends GitLab.com a JWT token. GitLab.com handles the request by verifying the token and then redirects the request to your GitLab instance.

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

You should avoid using a reverse proxy in front of your GitLab Self-Managed instance if possible.
Instead, consider using a public IP address and securing the domain with a firewall.

If you must use a reverse proxy for the GitLab for Jira Cloud app on a GitLab Self-Managed instance
that cannot be accessed directly from the internet, keep the following in mind:

- When you [install the GitLab for Jira Cloud app from the Atlassian Marketplace](#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace),
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
- If you use a rewrite or subfilter with your proxy, ensure the proxy
  does not rewrite or replace the `gitlab-jira-connect-${host}` app key.
  Otherwise, you might get a [`Failed to link group`](jira_cloud_app_troubleshooting.md#error-failed-to-link-group) error.
- When you select [**Create branch**](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/#Create-feature-branches) in the Jira development panel,
  you are redirected to the reverse proxy FQDN rather than the internal GitLab FQDN.

### External NGINX

This server block is an example of how to configure a reverse proxy for GitLab that works with Jira Cloud:

```nginx
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

### Set an additional JWT audience

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/498587) in GitLab 17.7.

{{< /history >}}

When GitLab receives a JWT token from Jira,
GitLab verifies the token by checking the JWT audience.
By default, the audience is derived from your internal GitLab FQDN.

In some reverse proxy configurations, you might have to set
the reverse proxy FQDN as an additional JWT audience.
To set an additional JWT audience:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab for Jira App**.
1. In **Jira Connect Additional Audience URL**, enter the additional audience
   (for example, `https://gitlab.mycompany.com`).
1. Select **Save changes**.

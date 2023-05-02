---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Jira Cloud app **(FREE)**

With the [GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud) app, you can connect GitLab and Jira Cloud and use the Jira development panel.

- **For GitLab.com**:
  - [Install the GitLab for Jira Cloud app](#install-the-gitlab-for-jira-cloud-app).
- **For self-managed GitLab**, do one of the following:
  - [Connect the GitLab for Jira Cloud app for self-managed instances](#connect-the-gitlab-for-jira-cloud-app-for-self-managed-instances) (GitLab 15.7 and later).
  - [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

If you use Jira Server or Jira Data Center, use the [Jira DVCS connector](dvcs/index.md) instead.

## Install the GitLab for Jira Cloud app **(FREE SAAS)**

Prerequisites:

- You must have at least the Maintainer role for the GitLab namespace.
- You must have administrator access to the Jira instance.

To install the GitLab for Jira Cloud app:

1. In Jira, select **Jira Settings > Apps > Find new apps**, and search for GitLab.
1. Select **GitLab for Jira Cloud**, and select **Get it now**.

   Alternatively, [get the app directly from the Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud).

1. To go to the configurations page, select **Get started**.
   You can always access this page in **Jira Settings > Apps > Manage apps**.
1. To open the list of available namespaces, select **Add namespace**.
1. To link to a namespace, select **Link**.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see
[Configure the GitLab for Jira Cloud app from the Atlassian Marketplace](https://youtu.be/SwR-g1s1zTo).

After you add a namespace, the following data is synced to Jira for all projects in that namespace:

- New merge requests, branches, and commits
- Existing merge requests (GitLab 13.8 and later)
- Existing branches and commits (GitLab 15.11 and later)

## Update the GitLab for Jira Cloud app

Most updates to the app are fully automated and don't require any user interaction. See the
[Atlassian Marketplace documentation](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/)
for details.

If the app requires additional permissions, [the update must first be manually approved in Jira](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval).

## Set up OAuth authentication for self-managed instances **(FREE SELF)**

The GitLab for Jira Cloud app is [switching to OAuth authentication](https://gitlab.com/gitlab-org/gitlab/-/issues/387299).
To enable OAuth authentication, you must create an OAuth application on the GitLab instance.

You must enable OAuth authentication to:

- [Connect the GitLab for Jira Cloud app for self-managed instances](#connect-the-gitlab-for-jira-cloud-app-for-self-managed-instances).
- [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

To create an OAuth application:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Applications** (`/admin/applications`).
1. Select **New application**.
1. In **Redirect URI**:
   - If you're installing the app from the official marketplace listing, enter `https://gitlab.com/-/jira_connect/oauth_callbacks`.
   - If you're installing the app manually, enter `<instance_url>/-/jira_connect/oauth_callbacks` and replace `<instance_url>` with the URL of your instance.
1. Clear the **Trusted** and **Confidential** checkboxes.
1. In **Scopes**, select the `api` checkbox only.
1. Select **Save application**.
1. Copy the **Application ID** value.
1. On the left sidebar, select **Settings > General** (`/admin/application_settings/general`).
1. Expand **GitLab for Jira App**.
1. Paste the **Application ID** value into **Jira Connect Application ID**.
1. Select **Save changes**.

## Connect the GitLab for Jira Cloud app for self-managed instances **(FREE SELF)**

> Introduced in GitLab 15.7.

You can link self-managed instances after installing the GitLab for Jira Cloud app from the marketplace.
Jira apps can only link to one URL per marketplace listing. The official listing links to GitLab.com.

NOTE:
With this method, GitLab.com serves as a proxy for Jira traffic from your instance.

If your instance doesn't meet the [prerequisites](#prerequisites) or you don't want to use the official marketplace listing, you can
[install the app manually](#install-the-gitlab-for-jira-cloud-app-manually).

It's not possible to create branches from Jira for self-managed instances. For more information, see [issue 391432](https://gitlab.com/gitlab-org/gitlab/-/issues/391432).

### Prerequisites

- The instance must be publicly available.
- The instance must be on GitLab version 15.7 or later.
- You must set up [OAuth authentication](#set-up-oauth-authentication-for-self-managed-instances).

### Set up your instance

[Prerequisites](#prerequisites)

To set up your self-managed instance for the GitLab for Jira Cloud app in GitLab 15.7 and later:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General** (`/admin/application_settings/general`).
1. Expand **GitLab for Jira App**.
1. In **Jira Connect Proxy URL**, enter `https://gitlab.com`.
1. Select **Save changes**.

### Link your instance

[Prerequisites](#prerequisites)

To link your self-managed instance to the GitLab for Jira Cloud app:

1. Install the [GitLab for Jira Cloud app](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).
1. Select **GitLab (self-managed)**.
1. Enter your GitLab instance URL.
1. Select **Save**.

## Install the GitLab for Jira Cloud app manually **(FREE SELF)**

If your GitLab instance is self-managed and you don't want to use the official marketplace listing,
you can install the app manually.

Each Jira Cloud application must be installed from a single location. Jira fetches
a [manifest file](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/)
from the location you provide. The manifest file describes the application to the system. To support
self-managed GitLab instances with Jira Cloud, you can do one of the following:

- [Install the application in development mode](#install-the-application-in-development-mode).
- [Create a Marketplace listing](#create-a-marketplace-listing).

### Prerequisites

- The instance must be publicly available.
- You must set up [OAuth authentication](#set-up-oauth-authentication-for-self-managed-instances).

### Install the application in development mode

[Prerequisites](#prerequisites-1)

To configure your Jira instance so you can install applications
from outside the Marketplace:

1. Sign in to your Jira instance as an administrator.
1. Place your Jira instance into
   [development mode](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-2--enable-development-mode).
1. Sign in to your GitLab application as a user with administrator access.
1. Install the GitLab application from your Jira instance as
   described in the [Atlassian developer guide](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-3--install-and-test-your-app):
   1. In your Jira instance, go to **Apps > Manage Apps** and select **Upload app**:
   1. For **App descriptor URL**, provide the full URL to your manifest file based
      on your instance configuration. By default, your manifest file is located at `/-/jira_connect/app_descriptor.json`. For example, if your GitLab self-managed instance domain is `app.pet-store.cloud`, your manifest file is located at `https://app.pet-store.cloud/-/jira_connect/app_descriptor.json`.
   1. Select **Upload**. Jira fetches the content of your `app_descriptor` file and installs
      it.
   1. To configure the integration, select **Get started**.
1. Disable [development mode](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-2--enable-development-mode) on your Jira instance.

The **GitLab for Jira Cloud** app now displays under **Manage apps**. You can also
select **Get started** to open the configuration page rendered from your GitLab instance.

NOTE:
If a GitLab update makes changes to the application descriptor, you must uninstall,
then reinstall the application.

### Create a Marketplace listing

[Prerequisites](#prerequisites-1)

If you don't want to use development mode on your Jira instance, you can create
your own Marketplace listing. This way, your application
can be installed from the Atlassian Marketplace.

To create a Marketplace listing:

1. Register as a Marketplace vendor.
1. List your application with the application descriptor URL.
   - Your manifest file is located at: `https://your.domain/your-path/-/jira_connect/app_descriptor.json`
   - You should list your application as `private` because public
     applications can be viewed and installed by any user.
1. Generate test license tokens for your application.

NOTE:
This method uses [automated updates](#update-the-gitlab-for-jira-cloud-app)
the same way as our GitLab.com Marketplace listing.

For more information about creating a Marketplace listing, see the [Atlassian documentation](https://developer.atlassian.com/platform/marketplace/installing-cloud-apps/#creating-the-marketplace-listing).

## Configure your GitLab instance to serve as a proxy for the GitLab for Jira Cloud app **(FREE SELF)**

A GitLab instance can serve as a proxy for other GitLab instances through the GitLab for Jira Cloud app.
You might want to use a proxy if you're managing multiple GitLab instances but only want to
[manually install](#install-the-gitlab-for-jira-cloud-app-manually) the GitLab for Jira Cloud app once.

To configure your GitLab instance to serve as a proxy:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General** (`/admin/application_settings/general`).
1. Expand **GitLab for Jira App**.
1. Select **Enable public key storage**.
1. Select **Save changes**.
1. [Install the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually).

Other GitLab instances that use the proxy must configure the **Jira Connect Proxy URL** and the [OAuth application](#set-up-oauth-authentication-for-self-managed-instances) **Redirect URI** settings to point to the proxy instance.

## Security considerations

The GitLab for Jira Cloud app connects GitLab and Jira. Data must be shared between the two applications, and access must be granted in both directions.

### Access to GitLab through OAuth **(FREE SELF)**

GitLab does not share an access token with Jira. However, users must authenticate through OAuth to configure the app.

An access token is retrieved through a [PKCE](https://www.rfc-editor.org/rfc/rfc7636) OAuth flow and stored only on the client side.
The app frontend that initializes the OAuth flow is a JavaScript application that's loaded from GitLab through an iframe on Jira.

The OAuth application must have the `api` scope, which grants complete read and write access to the API.
This access includes all groups and projects, the container registry, and the package registry.
However, the GitLab for Jira Cloud app only uses this access to:

- Display namespaces to be linked.
- Link namespaces.

Access through OAuth is only needed for the time a user configures the GitLab for Jira Cloud app. For more information, see [Access token expiration](../oauth_provider.md#access-token-expiration).

### Access to Jira through access token

Jira shares an access token with GitLab to authenticate and authorize data pushes to Jira.
As part of the app installation process, Jira sends a handshake request to GitLab containing the access token.
The handshake is signed with an [asymmetric JWT](https://developer.atlassian.com/cloud/jira/platform/understanding-jwt-for-connect-apps/),
and the access token is stored encrypted with `AES256-GCM` on GitLab.

## Troubleshooting

### Browser displays a sign-in message when already signed in

You might get the following message prompting you to sign in to GitLab.com
when you're already signed in:

```plaintext
You need to sign in or sign up before continuing.
```

The GitLab for Jira Cloud app uses an iframe to add namespaces on the
settings page. Some browsers block cross-site cookies, which can lead to this issue.

To resolve this issue, set up [OAuth authentication](#set-up-oauth-authentication-for-self-managed-instances).

### Manual installation fails

You might get an error if you have installed the GitLab for Jira Cloud app from the official marketplace listing and replaced it with manual installation:

```plaintext
The app "gitlab-jira-connect-gitlab.com" could not be installed as a local app as it has previously been installed from Atlassian Marketplace
```

To resolve this issue, disable the **Jira Connect Proxy URL** setting.

- In GitLab 15.7:

  1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
  1. Execute `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`.

- In GitLab 15.8 and later:

  1. On the top bar, select **Main menu > Admin**.
  1. On the left sidebar, select **Settings > General** (`/admin/application_settings/general`).
  1. Expand **GitLab for Jira App**.
  1. Clear the **Jira Connect Proxy URL** text box.
  1. Select **Save changes**.

### Data sync fails with `Invalid JWT` error

If the GitLab for Jira Cloud app continuously fails to sync data, it may be due to an outdated secret token. Atlassian can send new secret tokens that must be processed and stored by GitLab.
If GitLab fails to store the token or misses the new token request, an `Invalid JWT` error occurs.

To resolve this issue on GitLab self-managed, follow one of the solutions below, depending on your app installation method.

- If you installed the app from the official marketplace listing:

  1. Open the GitLab for Jira Cloud app on Jira.
  1. Select **Change GitLab version**.
  1. Select **GitLab.com (SaaS)**.
  1. Select **Change GitLab version** again.
  1. Select **GitLab (self-managed)**.
  1. Enter your **GitLab instance URL**.
  1. Select **Save**.

- If you [installed the GitLab for Jira Cloud app manually](#install-the-gitlab-for-jira-cloud-app-manually):

  - In GitLab 14.9 and later:
    - Contact the [Jira Software Cloud support](https://support.atlassian.com/jira-software-cloud/) and ask to trigger a new installed lifecycle event for the GitLab for Jira Cloud app in your namespace.
  - In all GitLab versions:
    - Re-install the GitLab for Jira Cloud app. This method might remove all synced data from the Jira development panel.

### `Failed to update GitLab version` error when setting up the GitLab for Jira Cloud app for self-managed instances

When you set up the GitLab for Jira Cloud app, you might get the following message after you enter your
self-managed instance URL:

```plaintext
Failed to update GitLab version. Please try again.
```

To resolve this issue, ensure all prerequisites for your installation method have been met:

- [Prerequisites for connecting the GitLab for Jira Cloud app](#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](#prerequisites-1)

If you're using GitLab 15.8 and earlier and have previously enabled both the `jira_connect_oauth_self_managed`
and the `jira_connect_oauth` feature flags, you must disable the `jira_connect_oauth_self_managed` flag
due to a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388943). To check for these flags:

1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Execute the following code:

   ```ruby
   # Check if both feature flags are enabled.
   # If the flags are enabled, these commands return `true`.
   Feature.enabled?(:jira_connect_oauth)
   Feature.enabled?(:jira_connect_oauth_self_managed)

   # If both flags are enabled, disable the `jira_connect_oauth_self_managed` flag.
   Feature.disable(:jira_connect_oauth_self_managed)
   ```

---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GitLab for Jira Cloud app development
---

Developers have several options for how set up a development environment for the GitLab for Jira Cloud app:

1. A full environment [with Jira](#set-up-with-jira). Use this when you need to test interactions with Jira.
1. A full environment [with a Jira Connect proxy](#setting-up-a-jira-connect-proxy). Use this when you need to test multiple GitLab instances connecting to Jira through a Jira Connect proxy, or when testing changes to the Jira Connect proxy itself.
1. A local environment [without Jira](#setup-without-jira). You can use this quicker setup if you do not require Jira, for example when testing the GitLab frontend.

## Set up with Jira

The following are required to install the app:

- A Jira Cloud instance. Atlassian provides [free instances for development and testing](https://developer.atlassian.com/platform/marketplace/getting-started/#free-developer-instances-to-build-and-test-your-app).
- A GitLab instance available over the internet. For the app to work, Jira Cloud should
  be able to connect to the GitLab instance through the internet. For this we
  recommend using Gitpod or a similar cloud development environment. For more
  information on using Gitpod with GDK, see the:

  - [GDK with Gitpod](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md)
    documentation.
  - [GDK in Gitpod](https://www.loom.com/share/9c9711d4876a40869b9294eecb24c54d)
    video.

  <!-- vale gitlab_base.Spelling = NO -->

  GitLab team members **must not** use tunneling tools such as Serveo or `ngrok`. These are
  security risks, and must not be run on GitLab developer laptops.

  <!-- vale gitlab_base.Spelling = YES -->

  Jira requires all connections to the app host to be over SSL. If you set up
  your own environment, remember to enable SSL and an appropriate certificate.

### Setting up GitPod

If you are using [Gitpod](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md)
you must [make port `3000` public](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md#make-the-rails-web-server-publicly-accessible).

### Install the app in Jira

To install the app in Jira:

1. Enable Jira development mode to install apps that are not from the Atlassian
   Marketplace:

   1. In Jira, go to **Jira settings > Apps > Manage apps**.
   1. Scroll to the bottom of the **Manage apps** page and select **Settings**.
   1. Select **Enable development mode** and select **Apply**.

1. Install the app:

   1. In Jira, go to **Jira settings > Apps > Manage apps**.
   1. Select **Upload app**.
   1. In the **From this URL** field, provide a link to the app descriptor. The host and port must point to your GitLab instance.

      For example:

      ```plaintext
      https://xxxx.gitpod.io/-/jira_connect/app_descriptor.json
      ```

   1. Select **Upload**.

   If the install was successful, you should see the **GitLab for Jira Cloud** app under **Manage apps**.
   You can also select **Getting Started** to open the configuration page rendered from your GitLab instance.

   _Note that any changes to the app descriptor requires you to uninstall then reinstall the app._
1. If the _Installed and ready to go!_ dialog opens asking you to **Get started**, do not get started yet
   and instead select **Close**.
1. You must now [set up the OAuth authentication flow](#set-up-the-gitlab-oauth-authentication-flow).

### Set up the GitLab OAuth authentication flow

GitLab for Jira users authenticate with GitLab using GitLab OAuth.

Ensure you have [installed the app in Jira](#install-the-app-in-jira) first before doing these steps,
otherwise the app installation in Jira fails.

The following steps describe setting up an environment to test the GitLab OAuth flow:

1. Start a [Gitpod session](#setting-up-gitpod).
1. On your GitLab instance, go to **Admin > Applications**.
1. Create a new application with the following settings:
   - Name: `GitLab for Jira`
   - Redirect URI: `YOUR_GITPOD_INSTANCE/-/jira_connect/oauth_callbacks`
   - Trusted: **No**
   - Confidential: **No**
   - Scopes: `api`
1. Copy the **Application ID** value.
1. Go to **Admin > Settings > General**.
1. Expand **GitLab for Jira App**.
1. Paste the **Application ID** value into **Jira Connect Application ID**.
1. In **Jira Connect Proxy URL**, enter `YOUR_GITPOD_INSTANCE` (for example, `https://xxxx.gitpod.io`).
1. Enable public key storage: **Leave unchecked**.
1. Select **Save changes**.

### Set up the app in Jira

Ensure you have [set up OAuth first](#set-up-the-gitlab-oauth-authentication-flow) first before doing these steps,
otherwise these steps fail.

1. In Jira, go to **Jira settings > Apps > Manage apps**.
1. Scroll to **User-installed apps**, find your GitLab for Jira Cloud app and expand it.
1. Select **Get started**.

You should be able to authenticate with your GitLab instance and begin linking groups.

### Troubleshooting

#### App installation fails

If the app installation fails, you might need to delete `jira_connect_installations` from your database.

1. Open the [database console](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md#access-postgresql).
1. Run `TRUNCATE TABLE jira_connect_installations CASCADE;`.

### Not authorized to access the file

If you use Gitpod and you get an error about Jira not being able to access the descriptor file, you will need to [make GitPod port public](#setting-up-gitpod).

## Setting up a Jira Connect Proxy

When a self-managed instance [installs the GitLab for Jira app from the Atlassian Marketplace](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace), the self-managed instance must use GitLab.com as a Jira Connect proxy. You can emulate this setup if you need to develop or test features such as the [handling of Jira lifecycle events](../../administration/settings/jira_cloud_app.md#gitlabcom-handling-of-app-lifecycle-events) and [branch creation](../../administration/settings/jira_cloud_app.md#gitlabcom-handling-of-branch-creation). 

To set up a development Jira Connect Proxy:

- A Jira Cloud instance. Atlassian provides [free instances for development and testing](https://developer.atlassian.com/platform/marketplace/getting-started/#free-developer-instances-to-build-and-test-your-app).
- Two GitLab instances available over the internet.
  - One to serve as the **Jira Connect proxy** (simulating GitLab.com)
  - One to serve as the **GitLab instance** that will connect to Jira through the Jira Connect proxy
  - For the app to work, Jira Cloud should
    be able to connect to the **Jira Connect proxy** instance through the internet. For this we
    recommend using Gitpod or a similar cloud development environment. For more
    information on using Gitpod with GDK, see the:

    - [GDK with Gitpod](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md)
    documentation.
    - [GDK in Gitpod](https://www.loom.com/share/9c9711d4876a40869b9294eecb24c54d)
    video.

    <!-- vale gitlab_base.Spelling = NO -->

    GitLab team members **must not** use tunneling tools such as Serveo or `ngrok`. These are
    security risks, and must not be run on GitLab developer laptops.

    <!-- vale gitlab_base.Spelling = YES -->

    Jira requires all connections to the app host to be over SSL. If you set up
    your own environment, remember to enable SSL and an appropriate certificate.

### Setting up GitPod

If you are using [Gitpod](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md)
you must [make port `3000` public](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md#make-the-rails-web-server-publicly-accessible).

### Set up the Jira Connect proxy instance

1. For the **Jira Connect proxy** instance, follow the [GDK with Gitpod](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md) instructions to start a new Gitpod workspace.

1. Set up OAuth authentication on the **Jira Connect proxy** by following the [Set up the GitLab OAuth authentication flow](#set-up-the-gitlab-oauth-authentication-flow) section.

1. Configure the **Jira Connect proxy** [to serve as a proxy](../../administration/settings/jira_cloud_app.md#configure-your-gitlab-instance-to-serve-as-a-proxy).

### Install the GitLab for Jira Cloud app in Jira

Follow the [Install the app in Jira](#install-the-app-in-jira) section, but use the URL of your **Jira Connect proxy** instance for the app descriptor:

```plaintext
https://JIRA_CONNECT_PROXY_INSTANCE/-/jira_connect/app_descriptor.json
```

If the _Installed and ready to go!_ dialog opens, select **Close** (don't select **Get started** yet).

### Set up the secondary GitLab instance

1. Set up a second GitLab instance using Gitpod, following the same [GDK with Gitpod](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitpod.md) instructions as for the proxy instance

1. Set up OAuth authentication on this instance following the same steps as in [Set up the GitLab OAuth authentication flow](#set-up-the-gitlab-oauth-authentication-flow), but with a crucial difference:
   - When setting the **Redirect URI**, use the URL of your **Jira Connect proxy** instance, not this secondary instance:

     ```plaintext
     https://JIRA_CONNECT_PROXY_INSTANCE/-/jira_connect/oauth_callbacks
     ```

1. Configure this GitLab instance to use the proxy:
   1. Go to **Admin > Settings > General**
   1. Expand **GitLab for Jira App**
   1. Paste the **Application ID** value into **Jira Connect Application ID**
   1. In **Jira Connect Proxy URL**, enter `JIRA_CONNECT_PROXY_INSTANCE` (for example, `https://xxxx.gitpod.io`)
   1. Select **Save changes**

### Complete the setup in Jira

1. In Jira, go to **Jira settings > Apps > Manage apps**.
1. Scroll to **User-installed apps**, find your GitLab for Jira Cloud app and expand it.
1. Select **Get started**.
1. To link the app to the secondary GitLab instance, select **Change GitLab version**.
1. Select all checkboxes, then select Next.
1. In **GitLab instance URL** ,enter `GITLAB_INSTANCE` (for example, `https://xxxx.gitpod.io`), then select Save.
1. Select **Sign in to GitLab**.
1. Select **Authorize**. A list of groups is now visible.
1. Select **Link groups**.
1. To link to a group, select **Link**.

## Setup without Jira

If you do not require Jira to test with, you can use the [Jira connect test tool](https://gitlab.com/gitlab-org/foundations/import-and-integrate/jira-connect-test-tool) and your local GDK.

1. Clone the [**Jira-connect-test-tool**](https://gitlab.com/gitlab-org/foundations/import-and-integrate/jira-connect-test-tool) `git clone git@gitlab.com:gitlab-org/manage/integrations/jira-connect-test-tool.git`.
1. Start the app `bundle exec rackup`. (The app requires your GDK GitLab to be available on `http://127.0.0.1:3000`.).
1. Open `config/gitlab.yml` and uncomment the `jira_connect` config.
1. If running GDK on a domain other than `localhost`, you must add the domain to `additional_iframe_ancestors`. For example:

   ```yaml
   additional_iframe_ancestors: ['localhost:*', '127.0.0.1:*', 'gdk.test:*']
   ```

1. Restart GDK.
1. Go to `http://127.0.0.1:3000/-/user_settings/personal_access_tokens`.
1. Create a new token with the `api` scope and copy the token.
1. Go to `http://localhost:9292`.
1. Paste the token and select **Install GitLab.com Jira Cloud app**.

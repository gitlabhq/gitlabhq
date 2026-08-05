---
stage: Agent Foundations
group: AI Catalog
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Set up GitLab Duo in Slack for local development
---

[GitLab Duo in Slack](../../user/project/integrations/gitlab_slack_application.md#gitlab-duo) responds when
a user mentions the GitLab bot in a Slack channel or thread. Slack must be able to reach your
GDK over the internet for this to work.

To test the feature locally, you must:

1. Expose your GDK to the internet through a tunnel.
1. Create your own copy of the GitLab for Slack app, and point its request URLs at the tunnel.
1. Install the app from GitLab, so that GitLab has a bot token to call Slack with.

## Prerequisites

- A GDK with [GitLab Duo set up](_index.md#set-up-your-local-development-environment).
- A CI/CD runner [registered against your GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md),
  tagged `gitlab--duo`. Use the `docker` executor: flows run in a Docker image, so the `shell`
  executor does not work. For more information, see
  [Configure runners to execute flows](../../user/duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows).
- A Slack workspace where you are an administrator. Use a personal test workspace, not the GitLab workspace.
- The `slack_duo_agent` [feature flag](../feature_flags/_index.md) enabled globally:

  ```ruby
  Feature.enable(:slack_duo_agent)
  ```

- A [default GitLab Duo namespace](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)
  set on your user, with the [Developer Flow](../../user/duo_agent_platform/flows/foundational_flows/developer.md)
  turned on for that top-level group.

## Expose your GDK to the internet

Slack must reach your GDK, so you need a reverse tunnel that gives your GDK a public HTTPS URL.

> [!warning]
> A tunnel exposes your local machine to the public internet. GitLab team members should get an approved exception, because the
> [laptop firewall requirements](https://handbook.gitlab.com/handbook/security/corporate/end-user-services/laptop-management/laptop-security/firewall/)
> prohibit circumventing the local firewall. Stop the tunnel when you finish.
> See this [past security exception request](https://gitlab.com/gitlab-com/gl-security/corp/issue-tracker/-/work_items/5009) as an example.

The following steps use [`ngrok`](https://ngrok.com/), but any tunnel that terminates TLS and
forwards to your GDK works.

1. Install `ngrok`, then add the authentication token from your
   [`ngrok` dashboard](https://dashboard.ngrok.com/get-started/your-authtoken):

   ```shell
   ngrok config add-authtoken <your_token>
   ```

1. Claim your static domain on the **Domains** page of the `ngrok` dashboard. The free plan includes
   one. A static domain means the tunnel URL survives restarts, so you configure the Slack app and
   `RAILS_HOSTS` only once.

1. Start a tunnel to the host and port your GDK listens on, and pass your static domain:

   ```shell
   ngrok http gdk.test:8080 --url=<your_static_domain>.ngrok-free.app
   ```

1. Start GDK with the `RAILS_HOSTS` set to your `ngrok` domain:

   ```shell
   RAILS_HOSTS=<your_static_domain>.ngrok-free.app gdk start
   ```

1. Confirm that the tunnel reaches your GDK by opening the tunnel URL in a browser. You should see your GDK sign-in page (It's fine if assets don't load).

## Create the Slack app

1. In your GDK, in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**, then expand **GitLab for Slack app**.
1. Select **Create Slack app**. GitLab redirects you to Slack with the generated manifest.

   If this returns a `502 Bad Gateway` page from NGINX, see
   [NGINX returns `502 Bad Gateway` when you create the Slack app](#nginx-returns-502-bad-gateway-when-you-create-the-slack-app).
1. Select your workspace, then **Next**, then select **Create and Install**.
1. On the **Review app permissions** page, select **Allow**, then select **Go to App Settings**.
1. Back in GitLab, in the **GitLab for Slack app** section:
   1. Select the **Enable GitLab for Slack app** checkbox.
   1. Paste the four credentials from the app settings page.
   1. Select **Save changes**.
1. In Slack, go to [**Your Apps**](https://api.slack.com/apps), select your app, then select **App Manifest**.
1. Replace every occurrence of your GDK host (`http://gdk.test:8080`) with your tunnel URL,
   except `oauth_config.redirect_urls`, which must stay as your GDK URL. Note the scheme change from `http` to `https`.

   > [!note]
   > Editing these values in the **Create Slack app** page does not work, as Slack ignores
   > the changes. This may be a bug that gets fixed at some point.

1. Select **Save Changes**.
1. Go to **Install App** and reinstall the app, so the new manifest gets applied.

## Give GitLab a bot token

Installing the app from Slack does not give GitLab a bot token. Install the app once more from
GitLab, which runs the OAuth exchange that stores the token on the `SlackIntegration` record:

1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **GitLab for Slack app** > **Install GitLab for Slack app**.
1. In Slack, select your test workspace, then select **Allow**.

Repeat these steps whenever you reinstall the app in Slack, because reinstalling mints a new bot
token that GitLab does not receive.

## Test a mention

1. In Slack, mention the bot in a channel, for example `@GitLab hi`. If the bot is not in the channel,
   Slack replies with a prompt to add it. Select **Add them**. Slack does not deliver the mention that
   triggered the prompt, so mention the bot again.
1. If your Slack account is not linked to a GitLab user, the bot adds a lock reaction (🔒) and sends
   you an ephemeral message with an authorization link. Select the link, authorize, then mention the
   bot again.
1. The bot reacts to your message, runs the Developer Flow as a CI/CD workload, and replies in the
   thread with a link to the session in GitLab.

Run the first mention as a user who can create projects in the default GitLab Duo namespace. Slack
mentions carry no project context, so `Ai::Messaging::DefaultProjectFlowResolver` derives one from
your default GitLab Duo namespace and calls `Ai::Messaging::WorkspaceProjectService`, which finds the
`duo-workspace` project in that namespace or creates it.

## Troubleshooting

### Verify that Slack can reach your GDK

1. In Slack, go to [**Your Apps**](https://api.slack.com/apps) and select your app.
1. Select **Event Subscriptions**. Next to the request URL, select **Retry** or **Verify**. Slack
   sends a challenge request to your GDK, and a green check confirms that your tunnel works.

If you later change the manifest to add scopes, select **Install App** > **Reinstall to Workspace**.
Slack grants scopes at install time only, so new scopes take effect only after you reinstall.

### NGINX returns `502 Bad Gateway` when you create the Slack app

`Create Slack app` redirects to Slack with the whole app manifest URL-encoded into the `Location`
header. The header is larger than the default proxy buffer in the GDK NGINX configuration, so NGINX
rejects the response and logs `upstream sent too big header while reading response header from
upstream` in `log/nginx/current`.

To resolve this error, in `nginx/conf/nginx.conf` in your GDK directory, add the following to the
`server` block, next to the other `proxy_` settings:

```nginx
proxy_buffer_size 16k;
proxy_buffers 8 16k;
proxy_busy_buffers_size 32k;
```

Then run `gdk restart nginx`. This file is generated from `components/nginx/nginx.conf.erb`, so
`gdk reconfigure` overwrites the change. To keep it, make the same change in the template.

### Slack API returns `account_inactive`

`integrations_json.log` records a Slack API error with `"error": "account_inactive"`, and the bot
never reacts or replies. Slack received the mention and GitLab processed it, but GitLab holds a
revoked bot token, so every call back to Slack fails.

To resolve this error, give GitLab the current token again:

1. Go to **Admin** > **Settings** > **Integrations** > **GitLab for Slack app**, and select the bin
   icon to delete the integration.
1. Select **Install GitLab for Slack app**, then select **Allow**.

### GitLab Duo `@mention` failures

When the bot posts an error back to the thread, match the message against
[GitLab Duo `@mention` failures](../../user/project/integrations/gitlab_slack_app_troubleshooting.md#gitlab-duo-mention-failures),
which lists each message, its cause, and the fix. That page also describes the log fields to filter
on in `log/integrations_json.log` and `log/sidekiq.log`.

Two cases behave differently in local development:

- The bot posts nothing at all. Check whether the mention reached your GDK before you assume the
  tunnel is at fault. Slack requests reach your GDK through the tunnel and then NGINX, so a delivered
  mention appears in `nginx/logs/access.log` in your GDK directory as a
  `POST /api/v4/integrations/slack/events` from `Slackbot`, and in `log/integrations_json.log` with
  Slack's IP address in `meta.remote_ip`. If neither log records the mention, Slack could not reach
  your GDK: check that your tunnel is running and that `RAILS_HOSTS` includes the tunnel host, then
  reverify the request URL in Slack. If the logs do record it, the mention arrived and the failure is
  in the response, such as [`account_inactive`](#slack-api-returns-account_inactive).
- The bot posts `Could not set up the service account for the Duo Developer flow`. The Developer Flow
  might be turned off for your top-level group. In the group, go to **Settings** > **GitLab Duo**,
  select **Change configuration**, and under **Flow execution**, turn on the Developer Flow.

### Default Duo namespace project does not get initialized properly

`Ai::Messaging::WorkspaceProjectService` creates the project with `initialize_with_readme: true`, so
the repository has a `README.md` commit on the default branch.

If the repository is not correctly initialized, flows have no default branch to check out and fail.
If this happens, initialize the repository with a commit.

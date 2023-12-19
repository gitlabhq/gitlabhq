---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting GitLab for Jira Cloud app administration **(FREE SELF)**

When administering the GitLab for Jira Cloud app for self-managed instances, you might encounter the following issues.

For GitLab.com, see [GitLab for Jira Cloud app](../../integration/jira/connect-app.md#troubleshooting).

## Sign-in message displayed when already signed in

You might get the following message prompting you to sign in to GitLab.com
when you're already signed in:

```plaintext
You need to sign in or sign up before continuing.
```

The GitLab for Jira Cloud app uses an iframe to add groups on the
settings page. Some browsers block cross-site cookies, which can lead to this issue.

To resolve this issue, set up [OAuth authentication](jira_cloud_app.md#set-up-oauth-authentication).

## Manual installation fails

You might get one of the following errors if you've installed the GitLab for Jira Cloud app
from the official marketplace listing and replaced it with [manual installation](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually):

```plaintext
The app "gitlab-jira-connect-gitlab.com" could not be installed as a local app as it has previously been installed from Atlassian Marketplace
```

```plaintext
The app host returned HTTP response code 401 when we tried to contact it during installation. Please try again later or contact the app vendor.
```

To resolve this issue, disable the **Jira Connect Proxy URL** setting.

- In GitLab 15.7:

  1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
  1. Execute `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`.

- In GitLab 15.8 and later:

  1. On the left sidebar, at the bottom, select **Admin Area**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **GitLab for Jira App**.
  1. Clear the **Jira Connect Proxy URL** text box.
  1. Select **Save changes**.

## Data sync fails with `Invalid JWT`

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

- If you [installed the GitLab for Jira Cloud app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually):

  - In GitLab 14.9 and later:
    - Contact the [Jira Software Cloud support](https://support.atlassian.com/jira-software-cloud/) and ask to trigger a new installed lifecycle event for the GitLab for Jira Cloud app in your group.
  - In all GitLab versions:
    - Re-install the GitLab for Jira Cloud app. This method might remove all synced data from the [Jira development panel](../../integration/jira/development_panel.md).

## `Failed to update the GitLab instance`

When you set up the GitLab for Jira Cloud app, you might get a `Failed to update the GitLab instance` error after you enter your self-managed instance URL.

To resolve this issue, ensure all prerequisites for your installation method have been met:

- [Prerequisites for connecting the GitLab for Jira Cloud app](jira_cloud_app.md#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](jira_cloud_app.md#prerequisites-1)

If you have configured a Jira Connect Proxy URL and the problem persists after checking the prerequisites, review [Debugging Jira Connect Proxy issues](#debugging-jira-connect-proxy-issues).

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

### Debugging Jira Connect Proxy issues

If you set **Jira Connect Proxy URL** to `https://gitlab.com` when you
[set up your instance](jira_cloud_app.md#set-up-your-instance), you can:

- Inspect the network traffic in your browser's development tools.
- Reproduce the `Failed to update the GitLab instance` error for more information.

You should see a `GET` request to `https://gitlab.com/-/jira_connect/installations`.

This request should return a `200 OK`, but it might return a `422 Unprocessable Entity` if there was a problem.
You can check the response body for the error.

If you cannot resolve the problem and you are a GitLab customer, contact [GitLab Support](https://about.gitlab.com/support/) for assistance. Provide
GitLab Support with:

1. Your GitLab self-managed instance URL.
1. Your GitLab.com username.
1. If possible, the `X-Request-Id` response header for the failed `GET` request to `https://gitlab.com/-/jira_connect/installations`.
1. Optional. [A HAR file that captured the problem](https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting).

The GitLab Support team can then look up why this is failing in the GitLab.com server logs.

#### GitLab Support

NOTE:
These steps can only be completed by GitLab Support.

In Kibana, the logs should be filtered for `json.meta.caller_id: JiraConnect::InstallationsController#update` and `NOT json.status: 200`.
If you have been provided the `X-Request-Id` value, you can use that against `json.correlation_id` to narrow down the results.

Each `GET` request to the Jira Connect Proxy URL `https://gitlab.com/-/jira_connect/installations` generates two log entries.

For the first log:

- `json.status` is `422`.
- `json.params.value` should match the GitLab self-managed URL `[[FILTERED], {"instance_url"=>"https://gitlab.example.com"}]`.

For the second log:

- `json.message` is `Proxy lifecycle event received error response` or similar.
- `json.jira_status_code` and `json.jira_body` might contain details on why GitLab.com wasn't able to connect back to the self-managed instance.
- If `json.jira_status_code` is `401` and `json.jira_body` is empty, [**Jira Connect Proxy URL**](jira_cloud_app.md#set-up-your-instance) might not be set to
  `https://gitlab.com`.

## Error when connecting the app

When you connect the GitLab for Jira Cloud app, you might get one of these errors:

```plaintext
Failed to load Jira Connect Application ID. Please try again.
```

```plaintext
Failed to link group. Please try again.
```

When you check the browser console, you might see the following message:

```plaintext
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://gitlab.example.com/-/jira_connect/oauth_application_id. (Reason: CORS header 'Access-Control-Allow-Origin' missing). Status code: 403.
```

A `403 Forbidden` is returned if the user information cannot be fetched from Jira because of insufficient permissions.

To resolve this issue, ensure the Jira user that installs and configures the app meets certain
[requirements](jira_cloud_app.md#jira-user-requirements).

---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab for Jira Cloud app administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

When administering the GitLab for Jira Cloud app, you might encounter the following issues.

For user documentation, see [GitLab for Jira Cloud app](../../integration/jira/connect-app.md#troubleshooting).

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

  1. Open a [Rails console](../operations/rails_console.md#starting-a-rails-console-session).
  1. Execute `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`.

- In GitLab 15.8 and later:

  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **GitLab for Jira App**.
  1. Clear the **Jira Connect Proxy URL** text box.
  1. Select **Save changes**.

If the issue persists, verify that your instance can connect to
`connect-install-keys.atlassian.com` to get the public key from Atlassian.
To test connectivity, run the following command:

```shell
# A `404 Not Found` is expected because you're not passing a token
curl --head "https://connect-install-keys.atlassian.com"
```

## Data sync fails with `Invalid JWT`

If the GitLab for Jira Cloud app continuously fails to sync data from your instance,
a secret token might be outdated. Atlassian can send new secret tokens to GitLab.
If GitLab fails to process or store these tokens, an `Invalid JWT` error occurs.

To resolve this issue:

- Confirm the instance is publicly available to:
  - GitLab.com (if you [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)).
  - Jira Cloud (if you [installed the app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)).
- Ensure the token request sent to the `/-/jira_connect/events/installed` endpoint when you install the app is accessible from Jira.
  The following command should return a `401 Unauthorized`:

  ```shell
  curl --include --request POST "https://gitlab.example.com/-/jira_connect/events/installed"
  ```

- If your instance has [SSL configured](https://docs.gitlab.com/omnibus/settings/ssl/), check your
  [certificates are valid and publicly trusted](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html#useful-openssl-debugging-commands).

Depending on how you installed the app, you might want to check the following:

- If you [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace),
  switch between GitLab versions in the GitLab for Jira Cloud app:

  <!-- markdownlint-disable MD044 -->

  1. In Jira, on the top bar, select **Apps > Manage your apps**.
  1. Expand **GitLab for Jira (gitlab.com)**.
  1. Select **Get started**.
  1. Select **Change GitLab version**.
  1. Select **GitLab.com (SaaS)**, then select **Save**.
  1. Select **Change GitLab version** again.
  1. Select **GitLab (self-managed)**, then select **Next**.
  1. Select all checkboxes, then select **Next**.
  1. Enter your **GitLab instance URL**, then select **Save**.

  <!-- markdownlint-enable MD044 -->

  If this method does not work, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new) if you're a Premium or Ultimate customer.
  Provide your GitLab instance URL and Jira URL. GitLab Support can try to run the following scripts to resolve the issue:

  ```ruby
  # Check if GitLab.com can connect to the GitLab Self-Managed instance
  checker = Gitlab::TcpChecker.new("gitlab.example.com", 443)

  # Returns `true` if successful
  checker.check

  # Returns an error if the check fails
  checker.error
  ```

  ```ruby
  # Locate the installation record for the GitLab Self-Managed instance
  installation = JiraConnectInstallation.find_by_instance_url("https://gitlab.example.com")

  # Try to send the token again from GitLab.com to the GitLab Self-Managed instance
  ProxyLifecycleEventService.execute(installation, :installed, installation.instance_url)
  ```

- If you [installed the app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually):
  - Ask [Jira Cloud Support](https://support.atlassian.com/jira-software-cloud/) to verify that Jira can connect to your
    instance.
  - [Reinstall the app](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually). This method might remove all [synced data](../../integration/jira/connect-app.md#gitlab-data-synced-to-jira) from the [Jira development panel](../../integration/jira/development_panel.md).

## Error: `Failed to update the GitLab instance`

When you set up the GitLab for Jira Cloud app, you might get a `Failed to update the GitLab instance` error after you enter your GitLab Self-Managed instance URL.

To resolve this issue, ensure all prerequisites for your installation method have been met:

- [Prerequisites for connecting the GitLab for Jira Cloud app](jira_cloud_app.md#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](jira_cloud_app.md#prerequisites-1)

If you have configured a Jira Connect Proxy URL and the problem persists after checking the prerequisites, review [Debugging Jira Connect Proxy issues](#debugging-jira-connect-proxy-issues).

If you're using GitLab 15.8 and earlier and have previously enabled both the `jira_connect_oauth_self_managed`
and the `jira_connect_oauth` feature flags, you must disable the `jira_connect_oauth_self_managed` flag
due to a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388943). To check for these flags:

1. Open a [Rails console](../operations/rails_console.md#starting-a-rails-console-session).
1. Execute the following code:

   ```ruby
   # Check if both feature flags are enabled.
   # If the flags are enabled, these commands return `true`.
   Feature.enabled?(:jira_connect_oauth)
   Feature.enabled?(:jira_connect_oauth_self_managed)

   # If both flags are enabled, disable the `jira_connect_oauth_self_managed` flag.
   Feature.disable(:jira_connect_oauth_self_managed)
   ```

### Error: `Invalid audience`

If you're using a [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy),
[`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog) might contain a message like:

```plaintext
Invalid audience. Expected https://proxy.example.com/-/jira_connect, received https://gitlab.example.com/-/jira_connect
```

To resolve this issue, set the reverse proxy FQDN as an
[additional JWT audience](jira_cloud_app.md#set-an-additional-jwt-audience).

### Debugging Jira Connect Proxy issues

If you set **Jira Connect Proxy URL** to `https://gitlab.com` when you
[set up your instance](jira_cloud_app.md#set-up-your-instance), you can:

- Inspect the network traffic in your browser's development tools.
- Reproduce the `Failed to update the GitLab instance` error for more information.

You should see a `GET` request to `https://gitlab.com/-/jira_connect/installations`.

This request should return a `200 OK`, but it might return a `422 Unprocessable Entity` if there was a problem.
You can check the response body for the error.

If you cannot resolve the issue and you're a GitLab customer, contact [GitLab Support](https://about.gitlab.com/support/) for assistance.
Provide GitLab Support with:

- Your GitLab Self-Managed instance URL.
- Your GitLab.com username.
- Optional. The `X-Request-Id` response header for the failed `GET`
  request to `https://gitlab.com/-/jira_connect/installations`.
- Optional. [A HAR file](https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting)
  you've processed with [`harcleaner`](https://gitlab.com/gitlab-com/support/toolbox/harcleaner) that captures the issue.

GitLab Support can then investigate the issue in the GitLab.com server logs.

#### GitLab Support

NOTE:
These steps can only be completed by GitLab Support.

Each `GET` request made to the Jira Connect Proxy URL `https://gitlab.com/-/jira_connect/installations` generates two log entries.

To locate the relevant log entries in Kibana, either:

- If you have the `X-Request-Id` value or correlation ID for the `GET` request to
  `https://gitlab.com/-/jira_connect/installations`, the
  [Kibana](https://log.gprd.gitlab.net/app/r/s/0FdPP) logs should be filtered for
  `json.meta.caller_id: JiraConnect::InstallationsController#update`, `NOT json.status: 200`
   and `json.correlation_id: <X-Request-Id>`. This should return two log entries.

- If you have the self-managed URL for the customer:
  1. The [Kibana](https://log.gprd.gitlab.net/app/r/s/QVsD4) logs should be filtered for
     `json.meta.caller_id: JiraConnect::InstallationsController#update`, `NOT json.status: 200`
     and `json.params.value: {"instance_url"=>"https://gitlab.example.com"}`. The self-managed URL
     must not have a leading slash. This should return one of the log entries.
  1. Add the `json.correlation_id` to the filter.
  1. Remove the `json.params.value` filter. This should return the other log entry.

For the first log:

- `json.status` is `422 Unprocessable Entity`.
- `json.params.value` should match the GitLab Self-Managed URL `[[FILTERED], {"instance_url"=>"https://gitlab.example.com"}]`.

For the second log, you might have one of the following scenarios:

- Scenario 1:
  - `json.message`, `json.jira_status_code`, and `json.jira_body` are present.
  - `json.message` is `Proxy lifecycle event received error response` or similar.
  - `json.jira_status_code` and `json.jira_body` might contain the response received from the GitLab Self-Managed instance or a proxy in front of the instance.
  - If `json.jira_status_code` is `401 Unauthorized` and `json.jira_body` is `(empty)`:
    - [**Jira Connect Proxy URL**](jira_cloud_app.md#set-up-your-instance) might not be set to `https://gitlab.com`.
    - The GitLab Self-Managed instance might be blocking outgoing connections. Ensure that your
      GitLab Self-Managed instance can connect to both `connect-install-keys.atlassian.com`
      and `gitlab.com`.
    - The GitLab Self-Managed instance is unable to decrypt the JWT token from Jira. [From GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147234),
      the [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog) contains more information about the error.
    - If a [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy) is in front of your GitLab Self-Managed instance,
      the `Host` header sent to the GitLab Self-Managed instance might not match the reverse proxy FQDN.
      Check the [Workhorse logs](../logs/_index.md#workhorse-logs) on the GitLab Self-Managed instance:

      ```shell
      grep /-/jira_connect/events/installed /var/log/gitlab/gitlab-workhorse/current
      ```

      The output might contain the following:

      ```json
      {
        "host":"gitlab.mycompany.com:443", // The host should match the reverse proxy FQDN entered into the GitLab for Jira Cloud app
        "remote_ip":"34.74.226.3", // This IP should be within the GitLab.com IP range https://docs.gitlab.com/ee/user/gitlab_com/#ip-range
        "status":401,
        "uri":"/-/jira_connect/events/installed"
      }
      ```

- Scenario 2:
  - `json.exception.class` and `json.exception.message` are present.
  - `json.exception.class` and `json.exception.message` contain whether an issue occurred while contacting the GitLab Self-Managed instance.

## Error: `Failed to link group`

When you link a group, you might get the following error:

```plaintext
Failed to link group. Please try again.
```

This error can be returned for multiple reasons.

- A `403 Forbidden` can be returned if the user information cannot be fetched from Jira because of insufficient permissions.
  To resolve this issue, ensure the Jira user that installs and configures the app
  meets certain [requirements](jira_cloud_app.md#jira-user-requirements).

- This error might also occur if you use a rewrite or subfilter with a [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy).
  The app key used in requests contains part of the server hostname, which some reverse proxy filters might capture.
  The app key in Atlassian and GitLab must match for authentication to work correctly.

- This error can happen if the GitLab instance was initially misconfigured when the
  GitLab for Jira Cloud app was first installed. In this case, data in the `jira_connect_installation`
  table might need to be deleted. Only delete this data if you are sure that no existing
  GitLab for Jira app installations need to be kept.

  1. Uninstall the GitLab for Jira Cloud app from any Jira projects.
  1. To delete the records, run this command in the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

     ```ruby
     JiraConnectInstallation.delete_all
     ```

## Error: `Failed to load Jira Connect Application ID`

When you sign in to the GitLab for Jira Cloud app after you point the app
to your GitLab Self-Managed instance, you might get the following error:

```plaintext
Failed to load Jira Connect Application ID. Please try again.
```

When you check the browser console, you might also see the following message:

```plaintext
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://gitlab.example.com/-/jira_connect/oauth_application_id. (Reason: CORS header 'Access-Control-Allow-Origin' missing). Status code: 403.
```

To resolve this issue:

1. Ensure `/-/jira_connect/oauth_application_id` is publicly accessible and returns a JSON response:

   ```shell
   curl --include "https://gitlab.example.com/-/jira_connect/oauth_application_id"
   ```

1. If you [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace),
   ensure [**Jira Connect Proxy URL**](jira_cloud_app.md#set-up-your-instance) is set to `https://gitlab.com` with no trailing slash.

## Error: `Missing required parameter: client_id`

When you sign in to the GitLab for Jira Cloud app after you point the app
to your GitLab Self-Managed instance, you might get the following error:

```plaintext
Missing required parameter: client_id
```

To resolve this issue, ensure all prerequisites for your installation method have been met:

- [Prerequisites for connecting the GitLab for Jira Cloud app](jira_cloud_app.md#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](jira_cloud_app.md#prerequisites-1)

## Error: `Failed to sign in to GitLab`

When you sign in to the GitLab for Jira Cloud app after you point the app
to your GitLab Self-Managed instance, you might get the following error:

```plaintext
Failed to sign in to GitLab
```

To resolve this issue, ensure the **Trusted** and **Confidential** checkboxes are cleared in
the [OAuth application](jira_cloud_app.md#set-up-oauth-authentication) created for the app.

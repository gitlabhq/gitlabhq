---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting the GitLab Workflow extension for VS Code

If you encounter any issues with the GitLab Workflow extension for VS Code, or have feature requests for it:

1. Check the [extension documentation](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/README.md)
   for known issues and solutions.
1. Report bugs or request features in the
   [`gitlab-vscode-extension` issue queue](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues).

## Enable debug logs

Both the VS Code Extension and the GitLab Language Server provide logs that can help you troubleshoot. To enable debug logging:

1. In VS Code, on the top bar, go to **Code > Preferences > Settings**.
1. On the top right corner, select **Open Settings (JSON)** to edit your `settings.json` file.
1. Add this line, or edit it if it already exists:

   ```json
   "gitlab.debug": true,
   ```

1. Save your changes.

### View log files

To view debug logs from either the VS Code Extension or the GitLab Language Server:

1. Use the command `GitLab: Show Extension Logs` to view the output panel.
1. In the upper right corner of the output panel, select either **GitLab Workflow** or
   **GitLab Language Server** from the dropdown list.

## Error: `407 Access Denied` failure with a proxy

If you use an authenticated proxy, you might encounter an error like `407 Access Denied (authentication_failed)`:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

GitLab Duo Code Suggestions does not support authenticated proxies. For the proposed feature,
see [issue 1234](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1234) in the extension's project.

## Configure self-signed certificates

To use self-signed certificates to connect to your GitLab instance, configure them using these settings.
These settings are community contributions, because the GitLab team uses a public CA. None of the fields are required.

Prerequisites:

- You're not using the [`http.proxy` setting](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)
  in VS Code. For more information, see [issue 314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314).

| Setting name | Default | Information |
| ------------ | :-----: | ----------- |
| `gitlab.ca`  | null    | Deprecated. See [the SSL setup guide](ssl.md) for more information on how to set up your self-signed CA. |
| `gitlab.cert`| null    | Unsupported. See [epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244). If your self-managed GitLab instance requires a custom certificate or key pair, set this option to point to your certificate file. See `gitlab.certKey`. |
| `gitlab.certKey`| null    | Unsupported. See [epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244). If your self-managed GitLab instance requires a custom certificate or key pair, set this option to point to your certificate key file. See `gitlab.cert`. |
| `gitlab.ignoreCertificateErrors` | false   | Unsupported. See [epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244). If you use a self-managed GitLab instance with no SSL certificate, or have certificate issues that prevent you from using the extension, set this option to `true` to ignore certificate errors. |

## Disable code suggestions

Code completion is enabled by default. To disable it:

1. In VS Code, on the left sidebar, select **Extensions > GitLab Workflow**.
1. Select **Manage** (**{settings}**) **> Extension Settings**.
1. In **GitLab > Duo Code Suggestions**, clear **Enable GitLab Duo Code Suggestions**.

## Disable streaming of code generation results

By default, code generation streams AI-generated code. Streaming sends generated code
to your editor incrementally, rather than waiting for the full code snippet to generate.
This allows for a more interactive and responsive experience.

If you prefer to see code generation results only when they are complete, you can turn off streaming.
Disabling streaming means that code generation requests might be perceived
as taking longer to resolve. To disable streaming:

1. In VS Code, on the top bar, go to **Code > Settings > Settings**.
1. On the top right corner, select **Open Settings (JSON)** to edit your `settings.json` file:

   ![The icons on the top right corner of VS Code, including 'Open Settings.'](img/open_settings_v17_5.png)
1. In your `settings.json` file, add this line, or set it to `false` it already exists:

   ```json
   "gitlab.featureFlags.streamCodeGenerations": false,
   ```

1. Save your changes.

## Error: Direct connection fails

> - Direct connection [introduced](https://gitlab.com/groups/gitlab-org/-/epics/13252) in GitLab 17.2.

To reduce latency, the Workflow extension tries to send suggestion completion requests directly to GitLab Cloud Connector,
bypassing the GitLab instance. This network connection does not use the proxy and certificate settings of the VS Code extension.

If your GitLab instance doesn't support direct connections, or your network prevents the extension from connecting to
GitLab Cloud Connector, you might see these warnings in your logs:

```plaintext
Failed to fetch direct connection details from GitLab instance.
Code suggestion requests will be sent to GitLab instance.
```

This error means your instance either doesn't support direct connections, or is misconfigured.
To fix the problem, see the [troubleshooting guide for Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md).

If you see this error, the extension can't connect to GitLab Cloud Connector, and is reverting to use your GitLab instance:

```plaintext
Direct connection for code suggestions failed.
Code suggestion requests will be sent to your GitLab instance.
```

The indirect connection through your GitLab instance is about 100 ms slower, but otherwise works the same.
This issue is often caused by network connection problems, like with your LAN firewall or proxy settings.

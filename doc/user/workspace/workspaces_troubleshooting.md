---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create a GitLab workspaces proxy to authenticate and authorize workspaces in your cluster.
title: Troubleshooting workspaces
---

When working with GitLab workspaces, you might encounter the following issues.

## Error: `Failed to renew lease`

When creating a workspace, you might encounter the following error message in the agent's log:

```plaintext
{"level":"info","time":"2023-01-01T00:00:00.000Z","msg":"failed to renew lease gitlab-agent-remote-dev-dev/agent-123XX-lock: timed out waiting for the condition\n","agent_id":XXXX}
```

The error is because of a known issue in the GitLab agent for Kubernetes.
This error occurs when an agent instance cannot renew its leadership lease, causing leader-only modules like `remote_development` to shut down.

To resolve this issue:

1. Restart the agent instance.
1. If the issue persists, check your Kubernetes cluster's health and connectivity.

## Error: `No agents available to create workspaces`

When you create a workspace in a project, you might get the following error:

```plaintext
No agents available to create workspaces. Please consult Workspaces documentation for troubleshooting.
```

This error can occur for several reasons. Work through the following troubleshooting steps.

### Check permissions

1. Ensure you have at least the Developer role for both the workspace project and agent project.
1. Verify the agent is allowed in an ancestor group of your workspace project.
For more information, see [allow an agent](gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-in-a-group).

### Check agent configuration

Verify the `remote_development` module is enabled in your agent configuration:

   ```yaml
   remote_development:
     enabled: true
   ```

If the `remote_development` module is disabled for the GitLab agent for Kubernetes,
set [`enabled`](settings.md#enabled) to `true`.

### Check agent name mismatch

Ensure the agent name you created in the [Create a GitLab Agent for Kubernetes token](set_up_infrastructure.md#create-a-gitlab-agent-for-kubernetes-token) step matches the folder name in
`.gitlab/agents/FOLDER_NAME/`.

If the names are different, rename the folder to match the agent name exactly.

### Check agent connection status

Verify the agent is connected to GitLab:

1. Go to your group.
1. Select **Operate** > **Kubernetes clusters**.
1. Verify if **Connection status** is **Connected**. If not connected, check the agent logs:

   ```shell
   kubectl logs -f -l app=gitlab-agent -n gitlab-workspaces
   ```

## Error: `unsupported scheme in GitLab Kubernetes Agent Server address`

This error occurs when the Kubernetes Agent Server (KAS) address is missing the required protocol
scheme.

To resolve this issue:

1. Add the `wss://` prefix to your `TF_VAR_kas_address` variable. For example: `wss://kas.gitlab.com`.
1. Update your configuration and redeploy the agent.

## Error: `ImagePullBackOff` when starting workspace in offline environment

When you create a workspace in an offline environment, you might see this error:

```plaintext
workspace-example-abc123-def456   0/1   Init:ImagePullBackOff   0
```

This error occurs when the workspace cannot pull init container images from `registry.gitlab.com`.
In offline environments, the init container image is hardcoded and cannot be overridden from your devfile.

{{< alert type="warning" >}}

The following workaround is unsupported and temporary. Use at your own risk until
[issue 509983](https://gitlab.com/gitlab-org/gitlab/-/issues/509983) provides a supported solution.

{{< /alert >}}

The workaround is:

1. Deploy a [Kubernetes mutating webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) to modify init container image references.
1. Ensure you have cluster administrator privileges to create, update, or delete
   the `MutatingWebhookConfiguration`.

For an example implementation, see [A Simple Kubernetes Admission Webhook](https://slack.engineering/simple-kubernetes-webhook/).

## Error: `redirect URI included is not valid`

When accessing a workspace, you might encounter an OAuth error about an invalid redirect URI.

This error can occur for the following reasons:

- OAuth application is not configured correctly. To resolve this issue:

  1. Verify your OAuth application redirect URI in GitLab matches your domain.
  1. Update the OAuth application redirect URI. For example: `https://YOUR_DOMAIN/auth/callback`.

- Workspaces proxy is using outdated OAuth credentials. to resolve this issue:

  1. Verify the proxy is using the latest OAuth credentials.
  1. Restart the workspaces proxy:

      ```shell
      kubectl rollout restart deployment -n gitlab-workspaces gitlab-workspaces-proxy
      ```

## Error: `Workspace does not exist`

You might get an error in VS Code that states

```plaintext
Workspace does not exist

Please select another workspace to open.
```

This issue occurs when the workspace starts successfully, but the expected project directory is
missing because the Git clone operation failed. Git clone operations fail due to network issues,
infrastructure problems, or revoked repository permissions.

To resolve this issue:

1. When prompted to select another workspace in the error dialog, select **Cancel**.
1. From the VS Code menu, select **File** > **Open Folder**.
1. Go to the `/projects` directory and select **OK**.
1. In the **EXPLORER** panel, check for a directory with the same name as your project.
   - If the directory is missing, the Git clone operation failed completely.
   - If the directory exists but is empty, the clone operation started but didn't complete.
1. Open a terminal. From the menu, select **Terminal** > **New Terminal**.
1. Go to the workspace logs directory:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. Check the logs for error output that might indicate why Git clone failed:

   ```shell
   less poststart-stderr.log
   ```

1. Resolve the identified issue and restart your workspace.

If the issue persists, create a new workspace with a working container image that includes Git.

## Debug `postStart` events

When your custom `postStart` events fail or don't behave as expected, you can use the workspace
logs directory to debug the issues.

Common `postStart` debugging scenarios and their resolutions:

- `Command not found`: Check `poststart-stderr.log` for errors indicating
  missing dependencies in your container image.
- `Permission denied`: Check for permission errors in `poststart-stderr.log` that might
  require adjusting file permissions or user configuration.
- `Network issues`: Check for connection timeouts or DNS resolution failures when your
  `postStart` events download dependencies or access external resources.
- `Long-running commands`: If `postStart` events hang, check `poststart-stdout.log`
  to see if commands are still running or if they completed successfully.

To check the `postStart` command execution logs:

1. Open a terminal in your workspace.
1. Go to the workspace logs directory:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. View the log files:

   ```shell
   # Monitor postStart execution output in real-time
   tail -f poststart-stdout.log

   # Check postStart errors
   cat poststart-stderr.log

   # Check VS Code server startup
   cat start-vscode.log
   ```

1. Check for errors:

   ```shell
   # Search for error messages across all logs
   grep -i error *.log

   # Search for specific command output
   grep "your-command-name" poststart-stdout.log
   ```

1. Resolve the identified issues and restart your workspace.

For more information, see [Workspace logs directory](_index.md#workspace-logs-directory) and
[Available log files](_index.md#available-log-files).

<!--- Other suggested topics:

## DNS configuration

## Workspace stops unexpectedly

## Workspace creation fails due to quotas

## Network connectivity

## SSH connection failures

### Network policy restrictions

-->

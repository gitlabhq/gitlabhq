---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Troubleshoot common issues with the GitLab Duo Agent Platform, including flows, permissions, and push rule configuration.
title: Troubleshooting the GitLab Duo Agent Platform
---

If you are working with the GitLab Duo Agent Platform,
you might encounter the following issues.

## View logs

After a flow is created, you can view the flow's session by going to **AI** > **Sessions**.

The **Details** tab shows a link to the CI/CD job logs.
These logs can contain troubleshooting information.

## Flows not visible in the UI

If you are trying to run a flow but it's not visible in the GitLab UI:

1. Ensure you have at least Developer role in the project.
1. Ensure GitLab Duo is [turned on and flows are allowed to execute](../gitlab_duo/turn_on_off.md).
1. Ensure the group you are in has been given permission [to use flows](../../administration/gitlab_duo/configure/access_control.md).
1. If the top-level group is configured correctly but flows are not visible for an individual project:
   1. Go to the project.
   1. Select **AI** > **Flows**.
   1. In the upper-right corner, select **Enable flow from group**.
   1. Select a flow, then select **Enable**.

1. If it still does not work:
   1. Disable the affected flow in the top-level group and save the configuration.
   1. Enable the affected flow in the top-level group and save the configuration.
   1. Wait a few minutes for the setting to propagate across your groups.

## Insufficient permissions to create a new pipeline for imported projects

If you are trying to run foundational flows in an imported project or a project created from a template,
you might get the error: `Error in creating workload: Insufficient permissions to create a new pipeline`.

To fix this issue:

1. Go to the top-level group.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **Flow execution**, identify the foundational flows you want to turn on.
1. Disable the flows in the top-level group and save the configuration.
1. Enable the same flows in the top-level group and save the configuration.
1. Wait a few minutes for the setting to propagate across projects in the group.

## Error: `Your request was valid but Workflow failed to complete it`

Flows require the project repository to have at least one commit.
If you run a flow in a project with no commits, you get the error:
`Your request was valid but Workflow failed to complete it. Please try again.`

This error occurs because the flow cannot find the default branch
in a repository with no commits.

To fix this issue, push an initial commit to the project before you run a flow.
For example, add a `README.md` file.

## Session is stuck in created state

If a session for your flow does not start:

- Ensure push rules are configured.

### Configure push rules to allow a service account

In the GitLab UI, foundational flows use a service account that:

- Creates commits with its own email address.
- Creates a [workload pipeline](../../ci/pipelines/pipeline_types.md#workload-pipeline).

Prerequisites:

- Administrator access.

To configure push rules for a project:

1. Find the email address associated with the service account:
   1. In the upper-right corner, select **Admin**.
   1. Select **Overview** > **Users** and search for the account associated with the flow.
      The account follows the pattern `duo-[flow-name]-[top-level-group-name]`.
   1. Locate the service account user and copy the email address.

1. Allow the email address to push to the project:
   1. In the top bar, select **Search or go to** and find your project.
   1. Select **Settings** > **Repository**.
   1. Expand **Push rules**.
   1. In **Commit author's email**, add a regular expression that allows the email address you just copied.
   1. Select **Save push rules**.

1. Allow the `duo/feature/` branch prefix:
   1. In the **Push rules** section, find **Branch name**.
   1. Add a regular expression that allows branches starting with ^duo/(fix|feature|refactor|docs/).*
      For example: `^(duo/feature)/.*$`
   1. Select **Save push rules**.

To create push rules for the instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Push rules**.
1. Follow the previous steps to allow **Commit author's email** and **Branch name**.
1. Select **Save push rules**.

## Error: `SSL certificate OpenSSL verify result: unable to get local issuer certificate (20)`

On GitLab Self-Managed instances that use custom or self-signed CA certificates, this message might display when GitLab Duo Agent Platform jobs fail during
the initial `git clone` (the `get_sources` phase).

This happens because GitLab Duo Agent Platform jobs set `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM=1`
to harden the agent sandbox. These variables prevent Git from reading system and global configuration files.
This breaks the runner's mechanism for injecting CA certificate paths during `get_sources`.

CI/CD jobs that do not execute flows are not affected. This issue is specific to workload pipelines for the GitLab Duo Agent Platform.

To resolve this issue, in the [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/) file, set the `GIT_SSL_CAINFO` environment variable at the runner level,
and mount the CA certificate into the container:

```toml
[[runners]]
  environment = ["GIT_SSL_CAINFO=/etc/gitlab-runner/certs/ca.crt"]
  [runners.docker]
    volumes = ["/path/to/your/ca-bundle.crt:/etc/gitlab-runner/certs/ca.crt:ro"]
```

Replace `/path/to/your/ca-bundle.crt` with the path to your CA certificate bundle on the runner host.
The file must be a PEM-formatted CA bundle that contains your root CA and any intermediate certificates.

You might expect to set this as a CI/CD variable, but custom CI/CD variables are
[not available](flows/execution_variables.md#custom-cicd-variables) in GitLab Duo Agent Platform jobs.
You must use the runner's `config.toml` `environment` directive instead.

To connect GitLab Duo CLI to your GitLab instance over a custom CA, add `NODE_EXTRA_CA_CERTS`
to the same `environment` line:

```toml
[[runners]]
  environment = [
    "GIT_SSL_CAINFO=/etc/gitlab-runner/certs/ca.crt",
    "NODE_EXTRA_CA_CERTS=/etc/gitlab-runner/certs/ca.crt"
  ]
  [runners.docker]
    volumes = ["/path/to/your/ca-bundle.crt:/etc/gitlab-runner/certs/ca.crt:ro"]
```

If the GitLab Duo CLI runs in the Anthropic Sandbox Runtime (SRT), runner `environment` variables might not reach it. If TLS errors persist after this change, in your `agent-config.yml`, in the `setup_script`, set `NODE_EXTRA_CA_CERTS` instead. The `setup_script` runs inside the container and is not filtered by the sandbox.

The `GIT_SSL_CAINFO` variable addresses Git operations that occur before the GitLab Duo CLI starts. For GitLab Duo CLI certificate configuration, see [custom SSL certificates](../gitlab_duo_cli/_index.md#custom-ssl-certificates).

## Troubleshooting in your IDE

If you encounter an issue while working with the GitLab Duo Agent Platform in your IDE, start by
ensuring that GitLab Duo is on and that you are properly connected.

- You meet the GitLab Duo Agent Platform [prerequisites](_index.md#prerequisites).
- Admin mode is [disabled](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session).
- Your project is in a [group namespace](../namespace/_index.md).
- You have a [default GitLab Duo namespace](../profile/preferences.md#namespace-resolution-in-your-local-environment)
  set or have a project open that has GitLab Duo access.

For further support, see the troubleshooting page for your extension and IDE:

- [GitLab for VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md#gitlab-duo)
- [GitLab Duo plugin for JetBrains IDEs](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)
- [GitLab for Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)

## Run the configuration diagnostic script

If you cannot identify the cause of a GitLab Duo Agent Platform issue from the related
feature documentation, run the diagnostic script to check your configuration.

The script checks the full configuration chain required for GitLab Duo Agent Platform features:

- License validity and plan.
- Instance-level GitLab Duo settings.
- CI/CD runners with the `gitlab--duo` tag.
- Namespace and project GitLab Duo settings.
- Foundational flows and their service accounts.
- Feature availability, such as Code Review Flow availability and automatic review settings.

> [!warning]
> This script reads configuration data only and does not modify any settings.
> The output may contain internal configuration details.
> Sanitize the output before sharing it with support.

Prerequisites:

- GitLab 18.8 or later

To run the diagnostic script in GitLab 19.0 or later:

- Run the built-in `gitlab:duo:verify_setup` [Rake task](../../administration/raketasks/_index.md).
  Replace `<group/project>` with the full path to the project, for example `gitlab-org/gitlab`.

  For example:

  ```shell
  sudo gitlab-rake "gitlab:duo:verify_setup[<group/project>]"
  ```

To run the diagnostic script in GitLab 18.8 to GitLab 18.11:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Download [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb).
1. Copy the `verify_setup.rb` file to your GitLab server.
1. Run the script.
   Replace `<group/project>` with the full path to the project, for example `gitlab-org/gitlab`.

   ```shell
   sudo gitlab-rails runner "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Download [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb).
1. Copy the `verify_setup.rb` file into the container.
1. Run the script.
   Replace `<group/project>` with the full path to the project, for example `gitlab-org/gitlab`.

   ```shell
   docker cp verify_setup.rb <container-id>:/tmp/verify_setup.rb
   docker exec -it <container-id> gitlab-rails runner \
   "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Download [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb).
1. Copy the `verify_setup.rb` file to your GitLab server.
1. Run the script from the GitLab application directory.
   Replace `<group/project>` with the full path to the project, for example `gitlab-org/gitlab`.

   ```shell
   sudo -u git bundle exec rails runner \
   "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Download [`verify_setup.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/verify_setup.rb).
1. Copy the `verify_setup.rb` file into the toolbox pod.
1. Run the script.
   Replace `<group/project>` with the full path to the project, for example `gitlab-org/gitlab`.

   ```shell
   # Find the toolbox pod
   kubectl get pods --namespace <namespace> -lapp=toolbox

   kubectl cp verify_setup.rb <namespace>/<toolbox-pod-name>:/tmp/verify_setup.rb
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner \
   "load '/tmp/verify_setup.rb'; Gitlab::Duo::Administration::VerifySetup.new('<group/project>').execute"
   ```

{{< /tab >}}

{{< /tabs >}}

## Related topics

- [Troubleshooting GitLab Duo Agentic Chat](../gitlab_duo_chat/troubleshooting.md)
- [Troubleshooting Code Review Flow](flows/foundational_flows/code_review.md#troubleshooting)
- [Troubleshooting GitLab MCP clients](../gitlab_duo/model_context_protocol/mcp_clients.md#troubleshooting)
- [Troubleshooting the GitLab MCP Server](../gitlab_duo/model_context_protocol/mcp_server_troubleshooting.md)

---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshoot GitLab Duo Workflow
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Private beta

{{< /details >}}

{{< alert type="warning" >}}

This feature is [a private beta](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

## General guidance

If you encounter issues, ensure that you have:

1. The latest version of the GitLab Workflow extension for VS Code.
1. A project that meets the [prerequisites](_index.md#prerequisites).
1. The repository open in VS Code.
1. The branch checked out.

For details on these steps, see [the prerequisites](_index.md#prerequisites) and
[how to connect to your repository](_index.md#connect-to-your-repository).

## View debugging logs

You can troubleshoot some issues by viewing debugging logs.

1. Open local debugging logs:
   - On macOS: <kbd>Cmd</kbd> + <kbd>,</kbd>
   - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
1. Search for the setting **GitLab: Debug** and enable it.
1. Open the language server logs:
   1. In VS Code, select **View** > **Output**.
   1. In the output panel at the bottom, in the upper-right corner,
      select **GitLab Workflow** or **GitLab Language Server** from the list.
1. Review for errors, warnings, connection issues, or authentication problems.

## Network issues

Your network might block the connection to the Workflow service,
for example, by using a firewall. The network must let HTTP/2 traffic through to the service.

To confirm that you can connect to the Workflow service:

1. In Google Chrome or Firefox, open Developer Tools and select the **Network** tab.
1. Right-click the column headers to show the **Protocol** column.
1. In the address bar, enter `https://duo-workflow.runway.gitlab.net/DuoWorkflow/ExecuteWorkflow`.
1. Ensure the request was successful and the **Protocol** column includes `h2` in Chrome or `HTTP/2` in Firefox.

If the request fails, your network might be blocking the connection.

## Docker setup

If you encounter issues with your Docker setup for Workflow, try the following steps.

1. [Install Docker and set the socket file path](docker_set_up.md#install-docker-and-set-the-socket-file-path).
1. Restart your container manager. For example, if you use Colima, `colima restart`.
1. Pull the base Docker image:

   ```shell
   docker pull registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.4
   ```

1. For permission issues, ensure your operating system user has the necessary Docker permissions.
1. Verify that Docker has internet connectivity by executing the command `docker image pull redhat/ubi8`.
   If this does not work, the DNS configuration of Colima might be at fault.
   Edit the DNS setting in `~/.colima/default/colima.yaml` to `dns: [1.1.1.1]` and then restart Colima with `colima restart`.
1. Check the executor logs:
   - Use `docker ps -a | grep duo-workflow` to get the list of Workflow containers and their ids.
   - Use `docker logs <container_id>` to view the logs for the specific container.

## IDE configuration

You can try several things to ensure your repository is properly configured and connected.

### View the project in the GitLab Workflow extension

Start by ensuring the correct project is selected in the GitLab Workflow extension for VS Code.

1. In VS Code, on the left sidebar, select **GitLab Workflow** ({{< icon name="tanuki" >}}).
1. Ensure the project is listed and selected.

If an error message appears next to the project name, select it to reveal what needs to be updated.

For example, you might have multiple repositories and need to select one, or there might be no repositories at all.

#### No Git repository

If your workspace doesn't have a Git repository initialized, you must create a new one:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. Select **Initialize Repository**.

When the repository is initialized, you should see the name in the **Source Control** view.

#### Git repository with no GitLab remote

You might have a Git repository but it's not properly connected to GitLab.

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. On the **Source Control** label, right-click and select **Repositories**.
1. Next to your repository, select the ellipsis ({{< icon name=ellipsis_h >}}), then **Remote > Add Remote**.
1. Enter your GitLab project URL.
1. Select the newly added remote as your upstream.

#### Multiple GitLab remotes

Your repository might have multiple GitLab remotes configured.
To select the correct one:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. On the status bar, select the current remote name.
1. From the list, select the appropriate GitLab remote.
1. Ensure the selected remote belongs to a group namespace in GitLab.

#### Multiple GitLab projects

If your VS Code workspace contains multiple GitLab projects, you might want
to close all the projects you're not using.

To close projects:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. Ensure repositories are shown: on the **Source Control** label, right-click and select **Repositories**.
1. Right-click the repository you want to close and select **Close Repository**.

### Project not in a group namespace

GitLab Duo Workflow requires that projects belong to a group namespace.

To determine the namespace your project is in, [look at the URL](../namespace/_index.md#determine-which-type-of-namespace-youre-in).

If necessary, you can
[transfer your project to a group namespace](../../tutorials/move_personal_project_to_group/_index.md#move-your-project-to-a-group).

## Still having issues?

Contact your GitLab administrator for assistance.

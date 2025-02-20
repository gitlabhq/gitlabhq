---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshoot GitLab Duo Workflow
---
If you encounter issues:

1. Ensure that you have the latest version of the GitLab Workflow extension.
1. Ensure that the project you want to use it with meets the [prerequisites](set_up.md#prerequisites).
1. Ensure that the folder you opened in VS Code has a Git repository for your GitLab project.
1. Ensure that you've checked out the branch for the code you'd like to change.
1. Check your Docker configuration:
   1. [Install Docker and set the socket file path](set_up.md#install-docker-and-set-the-socket-file-path).
   1. Restart your container manager. For example, if you use Colima, `colima restart`.
   1. Pull the base Docker image:

      ```shell
      docker pull registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.4
      ```

   1. For permission issues, ensure your operating system user has the necessary Docker permissions.
   1. Verify Docker's internet connectivity by executing the command `docker image pull redhat/ubi8`.
      If this does not work, the DNS configuration of Colima might be at fault.
      Edit the DNS setting in `~/.colima/default/colima.yaml` to `dns: [1.1.1.1]` and then restart Colima with `colima restart`.
1. Check local debugging logs:
   1. For more output in the logs, open the settings:
      1. On macOS: <kbd>Cmd</kbd> + <kbd>,</kbd>
      1. On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
      1. Search for the setting **GitLab: Debug** and enable it.
   1. Check the language server logs:
      1. To open the logs in VS Code, select **View** > **Output**. In the output panel at the bottom, in the top-right corner, select **GitLab Workflow** or **GitLab Language Server** from the list.
      1. Review for errors, warnings, connection issues, or authentication problems.
   1. Check the executor logs:
      1. Use `docker ps -a | grep duo-workflow` to get the list of Workflow containers and their ids.
      1. Use `docker logs <container_id>` to view the logs for the specific container.
1. Examine the [Workflow Service production LangSmith trace](https://smith.langchain.com/o/477de7ad-583e-47b6-a1c4-c4a0300e7aca/projects/p/5409132b-2cf3-4df8-9f14-70204f90ed9b?timeModel=%7B%22duration%22%3A%227d%22%7D&tab=0).

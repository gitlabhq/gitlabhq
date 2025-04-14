---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Set up Docker for GitLab Duo Workflow (optional)
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Private beta

{{< /details >}}

{{< alert type="warning" >}}

This feature is [a private beta](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

Use the following guide to set up GitLab Duo Workflow with Docker.

This is not the preferred method to run Workflow.
If you have VS Code and at least version 5.16.0 of the GitLab Workflow extension for VS Code,
you can use Workflow. For more information, see [the prerequisites](_index.md#prerequisites).

## Install Docker and set the socket file path

Workflow needs an execution platform like Docker where it can execute arbitrary code,
read and write files, and make API calls to GitLab.

If you are on macOS or Linux, you can either:

- Use the [automated setup script](docker_set_up.md#automated-setup). Recommended.
- Follow the [manual setup](docker_set_up.md#manual-setup).

If you are not on macOS or Linux, follow the [manual setup](docker_set_up.md#manual-setup).

### Automated setup

The automated setup script:

- Installs [Docker](https://formulae.brew.sh/formula/docker) and [Colima](https://github.com/abiosoft/colima).
- Sets Docker socket path in VS Code settings.

You can run the script with the `--dry-run` flag to check the dependencies
that get installed with the script.

1. Download the [setup script](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/-/blob/main/scripts/install-runtime).

   ```shell
   wget https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/-/raw/main/scripts/install-runtime
   ```

1. Run the script.

   ```shell
   chmod +x install-runtime
   ./install-runtime
   ```

### Manual setup

1. Install a Docker container engine, such as [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/).
1. Set the Docker socket path and Docker settings in VS Code:
   1. Open VS Code, then open the [Command Palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette):
      - On macOS: <kbd>Cmd</kbd> + <kbd>,</kbd>
      - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
   1. In the open Command Palette search for `settings.json`.
   1. Add a line to `settings.json` that defines the Docker socket path setting `gitlab.duoWorkflow.dockerSocket`,
      according to your container manager, and save your settings file. Some examples for common container
      managers on macOS, where you would replace `<your_user>` with your user's home folder:

      - Rancher Desktop:

         ```json
         "gitlab.duoWorkflow.dockerSocket": "/Users/<your_user>/.rd/docker.sock",
         "gitlab.duoWorkflow.useDocker": true,
         ```

      - Colima:

         ```json
         "gitlab.duoWorkflow.dockerSocket": "/Users/<your_user>/.colima/default/docker.sock",
         "gitlab.duoWorkflow.useDocker": true,
         ```

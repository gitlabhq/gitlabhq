---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Set up GitLab Duo Workflow
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< alert type="warning" >}}

This feature is considered [experimental](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

Use the following guide to set up GitLab Duo Workflow.

## Prerequisites

Before you can use Workflow:

1. Ensure you have an account on GitLab.com.
1. Ensure that the GitLab.com project you want to use with Workflow meets these requirements:
   - You must have at least the Developer role for the project.
   - Your project must belong to a [group namespace](../namespace/_index.md)
     with an **Ultimate** subscription and [experimental features turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
   - The project must have [GitLab Duo turned on](../gitlab_duo/_index.md).
1. [Install Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
1. [Install and set up](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup) the GitLab Workflow extension for VS Code.
   Minimum version 5.16.0.
1. [Install Docker and set the socket file path](set_up.md#install-docker-and-set-the-socket-file-path).

## Install Docker and set the socket file path

Workflow needs an execution platform like Docker where it can execute arbitrary code,
read and write files, and make API calls to GitLab.

If you are on macOS or Linux, you can either:

- Use the [automated setup script](set_up.md#automated-setup). Recommended.
- Follow the [manual setup](set_up.md#manual-setup).

If you are not on macOS or Linux, follow the [manual setup](set_up.md#manual-setup).

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
1. Set the Docker socket path in VS Code:
   1. Open VS Code, then open its settings:
      - On macOS: <kbd>Cmd</kbd> + <kbd>,</kbd>
      - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
   1. In the upper-right corner, select the **Open Settings (JSON)** icon.
   1. Add the Docker socket path setting `gitlab.duoWorkflow.dockerSocket`, according to your container manager, and save your settings file.
   Some examples for common container managers on macOS, where you would replace `<your_user>` with your user's home folder:

      - Rancher Desktop:

         ```json
         "gitlab.duoWorkflow.dockerSocket": "/Users/<your_user>/.rd/docker.sock",
         ```

      - Colima:

         ```json
         "gitlab.duoWorkflow.dockerSocket": "/Users/<your_user>/.colima/default/docker.sock",
         ```

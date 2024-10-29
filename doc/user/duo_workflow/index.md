---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Workflow

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../administration/feature_flags.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is an [experiment](../../policy/experiment-beta-support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for internal GitLab team members for testing, but not ready for production use.

Automate tasks and help increase productivity in your development workflow by using GitLab Duo Workflow.
GitLab Duo Workflow, currently only in your IDE, takes the information you provide
and uses AI to walk you through an implementation plan.

GitLab Duo Workflow supports a wide variety of use cases. Here are a few examples:

- Bootstrap a new project
- Write tests
- Fix a failed pipeline
- Implement a proof of concept for an existing issue
- Comment on a merge request with suggestions
- Optimize CI configuration

These are examples of successful use cases, but it can be used for many more.

## Prerequisites

Before you can use GitLab Duo Workflow:

1. [Install Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
1. [Install and set up](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup) the GitLab Workflow extension for VS Code.
   Minimum version 5.16.0.
1. In VS Code, [set the Docker socket file path](#install-docker-and-set-the-socket-file-path).

### Install Docker and set the socket file path

GitLab Duo Workflow needs an execution platform where it can execute arbitrary code,
read and write files, and make API calls to GitLab.

#### Automated setup

Installs Docker, Colima, and sets Docker socket path in VS Code settings.
You can run the script with the `--dry-run` flag to check the dependencies
that get installed with the script.

1. Download the [script](https://gitlab.com/-/snippets/3745948).
1. Run the script.

   ```shell
   chmod +x duo_workflow_runtime.sh
   ./duo_workflow_runtime.sh
   ```

#### Manual setup

Sets socket path if you have
[Docker or Docker alternatives](https://handbook.gitlab.com/handbook/tools-and-tips/mac/#docker-desktop)
installed already.

1. Open VS Code, then open its settings:
   - On Mac: <kbd>Cmd</kbd> + <kbd>,</kbd>
   - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
1. In the upper-right corner, select the **Open Settings (JSON)** icon.
1. Ensure the Docker socket settings are configured. If not, add this line to your settings file and save it:

   - For Rancher Desktop

     ```json
     "gitlab.duoWorkflow.dockerSocket": "${userHome}/.rd/docker.sock",
     ```

   - For Colima

     ```json
     "gitlab.duoWorkflow.dockerSocket": "${userHome}/.colima/default/docker.sock",
     ```

## Use GitLab Duo Workflow in VS Code

To use GitLab Duo Workflow:

1. In VS Code, open a folder that has a Git repository for a GitLab project.
   - The GitLab namespace for the project must have an **Ultimate** subscription.
   - You must check out the branch for the code you would like to change.
1. Open the command palette:
   - On Mac: <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>
   - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>P</kbd>.
1. Type `Duo Workflow` and select **GitLab: Show Duo Workflow**.

## The context GitLab Duo Workflow is aware of

GitLab Duo Workflow is aware of the context you're working in, specifically:

| Area           | How to use GitLab Duo Workflow                                                                     |
|----------------|----------------------------------------------------------------------------------------------------|
| Merge requests | Enter the merge request ID and project ID in the Duo Workflow panel                                |

In addition, Duo Workflow has read-only access to:

- The GitLab API for fetching project and merge request information.
- Merge request's CI pipeline trace to locate errors in the pipeline job execution.

## Current limitations

Duo Workflow has the following limitations:

- No support for VS Code themes.
- Can only run workflows for the GitLab project that's open in VS Code.

## Troubleshooting

If you encounter issues:

1. Ensure that you have the latest version of the GitLab Workflow extension.
1. Check that your open folder in VS Code corresponds to the GitLab project you want to interact with.
1. Ensure that you've checked out the branch as well.
1. Check your Docker and Docker socket configuration:
   1. Try [manual](#manual-setup) Docker socket configuration.
   1. If using Colima and encountering issues, try restarting it:

      ```shell
      colima stop
      colima start
      ```

   1. For permission issues, ensure your operating system user has the necessary Docker permissions.
1. Check the Language Server logs:
   1. To open the logs in VS Code, select **View** > **Output**. In the output panel at the bottom, in the top-right corner, select **GitLab Workflow** or **GitLab Language Server** from the list.
   1. Review for errors, warnings, connection issues, or authentication problems.
   1. For more output in the logs, open the settings:
      - On Mac: <kbd>Cmd</kbd> + <kbd>,</kbd>
      - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
   1. Search for the setting **GitLab: Debug** and enable it.
1. Examine the [Duo Workflow Service production LangSmith trace](https://smith.langchain.com/o/477de7ad-583e-47b6-a1c4-c4a0300e7aca/projects/p/5409132b-2cf3-4df8-9f14-70204f90ed9b?timeModel=%7B%22duration%22%3A%227d%22%7D&tab=0).

## Give feedback

Duo Workflow is an experiment and your feedback is crucial. To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

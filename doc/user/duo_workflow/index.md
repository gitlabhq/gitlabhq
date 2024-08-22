---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Workflow

DETAILS:
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../administration/feature_flags.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is an [experiment](../../policy/experiment-beta-support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for internal GitLab team members for testing, but not ready for production use.

Automate tasks and help increase productivity in your development workflow by using GitLab Duo Workflow.

GitLab Duo Workflow, as part of your IDE, takes the information you provide
and uses AI to walk you through an implementation plan.
For example, you can use GitLab Duo Workflow to:

- Help resolve an issue.
- Update your CI/CD pipeline.
- Interact with the GitLab API.
- Automate code-related tasks.

## Prerequisites

Before you can use GitLab Duo Workflow in VS Code:

1. Request access in the `#f_duo_workflow` Slack channel.
1. Install the [GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
   Minimum version 5.8.0.
1. In VS Code, [set the Docker socket file path](#install-docker-and-set-the-socket-file-path).

### Install Docker and set the socket file path

1. Install Docker:

   ```shell
   brew install docker
   ```

1. Install Colima by using Homebrew:

   ```shell
   brew install colima
   ```

1. Start Colima:

   ```shell
   colima start
   ```

1. Set Docker context:

   ```shell
   docker context use colima
   ```

1. Manually pull the required Docker image:

   ```shell
   docker pull redhat/ubi8
   ```

1. Access VS Code settings:
   - On Mac: <kbd>Cmd</kbd> + <kbd>,</kbd>
   - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>,</kbd>
1. In the upper-right corner, select the **Open Settings (JSON)** icon.
1. Add this line:

   ```json
   "gitlab.duoWorkflow.dockerSocket": "/Users/<username>/.colima/default/docker.sock"
   ```

1. Save the settings file.

## Use GitLab Duo Workflow in VS Code

To use GitLab Duo Workflow:

1. In VS Code, open your project.
1. Access the Command Palette:
   - On Mac: <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>
   - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>P</kbd>.
1. Type `Duo Workflow` and select **GitLab: Show Duo Workflow**.
1. In the Duo Workflow panel, type the merge request ID and project ID.

## The context Duo Workflow is aware of

GitLab Duo Workflow is aware of the context you're working in, specifically:

| Area          | How to use GitLab Duo Workflow                                                                          |
|---------------|--------------------------------------------------------------------------------------------------------|
| Merge requests| Enter the merge request ID and project ID in the Duo Workflow panel                                |

In addition, Duo Workflow has access to:

- The GitLab API for project and merge request information.
- The CI/CD pipeline for task execution. For details, see [merge request 162091](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162091).

## Current limitations

Duo Workflow should be used primarily for code-related tasks.

Duo Workflow has the following limitations:

- Higher latency due to CI/CD pipeline-based execution.
- No copy and paste functionality.
- Execution steps not displayed in UI.
- Cannot push changes automatically.
- Manual entry of merge request and project IDs required.
- No theme support.
- Project-specific workflow execution only.

## Troubleshooting

If you encounter issues:

1. Verify your GitLab permissions.
1. Check your local Docker setup.
1. Review LSP logs in your IDE for errors or warnings.
1. Examine the Duo Service production LangSmith trace if no IDE errors are found.

## Give feedback

Duo Workflow is an experiment and your feedback is crucial. To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

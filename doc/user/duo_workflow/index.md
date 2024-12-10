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
**LLM:** Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../administration/feature_flags.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is an [experiment](../../policy/development_stages_support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for internal GitLab team members for testing, but not ready for production use.

WARNING:
This feature is considered [experimental](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.

Duo Workflow is an AI-powered coding agent in the VS Code IDE. It helps you solve coding tasks more quickly.
Use it to speed up routine tasks, to improve your work, or to learn different approaches or technologies.

Duo Workflow works in the project you have open in your IDE, and helps you with coding tasks like:

- Draft code to implement your issue or improve your merge request, so you can get started more quickly.
- Refactor or simplify your code, to improve its structure and make it easier to maintain.
- Write or extend your tests, to improve test coverage and code reliability.

After you describe your goal, Duo Workflow generates and executes on a plan to address it. While it executes, you can pause or ask it to adjust the plan.

To improve its accuracy, be specific in your goal. Outline any changes you'd like to see. Reference related files, issues, or merge requests.

## Risks of Duo Workflow and AI Agents

Duo Workflow is an experimental product and users should consider their
circumstances before using this tool. Duo Workflow is an AI Agent that is given
some ability to perform actions on the users behalf. AI tools based on LLMs are
inherently unpredictable and you should take appropriate precautions.

Duo Workflow in VS Code runs workflows in a Docker container on your local
workstation. Running Duo Worklow inside of Docker is not a security measure but a
convenience to reduce the amount of disruption to your normal development
environment. All the documented risks should be considered before using this
product. The following risks are important to understand:

1. Our supported Docker servers are running in a VM. We do not support Docker
   Engine running on the host as this offers less isolation. Since Docker
   Engine is the most common way to run Docker on Linux we will likely not
   support many Linux setups by default, but instead we'll require them to
   install an additional Docker runtime to use Duo Workflow.
1. This VM running on your local workstation likely has access to your local
   network, unless you have created additional firewall rules to prevent it.
   Local network access may be an issue if you are running local development
   servers on your host that you would not want reachable by the workflow
   commands. Local network access may also be risky in a corporate intranet
   environment where you have internal resources that you do not want
   accessible by Duo Workflow.
1. The VM may be able to consume a lot of CPU, RAM and storage based on the
   limits configured with your Docker VM installation.
1. Depending on the configuration of the VM in your Docker installation it may
   also have access to other hardware on your host.
1. Unpatched installations of Docker may contain vulnerabilities that could
   eventually lead to code execution escaping the VM to the host or accessing
   resources on the host that you didn't intend.
1. Each version of Docker has different ways of mounting directories into the
   containers. Duo Workflow only mounts the directory for the project you have
   open in VS Code but depending on how your Docker installation works and
   whether or not you are running other containers there may still be some
   risks it could access other parts of your filesystem.
1. Duo Workflow has access to the local filesystem of the
   project where you started running Duo Workflow. This may include access to
   any credentials that you have stored in files in this directory, even if they
   are not committed to the project (e.g. `.env` files)
1. All your Docker containers usually run in a single VM. So this
   may mean that Duo Workflow containers are running in the same VM as other
   non Duo Workflow containers. While the containers are isolated to some
   degree this isolation is not as strict as VM level isolation

Other risks to be aware of when using Duo Workflow:

1. Duo Workflow also gets access to a time limited `ai_worfklows` scoped GitLab
   OAuth token with your user's identity. This token can be used to access
   certain GitLab APIs on your behalf. This token is limited to the duration of
   the workflow and only has access to certain APIs in GitLab but it can still,
   by design, perform write operations on the users behalf. You should consider
   what access your user has in GitLab before running workflows.
1. You should not give Duo Workflow any additional credentials or secrets, in
   goals or messages, as there is a chance it might end up using those in code
   or other API calls.

## Prerequisites

Before you can use GitLab Duo Workflow:

1. [Install Visual Studio Code](https://code.visualstudio.com/download) (VS Code).
1. [Install and set up](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup) the GitLab Workflow extension for VS Code.
   Minimum version 5.16.0.
1. In VS Code, [set the Docker socket file path](#install-docker-and-set-the-socket-file-path).

### Install Docker and set the socket file path

GitLab Duo Workflow needs an execution platform like Docker where it can execute arbitrary code,
read and write files, and make API calls to GitLab.

#### Automated setup

The setup script installs Docker and Colima, pulls the Docker base image, and sets Docker socket path in VS Code settings.
You can run the script with the `--dry-run` flag to check the dependencies
that get installed with the script.

1. Download the [setup script](https://gitlab.com/-/snippets/3745948).
1. Run the script.

   ```shell
   chmod +x duo_workflow_runtime.sh
   ./duo_workflow_runtime.sh
   ```

#### Manual setup

If you have [Docker Desktop](https://handbook.gitlab.com/handbook/tools-and-tips/mac/#docker-desktop)
or a container manager other than Colima installed already:

1. Pull the base Docker image:

   ```shell
   docker pull registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.4
   ```

1. Set the Docker socket path in VS Code:
   1. Open VS Code, then open its settings:
      - On Mac: <kbd>Cmd</kbd> + <kbd>,</kbd>
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
   1. [Install Docker and set the socket file path](#install-docker-and-set-the-socket-file-path).
   1. Restart your container manager. For example, if using Colima:

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

## Audit log

Audit event is created for each API request done by Duo Workflow. View these events on the [instance audit events](../../administration/audit_event_reports.md#instance-audit-events) page.

## Give feedback

Duo Workflow is an experiment and your feedback is crucial. To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

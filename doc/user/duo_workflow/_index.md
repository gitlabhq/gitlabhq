---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Workflow
---

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
The development, release, and timing of any products, features, or functionality may be
subject to change or delay and remain at the sole discretion of GitLab Inc.

GitLab Duo Workflow is an AI-powered coding agent in the Visual Studio Code (VS Code) IDE.

Workflow:

- Is designed to help you solve junior-level coding tasks more quickly,
  such as drafting code for small features or bugs.
- Works best in small or medium-sized repositories.

For more information, see:

- [How to use Workflow](#use-gitlab-duo-workflow-in-vs-code).
- [How to get the best results](#how-to-get-the-best-results).

## Risks of Workflow and AI Agents

Workflow is an experimental product and users should consider their
circumstances before using this tool. Workflow is an AI Agent that is given
some ability to perform actions on the users behalf. AI tools based on LLMs are
inherently unpredictable and you should take appropriate precautions.

Workflow in VS Code runs workflows in a Docker container on your local
workstation. Running Duo Worklow inside of Docker is not a security measure but a
convenience to reduce the amount of disruption to your normal development
environment. All the documented risks should be considered before using this
product. The following risks are important to understand:

1. Our supported Docker servers are running in a VM. We do not support Docker
   Engine running on the host as this offers less isolation. Since Docker
   Engine is the most common way to run Docker on Linux we will likely not
   support many Linux setups by default, but instead we'll require them to
   install an additional Docker runtime to use Workflow.
1. This VM running on your local workstation likely has access to your local
   network, unless you have created additional firewall rules to prevent it.
   Local network access may be an issue if you are running local development
   servers on your host that you would not want reachable by the workflow
   commands. Local network access may also be risky in a corporate intranet
   environment where you have internal resources that you do not want
   accessible by Workflow.
1. The VM may be able to consume a lot of CPU, RAM and storage based on the
   limits configured with your Docker VM installation.
1. Depending on the configuration of the VM in your Docker installation it may
   also have access to other hardware on your host.
1. Unpatched installations of Docker may contain vulnerabilities that could
   eventually lead to code execution escaping the VM to the host or accessing
   resources on the host that you didn't intend.
1. Each version of Docker has different ways of mounting directories into the
   containers. Workflow only mounts the directory for the project you have
   open in VS Code but depending on how your Docker installation works and
   whether or not you are running other containers there may still be some
   risks it could access other parts of your filesystem.
1. Workflow has access to the local filesystem of the
   project where you started running Workflow. This may include access to
   any credentials that you have stored in files in this directory, even if they
   are not committed to the project (e.g. `.env` files)
1. All your Docker containers usually run in a single VM. So this
   may mean that Workflow containers are running in the same VM as other
   non Workflow containers. While the containers are isolated to some
   degree this isolation is not as strict as VM level isolation

Other risks to be aware of when using Workflow:

1. Workflow also gets access to a time-limited `ai_workflows` scoped GitLab
   OAuth token with your user's identity. This token can be used to access
   certain GitLab APIs on your behalf. This token is limited to the duration of
   the workflow and only has access to certain APIs in GitLab but it can still,
   by design, perform write operations on the users behalf. You should consider
   what access your user has in GitLab before running workflows.
1. You should not give Workflow any additional credentials or secrets, in
   goals or messages, as there is a chance it might end up using those in code
   or other API calls.

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
1. [Install Docker and set the socket file path](#install-docker-and-set-the-socket-file-path).

### Install Docker and set the socket file path

Workflow needs an execution platform like Docker where it can execute arbitrary code,
read and write files, and make API calls to GitLab.

If you are on macOS or Linux, you can either:

- Use the [automated setup script](#automated-setup). Recommended.
- Follow the [manual setup](#manual-setup).

If you are not on macOS or Linux, follow the [manual setup](#manual-setup).

#### Automated setup

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

#### Manual setup

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

## Use GitLab Duo Workflow in VS Code

To use Workflow:

1. In VS Code, open the Git repository folder for your GitLab project.
   - You must check out the branch for the code you would like to change.
1. Open the command palette:
   - On macOS: <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>
   - On Windows and Linux: <kbd>Ctrl</kbd> + <kbd>P</kbd>.
1. Type `GitLab Duo Workflow` and select **GitLab: Show Duo Workflow**.
1. To create a workflow, select **New workflow**.
1. For **Task description**, specify a junior-level code task in detail,
   and then select **Start**.

After you describe your task, Workflow generates and executes on a plan to address it.
While it executes, you can pause or ask it to adjust the plan.

### How to get the best results

When you describe your task to Workflow, keep these tips in mind to get the best results:

- It works best within these conditions:
  - Code tasks on the level of a junior engineer.
  - Repositories up to medium size.
  - In the [supported languages](#supported-languages).
- Use mainly to work on small features or bugs.
- Be detailed with a clear definition of done.
- Try to add implementation examples, with commit or merge request IDs.
- Mention files by their names, and GitLab references by their IDs.
  For example, project, issue, or merge request IDs.
  For more information, see [the context that it's aware of](#the-context-workflow-is-aware-of).

## Supported languages

Workflow officially supports the following languages:

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## The context Workflow is aware of

Workflow is aware of the context you're working in, specifically:

| Area                          | How to use GitLab Workflow |
|-------------------------------|--------------------------------|
| Epics                         | Enter the epic ID and the name of the group the epic is in. The group must include a project that meets the [prerequisites](#prerequisites). |
| Issues                        | Enter the issue ID if it's in the current project. In addition, enter the project ID if it is in a different project. The other project must also meet the [prerequisites](#prerequisites). |
| Local files                   | Workflow can access all files available to Git in the project you have open in your editor. Enter the file path to reference a specific file. |
| Merge requests                | Enter the merge request ID if it's in the current project. In addition, enter the project ID if it's in a different project. The other project must also meet the [prerequisites](#prerequisites). |
| Merge request pipelines       | Enter the merge request ID that has the pipeline, if it's in the current project. In addition, enter the project ID if it's in a different project. The other project must also meet the [prerequisites](#prerequisites).  |

Workflow also has access to the GitLab [Search API](../../api/search.md) to find related issues or merge requests.

## APIs that Workflow has access to

To create solutions and understand the context of the problem,
Workflow accesses several GitLab APIs.

Specifically, an OAuth token with the `ai_workflows` scope has access
to the following APIs:

- [Projects API](../../api/projects.md)
- [Search API](../../api/search.md)
- [CI Pipelines API](../../api/pipelines.md)
- [CI Jobs API](../../api/jobs.md)
- [Merge Requests API](../../api/merge_requests.md)
- [Epics API](../../api/epics.md)
- [Issues API](../../api/issues.md)
- [Notes API](../../api/notes.md)
- [Usage Data API](../../api/usage_data.md)

## Current limitations

Workflow has the following limitations:

- Requires the workspace folder in VS Code to have a Git repository for a GitLab project.
- Only runs workflows for the GitLab project that's open in VS Code.
- Only accesses files in the current branch and project.
- Only accesses GitLab references in the GitLab instance of your project. For example, if your project is in GitLab.com, Workflow only accesses GitLab references in that instance. It cannot access external sources or the web.
- Only reliably accesses GitLab references if provided with their IDs. For example, issue ID and not issue URL.
- Can be slow or fail in large repositories.

## Troubleshooting

If you encounter issues:

1. Ensure that you have the latest version of the GitLab Workflow extension.
1. Ensure that the project you want to use it with meets the [prerequisites](#prerequisites).
1. Ensure that the folder you opened in VS Code has a Git repository for your GitLab project.
1. Ensure that you've checked out the branch for the code you'd like to change.
1. Check your Docker configuration:
   1. [Install Docker and set the socket file path](#install-docker-and-set-the-socket-file-path).
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

## Audit log

An audit event is created for each API request done by Workflow.
On your GitLab Self-Managed instance, you can view these events on the [instance audit events](../../administration/audit_event_reports.md#instance-audit-events) page.

## Give feedback

Workflow is an experiment and your feedback is crucial to improve it for you and others.
To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

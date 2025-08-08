---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Software development flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta
- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on GitLab Duo with self-hosted models: Not supported

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is a [private beta](../../../policy/development_stages_support.md).
- [Changed name](https://gitlab.com/gitlab-org/gitlab/-/issues/551382), `duo_workflow` [flag enabled](../../../administration/feature_flags/_index.md), and status changed to beta in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The software development flow is the first flow that's available in the VS Code IDE.
Formerly known as GitLab Duo Workflow, the software development flow:

- Runs in your IDE so that you do not have to switch contexts or tools.
- Creates and works through a plan, in response to your prompt.
- Stages proposed changes in your project's repository.
  You control when to accept, modify, or reject the suggestions.
- Understands the context of your project structure, codebase, and history.
  You can also add your own context, such as relevant GitLab issues or merge requests.

This flow is available in the VS Code IDE only.

## Prerequisites

Before you can use the software development flow in Visual Studio Code (VS Code), you must:

### Step 1: Configure your GitLab environment

#### For GitLab.com

- Have an account on GitLab.com.
- Have a project that meets the following requirements:
  - The project is on GitLab.com.
  - You have at least the Developer role.
  - The project belongs to a [group namespace](../../namespace/_index.md) with an Ultimate subscription.
  - [Beta and experimental features must be turned on](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
  - [GitLab Duo must be turned on](../../gitlab_duo/turn_on_off.md).

#### For GitLab Self-Managed

- Follow [the documentation](../../gitlab_duo/setup.md) to configure GitLab Duo on a GitLab Self-Managed instance.
- [GitLab Duo must be enabled](../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).
- [Beta and experimental features must be turned on](../../gitlab_duo/turn_on_off.md#on-gitlab-self-managed).

### Step 2: Set up your local development environment

- [Install VS Code](https://code.visualstudio.com/download).
- [Set up the GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#setup). Minimum version 5.16.0.
- [Successfully connect to your repository](#connect-to-your-repository).
- [Ensure an HTTP/2 connection to the backend service is possible](../troubleshooting.md#network-issues).

## Connect to your repository

To use the software development flow in VS Code, ensure your repository is properly connected.

1. In VS Code, on the top menu, select **Terminal > New Terminal**.
1. Clone your repository: `git clone <repository>`.
1. Change to the directory where your repository was cloned and check out your branch: `git checkout <branch_name>`.
1. Ensure your project is selected:
   1. On the left sidebar, select **GitLab Workflow** ({{< icon name="tanuki" >}}).
   1. Select the project name. If you have multiple projects, select the one you want to work with.
1. In the terminal, ensure your repository is configured with a remote: `git remote -v`. The results should look similar to:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   If no remote is defined, or you have multiple remotes:

   1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
   1. On the **Source Control** label, right-click and select **Repositories**.
   1. Next to your repository, select the ellipsis ({{< icon name=ellipsis_h >}}), then **Remote > Add Remote**.
   1. Select **Add remote from GitLab**.
   1. Choose a remote.

Now you can use the software development flow to help solve your coding tasks.

## Use the software development flow in VS Code

The software development flow is one flow in the Agent Platform.

To use the software development flow:

1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Flows** tab.
1. In the text box, specify a code task in detail.
   - The software development flow is aware of all files available to Git in the project branch.
   - You can provide additional [context](../../gitlab_duo/context.md#gitlab-duo-chat) for your chat.
   - The software development flow cannot access external sources or the web.
1. Select **Start**.

After you describe your task, a plan is generated and executed.
You can pause or ask it to adjust the plan.

## Supported languages

The software development flow officially supports the following languages:

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## APIs that the software development flow has access to

To create solutions and understand the context of the problem,
the software development flow accesses several GitLab APIs.

Specifically, an OAuth token with the `ai_workflows` scope has access
to the following APIs:

- [Projects API](../../../api/projects.md)
- [Search API](../../../api/search.md)
- [CI Pipelines API](../../../api/pipelines.md)
- [CI Jobs API](../../../api/jobs.md)
- [Merge Requests API](../../../api/merge_requests.md)
- [Epics API](../../../api/epics.md)
- [Issues API](../../../api/issues.md)
- [Notes API](../../../api/notes.md)
- [Usage Data API](../../../api/usage_data.md)

## Audit log

An audit event is created for each API request done by the software development flow.
On your GitLab Self-Managed instance, you can view these events on the
[instance audit events](../../../administration/compliance/audit_event_reports.md#instance-audit-events) page.

## Risks

The software development flow is an experimental product and users should consider their
circumstances before using this tool. It is subject to [the GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
The software development flow is an AI agent that is given some ability to perform actions on the user's behalf. AI tools based on LLMs are
inherently unpredictable and you should take appropriate precautions.

The software development flow in VS Code runs workflows on your local workstation.
All the documented risks should be considered before using this
product. The following risks are important to understand:

1. The software development flow has access to the local file system of the
   project where you started running it. The software development flow respects your local `.gitignore` file,
   but it can still access files that are not committed to the project and not called out in `.gitignore`.
   Such files can contain credentials (for example, `.env` files).
1. The software development flow also gets access to a time-limited `ai_workflows` scoped GitLab
   OAuth token with your user's identity. This token can be used to access
  GitLab APIs on your behalf. This token is limited to the duration of
   the workflow and only has access to certain APIs in GitLab.
   Without user approval, the software development performs only read operations. By design, the token can still 
   perform write operations on the users behalf. You should consider
   the access your user has in GitLab before running the software development flow.
1. You should not give the software development flow any additional credentials or secrets, in
   goals or messages, as there is a chance it might end up using those in code
   or other API calls.

## Give feedback

The software development flow is an experiment and your feedback is crucial to improve it for you and others.
To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

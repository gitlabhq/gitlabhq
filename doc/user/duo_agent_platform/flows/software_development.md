---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Software Development Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md): Yes

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is a [private beta](../../../policy/development_stages_support.md).
- [Changed name](https://gitlab.com/gitlab-org/gitlab/-/issues/551382), `duo_workflow` [flag enabled](../../../administration/feature_flags/_index.md), and status changed to beta in GitLab 18.2.
- For [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md), [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19213) in GitLab 18.4, as an [experiment](../../../policy/development_stages_support.md#experiment) with a [feature flag](../../../administration/feature_flags/_index.md) named `self_hosted_agent_platform`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The Software Development Flow helps you create AI-generated solutions for
work across the software development lifecycle.
Formerly known as GitLab Duo Workflow, this flow:

- Runs in your IDE so that you do not have to switch contexts or tools.
- Creates and works through a plan, in response to your prompt.
- Stages proposed changes in your project's repository.
  You control when to accept, modify, or reject the suggestions.
- Understands the context of your project structure, codebase, and history.
  You can also add your own context, such as relevant GitLab issues or merge requests.

This flow is available in the VS Code IDE only.

## Use the Software Development Flow in VS Code

Prerequisites:

- [Install and configure the GitLab extension for VS Code](../../../editor_extensions/visual_studio_code/setup.md) version 5.16.0 or later.
- Ensure you meet [the other prerequisites](../../duo_agent_platform/_index.md#prerequisites).

To use the flow:

1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Flows** tab.
1. In the text box, specify a code task in detail.
   - The flow is aware of all files available to Git in the project branch.
   - You can provide additional [context](../../gitlab_duo/context.md#gitlab-duo-chat) for your chat.
   - The flow cannot access external sources or the web.
1. Select **Start**.

After you describe your task, a plan is generated and executed.
You can pause or ask it to adjust the plan.

## Supported languages

The Software Development Flow officially supports the following languages:

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## APIs that the flow has access to

To create solutions and understand the context of the problem,
the flow accesses several GitLab APIs.

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

An audit event is created for each API request done by the Software Development Flow.
On your GitLab Self-Managed instance, you can view these events on the
[instance audit events](../../../administration/compliance/audit_event_reports.md#instance-audit-events) page.

## Risks

The Software Development Flow is an experimental product and users should consider their
circumstances before using this tool. It is subject to [the GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
This flow is an AI agent that is given some ability to perform actions on the user's behalf. AI tools based on LLMs are
inherently unpredictable and you should take appropriate precautions.

The Software Development Flow in VS Code runs workflows on your local workstation.
All the documented risks should be considered before using this
product. The following risks are important to understand:

1. The Software Development Flow has access to the local file system of the
   project where you started running it. The flow respects your local `.gitignore` file,
   but it can still access files that are not committed to the project and not called out in `.gitignore`.
   Such files can contain credentials (for example, `.env` files).
1. The Software Development Flow also gets access to a time-limited `ai_workflows` scoped GitLab
   OAuth token with your user's identity. This token can be used to access
  GitLab APIs on your behalf. This token is limited to the duration of
   the workflow and only has access to certain APIs in GitLab.
   Without user approval, the flow performs only read operations. By design, the token can still
   perform write operations on the users behalf. You should consider
   the access your user has in GitLab before running the flow.
1. You should not give the Software Development Flow any additional credentials or secrets, in
   goals or messages, as there is a chance it might end up using those in code
   or other API calls.

## Give feedback

The Software Development Flow is an experiment and your feedback is crucial to improve it for you and others.
To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

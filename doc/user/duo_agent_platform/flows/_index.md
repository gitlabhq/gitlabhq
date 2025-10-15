---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Flows
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../../policy/development_stages_support.md) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow`. Enabled by default.
- Additional flags are required for individual flows.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

A flow is a combination of one or more agents working together to solve a complex problem.

Flows are available in IDEs and the GitLab UI.

- In the UI, they run directly in GitLab CI/CD,
  helping you automate common development tasks without the need to leave your browser.
- In IDEs, flows are available in VS Code, Visual Studio, and JetBrains.

## Available flows

The following flows are available:

- [Fix your CI/CD pipeline](fix_pipeline.md).
- [Convert a Jenkinsfile to `.gitlab-ci.yml` file](convert_to_gitlab_ci.md).
- [Convert an issue to a merge request](issue_to_mr.md).
- Work with any aspect of [software development](software_development.md). In this flow,
  you describe your needs and GitLab Duo understands your repository, the codebase,
  and its structure.

For more focused pieces of work, like understanding selected code,
use [GitLab Duo Chat (Agentic)](../../gitlab_duo_chat/agentic_chat.md).

## Turn on flows

To turn flows on or off, use [the GitLab Duo settings](../../gitlab_duo/turn_on_off.md).

## Monitor running flows in the GitLab UI

To view flows that are running for your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Automate** > **Sessions**.

## View flow history in the IDEs

To view a history of flows you've run in your project:

- On the **Flows** tab, scroll down and view **Recent agent sessions**.

## Supported APIs and permissions

In the GitLab UI, flows have access to the following GitLab APIs:

- [Projects API](../../../api/projects.md)
- [Issues API](../../../api/issues.md)
- [Merge Requests API](../../../api/merge_requests.md)
- [Repository Files API](../../../api/repository_files.md)
- [Branches API](../../../api/branches.md)
- [Commits API](../../../api/commits.md)
- [CI Pipelines API](../../../api/pipelines.md)
- [Labels API](../../../api/labels.md)
- [Epics API](../../../api/epics.md)
- [Notes API](../../../api/notes.md)
- [Search API](../../../api/search.md)

Flows use each user's permissions and respect all project access controls and security policies.

## Give feedback

Agents flows are part of GitLab AI-powered development platform. Your feedback helps us improve these workflows.
To report issues or suggest improvements for flows,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

## Related topics

- [Configure where flows run](execution.md)

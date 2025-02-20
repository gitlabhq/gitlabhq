---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Workflow
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment
- LLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14153) in GitLab 17.4 [with a flag](../../administration/feature_flags.md) named `duo_workflow`. Enabled for GitLab team members only. This feature is an [experiment](../../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for internal GitLab team members for testing, but not ready for production use.

{{< /alert >}}

{{< alert type="warning" >}}

This feature is considered [experimental](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

{{< alert type="disclaimer" />}}

GitLab Duo Workflow is an AI-powered coding agent in the Visual Studio Code (VS Code) IDE.

Workflow:

- Is designed to help you solve junior-level coding tasks more quickly,
  such as drafting code for small features or bugs.
- Works best in small or medium-sized repositories.

For more information, see:

- [Use Workflow in your IDE](use_in_your_ide.md).
- [Best practices](best_practices.md).

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

## Audit log

An audit event is created for each API request done by Workflow.
On your GitLab Self-Managed instance, you can view these events on the [instance audit events](../../administration/audit_event_reports.md#instance-audit-events) page.

## Give feedback

Workflow is an experiment and your feedback is crucial to improve it for you and others.
To report issues or suggest improvements,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

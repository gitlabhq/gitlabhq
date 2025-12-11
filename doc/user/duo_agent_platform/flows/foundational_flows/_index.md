---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Foundational flows
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

Foundational flows are built and maintained by GitLab and display a GitLab-maintained badge ({{< icon name="tanuki-verified" >}}).

Each flow is designed to solve a specific problem or help you with a development task.

The following foundational flows are available:

- [Software Development](software_development.md): Create AI-generated solutions for work across the software development lifecycle.
- [Developer](developer.md): Create actionable merge requests from issues.
- [Fix CI/CD Pipeline](fix_pipeline.md): Diagnose and repair failed jobs.
- [Convert to GitLab CI/CD](convert_to_gitlab_ci.md): Migrate Jenkins pipelines to CI/CD.
- [Code Review](code_review.md): Automate code review with AI-native analysis and feedback.

## Security for foundational flows

In the GitLab UI, foundational flows have access to the following GitLab APIs:

- [Projects API](../../../../api/projects.md)
- [Issues API](../../../../api/issues.md)
- [Merge Requests API](../../../../api/merge_requests.md)
- [Repository Files API](../../../../api/repository_files.md)
- [Branches API](../../../../api/branches.md)
- [Commits API](../../../../api/commits.md)
- [CI Pipelines API](../../../../api/pipelines.md)
- [Labels API](../../../../api/labels.md)
- [Epics API](../../../../api/epics.md)
- [Notes API](../../../../api/notes.md)
- [Search API](../../../../api/search.md)

In addition, foundational flows use a service account to complete tasks.
For more information, see [the composite identity workflow](../../security.md#composite-identity-workflow).

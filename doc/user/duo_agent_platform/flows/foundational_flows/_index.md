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

Foundational flows are built and maintained by GitLab.

Each flow is designed to solve a specific problem or help you with a development task.

The following foundational flows are available:

- [Fix your CI/CD pipeline](fix_pipeline.md).
- [Convert a Jenkinsfile to `.gitlab-ci.yml` file](convert_to_gitlab_ci.md).
- [Convert an issue to a merge request](issue_to_mr.md).
- Work with any aspect of [software development](software_development.md). In this flow,
  you describe your needs and GitLab Duo understands your repository, the codebase,
  and its structure.

## Supported APIs and permissions

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

Foundational flows use each user's permissions and respect all project access controls and security policies.

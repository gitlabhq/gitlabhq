---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Foundational flows
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
- [Agentic SAST Vulnerability Resolution](agentic_sast_vulnerability_resolution.md): Automatically generate merge requests to resolve SAST vulnerabilities.
- [SAST false positive detection](sast_false_positive_detection.md): Automatically identify and filter false positives in SAST findings.

## Configure flow execution CI/CD details

You can configure the environment where flows use CI/CD to execute.

For example, on GitLab Self-Managed, administrators can configure a custom container registry
for foundational flow images.

For more information, see [Configure flow execution](../execution.md).

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

### Service accounts

Foundational flows use a service account to complete tasks.
For more information, see [composite identity workflow](../../composite_identity.md#composite-identity-workflow).

When foundational flows create merge requests, the merge request is attributed to the service account. This means the user who triggered the flow can approve and merge AI-generated code. Organizations with SOC 2, SOX, ISO 27001, or FedRAMP requirements should review the [compliance considerations](../../composite_identity.md#compliance-considerations-for-merge-requests) and implement appropriate approval policies.

## Turn foundational flows on or off

You can turn foundational flows on or off for a top-level group (namespace) or an instance.
If you turn off foundational flows for a top-level group, users with that group as
their default GitLab Duo namespace cannot access foundational flows in any namespace.

You can also turn flow execution on or off to control whether agents run in the GitLab UI.
When this setting is turned on, agents execute in CI/CD pipelines and consume compute minutes.

{{< tabs >}}

{{< tab title="For GitLab.com" >}}

Prerequisites:

- You must have the Owner role for the group.

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Flow execution**, select the **Allow flow execution** and **Allow foundational flows** checkboxes.
1. Select the checkbox for each foundational flow you want to turn on.
1. Select **Save changes**.

You must turn on individual foundational flows for the top-level group.
It can take a few minutes for these settings to propagate across groups.

{{< /tab >}}

{{< tab title="For an instance" >}}

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Flow execution**, select the **Allow flow execution** and **Allow foundational flows** checkboxes.
1. Select the checkbox for each foundational flow you want to turn on.
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

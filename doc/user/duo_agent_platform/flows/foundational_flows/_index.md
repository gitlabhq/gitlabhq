---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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
- [Secret false positive detection](secret_false_positive_detection.md): Automatically identify and filter false positives in secret detection findings.

## For developers

To learn how to create and add new foundational flows to GitLab, see the [foundational flows development guide](../../../../development/ai_features/foundational_flows.md).

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

When a foundational flow creates a merge request, the merge request is attributed to the human user who triggered the flow instead of the service account.
This is done to adhere to compliance frameworks that require segregation of duties. See [compliance considerations](../../composite_identity.md#compliance-considerations-for-merge-requests).

## Turn foundational flows on or off

You can turn foundational flows on or off:

- On GitLab.com: For top-level groups and projects.
- On GitLab Self-Managed: For instances, groups, and projects.

You can also turn flow execution on or off to control whether
features that consume compute minutes can run in the GitLab UI.
These features include external agents, foundational flows, and custom flows.

### On GitLab.com

{{< tabs >}}

{{< tab title="For a top-level group" >}}

Prerequisites:

- The Owner role for the top-level group.

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Flow execution**, select the **Allow flow execution** and **Allow foundational flows** checkboxes.
1. Select the checkbox for each foundational flow you want to turn on.
1. Select **Save changes**.

When you turn off foundational flows for a top-level group, users with that group as
their default GitLab Duo namespace cannot access foundational flows in any namespace.

{{< /tab >}}

{{< tab title="For a project" >}}

Prerequisites:

- The Maintainer or Owner role for the project.
- Flow execution and foundational flows turned on for the top-level group.

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings > General**.
1. Expand **GitLab Duo**.
1. Turn on the **GitLab Duo**, **Allow flow execution**, and **Allow foundational flows** toggles.
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

### On GitLab Self-Managed

{{< history >}}

- Full image reference for image registry [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/594208) in GitLab 19.0.

{{< /history >}}

{{< tabs >}}

{{< tab title="For an instance" >}}

Prerequisites:

- Administrator access.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Flow execution**, select the **Allow flow execution** and **Allow foundational flows** checkboxes.
1. Optional. In the **Image registry** text box, enter one of the following:

   - A registry hostname to use the default image from that registry.
   - A full image reference to override the image entirely (for example, `registry.example.com/group/project/image:tag`).

   Leave blank to use the default `registry.gitlab.com`.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="For a group" >}}

Prerequisites:

- The Maintainer or Owner role for the group.
- Flow execution and foundational flows turned on for the instance.

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **Flow execution**, select the **Allow flow execution** and **Allow foundational flows** checkboxes.
1. For top-level groups only, select the checkbox for each foundational flow you want to turn on.
1. Select **Save changes**.

When turned on for the group, foundational flows are available to all subgroups and projects.

{{< /tab >}}

{{< tab title="For a project" >}}

Prerequisites:

- The Maintainer or Owner role for the project.
- Flow execution and foundational flows turned on for the instance and group.

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings > General**.
1. Expand **GitLab Duo**.
1. Turn on the **GitLab Duo**, **Allow flow execution**, and **Allow foundational flows** toggles.
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

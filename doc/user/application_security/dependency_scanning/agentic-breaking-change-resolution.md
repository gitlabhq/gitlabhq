---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agentic breaking change resolution
description: AI-native resolution of problems with merge requests that bump dependencies.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17884) in GitLab 19.2 as a [beta](../../../policy/development_stages_support.md#beta) feature with [feature flags](../../../administration/feature_flags/_index.md) named `enable_dependency_bump_breaking_changes` and `dependency_bump_web_search`.

{{< /history >}}

Agentic breaking change resolution is an opt-in foundational flow that:

- Analyzes failed pipelines on merge requests that bump dependencies.
- Generates fixes to resolve breaking changes introduced by the dependency update.

> [!warning]
> When this feature is enabled, pipeline logs and code context from the affected merge request
> are sent to large language models (LLMs) for analysis. Review your organization's data policies
> before enabling this feature.

In this foundational flow, GitLab Duo:

- Examines pipeline error logs to identify the root cause of the failure.
- Analyzes dependency changelogs and release notes to identify breaking changes.
- Reviews code usage patterns of the updated dependency.
- Generates and commits code fixes directly to the dependency bump MR branch.
- Re-runs the pipeline after applying fixes.

Results are based on AI analysis and should be reviewed by a developer before merging.

## Prerequisites

- [GitLab Duo enabled](../../gitlab_duo/turn_on_off.md) in your project or group.
- [A default GitLab Duo namespace set](../../profile/preferences.md#set-a-default-gitlab-duo-namespace)
  in your user preferences.
- [Dependency scanning auto-remediation](../remediate/auto_remediation.md) enabled
  for the project. Agentic breaking change resolution acts on the dependency bump merge requests
  that auto-remediation creates.

## Enable agentic breaking change resolution

The feature is turned off by default and must be explicitly enabled at both the group and
project level.

### Turn on this foundational flow in a top-level group

To allow all projects in a group to use the foundational flow:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Under **Allow foundational flows**, select the **Resolve Dependency Bump Breaking Changes** checkbox.
1. Select **Save changes**.

### Turn on this foundational flow for a project

Prerequisites:

- The Maintainer or Owner role for the project.
- The foundational flow enabled for the top-level group.

To turn on agentic breaking change resolution for a specific project:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn on the **Turn on AI-powered resolution of dependency bump breaking changes** toggle.
1. Select **Save changes**.

## Trigger the flow

You can trigger the flow automatically or manually.

### Automatic trigger

The flow runs automatically when:

- A pipeline fails on a dependency bump merge request created by the auto-remediation agent.
- The feature is enabled for the project.
- GitLab Duo features are enabled for the project or group.

The analysis runs in the background. When complete, any generated fixes are committed to the
merge request branch and the pipeline is re-run.

### Manual trigger

To manually trigger agentic breaking change resolution on a merge request (that bumps dependencies)
with a failed pipeline:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests**.
1. Select the dependency bump merge request with a failed pipeline.
1. In the pipeline widget, select **Resolve breaking changes with Duo**.

The flow runs in the background. When complete, it commits any generated fixes to the MR branch
and re-runs the pipeline.

## Provide feedback

Share your feedback in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/605189).

## Related topics

- [Agentic breaking change resolution foundational flow](../../duo_agent_platform/flows/foundational_flows/agentic-breaking-change-resolution.md)
- [Dependency scanning auto-remediation](../remediate/auto_remediation.md)
- [Dependency scanning](_index.md)
- [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)

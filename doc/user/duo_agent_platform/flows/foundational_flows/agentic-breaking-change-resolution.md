---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agentic breaking change resolution flow
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17884) in GitLab 19.2 as an [beta](../../../../policy/development_stages_support.md#beta) feature with a [feature flag](../../../../administration/feature_flags/_index.md) named `enable_dependency_bump_breaking_changes` and `dependency_bump_web_search`.

{{< /history >}}

The agentic breaking change resolution flow automatically analyzes pipeline failures on
dependency bump merge requests and generates code fixes to resolve breaking changes
introduced by the dependency update.

When a dependency bump merge request has a failed pipeline, GitLab Duo analyzes the failure
and attempts to generate fixes. The flow examines:

- Pipeline error logs to identify the root cause of the failure.
- Dependency changelogs and release notes to identify breaking changes.
- Code usage patterns of the updated dependency to determine what needs to change.

After generating fixes, the flow commits them directly to the dependency bump merge request branch
and re-runs the pipeline.

Results are based on AI analysis and should be reviewed before merging.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Turn on **Allow foundational flows** and **Resolve Dependency Bump Breaking Changes**
  [for the top-level group](_index.md#turn-foundational-flows-on-or-off).
- [Configure push rules to allow a service account](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configure your own runners](../execution.md) or turn on
  [GitLab hosted runners](../../../../ci/runners/hosted_runners/_index.md) for your project.
- Turn on the feature for the project. See
  [Enable agentic breaking change resolution](../../../application_security/dependency_scanning/agentic-breaking-change-resolution.md#enable-agentic-breaking-change-resolution).

## Run agentic breaking change resolution

The flow runs automatically when a pipeline fails on a dependency bump merge request created
by the auto-remediation agent, and the feature is enabled for the project.

You can also trigger the flow manually:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests**.
1. Select the dependency bump merge request with a failed pipeline.
1. In the pipeline widget, select **Resolve breaking changes with Duo**.

The flow runs in the background. When complete, it commits any generated fixes to the MR branch
and re-runs the pipeline.

## Related topics

- [Agentic breaking change resolution](../../../application_security/dependency_scanning/agentic-breaking-change-resolution.md)
- [Dependency scanning](../../../application_security/dependency_scanning/_index.md)
- [GitLab Duo](../../../gitlab_duo/_index.md)

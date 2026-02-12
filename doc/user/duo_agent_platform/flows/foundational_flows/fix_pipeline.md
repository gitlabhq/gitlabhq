---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Fix CI/CD Pipeline Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduced as [an experiment](../../../../policy/development_stages_support.md) in GitLab 18.4 [with flags](../../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci` and `ai_duo_agent_fix_pipeline_button`. `duo_workflow_in_ci` is enabled by default. `ai_duo_agent_fix_pipeline_button` is disabled by default. These flags can be enabled or disabled for the instance or project.
- Enabled on GitLab.com and GitLab Self-Managed in GitLab 18.5.
- Feature flag `ai_duo_agent_fix_pipeline_button` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086) in GitLab 18.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8. Feature flag `ai_duo_agent_fix_pipeline_button` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681). Feature flag `duo_workflow_in_ci` was removed in GitLab 18.9.

{{< /history >}}

The Fix CI/CD Pipeline Flow helps you automatically diagnose and fix issues in your GitLab CI/CD pipeline. This flow:

- Analyzes pipeline failure logs and error messages.
- Identifies configuration issues and syntax errors.
- Suggests specific fixes based on the type of failure.
- Creates a merge request with changes that attempt to fix a failing pipeline.

The flow can automatically fix various pipeline issues, including:

- Syntax and configuration errors.
- Common job failures.
- Dependency and workflow issues.

This flow is available in the GitLab UI only.

> [!note]
> The Fix CI/CD Pipeline Flow creates merge requests by using a service account. Organizations with SOC 2, SOX, ISO 27001, or FedRAMP requirements should ensure appropriate peer review policies are in place. For more information, see [compliance considerations for merge requests](../../composite_identity.md#compliance-considerations-for-merge-requests).

## Prerequisites

To use this flow, you must:

- Have an existing failed pipeline.
- Have the Developer, Maintainer, or Owner role in the project.
- Meet [the other prerequisites](../../../duo_agent_platform/_index.md#prerequisites).
- [Ensure the GitLab Duo service account can create commits and branches](../../troubleshooting.md#session-is-stuck-in-created-state).
- Ensure that the Fix CI/CD Pipeline Flow is [turned on](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off).

## Fix the pipeline in a merge request

To fix the CI/CD pipeline in a merge request:

1. On the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and open your merge request.
1. To fix the pipeline, you can either:
   - Select the **Overview** tab and under the failing pipeline, select **Fix pipeline with Duo**.
   - Select the **Pipelines** tab and in the rightmost column, select **Fix pipeline with Duo** ({{< icon name="tanuki-ai" >}}).

1. To monitor progress, select **Automate** > **Sessions**.

When the session is complete, a comment shows a link to a merge request that contains the fix,
or a comment describes possible next steps.

## Fix other CI/CD pipelines

To fix a CI/CD pipeline that is not associated with a merge request:

1. Select **Build** > **Pipelines**.
1. Select your failing pipeline.
1. In the upper-right corner, select **Fix pipeline with Duo**.
1. To monitor progress, select **Automate** > **Sessions**.

## What the flow analyzes

The Fix CI/CD Pipeline Flow examines:

- Pipeline logs: Error messages, failed job outputs, and exit codes.
- Merge request changes: Changes that could have caused the failure.
- The current repository contents: For identifying syntax, linting, or import errors.
- Script errors: Command failures, missing executables, or permission issues.

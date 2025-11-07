---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Fix CI/CD Pipeline Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as [an experiment](../../../policy/development_stages_support.md) in GitLab 18.4 [with flags](../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci` and `ai_duo_agent_fix_pipeline_button`. `duo_workflow_in_ci` is enabled by default. `ai_duo_agent_fix_pipeline_button` is disabled by default. These flags can be enabled or disabled for the instance or project.
- Enabled on GitLab.com and GitLab Self-Managed in GitLab 18.5.
- Feature flag `ai_duo_agent_fix_pipeline_button` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086) in GitLab 18.5.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

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

## Prerequisites

To use this flow, you must:

- Have an existing failed pipeline.
- Have at least the Developer role in the project.
- Meet [the other prerequisites](../../duo_agent_platform/_index.md#prerequisites).

## Use the flow

To fix your CI/CD pipeline:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Code** > **Merge requests** and open your merge request.
1. Select the **Pipelines** tab.
1. In the rightmost column, for the failed pipeline you want to fix, select **Fix pipeline with Duo** ({{< icon name="tanuki-ai" >}}).
1. To monitor progress, select **Automate** > **Sessions**.

   After the session is complete, go back to your merge request.
1. Review the merge request and make changes as needed before merging.

## What the flow analyzes

The Fix CI/CD Pipeline Flow examines:

- **Pipeline logs**: Error messages, failed job outputs, and exit codes.
- **Merge request changes**: Changes that could have caused the failure.
- **The current repository contents**: For identifying syntax, linting, or import errors.
- **Script errors**: Command failures, missing executables, or permission issues.

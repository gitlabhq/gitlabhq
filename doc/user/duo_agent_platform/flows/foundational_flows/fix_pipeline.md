---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fix CI/CD Pipeline Flow
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced as [an experiment](../../../../policy/development_stages_support.md) in GitLab 18.4 [with feature flags](../../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci` and `ai_duo_agent_fix_pipeline_button`. `duo_workflow_in_ci` is enabled by default. `ai_duo_agent_fix_pipeline_button` is disabled by default. These flags can be enabled or disabled for the instance or project.
- Enabled on GitLab.com and GitLab Self-Managed in GitLab 18.5.
- Feature flag `ai_duo_agent_fix_pipeline_button` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086) in GitLab 18.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8. Feature flag `ai_duo_agent_fix_pipeline_button` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681). Feature flag `duo_workflow_in_ci` was removed in GitLab 18.9.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.
- Fixes to pipelines associated with a merge request [changed](https://gitlab.com/groups/gitlab-org/-/work_items/21837)
  to apply as code suggestions in GitLab 19.1
  [with a feature flag](../../../../administration/feature_flags/_index.md) named `fix_pipeline_next`.
  Enabled on GitLab.com for a subset of users.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241608) in GitLab 19.2. Feature flag `fix_pipeline_next` removed.

{{< /history >}}

The Fix CI/CD Pipeline Flow diagnoses and proposes fixes issues in your GitLab CI/CD pipeline.
To diagnose failures, the flow examines:

- Pipeline logs, including error messages, failed job outputs, and exit codes.
- Merge request changes that could have caused the failure.
- Repository contents, for identifying syntax, linting, or import errors.
- Script errors, including command failures, missing executables, or permission issues.

How the flow applies fixes depends on the pipeline context:

- If the pipeline is associated with a merge request, the flow applies inline code suggestions
  on the source branch. You can review and apply the suggestions directly from the merge request.
  - If the fix requires changes to files outside the current merge request diff, the flow
    creates a new merge request instead.
- If the pipeline is not associated with a merge request, the flow creates a new merge request
  that contains the fix.

In some cases, instead of attempting a fix, the flow posts a comment that describes
the failure and possible next steps.
This happens when the pipeline is associated with a merge request, for example:

- Insufficient context exists to determine a reliable fix.
- The failure is security-sensitive and should be reviewed by a person.
- The failure category is not actionable by the flow.

When a session starts and completes, the flow posts system notes to the merge request
with a link to the session. This flow is available in the GitLab UI only.

This flow is the recommended path if you use the GitLab Duo Agent Platform and want to
fix a failed pipeline automatically.
It's a separate experience from
[Root Cause Analysis](../../../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis),
a GitLab Duo Chat feature to troubleshoot single-job failures.

## Prerequisites

- Meet the [prerequisites for the GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Turn on **Allow foundational flows** and **Fix CI/CD Pipeline** [for the top-level group](_index.md#turn-foundational-flows-on-or-off).
- Have the Developer, Maintainer, or Owner role for the project.
- Have an existing failed pipeline.
- [Configure push rules to allow a service account](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configure your own runners](../execution.md#configure-runners-to-execute-flows) or turn on [GitLab hosted runners](../../../../ci/runners/hosted_runners/_index.md) for your project.

## Fix the pipeline in a merge request

{{< history >}}

- Using a flow in a GitLab Duo Agentic Chat conversation [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20484) in GitLab 19.2 [with a feature flag](../../../../administration/feature_flags/_index.md) named `agentic_foundational_flow_tool`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

To fix the CI/CD pipeline in a merge request:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and open your merge request.
1. Use one of these methods to fix the pipeline:
   - Select the **Overview** tab and, under the failing pipeline, select
     **Fix pipeline with Duo**.
   - Select the **Pipelines** tab and, in the rightmost column, select
     **Fix pipeline with Duo** ({{< icon name="tanuki-ai" >}}).
   - In the GitLab Duo sidebar, open a new or existing Agentic Chat conversation.
     Ask Agentic Chat to fix the pipeline.
1. To monitor progress, in the left sidebar, select **AI** > **Sessions**.

   If you are in Agentic Chat, you can also do the following:
   - See the progress in the Chat conversation.
   - Select **View Agent Session** in the conversation.

When the session is complete, the flow adds code suggestions to the merge request,
or a comment describes possible next steps.

## Fix other CI/CD pipelines

To fix a CI/CD pipeline that is not associated with a merge request:

1. Select **Build** > **Pipelines**.
1. Select your failing pipeline.
1. In the upper-right corner, select **Fix pipeline with Duo**.
1. To monitor progress, select **AI** > **Sessions**.

## Use `AGENTS.md` to customize the flow

The flow reads repository-specific instructions from an
[`AGENTS.md`](../../customize/agents_md.md) file in your repository.
You can use `AGENTS.md` to customize behavior such as:

- Commit message format for the changes the flow commits.
- Merge request metadata, such as labels and description, for merge requests the flow creates.
- How to classify and treat specific types of failures.

For example:

```markdown
## Fix pipeline merge requests

When opening a merge request as part of the Fix Pipeline flow (the title contains [FixPipeline]),
apply labels based on the following failed pipeline scenarios:

- Pipeline failed on merge_request: apply "pipeline::tier-1". This runs the cheaper tier-1
  pipeline instead of the full default pipeline.
- Pipeline failed on the default_branch (main): apply both "pipeline::expedited" and
  "main:broken". Do not apply pipeline::tier-1 in this case.
- Pipeline failed on other branches: apply "pipeline::tier-1". Same treatment as the
  merge_request case.
```

## Known issues

- The AI gateway processes only the last 150 KiB of job logs. If your job produces extensive
  output, the flow might not capture relevant failure information that appears earlier in the log.
  See the following section for workarounds.
- The flow cannot always verify package installation in the sandboxed runtime environment.
  If dependencies are missing, you can customize the default flow image. See
  [change the default Docker image](../execution.md#change-the-default-docker-image).
- Repository instructions in `AGENTS.md` influence the flow's behavior but are not guaranteed
  to be followed in every case.

## Troubleshooting

When working with the Fix CI/CD Pipeline Flow, you might encounter the following issues.

### Flow cannot identify the root cause of a failure

The flow might not identify the root cause of a pipeline failure.

This issue occurs when job logs exceed 150 KiB. The AI gateway processes only the last 150 KiB,
so relevant failure information that appears earlier in the log might not be captured.

To work around this issue, try the following:

- Reduce verbose output by removing debug logging and progress indicators.
- Redirect non-critical output using shell redirection (`> /dev/null`).
- Add a summary step at the end of your script that echoes key error messages.
- Use `after_script` to output diagnostic information after the main script completes.
- Split verbose jobs into smaller, focused jobs with more concise logs.

## Give feedback

The team is actively improving the Fix CI/CD Pipeline Flow. To report issues or suggest improvements, leave your feedback in [feedback issue 601991](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991).

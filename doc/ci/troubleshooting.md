---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Troubleshooting CI/CD

## Merge request pipeline widget

The merge request pipeline widget shows information about the pipeline status in a Merge Request. It's displayed above the [merge request ability to merge widget](#merge-request-ability-to-merge-widget).

There are several messages that can be displayed depending on the status of the pipeline.

### "Checking pipeline status"

This message is shown when the merge request has no pipeline associated with the latest commit yet and [Pipelines must succeed](../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds) is turned on. This might be because:

- GitLab hasn't finished creating the pipeline yet.
- You are using an external CI service and GitLab hasn't heard back from the service yet.
- You are not using CI/CD pipelines in your project.

After the pipeline is created, the message will update with the pipeline status.

Note: Currently if you delete the latest pipeline of a Merge Request, this message will be shown instead of a meaningful error message. This is a known issue and should be resolved soon.

## Merge request ability to merge widget

The merge request status widget shows the **Merge** button and whether or not a merge request is ready to merge. If the merge request can't be merged, the reason for this is displayed.

If the pipeline is still running, the **Merge** button is replaced with the **Merge when pipeline succeeds** button.

If [**Merge Trains**](merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md) are enabled, the button is either **Add to merge train** or **Add to merge train when pipeline succeeds**. **(PREMIUM)**

### "A CI/CD pipeline must run and be successful before merge"

This message is shown if the [Pipelines must succeed](../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds) setting is enabled in the project and a pipeline has not yet run successfully. This also applies if the pipeline has not been created yet, or if you are waiting for an external CI service. If you don't use pipelines for your project, then you should disable **Pipelines must succeed** so you can accept merge requests.

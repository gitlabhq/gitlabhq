# Merge when pipeline succeeds

When reviewing a merge request that looks ready to merge but still has one or
more CI jobs running, you can set it to be merged automatically when the
jobs pipeline succeeds. This way, you don't have to wait for the jobs to
finish and remember to merge the request manually.

![Enable](img/merge_when_pipeline_succeeds_enable.png)

When you hit the "Merge When Pipeline Succeeds" button, the status of the merge
request will be updated to represent the impending merge. If you cannot wait
for the pipeline to succeed and want to merge immediately, this option is
available in the dropdown menu on the right of the main button.

Both team developers and the author of the merge request have the option to
cancel the automatic merge if they find a reason why it shouldn't be merged
after all.

![Status](img/merge_when_pipeline_succeeds_status.png)

When the pipeline succeeds, the merge request will automatically be merged.
When the pipeline fails, the author gets a chance to retry any failed jobs,
or to push new commits to fix the failure.

When the jobs are retried and succeed on the second try, the merge request
will automatically be merged after all. When the merge request is updated with
new commits, the automatic merge is automatically canceled to allow the new
changes to be reviewed.

## Only allow merge requests to be merged if the pipeline succeeds

> **Note:**
You need to have jobs configured to enable this feature.

You can prevent merge requests from being merged if their pipeline did not succeed
or if there are discussions to be resolved.

Navigate to your project's settings page and expand the **Merge requests** section.
In the **Merge checks** subsection, select the **Pipelines must succeed** check
box and hit **Save** for the changes to take effect.

![Pipelines must succeed settings](img/merge_when_pipeline_succeeds_only_if_succeeds_settings.png)

From now on, every time the pipeline fails you will not be able to merge the
merge request from the UI, until you make all relevant jobs pass.

![Only allow merge if pipeline succeeds message](img/merge_when_pipeline_succeeds_only_if_succeeds_msg.png)

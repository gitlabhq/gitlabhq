# Merge When Build Succeeds

When reviewing a merge request that looks ready to merge but still has one or
more CI builds running, you can set it to be merged automatically when all
builds succeed. This way, you don't have to wait for the builds to finish and
remember to merge the request manually.

![Enable](img/merge_when_build_succeeds_enable.png)

When you hit the "Merge When Build Succeeds" button, the status of the merge
request will be updated to represent the impending merge. If you cannot wait
for the build to succeed and want to merge immediately, this option is available
in the dropdown menu on the right of the main button.

Both team developers and the author of the merge request have the option to
cancel the automatic merge if they find a reason why it shouldn't be merged
after all.

![Status](img/merge_when_build_succeeds_status.png)

When the build succeeds, the merge request will automatically be merged. When
the build fails, the author gets a chance to retry any failed builds, or to
push new commits to fix the failure.

When the builds are retried and succeed on the second try, the merge request
will automatically be merged after all. When the merge request is updated with
new commits, the automatic merge is automatically canceled to allow the new
changes to be reviewed.

## Only allow merge requests to be merged if the build succeeds

> **Note:**
You need to have builds configured to enable this feature.

You can prevent merge requests from being merged if their build did not succeed.

Navigate to your project's settings page, select the
**Only allow merge requests to be merged if the build succeeds** check box and
hit **Save** for the changes to take effect.

![Only allow merge if build succeeds settings](img/merge_when_build_succeeds_only_if_succeeds_settings.png)

From now on, every time the build fails you will not be able to merge the merge
request from the UI, until you make the build pass.

![Only allow merge if build succeeds msg](img/merge_when_build_succeeds_only_if_succeeds_msg.png)

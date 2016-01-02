# Rebase before merge

GitLab Enterprise Edition offers a way to rebase source branch of merge request. 
This feature is part of [Fast-forward merge](ff_merge.md) feature. 
It allows you to rebase source branch of merge request in order to perform fast-forward merge.

You can configure this per project basis by navigating to the project settings page and selecting `Rebase button` checkbox.
This checkbox is visible only if you have `Only fast-forward merging` checkbox enabled.

![Merge request settings](merge_request_settings.png)


Now if fast-forward merge requires rebase - you will see rebase button:

![Rebase request widget](rebase_request_widget.png)

GitLab will attempt to rebase source branch. If rebase succeed you will see `Accept merge request` button.
If clean rebase is not possible - you need to do rebase manually. 
Possibly rebase requires some conflicts to be resolved by human.

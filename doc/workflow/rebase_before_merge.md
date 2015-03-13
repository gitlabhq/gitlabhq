#Rebase before merge

GitLab Enterprise Edition offers a way to rebase before merging a merge request. You can configure this per project basis by navigating to the project settings page and selecting `Merge Requests Rebase` checkbox.

![Merge request settings](merge_request_settings.png)

Before accepting a merge request, select `rebase before merge`.
![Merge request widget](merge_request_widget.png)

GitLab will attempt to cleanly rebase before merging branches. If clean rebase is not possible, regular merge will be performed.
If clean rebase is possible and history of the traget branch will be altered with the the merge.
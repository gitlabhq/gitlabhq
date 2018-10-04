# "Work In Progress" Merge Requests

To prevent merge requests from accidentally being accepted before they're
completely ready, GitLab blocks the "Accept" button for merge requests that
have been marked a **Work In Progress**.

![Blocked Accept Button](img/wip_blocked_accept_button.png)

To mark a merge request a Work In Progress, simply start its title with `[WIP]`
or `WIP:`. As an alternative, you're also able to do it by sending a commit
with its title starting with `wip` or `WIP` to the merge request's source branch.

![Mark as WIP](img/wip_mark_as_wip.png)

To allow a Work In Progress merge request to be accepted again when it's ready,
simply remove the `WIP` prefix.

![Unmark as WIP](img/wip_unmark_as_wip.png)

## Filtering merge requests with WIP Status

To filter merge requests with the `WIP` status, you can type `wip`
and select the value for your filter from the merge request search input.

![Filter WIP MRs](img/filter_wip_merge_requests.png)

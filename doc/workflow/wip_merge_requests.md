# "Work In Progress" Merge Requests

To prevent merge requests from accidentally being accepted before they're completely ready, GitLab blocks the "Accept" button for merge requests that have been marked a **Work In Progress**.

![Blocked Accept Button](wip_merge_requests/blocked_accept_button.png)

To mark a merge request a Work In Progress, simply start its title with `[WIP]` or `WIP:`.

![Mark as WIP](wip_merge_requests/mark_as_wip.png)

To allow a Work In Progress merge request to be accepted again when it's ready, simply remove the `WIP` prefix.

![Unark as WIP](wip_merge_requests/unmark_as_wip.png)

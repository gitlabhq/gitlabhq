# "Work In Progress" Merge Requests

If a merge request is not yet ready to be merged, perhaps due to continued development
or open discussions, you can prevent it from being accepted before it's ready by flagging
it as a **Work In Progress**. This will disable the "Merge" button, preventing it from
being merged, and it will stay disabled until the "WIP" flag has been removed.

![Blocked Accept Button](img/wip_blocked_accept_button.png)

## Adding the "Work In Progress" flag to a Merge Request

There are several ways to flag a merge request as a Work In Progress:

- Add "[WIP]" or "WIP:" to the start of the merge request's title. Clicking on
  **Start the title with WIP:**, under the title box, when editing the merge request's
  description will have the same effect.
- Add the `/wip` [quick action](../quick_actions.md#quick-actions-for-issues-and-merge-requests)
  in a discussion comment in the merge request. This is a toggle, and can be repeated
  to change the status back. Note that any other text in the comment will be discarded.
- Add "wip" or "WIP" to the start of a commit message targeting the merge request's
  source branch. This is not a toggle, and doing it again in another commit will have
  no effect.

## Removing the "Work In Progress" flag from a Merge Request

Similar to above, when a Merge Request is ready to be merged, you can remove the
"Work in Progress" flag in several ways:

- Remove "[WIP]" or "WIP:" from the start of the merge request's title. Clicking on
  **Remove the WIP: prefix from the title**, under the title box, when editing the merge
  request's description, will have the same effect.
- Add the `/wip` [quick action](../quick_actions.md#quick-actions-for-issues-and-merge-requests)
  in a discussion comment in the merge request. This is a toggle, and can be repeated
  to change the status back. Note that any other text in the comment will be discarded.
- Click on the **Resolve WIP status** button near the bottom of the merge request description,
  next to the "Merge" button (see [image above](#work-in-progress-merge-requests)).
  Must have at least Developer level permissions on the project for the button to
  be visible.

## Including/Excluding WIP Merge Requests when searching

When viewing/searching the merge requests list, you can choose to include or exclude
WIP merge requests by adding a "WIP" filter in the search box, and choosing "Yes"
(to include) or "No" (to exclude).

![Filter WIP MRs](img/filter_wip_merge_requests.png)

---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Merge your branch into the main branch
---

After you have [created a branch](branch.md), made the required changes, and [committed them locally](commit.md),
you [push your branch](commit.md#send-changes-to-gitlab) and its commits to GitLab.

In the response to the `git push`, GitLab provides a direct link to create the merge request. For example:

```plaintext
...
remote: To create a merge request for my-new-branch, visit:
remote:   https://gitlab.example.com/my-group/my-project/merge_requests/new?merge_request%5Bsource_branch%5D=my-new-branch
```

To get your branch merged into the main branch:

1. Go to the page provided in the link that was provided by Git and
   [create your merge request](../../user/project/merge_requests/creating_merge_requests.md). The merge request's
   **Source branch** is your branch and the **Target branch** should be the main branch.
1. If necessary, have your [merge request reviewed](../../user/project/merge_requests/reviews/_index.md#request-a-review).
1. Have someone [merge your merge request](../../user/project/merge_requests/_index.md#merge-a-merge-request), or merge
   the merge request yourself, depending on your process.

## Related topics

- [Merge requests](../../user/project/merge_requests/_index.md)
- [Merge methods](../../user/project/merge_requests/methods/_index.md)
- [Merge conflicts](../../user/project/merge_requests/conflicts.md)

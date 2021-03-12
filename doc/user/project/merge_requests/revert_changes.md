---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, concepts
---

# Reverting changes **(FREE)**

You can use Git's powerful feature to [revert any commit](https://git-scm.com/docs/git-revert "Git revert documentation")
by clicking the **Revert** button in merge requests and commit details.

## Reverting a merge request

NOTE:
The **Revert** button is available only for merge requests
created in GitLab 8.5 and later. However, you can still revert a merge request
by reverting the merge commit from the list of Commits page.

NOTE:
The **Revert** button is shown only for projects that use the
merge method "Merge Commit", which can be set under the project's
**Settings > General > Merge request**. [Fast-forward commits](fast_forward_merge.md)
can not be reverted by using the merge request view.

After the merge request has been merged, use the **Revert** button
to revert the changes introduced by that merge request.

![Revert merge request](img/cherry_pick_changes_mr.png)

After you click that button, a modal appears where you can choose to
revert the changes directly into the selected branch or you can opt to
create a new merge request with the revert changes.

After the merge request has been reverted, the **Revert** button is no longer available.

## Reverting a commit

You can revert a commit from the commit details page:

![Revert commit](img/cherry_pick_changes_commit.png)

Similar to reverting a merge request, you can opt to revert the changes
directly into the target branch or create a new merge request to revert the
changes.

After a commit is reverted, the **Revert** button is no longer available.

When reverting merge commits, the mainline is always the
first parent. If you want to use a different mainline, you need to do that
from the command line.

Here's an example to revert a merge commit using the second parent as the
mainline:

```shell
git revert -m 2 7a39eb0
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

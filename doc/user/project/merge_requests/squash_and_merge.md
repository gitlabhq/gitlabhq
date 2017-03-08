# Squash and merge

> [Introduced][ee-1024] in GitLab Enterprise Edition 8.17.

Squashing lets you tidy up the commit history of a branch when accepting a merge
request. It applies all of the changes in the merge request as a single commit,
and then merges that commit using the merge method set for the project.

In other words, squashing a merge request turns a long list of commits:

![List of commits from a merge request][mr-commits]

Into a single commit on merge:

![A squashed commit followed by a merge commit][squashed-commit]

Note that the squashed commit is still followed by a merge commit, as the merge
method for this example repository uses a merge commit. Squashing also works
with the fast-forward merge strategy: see
[squashing and fast-forward merge](#squashing-and-fast-forward-merge) for more
details.

## Enabling squash for a merge request

Anyone who can create or edit a merge request can choose for it to be squashed
on the merge request form:

![Squash commits checkbox on edit form][squash-edit-form]

This can then be overridden at the time of accepting the merge request:

![Squash commits checkbox on accept merge request form][squash-mr-widget]

## Commit metadata for squashed commits

The squashed commit has the following metadata:

* Message: the title of the merge request.
* Author: the author of the merge request.
* Committer: the user who initiated the squash.

## Squashing and [fast-forward merge][ff-merge]

When a project has the fast-forward merge setting enabled, the merge request
must be able to be fast-forwarded without squashing in order to squash it. This
is because squashing is only available when accepting a merge request, so a
merge request may need to be [rebased][rebase] before squashing, even though
squashing can itself be considered equivalent to rebasing.

[ee-1024]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1024
[mr-commits]: img/squash_mr_commits.png
[squashed-commit]: img/squash_squashed_commit.png
[squash-edit-form]: img/squash_edit_form.png
[squash-mr-widget]: img/squash_mr_widget.png
[ff-merge]: fast_forward_merge.md
[rebase]: ../../../workflow/rebase_before_merge.md

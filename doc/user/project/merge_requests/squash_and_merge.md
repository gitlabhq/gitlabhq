# Squash and merge **[STARTER]**

> [Introduced][ee-1024] in [GitLab Starter][ee] 8.17.

Combine all commits of your merge request into one and retain a clean history.

## Overview

Squashing lets you tidy up the commit history of a branch when accepting a merge
request. It applies all of the changes in the merge request as a single commit,
and then merges that commit using the merge method set for the project.

In other words, squashing a merge request turns a long list of commits:

![List of commits from a merge request][mr-commits]

Into a single commit on merge:

![A squashed commit followed by a merge commit][squashed-commit]

The squashed commit's commit message is the merge request title. And note that 
the squashed commit is still followed by a merge commit, as the merge
method for this example repository uses a merge commit. Squashing also works
with the fast-forward merge strategy, see
[squashing and fast-forward merge](#squashing-and-fast-forward-merge) for more
details.

## Use cases

When working on a feature branch, you sometimes want to commit your current
progress, but don't really care about the commit messages. Those 'work in
progress commits' don't necessarily contain important information and as such
you'd rather not include them in your target branch. 

With squash and merge, when the merge request is ready to be merged,
all you have to do is enable squashing before you press merge to join
the commits include in the merge request into a single commit.

This way, the history of your base branch remains clean with
meaningful commit messages and is simpler to [revert] if necessary.

## Enabling squash for a merge request

Anyone who can create or edit a merge request can choose for it to be squashed
on the merge request form:

![Squash commits checkbox on edit form][squash-edit-form]

---

This can then be overridden at the time of accepting the merge request:

![Squash commits checkbox on accept merge request form][squash-mr-widget]

## Commit metadata for squashed commits

The squashed commit has the following metadata:

* Message: the title of the merge request.
* Author: the author of the merge request.
* Committer: the user who initiated the squash.

## Squash and fast-forward merge

When a project has the [fast-forward merge setting enabled][ff-merge], the merge
request must be able to be fast-forwarded without squashing in order to squash
it. This is because squashing is only available when accepting a merge request,
so a merge request may need to be rebased before squashing, even though
squashing can itself be considered equivalent to rebasing.

[ee-1024]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1024
[mr-commits]: img/squash_mr_commits.png
[squashed-commit]: img/squash_squashed_commit.png
[squash-edit-form]: img/squash_edit_form.png
[squash-mr-widget]: img/squash_mr_widget.png
[ff-merge]: fast_forward_merge.md#enabling-fast-forward-merges
[ee]: https://about.gitlab.com/products/
[revert]: revert_changes.md

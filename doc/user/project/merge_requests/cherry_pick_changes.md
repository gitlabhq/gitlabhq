# Cherry-pick changes

> [Introduced][ce-3514] in GitLab 8.7.

GitLab implements Git's powerful feature to [cherry-pick any commit][git-cherry-pick]
with introducing a **Cherry-pick** button in merge requests and commit details.

## Cherry-picking a merge request

After the merge request has been merged, a **Cherry-pick** button will be available
to cherry-pick the changes introduced by that merge request.

![Cherry-pick Merge Request](img/cherry_pick_changes_mr.png)

After you click that button, a modal will appear where you can choose to
cherry-pick the changes directly into the selected branch or you can opt to
create a new merge request with the cherry-pick changes

## Cherry-picking a Commit

You can cherry-pick a Commit from the Commit details page:

![Cherry-pick commit](img/cherry_pick_changes_commit.png)

Similar to cherry-picking a merge request, you can opt to cherry-pick the changes
directly into the target branch or create a new merge request to cherry-pick the
changes.

Please note that when cherry-picking merge commits, the mainline will always be the
first parent. If you want to use a different mainline then you need to do that
from the command line.

Here is a quick example to cherry-pick a merge commit using the second parent as the
mainline:

```bash
git cherry-pick -m 2 7a39eb0
```

[ce-3514]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3514 "Cherry-pick button Merge Request"
[git-cherry-pick]: https://git-scm.com/docs/git-cherry-pick "Git cherry-pick documentation"

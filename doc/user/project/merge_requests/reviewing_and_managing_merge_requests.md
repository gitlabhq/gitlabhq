---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# Reviewing and managing merge requests **(CORE)**

Merge requests are the primary method of making changes to files in a GitLab project.
Changes are proposed by [creating and submitting a merge request](creating_merge_requests.md),
which is then reviewed, and accepted (or rejected).

## View project merge requests

View all the merge requests within a project by navigating to **Project > Merge Requests**.

When you access your project's merge requests, GitLab will present them in a list,
and you can use the tabs available to quickly filter by open and closed. You can also [search and filter the results](../../search/index.md#filtering-issue-and-merge-request-lists).

![Project merge requests list view](img/project_merge_requests_list_view.png)

## View merge requests for all projects in a group

View merge requests in all projects in the group, including all projects of all descendant subgroups of the group. Navigate to **Group > Merge Requests** to view these merge requests. This view also has the open and closed merge requests tabs.

You can [search and filter the results](../../search/index.md#filtering-issue-and-merge-request-lists) from here.

![Group Issues list view](img/group_merge_requests_list_view.png)

## Semi-linear history merge requests

A merge commit is created for every merge, but the branch is only merged if
a fast-forward merge is possible. This ensures that if the merge request build
succeeded, the target branch build will also succeed after merging.

Navigate to a project's settings, select the **Merge commit with semi-linear history**
option under **Merge Requests: Merge method** and save your changes.

## View changes between file versions

The **Changes** tab, below the main merge request details and next to the discussion tab,
shows the changes to files between branches or commits. This view of changes to a
file is also known as a **diff**. By default, the diff view compares the file in the
merge request branch and the file in the target branch.

The diff view includes the following:

- The file's name and path.
- The number of lines added and deleted.
- Buttons for the following options:
  - Toggle comments for this file; useful for inline reviews.
  - Edit the file in the merge request's branch.
  - Show full file, in case you want to look at the changes in context with the rest of the file.
  - View file at the current commit.
  - Preview the changes with [Review Apps](../../../ci/review_apps/index.md).
- The changed lines, with the specific changes highlighted.

![Example screenshot of a source code diff](img/merge_request_diff_v12_2.png)

### Merge request diff file navigation

When reviewing changes in the **Changes** tab the diff can be navigated using
the file tree or file list. As you scroll through large diffs with many
changes, you can quickly jump to any changed file using the file tree or file
list.

![Merge request diff file navigation](img/merge_request_diff_file_navigation.png)

### Collapsed files in the Changes view

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232820) in GitLab 13.4.

When you review changes in the **Changes** tab, files with a large number of changes are collapsed
to improve performance. When files are collapsed, a warning appears at the top of the changes.
Click **Expand file** on any file to view the changes for that file.

### File-by-file diff navigation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/222790) in GitLab 13.2.
> - It's deployed behind a feature flag, enabled by default.
> - It's recommended for production use.
> - It's enabled on GitLab.com.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-file-by-file-diff-navigation).

For larger merge requests it might sometimes be useful to review single files at a time. To enable,
from your avatar on the top-right navigation bar, click **Settings**, and go to **Preferences** on the left
sidebar. Scroll down to the **Behavior** section and select **Show one file at a time on merge request's Changes tab**.
Click **Save changes** to apply.

From there, when reviewing merge requests' **Changes** tab, you will see only one file at a time. You can then click the buttons **Prev** and **Next** to view the other files changed.

![File-by-file diff navigation](img/file_by_file_v13_2.png)

#### Enable or disable file-by-file diff navigation **(CORE ONLY)**

File-by-file diff navigation is under development but ready for production use. It is
deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to disable it for your instance.

To enable it:

```ruby
# Instance-wide
Feature.enable(:view_diffs_file_by_file)
```

To disable it:

```ruby
# Instance-wide
Feature.disable(:view_diffs_file_by_file>)
```

### Merge requests commit navigation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18140) in GitLab 13.0.

To seamlessly navigate among commits in a merge request, from the **Commits** tab, click one of
the commits to open the single-commit view. From there, you can navigate among the commits
by clicking the **Prev** and **Next** buttons on the top-right of the page or by using the
<kbd>X</kbd> and <kbd>C</kbd> keyboard shortcuts.

![Merge requests commit navigation](img/commit_nav_v13_4.png)

### Incrementally expand merge request diffs

By default, the diff shows only the parts of a file which are changed.
To view more unchanged lines above or below a change click on the
**Expand up** or **Expand down** icons. You can also click on **Show unchanged lines**
to expand the entire file.

![Incrementally expand merge request diffs](img/incrementally_expand_merge_request_diffs_v12_2.png)

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205401) in GitLab 13.1, when viewing a
merge request's **Changes** tab, if a certain file was only renamed, you can expand it to see the
entire content by clicking **Show file contents**.

### Ignore whitespace changes in Merge Request diff view

If you click the **Hide whitespace changes** button, you can see the diff
without whitespace changes (if there are any). This is also working when on a
specific commit page.

![MR diff](img/merge_request_diff.png)

TIP: **Tip:**
You can append `?w=1` while on the diffs page of a merge request to ignore any
whitespace changes.

## Perform inline code reviews

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/13950) in GitLab 11.5.

GitLab provides a way of leaving comments in any part of the file being changed
in a Merge Request. To do so, click the **{comment}** **comment** icon in the gutter of the Merge Request diff UI to expand the diff lines and leave a comment, just as you would for a changed line.

![Comment on any diff file line](img/comment-on-any-diff-line.png)

### Commenting on multiple lines

> - [Introduced](https://gitlab.com/gitlab-org/ux-research/-/issues/870) in GitLab 13.2.
> - It's deployed behind a feature flag, enabled by default.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/221268) on GitLab 13.3.
> - It's enabled on GitLab.com.
> - It can be disabled or enabled per-project.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-multiline-comments). **(CORE ONLY)**

GitLab provides a way to select which lines of code a comment refers to. After starting a comment
a dropdown selector is shown to select the first line that this comment refers to.
The last line is the line that the comment icon was initially clicked on.

New comments default to single line comments by having the first and last lines
the same. Selecting a different starting line turns this into a multiline comment.

![Multiline comment selection highlighted](img/multiline-comment-highlighted.png)

Once a multiline comment is saved the lines of code pertaining to that comment are listed directly
above it.

![Multiline comment selection displayed above comment](img/multiline-comment-saved.png)

### Enable or disable multiline comments **(CORE ONLY)**

The multiline comments feature is under development but ready for production use.
It is deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to enable it for your instance.

To disable it:

```ruby
Feature.disable(:multiline_comments)
```

To enable it:

```ruby
Feature.enable(:multiline_comments)
```

## Pipeline status in merge requests widgets

If you've set up [GitLab CI/CD](../../../ci/README.md) in your project,
you will be able to see:

- Both pre-merge and post-merge pipelines and the environment information if any.
- Which deployments are in progress.

If there's an [environment](../../../ci/environments/index.md) and the application is
successfully deployed to it, the deployed environment and the link to the
Review App will be shown as well.

NOTE: **Note:**
When the default branch (for example, `main`) is red due to a failed CI pipeline, the `merge` button
When the pipeline fails in a merge request but it can be merged nonetheless,
the **Merge** button will be colored in red.

### Post-merge pipeline status

When a merge request is merged, you can see the post-merge pipeline status of
the branch the merge request was merged into. For example, when a merge request
is merged into the master branch and then triggers a deployment to the staging
environment.

Deployments that are ongoing will be shown, as well as the deploying/deployed state
for environments. If it's the first time the branch is deployed, the link
will return a `404` error until done. During the deployment, the stop button will
be disabled. If the pipeline fails to deploy, the deployment information will be hidden.

![Merge request pipeline](img/merge_request_pipeline.png)

For more information, [read about pipelines](../../../ci/pipelines/index.md).

### Merge when pipeline succeeds (MWPS)

Set a merge request that looks ready to merge to [merge automatically when CI pipeline succeeds](merge_when_pipeline_succeeds.md).

### Live preview with Review Apps

If you configured [Review Apps](https://about.gitlab.com/stages-devops-lifecycle/review-apps/) for your project,
you can preview the changes submitted to a feature-branch through a merge request
in a per-branch basis. No need to checkout the branch, install and preview locally;
all your changes will be available to preview by anyone with the Review Apps link.

With GitLab's [Route Maps](../../../ci/review_apps/index.md#route-maps) set, the
merge request widget takes you directly to the pages changed, making it easier and
faster to preview proposed modifications.

[Read more about Review Apps](../../../ci/review_apps/index.md).

## Associated features

There is also a large number of features to associated to merge requests:

| Feature                                                                                                                                               | Description                                                                                                                                              |
|-------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Bulk editing merge requests](../../project/bulk_editing.md)                                                                                          | Update the attributes of multiple merge requests simultaneously.                                                                                         |
| [Cherry-pick changes](cherry_pick_changes.md)                                                                                                         | Cherry-pick any commit in the UI by simply clicking the **Cherry-pick** button in a merged merge requests or a commit.                                   |
| [Fast-forward merge requests](fast_forward_merge.md)                                                                                                  | For a linear Git history and a way to accept merge requests without creating merge commits                                                               |
| [Find the merge request that introduced a change](versions.md)                                                                                        | When viewing the commit details page, GitLab will link to the merge request(s) containing that commit.                                                   |
| [Merge requests versions](versions.md)                                                                                                                | Select and compare the different versions of merge request diffs                                                                                         |
| [Resolve conflicts](resolve_conflicts.md)                                                                                                             | GitLab can provide the option to resolve certain merge request conflicts in the GitLab UI.                                                               |
| [Revert changes](revert_changes.md)                                                                                                                   | Revert changes from any commit from within a merge request.                                                                                              |

## Troubleshooting

Sometimes things don't go as expected in a merge request, here are some
troubleshooting steps.

### Merge request cannot retrieve the pipeline status

This can occur if Sidekiq doesn't pick up the changes fast enough.

#### Sidekiq

Sidekiq didn't process the CI state change fast enough. Please wait a few
seconds and the status will update automatically.

#### Bug

Merge Request pipeline statuses can't be retrieved when the following occurs:

1. A Merge Request is created
1. The Merge Request is closed
1. Changes are made in the project
1. The Merge Request is reopened

To enable the pipeline status to be properly retrieved, close and reopen the
Merge Request again.

## Tips

Here are some tips that will help you be more efficient with merge requests in
the command line.

NOTE: **Note:**
This section might move in its own document in the future.

### Copy the branch name for local checkout

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23767) in GitLab 13.4.

The merge request sidebar contains the branch reference for the source branch
used to contribute changes for this merge request.

To copy the branch reference into your clipboard, click the **Copy branch name** button
(**{copy-to-clipboard}**) in the right sidebar. You can then use it to checkout the branch locally
via command line by running `git checkout <branch-name>`.

### Checkout merge requests locally through the `head` ref

A merge request contains all the history from a repository, plus the additional
commits added to the branch associated with the merge request. Here's a few
ways to checkout a merge request locally.

Please note that you can checkout a merge request locally even if the source
project is a fork (even a private fork) of the target project.

This relies on the merge request `head` ref (`refs/merge-requests/:iid/head`)
that is available for each merge request. It allows checking out a merge
request via its ID instead of its branch.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223156) in GitLab
13.4, 14 days after a merge request gets closed or merged, the merge request
`head` ref will be deleted. This means that the merge request will not be available
for local checkout via the merge request `head` ref anymore. The merge request
can still be re-opened. Also, as long as the merge request's branch
exists, you can still check out the branch as it won't be affected.

#### Checkout locally by adding a Git alias

Add the following alias to your `~/.gitconfig`:

```plaintext
[alias]
    mr = !sh -c 'git fetch $1 merge-requests/$2/head:mr-$1-$2 && git checkout mr-$1-$2' -
```

Now you can check out a particular merge request from any repository and any
remote. For example, to check out the merge request with ID 5 as shown in GitLab
from the `origin` remote, do:

```shell
git mr origin 5
```

This will fetch the merge request into a local `mr-origin-5` branch and check
it out.

#### Checkout locally by modifying `.git/config` for a given repository

Locate the section for your GitLab remote in the `.git/config` file. It looks
like this:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

You can open the file with:

```shell
git config -e
```

Now add the following line to the above section:

```plaintext
fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

In the end, it should look like this:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
  fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

Now you can fetch all the merge requests:

```shell
git fetch origin

...
From https://gitlab.com/gitlab-org/gitlab-foss.git
 * [new ref]         refs/merge-requests/1/head -> origin/merge-requests/1
 * [new ref]         refs/merge-requests/2/head -> origin/merge-requests/2
...
```

And to check out a particular merge request:

```shell
git checkout origin/merge-requests/1
```

All the above can be done with the [`git-mr`](https://gitlab.com/glensc/git-mr) script.

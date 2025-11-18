---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Troubleshooting help for merge requests.
title: Troubleshooting merge requests
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with merge requests, you might encounter the following issues.

## Merge request cannot retrieve the pipeline status

This can occur if Sidekiq doesn't pick up the changes fast enough.

### Sidekiq

Sidekiq didn't process the CI state change fast enough. Wait a few
seconds and the status should update automatically.

### Pipeline status cannot be retrieved

Merge request pipeline statuses can't be retrieved when the following occurs:

1. A merge request is created
1. The merge request is closed
1. Changes are made in the project
1. The merge request is reopened

To enable the pipeline status to be properly retrieved, close and reopen the
merge request again.

## Rebase a merge request from the Rails console

{{< details >}}

- Tier: Free, Premium, Ultimate

{{< /details >}}

In addition to the `/rebase` [quick action](../quick_actions.md#issues-merge-requests-and-epics),
users with access to the [Rails console](../../../administration/operations/rails_console.md)
can rebase a merge request from the Rails console. Replace `<username>`,
`<namespace/project>`, and `<iid>` with appropriate values:

{{< alert type="warning" >}}

Any command that changes data directly could be damaging if not run correctly,
or under the right conditions. We highly recommend running them in a test environment
with a backup of the instance ready to be restored, just in case.

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::RebaseService.new(project: m.target_project, current_user: u).execute(m)
```

## Fix incorrect merge request status

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If a merge request remains **Open** after its changes are merged,
users with access to the [Rails console](../../../administration/operations/rails_console.md)
can correct the merge request's status. Replace `<username>`, `<namespace/project>`,
and `<iid>` with appropriate values:

{{< alert type="warning" >}}

Any command that changes data directly could be damaging if not run correctly,
or under the right conditions. We highly recommend running them in a test environment
with a backup of the instance ready to be restored, just in case.

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::PostMergeService.new(project: p, current_user: u).execute(m)
```

Running this command against a merge request with unmerged changes causes the
merge request to display an incorrect message: `merged into <branch-name>`.

## Close a merge request from the Rails console

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If closing a merge request doesn't work through the UI or API, try closing it in a
[Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

{{< alert type="warning" >}}

Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::CloseService.new(project: p, current_user: u).execute(m)
```

## Delete a merge request from the Rails console

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If deleting a merge request doesn't work through the UI or API, try deleting it in a
[Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

{{< alert type="warning" >}}

Any command that changes data directly could be damaging if not run correctly,
or under the right conditions. We highly recommend running them in a test environment
with a backup of the instance ready to be restored, just in case.

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
Issuable::DestroyService.new(container: m.project, current_user: u).execute(m)
```

## Merge request pre-receive hook failed

If a merge request times out, you might see messages that indicate a Puma worker
timeout problem:

- In the GitLab UI:

  ```plaintext
  Something went wrong during merge pre-receive hook.
  500 Internal Server Error. Try again.
  ```

- In the `gitlab-rails/api_json.log` log file:

  ```plaintext
  Rack::Timeout::RequestTimeoutException
  Request ran for longer than 60000ms
  ```

This error can happen if your merge request:

- Contains many diffs.
- Is many commits behind the target branch.
- References a Git LFS file that is locked.

Users on GitLab Self-Managed can request an administrator review server logs
to determine the cause of the error. GitLab SaaS users should
[contact Support](https://about.gitlab.com/support/#contact-support) for help.

## Cached merge request count

In a group, the sidebar displays the total count of open merge requests. This value is cached if it's
greater than 1000. The cached value is rounded to thousands (or millions) and updated every 24 hours.

## Check out merge requests locally through the `head` ref

{{< history >}}

- Deleting `head` refs 14 days after a merge request closes or merges [enabled on GitLab Self-Managed and GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130098) in GitLab 16.4.
- Deleting `head` refs 14 days after a merge request closes or merges [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/336070) in GitLab 16.6. Feature flag `merge_request_refs_cleanup` removed.

{{< /history >}}

A merge request contains all the history from a repository, plus the additional
commits added to the branch associated with the merge request. Here's a few
ways to check out a merge request locally.

You can check out a merge request locally even if the source
project is a fork (even a private fork) of the target project.

This relies on the merge request `head` ref (`refs/merge-requests/:iid/head`)
that is available for each merge request. It allows checking out a merge
request by using its ID instead of its branch.

In GitLab 16.6 and later, the merge request `head` ref is deleted 14 days after
a merge request is closed or merged. The merge request is then no longer available
for local checkout from the merge request `head` ref anymore. The merge request
can still be re-opened. If the merge request's branch
exists, you can still check out the branch, as it isn't affected.

### Check out locally using `glab`

```plaintext
glab mr checkout <merge_request_iid>
```

More information on the [GitLab terminal client](../../../editor_extensions/gitlab_cli/_index.md).

### Check out locally by adding a Git alias

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

This fetches the merge request into a local `mr-origin-5` branch and check
it out.

### Check out locally by modifying `.git/config` for a given repository

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

Now add the following line to the previous section:

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

To check out a particular merge request:

```shell
git checkout origin/merge-requests/1
```

These commands can be also be done with the [`git-mr`](https://gitlab.com/glensc/git-mr) script.

## Error: `source branch <branch_name> does not exist.` when the branch exists

This error can happen if the GitLab cache does not reflect the actual state of the
Git repository. This can happen if the Git data folder is mounted with `noexec` flag.

Prerequisites:

- You must be an administrator.

To force a cache update:

1. Open the GitLab Rails console with this command:

   ```shell
   sudo gitlab-rails console
   ```

1. In the Rails console, run this script:

   ```ruby
   # Get the project
   project = Project.find_by_full_path('affected/project/path')

   # Check if the affected branch exists in cache (it may return `false`)
   project.repository.branch_names.include?('affected_branch_name')

   # Expire the branches cache
   project.repository.expire_branches_cache

   # Check again if the affected branch exists in cache (this time it should return `true`)
   project.repository.branch_names.include?('affected_branch_name')
   ```

1. Reload the merge request.

## Approvals reset when automation approves a merge request

If you automate the creation of merge requests, or pushing to them, you might want to build automated
approvals for those merge requests. In GitLab Premium and Ultimate, by default, all approvals are removed
[when commits are added to the source branch](approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch).
To avoid this problem, add logic to your automation that ensures
[commits are processed before approving](../../../api/merge_request_approvals.md#approvals-for-automated-merge-requests) the merge request.

## Merge request `merged manually`

If a merged merge request contains a `merged manually` system note, it was either merged outside the GitLab UI, or contains commits
that were merged as part of a different merge request. For example:

- Merge request 1 is for the branch `single-fix`, and has commit `cd87d6`.
- Merge request 2 is for the branch `several-fixes`. It contains commit `cd87d6` and several others.

Merging the `several-fixes` branch merges all commits on that branch, including commit `cd87d6`.
Even though no action has been taken on the branch `single-fix`, commit `cd87d6` was merged
as part of `several-fixes`, so `single-fix` now shows as merged.

For more information, see [Multiple branches containing the same commit](../repository/branches/_index.md#multiple-branches-containing-the-same-commit).

---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Signed commits from the GitLab UI
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19185) in GitLab 15.4.
> - Displaying **Verified** badge for signed GitLab UI commits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218) in GitLab 16.3 [with a flag](../../../../administration/feature_flags.md) named `gitaly_gpg_signing`. Disabled by default.
> - Verifying the signatures using multiple keys specified in `rotated_signing_keys` option [introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163) in GitLab 16.3.
> - `gitaly_gpg_signing` feature flag [enabled by default](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876) on GitLab Self-Managed and GitLab Dedicated in GitLab 17.0.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

When you create a commit using the GitLab user interface, the commit is not pushed directly by you.
Instead, the commit is created on your behalf.

To sign these commits, GitLab uses a global key configured for the instance.
Because GitLab doesn't have access to your private key, the created commit can't be signed by using
the key associated with your account.

For example, if User A applies [suggestions](../../merge_requests/reviews/suggestions.md)
authored by User B, the commit contains the following:

```plaintext
Author: User A <a@example.com>
Committer: GitLab <noreply@gitlab.com>

Co-authored-by: User B <b@example.com>
```

## Prerequisites

Before you can use commit signing for GitLab UI commits, you must
[configure it](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits).

## Committer field of the commits

By default, when a commit is created on GitLab, the `Author` of the commit is set as the `Committer` of the commit.
To avoid confusion, when the commit is signed, the signature should belong to the `Committer` of the commit.

You should [configure](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits)
the `Committer` field to point to the instance itself.
For example, when this feature becomes enabled on GitLab.com, the `Committer` field is: `GitLab <noreply@gitlab.com>`.

GitLab provides multiple security features that rely on the `Committer` field to be set to the user who creates the commit.
For example:

- [Push rules](../push_rules.md): (`Reject unverified users` or `Commit author's email`).
- [Merge request approval prevention](../../merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).

When a commit is signed by the instance, GitLab relies on the `Author` field for those features.

## Commits created using REST API

[Commits created using the REST API](../../../../api/commits.md#create-a-commit-with-multiple-files-and-actions).
are also considered as web-based commits.
Using the REST API endpoint, you can set `author_name` and `author_email` fields of the commit,
which makes it possible to create commits on behalf of other users.

When commit signing is enabled, commits created using the REST API that have different `author_name`
and `author_email` than the user who sends the API request are rejected.

## Rebasing from UI

When signing commits made in the UI is enabled and you rebase a merge request from the UI, the commits aren't signed.

In this case, new commits aren't created.
The merge request commits are modified and added on top of the target branch, so GitLab cannot sign them.

To have rebased commits signed, a workaround is to rebase locally and push the changes to the merge
request branch.

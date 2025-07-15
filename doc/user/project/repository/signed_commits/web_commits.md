---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Signed commits from the GitLab UI
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Displaying **Verified** badge for signed GitLab UI commits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218) in GitLab 16.3 [with a flag](../../../../administration/feature_flags/_index.md) named `gitaly_gpg_signing`. Disabled by default.
- Verifying the signatures using multiple keys specified in `rotated_signing_keys` option [introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163) in GitLab 16.3.
- `gitaly_gpg_signing` feature flag [enabled by default](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876) on GitLab Self-Managed and GitLab Dedicated in GitLab 17.0.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

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

In Git, commits have both an author and a committer.
For web commits, the `Committer` field is configurable. To update this field, see
[Configure commit signing for GitLab UI commits](../../../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits).

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

## Troubleshooting

### Web commits become unsigned after rebase

Previously-signed commits in a branch become unsigned when:

- Commit signing is configured for commits created from the GitLab UI.
- The merge request is rebased from the GitLab UI.

This happens because the previous commits are modified, and added on top of the target branch. GitLab
can't sign these commits.

To work around this problem, rebase the branch locally, and push the changes back up to GitLab.

---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Internal allowed API
---

The `internal/allowed` endpoint assesses whether a user has permission to perform
certain operations on the Git repository. It performs multiple checks, such as:

- Ensuring the branch or tag name is acceptable.
- Whether or not the user has the authority to perform that action.

## Endpoint definition

The internal API endpoints are defined under
[`lib/api/internal`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/api/internal),
and the `/allowed` path is in
[`lib/api/internal/base.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb).

## Use the endpoint

`internal/allowed` is called when you:

- Push to the repository.
- Perform actions on the repository through the GitLab user interface, such as
  applying suggestions or using the GitLab IDE.

Gitaly typically calls this endpoint. It is only called internally (by other parts
of the application) rather than by external users of the API.

## Push checks

A key part of the `internal/allowed` flow is the call to
`EE::Gitlab::Checks::PushRuleCheck`, which can perform the following checks:

- `EE::Gitlab::Checks::PushRules::CommitCheck`
- `EE::Gitlab::Checks::PushRules::TagCheck`
- `EE::Gitlab::Checks::PushRules::BranchCheck`
- `EE::Gitlab::Checks::PushRules::FileSizeCheck`

## Recursion

Some of the Gitaly RPCs called by `internal/allowed` then, themselves, make calls
back to `internal/allowed`. These calls are now correlated with the original request.
Gitaly relies on the Rails application for authorization, and maintains no permissions model itself.

These calls show up in the logs differently to the initial requests. {example}

Because this endpoint can be called recursively, slow performance on this endpoint can result in an exponential performance impact. This documentation is in fact adapted from [the investigation into its performance](https://gitlab.com/gitlab-org/gitlab/-/issues/222247).

## Known performance issues

### Refs

The number of [`refs`](https://git-scm.com/book/en/v2/Git-Internals-Git-References)
on the Git repository have a notable effect on the performance of `git` commands
called upon it. Gitaly RPCs are similarly affected. Certain `git` commands scan
through all refs, causing a notable impact on the speed of those commands.

On the `internal/allowed` endpoint, the recursive nature of RPC calls mean the
ref counts have an exponential effect on performance.

#### Environment refs

[Stale environment refs](https://gitlab.com/gitlab-org/gitlab/-/issues/296625)
are a common example of excessive refs causing performance issues. Stale environment
refs can number into the tens of thousands on busy repositories, as they aren't
cleared up automatically.

#### Dangling refs

Dangling refs are created to prevent accidental deletion of objects from object pools.
Large numbers of these refs can exist, which may have potential performance implications.
For existing discussion around this issue, read
[`gitaly#1900`](https://gitlab.com/gitlab-org/gitaly/-/issues/1900). This issue
appears to have less effect than stale environment refs.

### Pool repositories

When a fork is created on GitLab, a central pool repository is created and the forks
are linked to it. This pool repository prevents duplication of data by storing
data common to other forks. However, the pool repository is not cleaned up in the
same manner as the standard repositories, and is more prone to the refs issue.

## Feature flags

### Parallel push checks

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available,
an administrator can [enable the feature flag](../../administration/feature_flags.md) named `parallel_push_checks`.
On GitLab.com, by default this feature is not available. To make it available
per project, ask GitLab.com administrator to
[enable the feature flag](../../administration/feature_flags.md) named `parallel_push_checks`.
You should not use this feature for production environments. On GitLab Dedicated, this feature is
not available.

This experimental feature flag enables the endpoint to run multiple RPCs simultaneously,
reducing the overall time taken by roughly half. This time savings is achieved through
threading, and has potential side effects at large scale. On GitLab.com, this feature flag
is enabled only for `gitlab-org/gitlab` and `gitlab-com/www-gitlab-com` projects.
Without it, those projects routinely time out requests to the endpoint. When this
feature was deployed to all of GitLab.com, some pushes failed, presumably due to
exhausting resources like database connection pools.

You should enable this feature flag only if you are experiencing timeouts, and
only enable it for that specific project.

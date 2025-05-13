---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: How protection rules work with protected branches in GitLab, especially in complex scenarios.
title: Protection rules and permissions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Protection rules control access to branches and determine what happens when multiple
rules apply to the same branch. They help you implement the right security measures for your
repository branches. These rules cover:

- Permission levels, precedence, and rule conflicts.
- Force push permissions across multiple matching rules.
- Code Owner approvals.
- Protection settings between groups and projects.

## Push and merge permissions

{{< history >}}

- Branch push permission [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118532) to require GitLab administrators to also have the **allowed** permission in GitLab 16.0.

{{< /history >}}

When a branch is protected, the default behavior enforces these restrictions on the branch:

| Action                   | Who can do it                           |
|:-------------------------|:----------------------------------------|
| Protect a branch         | At least the Maintainer role.           |
| Push to the branch       | Anyone with **Allowed** permission. (1) |
| Force push to the branch | No one.                                 |
| Delete the branch        | No one. (2)                             |

1. Users with the Developer role can create a project in a group, but might not be allowed to
   initially push to the [default branch](default.md).
1. No one can delete a protected branch using Git commands, however, users with at least Maintainer
   role can [delete a protected branch](protected.md#delete-protected-branches) from the UI or API.

### When a branch matches multiple rules

When a branch matches multiple rules, the **most permissive rule** determines the
level of protection for the branch. For example, consider these rules, which include
[wildcards](protected.md#use-wildcard-rules):

| Branch name pattern | Allowed to merge       | Allowed to push and merge |
|---------------------|------------------------|---------------------------|
| `v1.x`              | Maintainer             | Maintainer                |
| `v1.*`              | Maintainer + Developer | Maintainer                |
| `v*`                | No one                 | No one                    |

A branch named `v1.x` is a case-sensitive match for all three branch name patterns: `v1.x`, `v1.*`, and `v*`.
As the most permissive option determines the behavior, the resulting permissions for branch `v1.x` are:

- **Allowed to merge:** Of the three settings, `Maintainer + Developer` is most permissive,
  and controls branch behavior as a result. Even though the branch also matched `v1.x` and `v*`
  (which each have stricter permissions), users with the Developer role can merge into the branch.
- **Allowed to push and merge:** Of the three settings, `Maintainer` is the most permissive, and controls
  branch behavior as a result. Even though branches matching `v*` are set to `No one`, branches
  that _also_ match `v1.x` or `v1.*` receive the more permissive `Maintainer` permission.

To be certain that a rule controls the behavior of a branch,
_all_ other patterns that match must apply less or equally permissive rules.

If you want to ensure that `No one` is allowed to push to branch `v1.x`, every pattern
that matches `v1.x` must set `Allowed to push and merge` to `No one`, like this:

| Branch name pattern | Allowed to merge       | Allowed to push and merge |
|---------------------|------------------------|---------------------------|
| `v1.x`              | Maintainer             | No one                    |
| `v1.*`              | Maintainer + Developer | No one                    |
| `v*`                | No one                 | No one                    |

## Force push permissions

When a branch matches multiple rules, the **most permissive rule** determines whether
force push is allowed. For example, consider these rules, which include
[wildcards](protected.md#use-wildcard-rules):

| Branch name pattern | Allow force push |
|---------------------|------------------|
| `v1.x`              | Yes              |
| `v1.*`              | No               |
| `v*`                | No               |

A branch named `v1.x` matches all three branch name patterns: `v1.x`, `v1.*`, and `v*`.
As the most permissive option determines the behavior, the resulting permissions for branch `v1.x` are:

- **Allow force push:** Of the three settings, `Yes` is most permissive,
  and controls branch behavior as a result. Even though the branch also matched `v1.x` and `v*`
  (which each have stricter permissions), any user that can push to this branch can also force push.

## Code owner approvals

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If a branch is protected by multiple rules, code owner approval is required if any of
the applicable rules have **Required approval from code owners** enabled.

For example, consider these rules:

| Branch name pattern | Code owner approval required |
|---------------------|------------------------------|
| `v1.x`              | Yes                          |
| `v1.*`              | No                           |
| `v*`                | No                           |

A branch named `v1.x` matches all three branch name patterns: `v1.x`, `v1.*`, and `v*`.
Because at least one rule (`v1.x`) requires code owner approval, all merge requests to this branch
require approval by a Code Owner before they can be merged.

Unlike push, merge, and force push permissions (which use the most permissive rule),
code owner approval uses the most restrictive rule. If any rule requires code owner approval,
then all merge requests to matching branches require approval.

## Rules across groups and projects

Branch protection rules can be set in both groups and projects:

- Group rules apply to all projects in a group and cannot be overridden.
- Project rules apply only to that specific project.

When both group and project rules exist that match a branch:

1. Group rules always take precedence over project rules.
1. If multiple group rules match a branch, the most permissive rule applies.
1. If no group rules match but multiple project rules match, the most permissive project rule applies.

For example, if a group owner set up a rule requiring Code Owner approval for the `main` branch,
project maintainers cannot disable this requirement in the project.

## Examples

The following examples illustrate how protection rules work in practice.

### Merge permission

Assume you have these rules set up:

| Branch name pattern | Allowed to merge                          |
|---------------------|-------------------------------------------|
| `development`       | Developers + Maintainers                  |
| `dev*`              | Maintainers only                          |
| `*`                 | No one                                    |

With these rules:

- For a branch named `development`: Developers and Maintainers can merge (from `development` rule).
- For a branch named `dev-feature`: Maintainers can merge (from `dev*` rule).
- For a branch named `feature`: No one can merge (from `*` rule).

### Push permission

Assume you have these rules set up:

| Branch name pattern | Allowed to push and merge                  |
|---------------------|-------------------------------------------|
| `production`        | No one                                    |
| `prod*`             | Maintainers only                          |
| `*`                 | Developers + Maintainers                  |

With these rules:

- For a branch named `production`: No one can push (from `production` rule).
- For a branch named `prod-release`: Maintainers can push (from `prod*` rule).
- For a branch named `feature`: Developers and Maintainers can push (from `*` rule).

### Direct push permission

Assume you have these rules set up:

| Branch name pattern | Allowed to merge        | Allowed to push and merge |
|---------------------|-------------------------|---------------------------|
| `main`              | Everyone with access    | No one                    |
| `m*`                | Maintainers only        | Maintainers only          |

With these rules:

- For a branch named `main`:
  - Everyone with access can create merge requests.
  - No one can push directly (must use merge requests).
- For a branch named `maintenance`:
  - Only Maintainers can create merge requests.
  - Only Maintainers can push directly.

### Code owner approval

Assume you have these rules set up:

| Branch name pattern | Code owner approval required | Allowed to push and merge |
|---------------------|------------------------------|---------------------------|
| `release-*`         | Yes                          | Maintainers only          |
| `rel*`              | No                           | Maintainers only          |

With these rules:

- For a branch named `release-1.0`:
  - Code owner approval is required for merge requests.
  - Only Maintainers can push directly.
- For a branch named `relations-feature`:
  - Code owner approval is not required.
  - Only Maintainers can push directly.

## Related topics

- [Protected branches](protected.md)
- [Protected branches API](../../../../api/protected_branches.md)
- [Branch rules](branch_rules.md)
- [Code Owners](../../codeowners/_index.md#code-owners-and-protected-branches)

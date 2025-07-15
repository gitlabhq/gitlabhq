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
rules apply to the same branch.
They help you implement the right security measures for your
repository branches. These rules cover:

- Permission levels, precedence, and rule conflicts.
- Force push permissions across multiple matching rules.
- Code Owner approvals.
- Protection settings between groups and projects.

## Rule behaviors

When a branch matches multiple protection rules, these behaviors apply:

- Group rules apply to all projects in a group and cannot be modified from project settings.
  For more information, see [Rules across groups and projects](#rules-across-groups-and-projects).
- When a branch matches multiple rules, the most permissive rule applies. However,
  [code owner approval](#code-owner-approval) uses the most restrictive rule.
- Exact branch names like `main` do not override wildcard patterns like `m*`.

## Push and merge permissions

{{< history >}}

- Branch push permission [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118532) to require GitLab administrators to also have the **Allowed** permission in GitLab 16.0.

{{< /history >}}

When a branch is protected, the default behavior enforces these restrictions:

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

## Force push permissions

Force push permissions follow the same most permissive rule applies logic. For example, consider
these rules, which include [wildcards](protected.md#use-wildcard-rules):

| Branch name pattern | Allow force push |
|---------------------|------------------|
| `v1.x`              | Yes              |
| `v1.*`              | No               |
| `v*`                | No               |

A branch named `v1.x` matches all three branch name patterns: `v1.x`, `v1.*`, and `v*`.
As the most permissive option determines the behavior, the resulting permissions for branch `v1.x` are:

- **Allow force push**: Of the three settings, `Yes` is most permissive,
  and controls branch behavior as a result. Even though the branch also matched `v1.x` and `v*`
  (which each have stricter permissions), any user that can push to this branch can also force push.

## Code owner approval

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Unlike push and merge permissions, and force push permissions, code owner approval uses the most
restrictive rule. If a branch is protected by multiple rules, code owner approval is required if any of
the applicable rules have **Required approval from code owners** enabled. For more information, see
[require code owner approval](protected.md#require-code-owner-approval).

For example, consider these rules:

| Branch name pattern | Code owner approval required |
|---------------------|------------------------------|
| `v1.x`              | Yes                          |
| `v1.*`              | No                           |
| `v*`                | No                           |

A branch named `v1.x` matches all three branch name patterns: `v1.x`, `v1.*`, and `v*`.
Because at least one rule (`v1.x`) requires code owner approval, all merge requests to this branch
require approval by a Code Owner before they can be merged.

## Rules across groups and projects

Branch protection rules can be set in both groups and projects:

- Group rules apply to all projects in a group and cannot be modified from project settings.
- Project rules apply only to that specific project.

When both group and project rules exist that match a branch:

- All matching rules are evaluated together.
- The most permissive rule applies for most settings.
- For [code owner approval](#code-owner-approval), the most restrictive rule applies.

You cannot edit or remove group rules from project settings, but you can add
additional project rules for the same branch. For example:

- A group rule for `main` disallows force push.
- You can add a project rule for `main` that allows force push.
- Both rules exist, but the more permissive project rule takes effect for force push settings.

## Multiple branch rule examples

The following examples demonstrate how different rules can affect branch protection.

### Allowed to merge

An example of how an exact branch name does not override a more permissive wildcard pattern.

| Branch pattern | Allowed to merge          |
|----------------|---------------------------|
| `release-v1.0` | No one                    |
| `release*`     | Maintainer                |
| `*`            | Developer + Maintainer    |

- Branch `release-v1.0` matches all three patterns. The most permissive rule applies:
  - **Allowed to merge**: Developer + Maintainer can merge (from `*` rule).

### Allowed to push and merge

An example of how multiple branch rules apply to different branch names.

| Branch pattern | Allowed to merge       | Allowed to push and merge |
|----------------|------------------------|---------------------------|
| `main`         | Maintainer             | No one                    |
| `m*`           | Developer + Maintainer | Developer + Maintainer    |
| `r*`           | No one                 | No one                    |

- Branch `main` matches two patterns (`main` and `m*`). The most permissive rule applies:
  - **Allowed to merge**: Developer + Maintainer can merge (from `m*` rule).
  - **Allowed to push and merge**: Developer + Maintainer can push (from `m*` rule).
- Branch `release-v1.0` matches one pattern:
  - **Allowed to merge**: No one can merge (from `r*` rule).
  - **Allowed to push and merge**: No one can push (from `r*` rule).

### Code owner requirements

Code owner approval works differently from other branch protection settings. When multiple rules
match, the most restrictive rule applies instead of the most permissive.

| Branch pattern | Code owner approval required |
|----------------|------------------------------|
| `production`   | Yes                          |
| `prod*`        | No                           |
| `p*`           | Yes                          |

- Branch `production` matches all three patterns. The most restrictive rule applies:
  - **Code owner approval**: Required (from `production` and `p*` rules).
- Branch `product-v1.0` matches two patterns (`prod*` and `p*`). The most restrictive rule applies:
  - **Code owner approval**: Required (from `p*` rule).

### Ensure strict protection

To ensure strict protection that cannot be overridden by more permissive patterns, configure all
matching patterns with the same restrictive settings.

| Branch pattern | Allowed to merge | Allowed to push and merge |
|----------------|------------------|---------------------------|
| `production`   | Maintainer       | No one                    |
| `prod*`        | Maintainer       | No one                    |
| `p*`           | Maintainer       | No one                    |
| `*`            | Maintainer       | No one                    |

Now branch `production` has restrictive push permissions because all matching rules specify
**No one** can push.

## Related topics

- [Protected branches](protected.md)
- [Protected branches API](../../../../api/protected_branches.md)
- [Branch rules](branch_rules.md)
- [Code Owners](../../codeowners/_index.md#code-owners-and-protected-branches)

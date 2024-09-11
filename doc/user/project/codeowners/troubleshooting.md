---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use Code Owners to define experts for your code base, and set review requirements based on file type or location."
---

# Troubleshooting Code Owners

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When working with Code Owners, you might encounter the following issues.

For more information about how the Code Owners feature handles errors, see the
[Code Owners reference](reference.md).

## Approvals shown as optional

A Code Owner approval rule is optional if any of these conditions are true:

- The user or group is not a member of the project.
  Code Owners [cannot inherit members from parent groups](https://gitlab.com/gitlab-org/gitlab/-/issues/288851/).
- [Code Owner approval on a protected branch](../repository/branches/protected.md#require-code-owner-approval-on-a-protected-branch) has not been set up.
- The section is [marked as optional](index.md#make-a-code-owners-section-optional).
- No eligible code owners are available to approve the merge request due to conflicts
  with other [merge request approval settings](../merge_requests/approvals/settings.md).

## Approvals do not show

The [`CODEOWNERS` file](index.md#codeowners-file) must be present in the target branch before the merge request is created.

Code Owner approval rules only update when the merge request is created.
If you update the `CODEOWNERS` file, close the merge request and create a new one.

## User not shown as possible approver

A user might not show as an approver on the Code Owner merge request approval rules
if any of these conditions are true:

- A rule prevents the specific user from approving the merge request.
  Check the project [merge request approval](../merge_requests/approvals/settings.md#edit-merge-request-approval-settings) settings.
- A Code Owner group has a visibility of **private**, and the current user is not a
  member of the Code Owner group.
- Current user is an external user who does not have permission to the internal Code Owner group.

## Approval rule is invalid

You might get an error that states:

```plaintext
Approval rule is invalid.
GitLab has approved this rule automatically to unblock the merge request.
```

This issue occurs when an approval rule uses a Code Owner that is not a direct member of the project.

The workaround is to check that the group or user has been invited to the project.

## User or group not shown when viewing Code Owners for a directory

Code Owners might not show the intended user or group based on your configured rules when viewing a directory,
but correctly show the Code Owners for files beneath the directory.

For example:

```plaintext
* @dev-team
docs/ @tech-writer-team
```

All files beneath the `docs/` directory show `@tech-writer-team` as Code Owners, but the directory itself shows `@dev-team`.

This behavior occurs when viewing a directory because the [syntax rule](../../project/codeowners/reference.md#directory-paths)
applies to all files beneath the directory, which does not include the directory itself. To resolve this, update the `CODEOWNERS` file to include the
directory specifically along with all files beneath the directory. For example:

```plaintext
* @dev-team
docs @tech-writer-team
docs/ @tech-writer-team
```

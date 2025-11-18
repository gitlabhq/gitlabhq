---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use Code Owners to define experts for your codebase, and set review requirements based on file type or location.
title: Troubleshooting Code Owners
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with Code Owners, you might encounter the following issues.

For more information about how the Code Owners feature handles errors, see [Error handling](advanced.md#error-handling).

## Validate your CODEOWNERS file

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15598) in GitLab 17.11 [with a flag](../../../administration/feature_flags/_index.md) named `accessible_code_owners_validation`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/524437) in GitLab 18.1.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/549626) in GitLab 18.2. Feature flag `accessible_code_owners_validation` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

When viewing a [`CODEOWNERS` file](_index.md#codeowners-file), GitLab runs
validations to help you find syntax and permission issues. If no syntax issues
are found, GitLab:

- Does not run more validators against the file.
- Runs more permissions validations against the first 200 unique user and group references found in the file.

How this works:

1. Find all references that can access the project. If a user or group reference is
   added, but does not have project access, show an error.
1. For each valid user reference, check that the user has permission to approve
   merge requests in the project. If the user does not have that permission, show an error.
1. For each valid group reference, check that the maximum role value is Developer or higher.
   For each group reference that has a value lower than Developer, show an error.
1. For each valid group reference, check that they group contains at least one user with
   permission to approve merge requests. For any group reference containing zero users with
   permission to approve merge requests, show an error.

## Approvals do not show

The [`CODEOWNERS` file](_index.md#codeowners-file) must be present in the target branch before the
merge request is created.

Code Owner approval rules only update when the merge request is created.
If you update the `CODEOWNERS` file, close the merge request and create a new one.

## Approvals shown as optional

A Code Owner approval rule is optional if any of these conditions are true:

- The user or group is not a member of the project.
  Code Owners [cannot inherit members from parent groups](https://gitlab.com/gitlab-org/gitlab/-/issues/288851/).
- The user or group is [malformed or inaccessible](advanced.md#malformed-owners).
- [Code Owner approval on a protected branch](../repository/branches/protected.md#require-code-owner-approval) has not been set up.
- The section is [marked as optional](reference.md#optional-sections).
- No eligible code owners are available to approve the merge request due to conflicts
  with other [merge request approval settings](../merge_requests/approvals/settings.md).

## User not shown as possible approver

A user might not show as an approver on the Code Owner merge request approval rules
if any of these conditions are true:

- A rule prevents the specific user from approving the merge request.
  Check the project [merge request approval](../merge_requests/approvals/settings.md#edit-merge-request-approval-settings) settings.
- A Code Owner group has a visibility of private, and the current user is not a
  member of the Code Owner group.
- The specific username is spelled incorrectly or
  [malformed in the `CODEOWNERS` file](advanced.md#malformed-owners).
- Current user is an external user who does not have permission to the internal Code Owner group.

## Approval rule is invalid

You might get an error that states:

```plaintext
Approval rule is invalid.
GitLab has approved this rule automatically to unblock the merge request.
```

This issue occurs when an approval rule uses a Code Owner that is not a direct member of the project.

The workaround is to check that the group or user has been invited to the project.

## `CODEOWNERS` not updated when user or group names change

When a user or group change their names, the `CODEOWNERS` isn't automatically updated with the new names.
To enter the new names, you must edit the file.

Organizations using SAML SSO can [set usernames](../../../integration/saml.md#set-a-username) to
prevent users from changing their usernames.

## Incompatibility with Global group memberships locks

The Code Owners feature requires direct group memberships to projects.
When Global group memberships locks are enabled, they prevent groups from being invited as direct members to projects.
This creates an incompatibility between the two features.

When the Global [SAML](../../group/saml_sso/group_sync.md#global-saml-group-memberships-lock) or [LDAP](../../../administration/auth/ldap/ldap_synchronization.md#global-ldap-group-memberships-lock) group memberships lock is enabled, you can't use groups or subgroups as Code Owners.

If you enabled either Global SAML or LDAP group memberships lock, you have the following options:

- Use individual users as Code Owners instead of groups.
- If using group-based Code Owners is a higher priority, disable the Global group memberships lock.

Support for inherited group members is proposed in [issue 288851](https://gitlab.com/gitlab-org/gitlab/-/issues/288851).

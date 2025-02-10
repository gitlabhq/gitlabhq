---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to create a merge request for a confidential issue without leaking information publicly."
title: Merge requests for confidential issues
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Merge requests in a public repository are also public, even when you create a
merge request for a [confidential issue](../issues/confidential_issues.md).
To avoid leaking confidential information when working on a confidential issue,
create your merge request from a private fork in the same namespace.

Roles are inherited from parent groups. If you create your private fork in the
same namespace (same group or subgroup) as the original (public) repository,
developers receive the same permissions in your fork. This inheritance ensures:

- Developer users have the needed permissions to view confidential issues and resolve them.
- You do not need grant individual users access to your fork.

To learn more, see [Patch release runbook for GitLab engineers: Preparing security fixes for a patch release](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md).

## Create a confidential merge request

Branches are public by default. To protect the confidentiality of your work, you
must create your branches and merge requests in the same namespace, but downstream
in a private fork. If you create your private fork in the same namespace as the
public repository, your fork inherits the permissions of the upstream public repository.
Users with the Developer role for the upstream public repository inherit those upstream
permissions in your downstream private fork without action by you. These users can
immediately push code to branches in your private fork to help fix the confidential issue.

WARNING:
Your private fork might expose confidential information if you create it in a different
namespace than the upstream repository. The two namespaces might not contain the same users.

Prerequisites:

- You have the Owner or Maintainer role for the public repository, as you need one
  of these roles to [create a subgroup](../../group/subgroups/_index.md).
- You have [forked](../repository/forking_workflow.md) the public repository.
- Your fork has a **Visibility level** of _Private_.

To create a confidential merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues** and find the issue you want to create a merge request for.
1. Scroll below the issue description, and select **Create confidential merge request**.
1. Select the item that meets your needs:
   - *To create both a branch and a merge request,* select
     **Create confidential merge request and branch**. Your merge request will
     target the default branch of your fork, *not* the default branch of the
     public upstream project.
   - *To create only a branch,* select **Create branch**.
1. Select a **Project** to use. These projects have merge requests enabled, and
   you have the Developer role (or greater) in them.
1. Provide a **Branch name**, and select a **Source (branch or tag)**. GitLab
   checks whether these branches are available in your private fork, because both
   branches must be available in your selected fork.
1. Select **Create**.

This merge request targets your private fork, not the public upstream project.
Your branch, merge requests, and commits remain in your private fork. This prevents
prematurely revealing confidential information.

Open a merge request
[from your fork to the upstream repository](../repository/forking_workflow.md#merge-changes-back-upstream) when:

- You believe the problem is resolved in your private fork.
- You are ready to make the confidential commits public.

## Related topics

- [Confidential issues](../issues/confidential_issues.md)
- [Make an epic confidential](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [Add an internal note](../../discussions/_index.md#add-an-internal-note)
- [Security practices for confidential merge requests](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md#security-releases-critical-non-critical-as-a-developer) at GitLab

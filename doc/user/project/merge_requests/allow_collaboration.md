---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "When you fork a merge request, you can set whether or not members of the upstream repository can contribute to your fork."
title: Collaborate on merge requests across forks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you open a merge request from your [fork](../repository/forking_workflow.md), you can allow upstream
members to collaborate with you on your branch.
When you enable this option, members who have permission to merge to the target branch get
permission to write to the merge request's source branch.

The members of the upstream project can then make small fixes or rebase branches
before merging.

This feature is available for merge requests across forked projects that are
[publicly accessible](../../public_access.md).

## Allow commits from upstream members

As the author of a merge request, you can allow commit edits from
upstream members of the project you're contributing to:

1. While creating or editing a merge request, scroll to **Contribution** and
   select the **Allow commits from members who can merge to the target branch**
   checkbox.
1. Finish creating your merge request.

After you create the merge request, the merge request widget displays the message
**Members who can merge are allowed to add commits**. Upstream members can then:

- Commit directly to your branch.
- Retry the pipelines and jobs of the merge request.

## Prevent commits from upstream members

As the author of a merge request, you can prevent commit edits from
upstream members of the project you're contributing to:

1. While creating or editing a merge request, scroll to **Contribution** and
   clear the **Allow commits from members who can merge to the target branch**
   checkbox.
1. Finish creating your merge request.

## Push to the fork as the upstream member

You can push directly to the branch of the forked repository if:

- The author of the merge request enabled contributions from upstream members.
- You have at least the Developer role for the upstream project.

To push changes, or add a commit, to the branch of a fork, you can use command line Git.
For more information, see [use Git to push to a fork as an upstream member](../../../topics/git/forks.md#push-to-a-fork-as-an-upstream-member).

## Troubleshooting

### Pipeline status unavailable from MR page of forked project

When a user forks a project, the permissions of the forked copy are not copied
from the original project. The creator of the fork must grant permissions to the
forked copy before members in the upstream project can view or merge the changes
in the merge request.

To see the pipeline status from the merge request page of a forked project
going back to the original project:

1. [Create a group](../../group/_index.md#create-a-group) containing all the upstream members.
1. On the left sidebar, select **Search or go to** and find the forked project.
1. Go to the **Manage > Members** page in the forked project and invite the newly-created
   group to the forked project.

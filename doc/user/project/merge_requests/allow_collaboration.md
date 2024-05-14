---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "When you fork a merge request, you can set whether or not members of the upstream repository can contribute to your fork."
---

# Collaborate on merge requests across forks

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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

- The author of the merge request has enabled contributions from upstream
  members.
- You have at least the Developer role in the
  upstream project.

In the following example:

- The forked repository URL is `git@gitlab.com:contributor/forked-project.git`.
- The branch of the merge request is `fork-branch`.

To change or add a commit to the contributor's merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request.
1. In the upper-right corner, select **Code**, then select **Check out branch**.
1. On the dialog, select **Copy** (**{copy-to-clipboard}**).
1. In your terminal, go to your cloned version of the repository, and
   paste the commands. For example:

   ```shell
   git fetch "git@gitlab.com:contributor/forked-project.git" 'fork-branch'
   git checkout -b 'contributor/fork-branch' FETCH_HEAD
   ```

   Those commands fetch the branch from the forked project, and create a local branch
   for you to work on.

1. Make your changes to your local copy of the branch, and then commit them.
1. Push your local changes to the forked project. The following command pushes
   the local branch `contributor/fork-branch` to the `fork-branch` branch of
   the `git@gitlab.com:contributor/forked-project.git` repository:

   ```shell
   git push git@gitlab.com:contributor/forked-project.git contributor/fork-branch:fork-branch
   ```

   If you have amended or squashed any commits, you must force push. Proceed
   with caution as this command rewrites the commit history:

   ```shell
   git push --force git@gitlab.com:contributor/forked-project.git contributor/fork-branch:fork-branch
   ```

   Note the colon (`:`) between the two branches. The general scheme is:

   ```shell
   git push <forked_repository_git_url> <local_branch>:<fork_branch>
   ```

## Troubleshooting

### Pipeline status unavailable from MR page of forked project

When a user forks a project, the permissions of the forked copy are not copied
from the original project. The creator of the fork must grant permissions to the
forked copy before members in the upstream project can view or merge the changes
in the merge request.

To see the pipeline status from the merge request page of a forked project
going back to the original project:

1. [Create a group](../../group/index.md#create-a-group) containing all the upstream members.
1. On the left sidebar, select **Search or go to** and find the forked project.
1. Go to the **Manage > Members** page in the forked project and invite the newly-created
   group to the forked project.

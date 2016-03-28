# How to create a branch

A branch is an independent line of development.

New commits are recorded in the history for the current branch, which results in taking the source from someone’s repository (the place where the history of your work is stored) at certain point in time, and apply your own changes to it in the history of the project.

To add changes to your GitLab project, you should create a branch. You can do it in your [shell](basic-git-commands.md) or in GitLab.

To create a new branch in GitLab, sign in and then select a project on the right side of your screen:

![Select a project](basicsimages/select_project.png)

Click on "commits" on the menu on the left side of your screen:

![Commits](basicsimages/commits.png)

Click on the "branches" tab:

![Branches](basicsimages/branches.png)

Click on the "new branch" button on the right side of the screen:

![New branch](basicsimages/newbranch.png)

Fill out the information required:

1. Add a name for your new branch (you can't add spaces, so you can use hyphens or underscores)

1. On the "create from" space, add the the name of the branch you want to branch off from

1. Click on the button "create branch"

![Branch info](basicsimages/branch_info.png)

## From an issue
When an issue should be resolved one could also create a branch on the issue page. A button is displayed after the description unless there is already a branch or a referenced merge request.

![New Branch Button](basicsimages/new_branch_button.png)

The branch created diverges from the default branch of the project, usually `master`. The branch name will be based on the title of the issue and as suffix its ID. Thus the example screenshot above will yield a branch named `et-cum-et-sed-expedita-repellat-consequatur-ut-assumenda-numquam-rerum-2`.
After the branch is created the user can edit files in the repository to fix the issue. When a merge request is created the
description field will display `Closes #2` to use the issue closing pattern. This will close the issue once the merge request is merged.

### Note:

You will be able to find and select the name of your branch in the white box next to a project's name:

![Branch name](basicsimages/branch_name.png)

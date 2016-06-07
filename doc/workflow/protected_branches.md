# Protected branches

Permissions in GitLab are fundamentally defined around the idea of having read or write permission to the repository and branches.

To prevent people from messing with history or pushing code without review, we've created protected branches.

A protected branch does three simple things:

* it prevents pushes from everybody except users with Master permission
* it prevents anyone from force pushing to the branch
* it prevents anyone from deleting the branch

You can make any branch a protected branch. GitLab makes the master branch a protected branch by default.

To protect a branch, user needs to have at least a Master permission level, see [permissions document](../permissions/permissions.md).

![protected branches page](protected_branches/protected_branches1.png)

Navigate to project settings page and select `protected branches`. From the `Branch` dropdown menu select the branch you want to protect.

Some workflows, like [GitLab workflow](gitlab_flow.md), require all users with write access to submit a Merge request in order to get the code into a protected branch.

Since Masters and Owners can already push to protected branches, that means Developers cannot push to protected branch and need to submit a Merge request.

However, there are workflows where that is not needed and only protecting from force pushes and branch removal is useful.

For those workflows, you can allow everyone with write access to push to a protected branch by selecting `Developers can push` check box.

On already protected branches you can also allow developers to push to the repository by selecting the `Developers can push` check box.

![Developers can push](protected_branches/protected_branches2.png)

## Automatically-protect new branches that match a regex pattern

Some workflows, like [GitLab workflow](gitlab_flow.md#release-branches-with-gitlab-flow),
requires that new branches (e.g. "release" branches) are created on a regular
basis. Most of the time, these branches are created by automated scripts.
Since these branches must be protected and follow a known pattern, they can be
automatically protected as soon as they are pushed to GitLab.

To enable the auto-protection of branches, navigate to the project settings pages,
and enter the regex pattern that branches should match in the `Auto-protected
branch pattern` text field. You can also allow everyone with write access to push
to a new auto-protected branch by selecting the `Developers can push to
auto-protected branches` check box.

![Auto-protected branches](protected_branches/protected_branches3.png)

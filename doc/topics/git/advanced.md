---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Introduction to Git rebase and force push, methods to resolve merge conflicts through the command line."
title: Advanced Git operations
---

Advanced Git operations help you perform tasks to maintain and manage your code.
They are more complex actions that go beyond [basic Git operations](basics.md).
These operations enable you to:

- Rewrite commit history.
- Revert and undo changes.
- Manage remote repository connections.

They provide you with the following benefits:

- Code quality: Maintain a clean, linear project history.
- Problem solving: Provide tools to fix mistakes or adjust your repository's state.
- Workflow optimization: Streamline complex development processes.
- Collaboration: Facilitate smoother teamwork in large or complex projects.

To use Git operations effectively, it's important to understand key concepts such as
repositories, branches, commits, and merge requests.
For more information, see [Get started learning Git](get_started.md).

## Best practices

When you use advanced Git operations, you should:

- Create a backup or work on a [separate branch](branch.md).
- Communicate with your team before when you use operations that affect shared branch history.
- Use descriptive [commit messages](../../tutorials/update_commit_messages/_index.md)
  when you rewrite history.
- Update your knowledge of Git to stay current with best practices and new features.
  For more information, see the [Git documentation](https://git-scm.com/docs).
- Practice advanced operations in a test repository.

## Rebase and resolve conflicts

The `git rebase` command updates your branch with the contents of another branch.
It confirms that changes in your branch don't conflict with changes in the target branch.
If you have a [merge conflict](../../user/project/merge_requests/conflicts.md),
you can rebase to fix it.

For more information, see [Rebase to address merge conflicts](git_rebase.md).

## Cherry-pick changes

The `git cherry-pick` command applies specific commits from one branch to another.
Use it to:

- Backport bug fixes from the default branch to previous release branches.
- Copy changes from a fork to the upstream repository.
- Apply specific changes without merging entire branches.

For more information, see [Cherry-pick changes with Git](cherry_pick.md).

## Revert and undo changes

The following Git commands help you to revert and undo changes:

- `git revert`: Creates a new commit that undoes the changes made in a previous commit.
  This helps you to undo a mistake or a change that you no longer need.
- `git reset`: Resets and undoes changes that are not yet committed.
- `git restore`: Restores changes that are lost or deleted.

For more information, see [Revert changes](undo.md).

## Reduce repository size

The size of a Git repository can impact performance and storage costs.
It can differ slightly from one instance to another due to compression, housekeeping, and other factors.
For more information about repository size, see [Repository size](../../user/project/repository/repository_size.md)

You can use Git to purge files from your repository's history and reduce its size. For more information, see [Reduce repository size](repository.md).

## File management

You can use Git to manage files in your repository. It helps you track changes, collaborate with others, and manage large files. The following options are available:

- `git log`: View changes to files in your repository.
- `git blame`: Identify who last modified a line of code in a file.
- `git lfs`: Manages, track, and lock files in your repository.

<!-- Include when the relevant MR is merged.

For more information, see [File management](file_management.md).

-->

## Update Git remote URLs

The `git remote set-url` command updates the URL of the remote repository.
Use this if:

- You imported an existing project from another Git repository host.
- Your organization moved your projects to a new GitLab instance with a new domain name.
- The project was renamed to a new path in the same GitLab instance.

For more information, see [Update Git remote URLs](../../tutorials/update_git_remote_url/_index.md).

## Related topics

- [Getting started](get_started.md)
- [Basic Git operations](basics.md)
- [Common Git commands](commands.md)

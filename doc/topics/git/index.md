---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: index
---

# Git **(FREE)**

Git is a [free and open source](https://git-scm.com/about/free-and-open-source)
distributed version control system designed to handle everything from small to
large projects with speed and efficiency.

[GitLab](https://about.gitlab.com) is a Git-based fully integrated platform for
software development. Besides Git's functionalities, GitLab has a lot of
powerful [features](https://about.gitlab.com/features/) to enhance your
[workflow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/).

We've gathered some resources to help you to get the best from Git with GitLab.

More information is also available on the [Git website](https://git-scm.com).

## Getting started

The following resources can help you get started with Git:

- [Git-ing started with Git](https://www.youtube.com/watch?v=Ce5nz5n41z4),
  a video introduction to Git.
- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
- [Git on the Server - GitLab](https://git-scm.com/book/en/v2/Git-on-the-Server-GitLab)
- [How to install Git](how_to_install_git/index.md)
- [Git terminology](../../gitlab-basics/start-using-git.md#git-terminology)
- [Start using Git on the command line](../../gitlab-basics/start-using-git.md)
- [Edit files through the command line](../../gitlab-basics/command-line-commands.md)
- [GitLab Git Cheat Sheet (download)](https://about.gitlab.com/images/press/git-cheat-sheet.pdf)
- Commits:
  - [Revert a commit](../../user/project/merge_requests/revert_changes.md#reverting-a-commit)
  - [Cherry-picking a commit](../../user/project/merge_requests/cherry_pick_changes.md#cherry-picking-a-commit)
  - [Squashing commits](../gitlab_flow.md#squashing-commits-with-rebase)
  - [Squash-and-merge](../../user/project/merge_requests/squash_and_merge.md)
  - [Signing commits](../../user/project/repository/gpg_signed_commits/index.md)
- [Git stash](stash.md)
- [Git file blame](../../user/project/repository/git_blame.md)
- [Git file history](../../user/project/repository/git_history.md)
- [Git tags](tags.md)

### Concepts

The following are resources on version control concepts:

- [Why Git is Worth the Learning Curve](https://about.gitlab.com/blog/2017/05/17/learning-curve-is-the-biggest-challenge-developers-face-with-git/)
- [The future of SaaS hosted Git repository pricing](https://about.gitlab.com/blog/2016/05/11/git-repository-pricing/)
- [Git website on version control](https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control)
- [GitLab University presentation about Version Control](https://docs.google.com/presentation/d/16sX7hUrCZyOFbpvnrAFrg6tVO5_yT98IgdAqOmXwBho/edit?usp=sharing)

### Work with Git on the command line

You can do many Git tasks from the command line:

- [Bisect](bisect.md).
- [Cherry pick](cherry_picking.md).
- [Feature branching](feature_branching.md).
- [Getting started with Git](getting_started.md).
- [Git add](git_add.md).
- [Git log](git_log.md).
- [Git stash](stash.md).
- [Merge conflicts](merge_conflicts.md).
- [Rollback commits](rollback_commits.md).
- [Subtree](subtree.md).
- [Unstage](unstage.md).

## Git tips

The following resources may help you become more efficient at using Git:

- [Useful Git commands](useful_git_commands.md) collected by the GitLab support team.
- [Git Tips & Tricks](https://about.gitlab.com/blog/2016/12/08/git-tips-and-tricks/)
- [Eight Tips to help you work better with Git](https://about.gitlab.com/blog/2015/02/19/8-tips-to-help-you-work-better-with-git/)

## Troubleshooting Git

If you have problems with Git, the following may help:

- [Numerous _undo_ possibilities in Git](numerous_undo_possibilities_in_git/index.md)
- Learn a few [Git troubleshooting](troubleshooting_git.md) techniques

## Branching strategies

- [Feature branch workflow](../../gitlab-basics/feature_branch_workflow.md)
- [Develop on a feature branch](feature_branch_development.md)
- [GitLab Flow](../gitlab_flow.md)
- [Git Branching - Branches in a Nutshell](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
- [Git Branching - Branching Workflows](https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows)

## Advanced use

The following are advanced topics for those who want to get the most out of Git:

- [Introduction to Git rebase, force-push, and merge conflicts](git_rebase.md)
- [Server Hooks](../../administration/server_hooks.md)
- [Git Attributes](../../user/project/git_attributes.md)
- Git Submodules: [Using Git submodules with GitLab CI](../../ci/git_submodules.md)
- [Partial Clone](partial_clone.md)

## API

[Gitignore templates](../../api/templates/gitignores.md) API allow for
Git-related queries from GitLab.

## Git Large File Storage (LFS)

The following relate to Git Large File Storage:

- [Getting Started with Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- [Migrate an existing Git repository with Git LFS](lfs/migrate_to_git_lfs.md)
- [Removing objects from LFS](lfs/index.md#removing-objects-from-lfs)
- [GitLab Git LFS user documentation](lfs/index.md)
- [GitLab Git LFS administrator documentation](../../administration/lfs/index.md)
- [Towards a production quality open source Git LFS server](https://about.gitlab.com/blog/2015/08/13/towards-a-production-quality-open-source-git-lfs-server/)

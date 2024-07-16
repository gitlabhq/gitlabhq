---
stage: Create
group: Source Code
description: Common commands and workflows.
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Learn Git

Git is a [free and open source](https://git-scm.com/about/free-and-open-source)
distributed version control system. It handles projects of all sizes quickly and
efficiently, while providing support for rolling back changes when needed.

GitLab is built on top of (and with) Git, and provides you a Git-based, fully-integrated
platform for software development. GitLab adds many powerful
[features](https://about.gitlab.com/features/) on top of Git to enhance your workflow.

These resources can help you to get the best from using Git with GitLab.

## Learn about Git

New to Git? These resources can help you understand basic Git concepts before
you dive in:

- [Git concepts](get_started.md)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  GitLab workflow video tutorial: [GitLab source code management walkthrough](https://www.youtube.com/watch?v=wTQ3aXJswtM)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  Git basics video tutorial: [Git-ing started with Git](https://www.youtube.com/watch?v=Ce5nz5n41z4)
- PDF download: [GitLab Git Cheat Sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf)

The official Git documentation also offers information on
[Git basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics).

## Begin using Git

After you learn how Git works, you're ready to try it out. These resources are
appropriate for when you're ready to start learning Git by doing:

- [How to install Git](how_to_install_git/index.md)
- Tutorial: [Make your first Git commit](../../tutorials/make_first_git_commit/index.md)
- Tutorial: [Update Git commit messages](../../tutorials/update_commit_messages/index.md)
- The [GitLab CLI](https://gitlab.com/gitlab-org/cli/)

A typical Git user encounters these concepts soon after starting to use Git:

- [`git add`](../../gitlab-basics/add-file.md) to start tracking files with Git.
- [Tags](../../user/project/repository/tags/index.md) and
  [branches](../../user/project/repository/branches/index.md).
- [How to undo changes](undo.md), including `git reset`.
- View a chronological list of changes to a file with
  [Git history](../../user/project/repository/files/git_history.md).
- View a line-by-line editing history of a file with
  [`git blame`](../../user/project/repository/files/git_blame.md).
- [Sign commits](../../user/project/repository/signed_commits/gpg.md)
  for increased accountability and trust.

## Learn more complex commands

When you're comfortable with basic Git commands, you're ready to dive into the
more complex features of Git. These commands aren't required when creating
straightforward changes. When you begin managing multiple branches or need more complex
change management, you're ready for these features:

- To stop tracking changes to a file, because you don't want to commit them,
  [unstage the changes](undo.md).
- [Stash your changes](../../gitlab-basics/add-file.md) when your current work isn't ready to create a commit locally,
  but you need to switch branches to work on something else.
- If you create many small commits locally, you can use
  [squash and merge](../../user/project/merge_requests/squash_and_merge.md)
  to combine them into fewer commits before pushing them.
- [Cherry-pick](../../user/project/merge_requests/cherry_pick_changes.md) the contents
  of a commit from one branch to another.
- [Revert an existing commit](../../user/project/merge_requests/revert_changes.md#revert-a-commit)
  if it contains changes you no longer want.

## Learn branching and workflow strategies

When you're comfortable with the creation and handling of individual branches,
you're ready to learn about Git workflows and branching strategies:

- [Feature branch workflow](../../gitlab-basics/feature_branch_workflow.md)
- [Introduction to Git rebase, force-push, and merge conflicts](git_rebase.md)
- [GitLab Flow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/)
  - [GitLab Flow best practices](https://about.gitlab.com/topics/version-control/what-are-gitlab-flow-best-practices/)
- From the official Git documentation:
  - [Git Branching - Branches in a Nutshell](https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell)
  - [Git Branching - Branching Workflows](https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows)

## Learn advanced topics in Git management

Git and GitLab, combined together, provide advanced features for repository management:

- Enforce commit policies and run tasks with [Git server hooks](../../administration/server_hooks.md).
- Define which file types to treat as binary, and set the languages to use for
  syntax highlighting with [the `.gitattributes` file](../../user/project/git_attributes.md).
- To keep a Git repository as a subdirectory in another repository,
  [use Git submodules with GitLab CI](../../ci/git_submodules.md).
- When working with extremely large repositories, you can use a [partial clone](partial_clone.md)
  of a repository instead of a complete clone.
- GitLab APIs for [`.gitignore` files](../../api/templates/gitignores.md),
  [commits](../../api/commits.md), [tags](../../api/tags.md),
  and [repositories](../../api/repositories.md).

### Git Large File Storage (LFS)

Many Git projects must manage large binary assets, such as videos and images.
Implementing [Git Large File Storage](https://git-lfs.com) can help manage these assets while keeping
your repository small:

- [User documentation](lfs/index.md) for Git LFS at GitLab
- [Administrator documentation](../../administration/lfs/index.md) for Git LFS at GitLab
- Blog post: [Getting Started with Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- [Migrate an existing Git repository](lfs/index.md#migrate-an-existing-repository-to-git-lfs) to Git LFS
- [Stop tracking a file](lfs/index.md#stop-tracking-a-file-with-git-lfs) with Git LFS
- Blog post: [Towards a production-quality open source Git LFS server](https://about.gitlab.com/blog/2015/08/13/towards-a-production-quality-open-source-git-lfs-server/)

## Related topics

- Official [Git documentation](https://git-scm.com), including
  [Git on the Server - GitLab](https://git-scm.com/book/en/v2/Git-on-the-Server-GitLab)
- [Git troubleshooting](troubleshooting_git.md) techniques
- Blog post: [Git Tips & Tricks](https://about.gitlab.com/blog/2016/12/08/git-tips-and-tricks/)
- Blog post: [Eight Tips to help you work better with Git](https://about.gitlab.com/blog/2015/02/19/8-tips-to-help-you-work-better-with-git/)

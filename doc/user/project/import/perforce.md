---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from Perforce Helix
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[Perforce Helix](https://www.perforce.com/) provides a set of tools which also
include a centralized, proprietary version control system similar to Git.

## Perforce vs Git

The following list illustrates the main differences between Perforce Helix and
Git:

- In general, the biggest difference is that Perforce branching is heavyweight
  compared to Git lightweight branching. When you create a branch in Perforce,
  it creates an integration record in their proprietary database for every file
  in the branch, regardless how many were actually changed. With Git, however,
  a single SHA acts as a pointer to the state of the whole repository after the
  changes, which can be helpful when adopting feature branching workflows.
- Context switching between branches is less complex in Git. If your manager
  says, 'You need to stop work on that new feature and fix this security
  vulnerability,' Git can help you do this.
- Having a complete copy of the project and its history on your local computer
  means every transaction is very fast, and Git provides that. You can branch
  or merge, and experiment in isolation, and then clean up before sharing your
  changes with others.
- Git makes code review less complex, because you can share your changes without
  merging them to the default branch. This is compared to Perforce, which had to
  implement a Shelving feature on the server so others could review changes
  before merging.

## Why migrate

Perforce Helix can be difficult to manage both from a user and an administrator
perspective. Migrating to Git/GitLab there is:

- **No licensing costs**: Git is GPL while Perforce Helix is proprietary.
- **Shorter learning curve**: Git has a big community and a vast number of
  tutorials to get you started.
- **Integration with modern tools**: By migrating to Git and GitLab, you can have
  an open source end-to-end software development platform with built-in version
  control, issue tracking, code review, CI/CD, and more.

## How to migrate

Git includes a built-in mechanism (`git p4`) to pull code from Perforce and to
submit back from Git to Perforce.

Here's a few links to get you started:

- [`git-p4` manual page](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-p4.html)
- [`git-p4` example usage](https://archive.kernel.org/oldwiki/git.wiki.kernel.org/index.php/Git-p4_Usage.html)
- [Git book migration guide](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git#_perforce_import)

`git p4` and `git filter-branch` are not very good at
creating small and efficient Git packfiles. So it might be a good
idea to spend time and CPU to properly repack your repository before
sending it for the first time to your GitLab server. See
[this StackOverflow question](https://stackoverflow.com/questions/28720151/git-gc-aggressive-vs-git-repack/).

## Related topics

- [Mirror with Perforce Helix with Git Fusion](../repository/mirror/bidirectional.md#mirror-with-perforce-helix-with-git-fusion)

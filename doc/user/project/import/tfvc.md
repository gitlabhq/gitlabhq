---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from TFVC to Git
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Team Foundation Server (TFS), renamed [Azure DevOps Server](https://azure.microsoft.com/en-us/products/devops/server/)
in 2019, is a set of tools developed by Microsoft which also includes
[Team Foundation Version Control](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/what-is-tfvc?view=azure-devops)
(TFVC), a centralized version control system similar to Git.

In this document, we focus on the TFVC to Git migration.

## TFVC vs Git

The main differences between TFVC and Git are:

- **Git is distributed:** While TFVC is centralized using a client-server architecture,
  Git is distributed. This translates to Git having a more flexible workflow since
  you work with a copy of the entire repository. This allows you to quickly
  switch branches or merge, for example, without needing to communicate with a remote server.
- **Storage:** Changes in a centralized version control system are per file (changeset),
  while in Git a committed file is stored in its entirety (snapshot). That means that it is
  very easy to revert or undo a whole change in Git.

For more information, see:

- The Microsoft [comparison of Git and TFVC](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/comparison-git-tfvc?view=azure-devops).
- The Wikipedia [comparison of version control software](https://en.wikipedia.org/wiki/Comparison_of_version_control_software).

## Why migrate

Advantages of migrating to Git/GitLab:

- **No licensing costs:** Git is open source, while TFVC is proprietary.
- **Shorter learning curve:** Git has a big community and a vast number of
  tutorials to get you started (see our [Git topic](../../../topics/git/_index.md)).
- **Integration with modern tools:** After migrating to Git and GitLab, you have
  an open source, end-to-end software development platform with built-in version
  control, issue tracking, code review, CI/CD, and more.

## How to migrate

Migration options from TFVC to Git depend on your operating system.

- If you're migrating on Microsoft Windows, use the [`git-tfs`](https://github.com/git-tfs/git-tfs)
  tool. See [Migrate TFS to Git](https://github.com/git-tfs/git-tfs/blob/master/doc/usecases/migrate_tfs_to_git.md)
  for details.
- If you're on a Unix-based system, follow the procedures described with this
  [TFVC to Git migration tool](https://github.com/turbo/gtfotfs).

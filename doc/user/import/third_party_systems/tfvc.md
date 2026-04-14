---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate from Team Foundation Version Control
description: "Migrate from Team Foundation Version Control to Git."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Team Foundation Version Control](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/what-is-tfvc?view=azure-devops)
(TFVC) is a centralized version control system similar to Git.

The main differences between TFVC and Git are:

- While TFVC is centralized using a client-server architecture, Git is distributed. Git has a more flexible workflow
  because you work with a copy of the entire repository. You can quickly switch branches or merge, for example, without
  needing to communicate with a remote server.
- Changes in a centralized version control system are per file (changeset), while in Git a committed file is stored in
  its entirety (snapshot).

For more information, see:

- The Microsoft [comparison of Git and TFVC](https://learn.microsoft.com/en-us/azure/devops/repos/tfvc/comparison-git-tfvc?view=azure-devops).
- The Wikipedia [comparison of version control software](https://en.wikipedia.org/wiki/Comparison_of_version_control_software).

## Migrate to Git

We do not provide a tool to migrate from TFVC to Git. For information on migrating:

- If you're migrating on Microsoft Windows, see:
  - The [`git-tfs`](https://github.com/git-tfs/git-tfs) tool.
  - This [TFS to Git migration information](https://github.com/git-tfs/git-tfs/blob/master/doc/usecases/migrate_tfs_to_git.md).
- If you're on a Unix-based system, see this [TFVC to Git migration tool](https://github.com/turbo/gtfotfs).

---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate from Perforce P4
description: "Migrate from Perforce P4 to Git."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Perforce P4](https://www.perforce.com/) provides a set of tools which also
include a centralized, proprietary version control system similar to Git.

The following lists the main differences between Perforce P4 and Git:

- Perforce P4 branching is heavyweight compared to Git lightweight branching. When you create a branch in Perforce P4,
  it creates an integration record in its proprietary database for every file in the branch, regardless of how many were
  actually changed. With Git, a single SHA acts as a pointer to the state of the whole repository after the
  changes, which can be helpful when adopting feature branching workflows.
- Context switching between branches is less complex in Git.
- With Git, having a complete copy of the project and its history on your local computer
  means every transaction is very fast. You can branch or merge, experiment in isolation, and then clean up before
  sharing your changes with others.
- Git makes code review less complex because you can share your changes without merging them to the default branch.
  Perforce P4 needed a Shelving feature on the server so others could review changes before merging.

## Migrate to Git

Git includes a subcommand (`git p4`) to move between Perforce P4 repositories and Git repositories.

For more information, see:

- [`git-p4` manual page](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-p4.html)
- [`git-p4` documentation](https://git-scm.com/docs/git-p4)
- [Git book migration guide](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git#_perforce_import)

`git p4` and `git filter-branch` are not very good at creating small and efficient Git packfiles. You might want to
properly repack your repository before sending it for the first time to your GitLab server. For more information, see
[this StackOverflow question](https://stackoverflow.com/questions/28720151/git-gc-aggressive-vs-git-repack).

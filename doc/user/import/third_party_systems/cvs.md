---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate from Concurrent Versions System
description: "Migrate from Concurrent Versions System to Git."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Concurrent Versions System](https://savannah.nongnu.org/projects/cvs) (CVS) is a centralized version
control system similar to [Subversion](https://subversion.apache.org/).

For an overview of the differences between CVS and Git, see this [Stack Overflow post](https://stackoverflow.com/a/824241/974710).
For a more complete list of differences, see the Wikipedia article
[comparing the different version control software](https://en.wikipedia.org/wiki/Comparison_of_version_control_software).

## Migrate to Git

We do not provide a tool to migrate from CVS to Git. For information on migrating, see these resources:

- [Migrate using the `cvs-fast-export` tool](https://gitlab.com/esr/cvs-fast-export)
- [Stack Overflow post on importing CVS repositories](https://stackoverflow.com/questions/11362676/how-to-import-and-keep-updated-a-cvs-repository-in-git/11490134#11490134)
- [Man page of the `git-cvsimport` tool](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-cvsimport.html)
- [Migrate using `reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html#conversion)

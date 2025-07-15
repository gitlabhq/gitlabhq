---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from ClearCase
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[ClearCase](https://www.ibm.com/products/devops-code-clearcase) is a set of
tools developed by IBM which also include a centralized version control system
similar to Git.

A good read of ClearCase's basic concepts is can be found in this
[StackOverflow post](https://stackoverflow.com/a/645771/974710).

The following table illustrates the main differences between ClearCase and Git:

| Aspect | ClearCase | Git |
| ------ | --------- | --- |
| Repository model | Client-server | Distributed |
| Revision IDs | Branch + number  | Global alphanumeric ID |
| Scope of Change | File | Directory tree snapshot |
| Concurrency model | Merge | Merge |
| Storage Method | Deltas | Full content |
| Client | CLI, Eclipse, CC Client | CLI, Eclipse, Git client/GUIs |
| Server | UNIX, Windows legacy systems | UNIX, macOS |
| License | Proprietary | GPL |

## Why migrate

ClearCase can be difficult to manage both from a user and an administrator perspective.
Migrating to Git/GitLab there is:

- **No licensing costs**, Git is GPL while ClearCase is proprietary.
- **Shorter learning curve**, Git has a big community and a vast number of
  tutorials to get you started.
- **Integration with modern tools**, migrating to Git and GitLab you can have
  an open source end-to-end software development platform with built-in version
  control, issue tracking, code review, CI/CD, and more.

## How to migrate

While there doesn't exist a tool to fully migrate from ClearCase to Git, here
are some useful links to get you started:

- [Bridge for Git and ClearCase](https://github.com/charleso/git-cc)

- [ClearCase to Git](https://therub.org/2013/07/19/clearcase-to-git/)
- [Dual syncing ClearCase to Git](https://therub.org/2013/10/22/dual-syncing-clearcase-and-git/)
- [Moving to Git from ClearCase](https://sateeshkumarb.wordpress.com/2011/01/15/moving-to-git-from-clearcase/)
- [ClearCase to Git webinar](https://www.brighttalk.com/webcast/11817/162473)

---
title: See who locked a file or directory
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
documentation_link: "../../../user/project/file_lock"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/13019
categories: [ Source Code Management ]
level: secondary
weight: 50
---

When a file is locked, you now see who locked it and what your options are,
without leaving the blob viewer.

Previously, only a **Locked** label appeared, with no way to tell who locked the
file or whether you could unlock it yourself. Now, a popover next to the label
shows who locked it. If you have permission to unlock the file, the popover
includes an unlock action. If you don't, it explains why. For locked
directories, the popover links you directly to the specific file that's
blocking your changes.

---
title: Preview a new file before commit
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/web_editor/#create-a-file"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253963
categories: [ Source Code Management ]
level: secondary
weight: 40
---

The new file page now has **Write** and **Preview** tabs, the same pair the edit page has had for
years, so you can see how a Markdown or AsciiDoc file renders before its first commit exists.
Preview keeps up with your edits: rename a file from `.txt` to `.md` mid-edit and the preview
switches renderer; rename it away from Markdown and the live preview stops. Snippets also gained
Markdown live preview, available from the editor's right-click menu.

Thank you to [skkzsh](https://gitlab.com/skkzsh) for this contribution!

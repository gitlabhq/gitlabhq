---
title: Embed code from a repository in Markdown
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: plan
documentation_link: "../../../user/markdown/#embed-code-from-a-repository"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/300855
categories: [ Markdown ]
level: secondary
weight: 50
---

In previous versions of GitLab,
[permalinks](../../../user/project/repository/files/_index.md#create-permalinks)
to a file's lines rendered as plain URLs, so you had to leave the merge request,
issue, or wiki page to view the referenced code.

Now, permalinks render as a syntax-highlighted snippet with the file path and commit,
so you can read the code without leaving the page. You can only view embedded
snippets if you have read access to the repository.

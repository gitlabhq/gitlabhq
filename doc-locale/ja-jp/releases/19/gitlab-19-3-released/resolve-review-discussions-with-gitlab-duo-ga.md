---
title: "GitLab Duoによるレビューディスカッションの解決が一般提供になりました"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#resolve-a-discussion-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22058
categories: [ DAP Code Review ]
level: secondary
weight: 20
---

以前のバージョンのGitLabでは、コードレビューのコメントを解決するために、エディタに切り替えて修正を実装し、変更をコミットしてプッシュしたうえで、スレッドを手動でクローズする必要がありました。

**GitLab Duoで解決**を選択するだけで、GitLab Duoがレビューディスカッションを代わりに対応します。

GitLab Duoはコメントと周辺のコードを読み取り、ソースブランチに対して要求された変更を加えたうえで、変更内容のサマリーをディスカッションに返信し、スレッドを解決します。
変更がコメントに正しく対応していない場合は、あなたまたはレビュアーがスレッドを再オープンできます。

---
title: "レビューディスカッションをGitLab Duoで解決（ベータ版）"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#resolve-a-discussion-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22117
categories: [ DAP Code Review ]
---


以前のバージョンのGitLabでは、コードレビューのコメントを解決するには、エディタに切り替えて修正を実装し、変更をコミットしてプッシュしてから、スレッドを手動でクローズする必要がありました。
未解決のディスカッションごとにこのサイクルを繰り返す必要があり、コンテキストスイッチのオーバーヘッドが多忙なレビュー全体で積み重なっていました。

任意のレビューディスカッションで**GitLab Duoで解決**を選択できるようになりました。
GitLab Duoはレビューコメントとその周辺のコードを読み取り、レビュアーが説明した変更を実装して、ブランチにコミットします。その後、GitLab Duoは変更内容と理由の簡単なサマリーをディスカッションに返信し、スレッドを解決します。変更内容を確認し、修正がコメントに正しく対応していない場合はスレッドを再オープンできます。

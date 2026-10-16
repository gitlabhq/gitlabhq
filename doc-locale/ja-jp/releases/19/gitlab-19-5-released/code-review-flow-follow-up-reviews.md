---
title: コードレビューフローのフォローアップレビュー
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/code_review/#follow-up-reviews"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21620
categories: [ DAP Code Review ]
level: secondary
weight: 50
---

以前のバージョンのGitLabでは、GitLab Duoにマージリクエストの再レビューを依頼すると、初回レビューとして扱われていました。そのため、既に対応済みのスレッドを含め、以前の指摘が繰り返されることがありました。

今回のリリースで、コードレビューフローが以前のGitLab Duoレビューのコメントスレッド（返信を含む）を参照して新しい変更を評価するようになりました。GitLab Duoは前回のレビュー以降に追加された行に焦点を当て、既に指摘した点を繰り返さず、未解決の指摘をサマリーにまとめます。コードが正しい理由をスレッドで返信した場合、GitLab Duoはその点を再度指摘しません。

フォローアップレビューを開始するには、GitLab Duoにマージリクエストの再レビューを依頼してください。**プッシュ時に新しいレビューを開始**をオンにすると、変更をプッシュした際にGitLab Duoが自動的にフォローアップレビューを開始します。

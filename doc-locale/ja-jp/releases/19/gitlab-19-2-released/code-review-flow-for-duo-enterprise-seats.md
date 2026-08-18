---
title: GitLab Duo EnterpriseシートのCode Review Flow
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22247
categories: [ DAP Code Review ]
---

以前のバージョンのGitLabでは、GitLab Duo Enterpriseシートを持つユーザーがGitLab Duoにコードレビューをリクエストすると、GitLab Duoコードレビューがレビューを実行していました。
これは、グループに対してコードレビューフローが有効になっている場合でも同様でした。すべてのユーザーに対してエージェント型フローを有効にする方法はありませんでした。

今回のリリースで、トップレベルグループのオーナーがこのデフォルト設定を変更し、ユーザーのシートに関わらず、すべてのコードレビューでコードレビューフローを使用するよう設定できるようになりました。
すべてのレビューはGitLabクレジットを消費します。

この変更により、GitLab Duo Enterpriseシートを持つユーザーも、他のユーザーと同様に、リポジトリ全体のコンテキスト認識、マルチステップの推論、およびレビューセッションを利用できるようになります。

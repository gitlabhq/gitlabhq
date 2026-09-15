---
title: GitLabクレジットの使用上限が一般提供開始
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits/#usage-caps"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607551
categories: [ Consumables Cost Management ]
level: secondary
---

オンデマンド使用により、予期しない超過料金が発生する場合があります。GitLabクレジットの使用上限が一般提供開始となりました。カスタマーポータルでサブスクリプションレベルのオンデマンドクレジット上限を設定し、GraphQL APIでユーザーごとのデフォルト上限や個別オーバーライドを設定できます。消費量が上限に達すると、GitLab Duo Agent Platformなど、GitLabクレジットを消費する機能は、次の請求期間が始まるか管理者が上限を調整するまで停止されます。使用上限はGitLab 18.11で`budget_caps_graphql_api`機能フラグの背後に導入されました。GitLab 19.3では、この機能フラグが削除されました。

---
title: マージリクエストのレビューとデプロイ承認のWebhook
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: create
co_create: true
documentation_link: "../../../user/project/integrations/webhook_events/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246562
categories: [ Code Review Workflow, Deployment Management ]
level: secondary
---

マージリクエストのレビューとデプロイ承認にWebhookを使用できます。マージリクエストのレビューを
**変更をリクエスト**または**レビュー済み**として送信すると、GitLabは`changes.reviewers`エントリを含む
`merge_request` Webhookを送信します。これにより、外部ツールは承認だけでなくレビューアクティビティにも
対応できるようになります。

デプロイWebhookには`blocked`、`approved`、`rejected`のステータスと、トップレベルの`approver`および
`approval`フィールドが追加され、デプロイの承認ライフサイクル全体を追跡できます。`blocked`ステータスは
すべてのティアで利用可能です。`approved`および`rejected`ステータスはPremiumおよびUltimateのみで
利用可能で、`approver.email`は削除済みの状態で表示されます。

これらのコントリビュートをいただいた[Messias Tayllan](https://gitlab.com/tayllanr)（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246562)）
および[Anvita Gupta](https://gitlab.com/arcesium-guptaanv)（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239337)）
に感謝いたします！

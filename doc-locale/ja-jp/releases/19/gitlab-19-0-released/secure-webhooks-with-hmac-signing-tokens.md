---
title: HMACサイニングトークンでWebhookを保護する
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/project/integrations/webhooks/#signing-tokens"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/19367"
categories: [ Importers ]
weight: 110
---

既存の`X-Gitlab-Token`ヘッダーは静的なシークレットを平文で送信するため、Webhookが傍受やリプレイ攻撃を受けやすい状態になっています。

任意のWebhookにサイニングトークンを追加できるようになりました。GitLabはサイニングトークンを使用して、以下の情報に対するHMAC-SHA256署名を計算します。

- WebhookのユニークID
- リクエストのタイムスタンプ
- Webhookのペイロード

GitLabはその結果を`webhook-signature`ヘッダーで送信し、[Standard Webhooks](https://www.standardwebhooks.com/)仕様に従って`webhook-id`および`webhook-timestamp`ヘッダーも併せて送信します。

署名を再計算することで、リクエストが本当にGitLabから送信されたものであること、およびペイロードが改ざんされていないことを確認できます。タイムスタンプを検証することで、リプレイされたリクエストを拒否することも可能です。

[Van Anderson](https://gitlab.com/van.m.anderson)さんと[Norman Debald](https://gitlab.com/Modjo85)さんのコミュニティへのコントリビュートに感謝します！

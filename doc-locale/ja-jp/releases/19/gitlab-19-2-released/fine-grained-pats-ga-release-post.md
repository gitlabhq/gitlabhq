---
title: "詳細権限PATが一般提供開始"
tier: [Free, Premium, Ultimate]
offering: [gitlab_com, self_managed, gitlab_dedicated]
stage: software_supply_chain_security
documentation_link: "../../../auth/tokens/fine_grained_access_tokens/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/18554"
categories: [Permissions]
weight: 50
---

詳細権限パーソナルアクセストークン（PAT）が一般提供（GA）になりました。従来のPATは所属するすべてのプロジェクトとグループへのアクセスを付与しますが、詳細権限PATでは各トークンを特定のリソースとアクションに限定できます。これにより、自動化やインテグレーションに最小権限の原則を適用しやすくなり、トークンが漏洩または不正利用された場合の潜在的な影響を軽減できます。

セットアップを簡単にするために、トークン作成時に**Duoで権限を追加**機能を使用して適切なパーミッションを選択できます。既存の従来のPATは引き続き従来どおり機能します。新しいトークンについては、各トークンが必要なリソースとアクションのみにスコープされるよう、GitLabは詳細権限PATを推奨しています。

GAリリースにより、詳細権限PATはREST APIエンドポイントの完全なカバレッジと、最もよく使用されるGraphQLタイプおよびミューテーションのカバレッジを備えるようになりました。

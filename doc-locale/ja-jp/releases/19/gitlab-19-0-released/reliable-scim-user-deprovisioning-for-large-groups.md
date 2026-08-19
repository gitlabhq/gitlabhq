---
title: 大規模グループにおける信頼性の高いSCIMユーザーデプロビジョニング
stage: tenant_scale
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com ]
documentation_link: "../../../development/internal_api/#group-scim-api"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/521324"
categories: [ User Management ]
weight: 90
---

SCIMを通じて多数のユーザーを管理している組織では、グループメンバーのデプロビジョニング処理がタイムアウトし、`500`エラーが返されることがありました。SCIMの`DELETE`および`PATCH`リクエストは、成功レスポンスを即座に返すようになりました。メンバーシップの削除は非同期で処理されるため、IDプロバイダーおよびSCIMクライアントは一貫した成功レスポンスを受け取ることができます。

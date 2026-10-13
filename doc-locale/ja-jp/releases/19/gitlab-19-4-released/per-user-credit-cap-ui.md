---
title: GraphQL APIを使用せずにクレジットキャップを設定する
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#manage-credit-caps"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/628559
categories: [ Consumables Cost Management ]
level: secondary
---

クレジットキャップは、各ユーザーが消費できるGitLabクレジットの上限を制限する機能ですが、これまではGraphQL APIを通じてのみ設定できました。一部のユーザーに異なるキャップを設定するには、ミューテーションを手動で記述する必要がありました。

新しい**クレジットキャップ**ページでは、すべてのユーザーにデフォルトで適用されるフラットキャップを設定し、検索可能なピッカーを使用して個々のユーザーにユーザーごとのオーバーライドを追加できます。
このページは、GitLab.comのグループオーナーおよびGitLab Self-Managedの管理者向けに、**GitLabクレジット**内で利用できます。
キャップの変更をスクリプト化する場合は、引き続きGraphQLミューテーションを使用できます。

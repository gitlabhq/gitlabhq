---
title: デフォルト以外のブランチトラッキングが一般提供開始
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/vulnerability_report"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/3430
categories: [ Vulnerability Management ]
level: primary
weight: 50
---

デフォルト以外のブランチトラッキングが一般提供（GA）になりました。デフォルトブランチ以外のブランチで脆弱性を追跡できます。最良の結果を得るには、特定の環境向けブランチ（`project-qa`、`project-prod`）やデプロイプラットフォーム向けブランチ（`project-iOS`、`project-android`）など、長期間維持されるリリースブランチを少数に絞って対象にすることをお勧めします。

このリリースには以下の機能が含まれています。

- セキュリティ設定ページで、追加のブランチまたはタグを3つまで追跡できます。これはデフォルトの追跡ブランチに加えて利用できます。
- 脆弱性レポートで追跡対象のrefによるフィルタリングが可能です。
- プロジェクトレベルのセキュリティダッシュボードでブランチによるフィルタリングが可能です。
- 追跡対象ブランチの脆弱性ステータスを更新できます。
- 脆弱性管理ポリシーが追跡対象の各ブランチを個別に評価し、そのブランチの脆弱性のみを更新します。

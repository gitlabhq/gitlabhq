---
title: デフォルト以外のブランチのトラッキング（ベータ版）
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/remediate/dependency_scanning_auto_remediation/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/604799
categories: [ Vulnerability Management ]
level: primary
weight: 50
---

デフォルトブランチ以外のブランチでも脆弱性を追跡できるようになりました。最良の結果を得るには、特定の環境（`project-qa`、`project-prod`）やデプロイプラットフォーム（`project-iOS`、`project-android`）向けのブランチなど、長期間維持されるリリースブランチを少数に絞って対象にすることをお勧めします。

このベータ版には以下の機能が含まれています。

- セキュリティ設定ページで追跡ブランチを追加できます（ネームスペース内のプロジェクト数の2倍まで）。
- 脆弱性レポートでブランチによるフィルタリングが可能です。
- プロジェクトレベルのセキュリティダッシュボードでブランチによるフィルタリングが可能です。
- 追跡ブランチ上のすべての脆弱性タイプ（以前は対象外だったCVEを含む）を追跡できます。
- ブランチがデフォルトブランチにマージされた際に、脆弱性ステータスのメタデータの整合性を維持します。
- 追跡ブランチ上の脆弱性ステータスを更新できます。

---
title: スキャナー有効化ウィザードでカバレッジのギャップを解消
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/scanner_enablement_wizard"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21626
categories: [ Security Asset Inventories ]
level: secondary
weight: 50
---

<!-- Category: Security Asset Inventories -->

スキャナー有効化ウィザードを使用することで、注意が必要なプロジェクトを手動で特定することなく、プロジェクト全体のスキャナーカバレッジのギャップを解消できるようになりました。

セキュリティ設定プロファイルは、実行するスキャナーとその方法を定義します。セキュリティインベントリは、プロジェクト全体のスキャナーカバレッジを表示し、選択したプロジェクトやサブグループにプロファイルを一括適用できます。ウィザードはその上に目標主導のワークフローを追加します。目標を設定すると、カバレッジが不足しているプロジェクトを検出し、そのギャップのみを解消します。

---
title: セキュリティ設定プロファイルにおける依存関係スキャン
stage: security_risk_management
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/configuration/security_configuration_profiles/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/19952"
categories: [ Security Testing Configuration ]
weight: 20
---

GitLab 18.11では、SASTとシークレット検出のセキュリティ設定プロファイルが導入されました。
今回のリリースで、**Dependency Scanning - Default**プロファイルにより、依存関係スキャンも利用できるようになりました。
このプロファイルを使用すると、CI/CD設定ファイルを一切編集することなく、すべてのプロジェクトに標準化されたSCAカバレッジを適用するための統合コントロールサーフェスを利用できます。

このプロファイルは2つのスキャントリガーを有効化します。

- **マージリクエストパイプライン**: オープンなマージリクエストがあるブランチに新しいコミットがプッシュされるたびに、依存関係スキャンを自動的に実行します。結果には、マージリクエストによって導入された新しい脆弱性のみが含まれます。
- **ブランチパイプライン（デフォルトブランチのみ）**: 変更がデフォルトブランチにマージまたはプッシュされたときに自動的に実行され、デフォルトブランチの依存関係の状態を包括的に確認できます。

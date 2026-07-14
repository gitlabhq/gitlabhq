---
title: サードパーティスキャナーの結果をGitLabで活用する
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/detect/sarif"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595060
categories: [ Security Testing Integrations ]
level: secondary
weight: 50
---

<!-- Category: Security Testing Integrations -->

SARIF 2.1.0準拠のスキャナーであれば、そのセキュリティ検出結果をGitLabの脆弱性管理で活用できるようになりました。

スキャナーを実行してSARIFアーティファクトを出力するCI/CDジョブを定義するだけで、GitLabがその検出結果を解析・検証し、セキュリティワークフローにインポートします。結果はパイプラインのセキュリティタブ、脆弱性レポート、セキュリティダッシュボード、マージリクエストのセキュリティウィジェット、セキュリティポリシーに、GitLabネイティブスキャナーの出力と並べて表示されます。この機能により、セキュリティチームはどのツールで検出された脆弱性も一元的に把握できます。

GitLabは各検出結果の識別子をもとにレポートタイプを割り当て、`SAST`、`dependency scanning`、`secret detection`などのカテゴリに分類します。対応スキャナーには、SASTではSemgrepとCheckmarx、依存関係スキャンとコンテナスキャンではTrivyとSnyk、シークレット検出ではGitleaksが含まれます。

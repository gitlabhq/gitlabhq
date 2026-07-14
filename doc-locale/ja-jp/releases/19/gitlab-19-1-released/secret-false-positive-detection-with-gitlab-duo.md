---
title: GitLab Duoによるシークレット誤検出判定
stage: software_supply_chain_security
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/vulnerabilities/secret_false_positive_detection/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21233"
categories: [ Vulnerability Management ]
weight: 10
---

<!-- categories: Vulnerability Management -->

GitLab Duo Agent Platformによるシークレット誤検出判定が一般提供（GA）になりました。

セキュリティチームは、実際のシークレットとして誤ってフラグが立てられたシークレット検出の検出結果の調査に多くの時間を費やしています。
このような誤検出は、アラート疲れの誘発、スキャン結果への信頼低下、そして本来の重大なセキュリティリスクの見落としにつながります。

セキュリティスキャンの実行時、GitLab Duoは重大度が「致命的」および「高」のシークレット検出の脆弱性をそれぞれ自動的に分析し、誤検出かどうかを判定します。
AI評価は脆弱性レポートに表示されるため、より迅速かつ確信を持ったトリアージの判断に必要なコンテキストをすぐに確認できます。

主な機能は次のとおりです。

- 自動分析: 手動でトリガーすることなく、各セキュリティスキャンの実行後に自動で実行されます。
- 手動トリガー: 脆弱性の詳細ページで個々の脆弱性に対して誤検出判定をトリガーし、オンデマンドで分析できます。
- 影響度の高い検出結果への集中: 重大度が「致命的」および「高」の脆弱性のみを分析することで、シグナル対ノイズ比を最大限に改善します。
- コンテキストを考慮したAIによる推論: 各評価には、コードのコンテキストと脆弱性の特性に基づいて、その検出結果が真陽性である可能性が高い理由の説明が含まれます。
- 信頼スコア: 各検出結果には信頼スコアが含まれており、モデルの確信度に基づいてレビューの優先順位付けに役立てることができます。
- シームレスなワークフローインテグレーション: 結果は、既存の重大度、ステータス、および修正情報とともに脆弱性レポートに直接表示されます。

フィードバックは[イシュー592861](https://gitlab.com/gitlab-org/gitlab/-/issues/592861)にお寄せください。

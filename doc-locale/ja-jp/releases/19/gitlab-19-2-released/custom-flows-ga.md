---
title: GitLab Duoのカスタムフローが一般提供を開始
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/duo_agent_platform/flows/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/602415
categories: [ AI Catalog Creation ]
level: primary
weight: 10
---

カスタムフローは、GitLabプロジェクト全体にわたる複雑なマルチステップタスクを自動化するために、ユーザーが作成・設定できるAI駆動のワークフローです。チームはワークフローのステップ、コンポーネント、トリガーを定義することで、繰り返し発生する開発・運用作業をGitLabイベントに応じて自動実行できます。GitLab UIでは、フローがGitLab CI/CD上で直接実行されるため、GitLabを離れることなく一般的なタスクを自動化できます。

主な機能は次のとおりです。

- チーム固有の自動化に対応した、YAMLで定義された再利用可能なワークフロー
- 複雑なマルチステップタスクに対応するマルチエージェントオーケストレーション
- 重要なステップでの承認やフィードバックのために、ユーザーが定義できるヒューマン・イン・ザ・ループ（HITL）チェックポイント
- メンション、割り当て、パイプラインイベント、マージリクエストのライフサイクルイベントを含むネイティブGitLabトリガー
- プロジェクトまたはAIカタログからのフローの作成と管理
- パブリックおよびプライベートの表示レベル制御
- サービスアカウントと複合IDを使用したセキュアな実行
- 実行前に設定の問題を検出するYAML検証

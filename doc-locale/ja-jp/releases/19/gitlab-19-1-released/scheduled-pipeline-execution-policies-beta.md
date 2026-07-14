---
title: スケジュールパイプライン実行ポリシー（ベータ版）
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/scheduled_pipeline_execution_policies/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17875"
categories: [ Security Policy Management ]
level: secondary
weight: 50
---

<!-- categories: Security Policy Management -->

スケジュールパイプライン実行ポリシーがベータ版として利用可能になり、有効化に実験フラグが不要になりました。コミットの有無に関わらず、プロジェクト全体でカスタムCI/CDジョブを日次・週次・月次のケイデンスで適用できます。スケジュールポリシーを使用することで、定期的なコード変更が行われないリポジトリに対しても、コンプライアンススクリプト、セキュリティスキャン、依存関係チェックを実行できます。

スケジュールポリシーは、通常のパイプライン実行ポリシーと一貫した変数の優先順位を適用するようになりました。各セキュリティポリシープロジェクトは最大5つのスケジュールポリシーをサポートし、ポリシーが無効化または削除された場合、GitLabは実行中のパイプラインを自動的にキャンセルします。スケジュールはYAMLまたはUIで設定でき、タイムゾーンのサポート、時間帯分散、ブランチターゲティング、スヌーズ機能を備えています。

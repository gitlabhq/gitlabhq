---
title: スケジュールされたパイプライン実行ポリシーがGAになりました
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/scheduled_pipeline_execution_policies/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17875"
categories: [ Security Policy Management ]
level: primary
weight: 10
---

スケジュールされたパイプライン実行ポリシーが一般提供（GA）になりました。セキュリティポリシープロジェクトでスケジュールを一度定義するだけで、対象となるすべてのプロジェクトに適用できます。各プロジェクトの `.gitlab-ci.yml` を個別に編集する必要はありません。要件が変更された場合も、多数のCI/CD設定ファイルを横断して変更を調整する代わりに、ポリシーを一か所で更新するだけで対応できます。

スケジュールポリシーを使用すると、コミットの有無に関わらず、コンプライアンススクリプト、セキュリティスキャン、またはその他のカスタムCI/CDジョブを日次・週次・月次のケイデンスで実行できます。これは、定期的なコード変更がないリポジトリ（新たに発見された脆弱性を検出するための依存スキャンの実行など）に特に有効です。各ポリシーは独立したパイプラインとして実行され、タイムゾーンのサポート、時間帯分散、およびブランチターゲティングに対応しています。

---
title: インスタンスレベルのカスタムレビュー指示
offering: [ self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/customize/review_instructions#configure-custom-review-instructions-for-an-instance"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22616
categories: [ DAP Code Review ]
---

以前のバージョンのGitLabでは、GitLab Duoのカスタムレビュー指示はプロジェクトレベルまたはグループレベルでのみ定義できました。
インスタンス全体で一貫したレビューガイダンス（セキュリティルールや社内コーディング標準など）を適用したい管理者は、すべてのプロジェクトに同じ指示を重複して設定する必要がありました。

今回のリリースで、インスタンス全体に対してカスタムレビュー指示を設定できるようになりました。

管理者はインスタンス内のプロジェクトをテンプレートとして選択できます。GitLab Duoがコードレビューを実行する際、インスタンスレベルの `.gitlab/duo/mr-review-instructions.yaml` ファイルの指示が、グループレベルおよびプロジェクトレベルの指示と組み合わせて適用されます。これにより、組織はインスタンス全体のレビュー標準に対して信頼できる唯一の情報源を持つことができます。

コードレビューフローとGitLab Duoコードレビューはいずれも、インスタンスレベルのカスタム指示をサポートしています。

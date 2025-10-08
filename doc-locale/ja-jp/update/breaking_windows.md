---
stage: none
group: none
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
noindex: true
title: GitLab.comでの破壊的な変更のデプロイ
---

GitLab.comには継続的に変更がデプロイされています。ただし、破壊的な変更については、準備により多くの時間が必要になる場合があります。

破壊的な変更は、GitLab 18.0リリースの1か月前から3つの時間枠に分けてデプロイされます。以下の表は、それぞれの破壊的な変更のデプロイ時期を示しています。

## 時間枠1 {#window-1}

この時間枠は2025年4月21日から23日の09:00 UTCから22:00 UTCに実施されます。

| 非推奨 | 影響 | ステージ | スコープ | 潜在的な影響の確認 |
|-------------|--------|-------|-------|------------------------|
| [CI/CDジョブトークン - **認証されたグループとプロジェクト**許可リストの適用](deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement) | 高 | ソフトウェアサプライチェーンセキュリティ | プロジェクト | 詳細については[この変更について](https://gitlab.com/gitlab-org/gitlab/-/issues/383084#understanding-this-change)のセクションを参照してください。 |
| [`ProjectMonthlyUsageType` GraphQL APIの`name`フィールドの非推奨](deprecations.md#deprecation-of-name-field-in-projectmonthlyusagetype-graphql-api) | 低 | Fulfillment | プロジェクト |  |
| [`NamespaceProjectSortEnum` GraphQL APIの`STORAGE` enumの非推奨](deprecations.md#deprecation-of-storage-enum-in-namespaceprojectsortenum-graphql-api) | 低 | Fulfillment | グループ |  |
| [DAST `dast_devtools_api_timeout`のデフォルト値の低下](deprecations.md#dast-dast_devtools_api_timeout-will-have-a-lower-default-value) | 低 | アプリケーションセキュリティテスト | プロジェクト |  |
| [APIディスカバリでブランチパイプラインをデフォルトで使用](deprecations.md#api-discovery-will-use-branch-pipelines-by-default) | 低 | アプリケーションセキュリティテスト | プロジェクト |  |
| [アプリケーションセキュリティテストアナライザーのメジャーバージョンアップデート](deprecations.md#application-security-testing-analyzers-major-version-update) | 低 | アプリケーションセキュリティテスト | プロジェクト |  |

## 時間枠2 {#window-2}

この時間枠は2025年4月28日から30日の09:00 UTCから22:00 UTCに実施されます。

| 非推奨 | 影響 | ステージ | スコープ | 潜在的な影響の確認 |
|-------------|--------|-------|-------|------------------------|
| [`add_on_purchase` GraphQLフィールドを`add_on_purchases`に置き換え](deprecations.md#replace-add_on_purchase-graphql-field-with-add_on_purchases) | 低 | Fulfillment | インスタンス、グループ |  |
| [ネームスペース`add_on_purchase` GraphQLフィールドを`add_on_purchases`に置き換え](deprecations.md#replace-namespace-add_on_purchase-graphql-field-with-add_on_purchases) | 低 | Fulfillment | インスタンス、グループ |  |
| [スキャン実行ポリシーで許可されるアクション数の制限](deprecations.md#limit-number-of-scan-execution-policy-actions-allowed-per-policy) | 低 | セキュリティリスク管理 | インスタンス、グループ、プロジェクト |  |

## 時間枠3 {#window-3}

この時間枠は2025年5月5日から7日の09:00 UTCから22:00 UTCに実施されます。

| 非推奨 | 影響 | ステージ | スコープ | 潜在的な影響の確認 |
|-------------|--------|-------|-------|------------------------|
| [CI/CDジョブトークン - **プロジェクトからのアクセス制限**設定の削除](deprecations.md#cicd-job-token---limit-access-from-your-project-setting-removal) | 高 | ソフトウェアサプライチェーンセキュリティ | プロジェクト | 詳細については[この変更について](https://gitlab.com/gitlab-org/gitlab/-/issues/395708#understanding-this-change)のセクションを参照してください。 |
| [Terraform CI/CDテンプレートの非推奨](deprecations.md#deprecate-terraform-cicd-templates) | 中 | Deploy | プロジェクト |  |
| [ライセンスメタデータ形式V1の非推奨](deprecations.md#deprecate-license-metadata-format-v1) | 低 | Secure | インスタンス |  |
| [`ciJobTokenScopeRemoveProject`の`direction` GraphQL引数の非推奨](deprecations.md#the-direction-graphql-argument-for-cijobtokenscoperemoveproject-is-deprecated) | 低 | Govern | プロジェクト |  |
| [今後および開始済みのマイルストーンフィルターの動作変更](deprecations.md#behavior-change-for-upcoming-and-started-milestone-filters) | 低 | Plan | グループ、プロジェクト |  |
| [依存プロキシトークンスコープの適用](deprecations.md#dependency-proxy-token-scope-enforcement) | 高 | Package | グループ |  |
| [duoProAssignedUsersCount GraphQLフィールドの削除](deprecations.md#remove-duoproassigneduserscount-graphql-field) | 低 | Plan | グループ、プロジェクト |  |

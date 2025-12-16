---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: マージリクエストには、CI/CDパイプラインの結果とマージ可能性テストの結果がレポートエリアに表示されます。
title: マージリクエストウィジェット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストの概要ページには、マージリクエストに対してアクションを実行するサービスからのステータス更新が表示されます。すべてのサブスクリプションレベルでウィジェット領域が表示されますが、領域の内容はサブスクリプションレベルと、プロジェクト用に構成したサービスによって異なります。

## パイプライン情報 {#pipeline-information}

プロジェクトで[GitLab CI/CD](../../../ci/_index.md)をセットアップしている場合、[マージリクエスト](_index.md)のウィジェット領域の**概要**タブにパイプライン情報が表示されます:

- マージ前とマージ後の両方のパイプライン、および環境情報（もしあれば）。
- どのデプロイが進行中か。

アプリケーションが正常にデプロイされると、[environment](../../../ci/environments/_index.md) 、デプロイされた環境と[レビューアプリ](../../../ci/review_apps/_index.md)へのリンクの両方が表示されます。

パイプラインがマージリクエストで失敗したが、それでもマージできる場合、GitLabは**マージ**を赤で表示します。

## マージ後のパイプラインのステータス {#post-merge-pipeline-status}

マージリクエストをマージすると、マージリクエストがマージされたブランチのマージ後のパイプラインのステータスを確認できます。たとえば、マージリクエストが[デフォルトブランチ](../repository/branches/default.md)にマージされ、ステージング環境へのデプロイをトリガーする場合などです。

GitLabは、進行中のデプロイと、環境の状態（デプロイ中またはデプロイ済）を表示します。それがブランチの最初のデプロイである場合、完了するまでリンクは`404`エラーを返します。デプロイ中、GitLabは停止ボタンを無効にします。パイプラインがデプロイに失敗した場合、GitLabはデプロイ情報を非表示にします。

![マージリクエストパイプライン](img/post_merge_pipeline_v16_0.png)

詳細については、[パイプラインについてお読みください](../../../ci/pipelines/_index.md)。

## 自動マージを設定 {#set-auto-merge}

マージする準備ができているマージリクエストを、[CIパイプラインが成功した場合に自動的にマージされる](auto_merge.md)ように設定します。

## レビューアプリによるライブプレビュー {#live-preview-with-review-apps}

プロジェクトの[レビューアプリ](../../../ci/review_apps/_index.md)を構成して、フィーチャーブランチに送信された変更をマージリクエストを介してブランチごとにプレビューします。ブランチをチェックアウトしたり、インストールしたり、ローカルでプレビューしたりする必要はありません。すべての変更は、レビューアプリリンクを持つすべての人がプレビューできます。

GitLab [ルートマップ](../../../ci/review_apps/_index.md#route-maps)が設定されている場合、マージリクエストウィジェットを使用すると、変更されたページに直接移動できるため、提案された変更をより簡単かつ迅速にプレビューできます。

[レビューアプリの詳細](../../../ci/review_apps/_index.md)。

## ライセンスコンプライアンス {#license-compliance}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトの依存関係に対して検出されたライセンスのリストを表示するには、プロジェクトの[ライセンスコンプライアンス](../../compliance/license_scanning_of_cyclonedx_files/_index.md)を設定します。

![マージリクエストに表示されるライセンスコンプライアンス情報の例](img/license_compliance_widget_v15_3.png)。

## セキュリティポリシー {#security-policies}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デベロッパーが脆弱性とサポートされていないライセンスをマージしたり、マージリクエストに必要な承認を強制したりすることを防ぐには、[セキュリティポリシー](../../application_security/policies/merge_request_approval_policies.md)を設定します。セキュリティポリシーは、プロジェクト、グループ、またはインスタンスに対して構成できます。オプションで、セキュリティポリシーを警告モードに設定して、デベロッパーがマージすることを妨げずに、所見の認識を高めることができます。

## 外部ステータスチェック {#external-status-checks}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[外部ステータスチェック](status_checks.md)を設定している場合は、マージリクエストのこれらのチェックのステータスを[特定のウィジェットで](status_checks.md#status-checks-widget)確認できます。

## アプリケーションセキュリティスキャン {#application-security-scanning}

アプリケーションセキュリティスキャンツールを有効にすると、GitLabはセキュリティスキャンウィジェットに結果を表示します。詳細については、[マージリクエストウィジェットのセキュリティスキャン出力](../../application_security/detect/security_scanning_results.md)を参照してください。

{{< alert type="note" >}}

[子パイプライン](../../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)で実行されるセキュリティスキャンの結果は、セキュリティスキャンウィジェットに表示されません。このサポートは[エピック18377](https://gitlab.com/groups/gitlab-org/-/epics/18377)で提案されています。セキュリティスキャンの結果をウィジェットに表示する場合は、親パイプラインでスキャンジョブを実行します。

{{< /alert >}}

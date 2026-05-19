---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: シークレットの誤検出判定
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.10の[エピック17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152)で、`duo_secret_detection_false_positive`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ](../../../../policy/development_stages_support.md#beta)機能として導入されました。[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074)

{{< /history >}}

シークレット誤検出判定は、シークレット検出の結果を自動的に分析し、潜在的な誤検出を特定します。実際のセキュリティリスクではない可能性が高いシークレットを無視することで、脆弱性レポートにおけるノイズが減少します。

シークレット検出のスキャンが実行されると、GitLab Duoは各結果を自動的に分析し、それが誤検出である可能性を判断します。この検出機能は、[GitLabのシークレット検出](../../../application_security/secret_detection/_index.md)によって検出されるすべてのシークレットタイプで利用可能です。

GitLab Duoのアセスメントには、各誤検出判定結果に関する情報が含まれています:

- 信頼度スコア: その検出結果が誤検出である可能性を示す数値スコア。
- 説明: 検出された内容が真の陽性である可能性、またはそうではない可能性の理由。
- ビジュアルインジケーター: 評価結果を示す脆弱性レポート内のバッジ。

結果はAIによる分析に基づいており、セキュリティ担当者によるレビューが必要です。この機能を使用するには、アクティブなサブスクリプションが割り当てられたGitLab Duoが必要です。

> [!note]
> このフローは、そのサービスアカウントからの言及、割り当て、またはレビューのリクエストによってトリガーすることはできません。セキュリティスキャンの完了後、フローは自動的に実行されます。脆弱性レポートから**誤検出のチェック**ボタンをクリックすることで、手動で実行できます。

## シークレット誤検出判定の実行 {#running-secret-false-positive-detection}

フローは次のシナリオで自動的に実行されます:

- シークレット検出スキャンがデフォルトブランチで正常に完了している。
- スキャンがシークレットを検出している。
- プロジェクトまたはグループでGitLab Duoの機能が有効になっている。

既存の脆弱性に対する分析を手動でトリガーすることもできます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 分析する脆弱性を選択します。
1. 右上隅で、**誤検出をチェック**を選択します。

## 関連リンク {#related-links}

- [シークレット検出の誤検出判定](../../../application_security/vulnerabilities/secret_false_positive_detection.md)。
- [脆弱性レポート](../../../application_security/vulnerability_report/_index.md)。
- [シークレット検出](../../../application_security/secret_detection/_index.md)。

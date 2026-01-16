---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SASTの誤検出検出
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.7で機能[フラグ](../../../../administration/feature_flags/_index.md)`enable_vulnerability_fp_detection`および`ai_experiment_sast_fp_detection`とともに[ベータ版](../../../../policy/development_stages_support.md#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/18977)されました。デフォルトでは有効になっています。

{{< /history >}}

SASTの誤検出検出は、重大度が高いSAST脆弱性を自動的に分析して、潜在的な誤検出を特定します。これにより、実際のセキュリティリスクではない可能性が高い脆弱性にフラグを設定することで、脆弱性レポートのノイズが軽減されます。

SASTセキュリティスキャンを実行すると、GitLab Duoは各脆弱性を自動的に分析して、それが誤検出である可能性を判断します。検出は、[GitLabがサポートするSASTアナライザー](../../../application_security/sast/analyzers.md)からの脆弱性に対して利用可能です。

GitLab Duoの評価には以下が含まれます:

- **Confidence score**: その調査結果が誤検出である可能性を示す数値スコア。
- **Explanation**: 調査結果が真の陽性であるかどうかに関するコンテキスト推論。
- **Visual indicator**: 脆弱性レポートに評価を示すバッジ。

結果はAI分析に基づいており、セキュリティの専門家によるレビューが必要です。この機能を使用するには、アクティブなサブスクリプションがあるGitLab Duoが必要です。

## SASTの誤検出検出の実行 {#running-sast-false-positive-detection}

このフローは、次の場合に自動的に実行されます:

- SASTセキュリティスキャンがデフォルトブランチで正常に完了します。
- スキャンは、重大または高い重大度の脆弱性を検出します。
- GitLab Duo機能がプロジェクトまたはグループに対して有効になっている。

既存の脆弱性の分析を手動でトリガーすることもできます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 分析する脆弱性を選択します。
1. 右上隅で、**偽陽性のチェック**を選択します。

## 関連リンク {#related-links}

- [SASTの誤検出検出](../../../application_security/vulnerabilities/false_positive_detection.md)。
- [脆弱性レポート](../../../application_security/vulnerability_report/_index.md)。
- [SAST](../../../application_security/sast/_index.md)。

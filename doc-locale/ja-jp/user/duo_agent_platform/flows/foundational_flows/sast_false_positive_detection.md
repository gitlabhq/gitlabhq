---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SAST誤検出判定フロー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7で[機能フラグ](../../../../administration/feature_flags/_index.md)`enable_vulnerability_fp_detection`および`ai_experiment_sast_fp_detection`とともに[ベータ版](../../../../policy/development_stages_support.md#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/18977)されました。デフォルトでは有効になっています。
- GitLab 18.10で[一般提供](https://gitlab.com/groups/gitlab-org/-/work_items/19789)になりました。

{{< /history >}}

SAST誤検出判定フローは、SASTのクリティカルおよび高重大度の脆弱性を自動的に分析し、潜在的な誤検出を特定します。このプロセスにより、実際のセキュリティリスクではない可能性が高い脆弱性にフラグを立てることで、脆弱性レポートのノイズを低減します。

SASTセキュリティスキャンを実行すると、GitLab Duoは各脆弱性を自動的に分析し、それが誤検出である可能性を判定します。この検知機能は、[GitLabがサポートするSASTアナライザー](../../../application_security/sast/analyzers.md)から報告された脆弱性に対して利用できます。

GitLab Duoの評価には次の内容が含まれます:

- 信頼度スコア: その検出結果が誤検出である可能性を示す数値スコア。
- 説明: その検出結果が真の検出であるかどうかに関する、コンテキストに基づく判断理由。
- ビジュアルインジケーター: 脆弱性レポートには、評価を示すバッジが表示されます。

結果はAIによる分析に基づいており、セキュリティ担当者によるレビューが必要です。この機能を使用するには、アクティブなサブスクリプションが割り当てられたGitLab Duoが必要です。

クリックスルーデモについては、[SAST誤検出判定フロー](https://gitlab.navattic.com/sast-fp-detection-flow)を参照してください。

> [!note]
> メンションしたり、割り当てたり、サービスアカウントからのレビューをリクエストしたりして、このフローをトリガーすることはできません。セキュリティスキャンが完了すると、フローは自動的に実行されます。脆弱性レポートから、**誤検出をチェック**ボタンをクリックすることで、手動で実行することもできます。

<!-- Demo published on 2026-02-17 -->

## SAST誤検出判定の実行 {#run-sast-false-positive-detection}

このフローは、次の条件を満たした場合に自動的に実行されます:

- デフォルトブランチでSASTセキュリティスキャンが正常に完了した。
- スキャンによって、重大度が致命的または高い脆弱性が検出された。
- プロジェクトまたはグループでGitLab Duoの機能が有効になっている。

既存の脆弱性に対する分析を手動でトリガーすることもできます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 分析する脆弱性を選択します。
1. 右上隅で、**偽陽性のチェック**を選択します。

## 関連トピック {#related-topics}

- [SASTの誤検出判定](../../../application_security/vulnerabilities/false_positive_detection.md)。
- [脆弱性レポート](../../../application_security/vulnerability_report/_index.md)。
- [SAST](../../../application_security/sast/_index.md)。

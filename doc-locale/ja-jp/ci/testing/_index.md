---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDを使用してテストする
description: テストレポート、コード品質分析、およびセキュリティスキャンを生成して、マージリクエストに表示します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

フィーチャーブランチの変更をテストするには、GitLab CI/CDを使用します。テストレポートを表示したり、重要な情報へのリンクを[マージリクエスト](../../user/project/merge_requests/_index.md)に直接追加したりできます。

## テストと品質レポート {#testing-and-quality-reports}

次のレポートを生成できます:

| 機能                                                                                 | 説明 |
| --------------------------------------------------------------------------------------- | ----------- |
| [アクセシビリティテスト](accessibility_testing.md)                                       | 変更されたページのアクセシビリティ違反を検出します。 |
| [ブラウザパフォーマンステスト](browser_performance_testing.md)                           | コード変更がブラウザのパフォーマンスに与える影響を測定します。 |
| [コードカバレッジ](code_coverage/_index.md)                                                | テストカバレッジの結果、差分の行ごとのカバレッジ、および全体的なメトリクスを表示します。 |
| [コード品質](code_quality.md)                                                         | Code Climateでソースコード品質を分析します。 |
| [任意のジョブアーティファクトを表示する](../yaml/_index.md#artifactsexpose_as)                 | `artifacts:expose_as`を使用して、選択したジョブアーティファクトにリンクします。 |
| [フェイルファストテスト](fail_fast_testing.md)                                               | RSpecテストが失敗した場合、パイプラインを早期に停止させます。 |
| [ライセンススキャン](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | 依存関係ライセンスをスキャンして管理します。 |
| [ロードパフォーマンステスト](load_performance_testing.md)                                 | コード変更がサーバーのパフォーマンスに与える影響を測定します。 |
| [メトリクスレポート](metrics_reports.md)                                                   | メモリ使用量やパフォーマンスなどのカスタムメトリクスを追跡します。 |
| [単体テストレポート](unit_test_reports.md)                                               | ジョブログを確認しなくても、テスト結果を表示して失敗を特定できます。 |

## セキュリティレポート {#security-reports}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

プロジェクトを脆弱性についてスキャンすることにより、[セキュリティレポート](../../user/application_security/_index.md)を生成できます:

| 機能                                                                                       | 説明 |
| --------------------------------------------------------------------------------------------- | ----------- |
| [コンテナスキャン](../../user/application_security/container_scanning/_index.md)            | Dockerイメージに脆弱性がないかスキャンします。 |
| [動的アプリケーションセキュリティテスト (DAST)](../../user/application_security/dast/_index.md) | 実行中のWebアプリケーションに脆弱性がないかスキャンします。 |
| [依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)          | 依存関係に脆弱性がないかスキャンします。 |
| [静的アプリケーションセキュリティテスト（SAST）](../../user/application_security/sast/_index.md)  | ソースコードに脆弱性がないかスキャンします。 |

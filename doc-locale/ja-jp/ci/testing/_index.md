---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CDによるテスト
description: テストレポート、コード品質分析、およびセキュリティスキャンを生成し、マージリクエストに表示します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

フィーチャーブランチでの変更をテストするには、GitLab CI/CDを使用します。テストレポートを表示し、重要な情報を[マージリクエスト](../../user/project/merge_requests/_index.md)に直接リンクできます。

## テストと品質レポート {#testing-and-quality-reports}

次のレポートを生成できます:

| 機能                                                                                 | 説明 |
| --------------------------------------------------------------------------------------- | ----------- |
| [アクセシビリティテスト](accessibility_testing.md)                                       | 変更されたページにおけるアクセシビリティ違反を検出します。 |
| [ブラウザパフォーマンステスト](browser_performance_testing.md)                           | コードの変更によるブラウザのパフォーマンスへの影響を測定します。 |
| [コードカバレッジ](code_coverage/_index.md)                                                | テストカバレッジ結果、差分における行ごとのカバレッジ、および全体的なメトリクスを表示します。 |
| [コード品質](code_quality.md)                                                         | Code Climateでソースコード品質を分析します。 |
| [任意のジョブアーティファクトを表示する](../yaml/_index.md#artifactsexpose_as)                 | `artifacts:expose_as`を使用して、選択したジョブのアーティファクトにリンクします。 |
| [フェイルファストテスト](fail_fast_testing.md)                                               | RSpecテストが失敗したときに、パイプラインを早期に停止します。 |
| [ライセンススキャン](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | 依存ライセンスをスキャンおよび管理します。 |
| [ロードパフォーマンステスト](load_performance_testing.md)                                 | コードの変更によるサーバーパフォーマンスへの影響を測定します。 |
| [メトリクスレポート](metrics_reports.md)                                                   | メモリ使用量やパフォーマンスなどのカスタムメトリクスを追跡するします。 |
| [単体テストレポート](unit_test_reports.md)                                               | ジョブログを確認せずにテスト結果を表示し、失敗を特定します。 |

## セキュリティレポート {#security-reports}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

プロジェクトの脆弱性をスキャンすることで、[セキュリティレポート](../../user/application_security/_index.md)を生成できます:

| 機能                                                                                       | 説明 |
| --------------------------------------------------------------------------------------------- | ----------- |
| [コンテナスキャン](../../user/application_security/container_scanning/_index.md)            | Dockerイメージの脆弱性をスキャンします。 |
| [動的アプリケーションセキュリティテスト（DAST）](../../user/application_security/dast/_index.md) | 実行中のウェブアプリケーションの脆弱性をスキャンします。 |
| [依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)          | 依存関係の脆弱性をスキャンします。 |
| [静的アプリケーションセキュリティテスト（SAST）](../../user/application_security/sast/_index.md)  | ソースコードの脆弱性をスキャンします。 |

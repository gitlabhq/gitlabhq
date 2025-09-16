---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでテストし、マージリクエストでレポートを生成する
description: 単体テスト、インテグレーションテスト、テストレポート、カバレッジ、品質保証。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDを使用して、フィーチャーブランチに含まれる変更をテストします。また、[マージリクエスト](../../user/project/merge_requests/_index.md)から直接レポートを表示したり、重要な情報にリンクしたりすることもできます。

| 機能                                                                                 | 説明 |
| --------------------------------------------------------------------------------------- | ----------- |
| [アクセシビリティテスト](accessibility_testing.md)                                       | マージリクエストで変更されたページのA11y違反を自動的にレポートします。 |
| [ブラウザパフォーマンステスト](browser_performance_testing.md)                           | 保留中のコード変更によるブラウザパフォーマンスへの影響を迅速に判断します。 |
| [ロードパフォーマンステスト](load_performance_testing.md)                                 | 保留中のコード変更によるサーバーパフォーマンスへの影響を迅速に判断します。 |
| [コードカバレッジ](code_coverage/_index.md)                                                | マージリクエストでテストカバレッジの結果、ファイル差分の行ごとのカバレッジ、全体的なメトリクスを表示します。 |
| [Code Quality](code_quality.md)                                                         | [Code Climate](https://codeclimate.com/)アナライザーを使用してソースコード品質を分析し、Code Climateレポートをマージリクエストウィジェット領域に直接表示します。 |
| [任意のジョブアーティファクトを表示する](../yaml/_index.md#artifactsexpose_as)                 | `artifacts:expose_as`パラメータでCIパイプラインを設定し、マージリクエスト内の選択した[アーティファクト](../jobs/job_artifacts.md)に直接リンクします。 |
| [単体テストレポート](unit_test_reports.md)                                               | 単体テストレポートを使用するようにCIジョブを設定し、ジョブログ全体を確認しなくても失敗をより簡単かつ迅速に特定できるように、GitLabにマージリクエストに関するレポートを表示させます。 |
| [ライセンススキャン](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | 依存関係のライセンスを管理します。 |
| [メトリクスレポート](metrics_reports.md)                                                   | マージリクエストで、メモリ使用量やブランチ間のパフォーマンスなどのカスタムメトリクスを追跡します。 |
| [フェイルファストテスト](fail_fast_testing.md)                                               | RSpecテストスイートの一部を実行し、失敗したテストがあれば全体を実行する前にパイプラインを停止し、リソースを節約します。 |

## セキュリティレポート {#security-reports}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前述のレポートに加えて、GitLabはプロジェクトで検出された脆弱性をスキャンして報告することで、多くの種類の[セキュリティレポート](../../user/application_security/_index.md)を生成できます。

| 機能                                                                                      | 説明 |
|----------------------------------------------------------------------------------------------|-------------|
| [コンテナスキャン](../../user/application_security/container_scanning/_index.md)            | 既知の脆弱性について、Dockerイメージを分析します。 |
| [動的アプリケーションセキュリティテスト（DAST）](../../user/application_security/dast/_index.md) | 既知の脆弱性について、実行中のWebアプリケーションを分析します。 |
| [依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)          | 既知の脆弱性について、依存関係を分析します。 |
| [静的アプリケーションセキュリティテスト（SAST）](../../user/application_security/sast/_index.md)  | 既知の脆弱性について、ソースコードを分析します。 |

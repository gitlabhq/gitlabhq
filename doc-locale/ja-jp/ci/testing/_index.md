---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでテストし、マージリクエストでレポートを生成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDを使用して、フィーチャーブランチに含まれる変更をテストします。また、[マージリクエスト](../../user/project/merge_requests/_index.md)から直接レポートを表示したり、重要な情報にリンクしたりすることもできます。

| 機能                                                                                | 説明 |
| -------------------------------------------------------------------------------------- | ----------- |
| [アクセシビリティテスト](accessibility_testing.md)                                      | マージリクエストで変更されたページのA11y違反を自動的にレポートします。 |
| [ブラウザパフォーマンステスト](browser_performance_testing.md)                          | 保留中のコード変更のブラウザパフォーマンスへの影響を迅速に判断します。 |
| [ロードパフォーマンステスト](load_performance_testing.md)                                | 保留中のコード変更のサーバーパフォーマンスへの影響を迅速に判断します。 |
| [コードカバレッジ](code_coverage/_index.md)                                                      | マージリクエストでテストカバレッジの結果、ファイル差分の行ごとのカバレッジ、および全体的なメトリクスを表示します。 |
| [コード品質](code_quality.md)                                                        | [code climate](https://codeclimate.com/)アナライザーを使用してソースコード品質を分析し、code climateレポートをマージリクエストウィジェット領域に直接表示します。 |
| [Display arbitrary job artifacts(任意のジョブアーティファクトを表示する)](../yaml/_index.md#artifactsexpose_as)                 | `artifacts:expose_as`パラメータでCIパイプラインを構成して、マージリクエスト内の選択した[アーティファクト](../jobs/job_artifacts.md)に直接リンクします。 |
| [単体試験レポート](unit_test_reports.md)                                              | 単体試験レポートを使用するようにCIジョブを設定し、ジョブログ全体を確認しなくても失敗をより簡単かつ迅速に特定できるように、GitLabにマージリクエストに関するレポートを表示させます。 |
| [ライセンススキャン](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | 依存関係のライセンスを管理します。 |
| [メトリクスレポート](metrics_reports.md)                                                  | マージリクエストにメトリクスレポートを表示して、重要なメトリクスへの変更を迅速かつ簡単に特定できるようにします。 |
| [フェイルファストテスト](fail_fast_testing.md)                                              | RSpecテストスイートのサブセットを実行するため、失敗したテストは、テストのフルスイートの実行前にパイプラインを停止させ、リソースを節約します。 |

## セキュリティレポート

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

上記のレポートに加えて、GitLabは多くの種類の[セキュリティレポート](../../user/application_security/_index.md)を実行できます。プロジェクトで見つかった脆弱性をスキャンしてレポートすることで生成されます。

| 機能                                                                                      | 説明 |
|----------------------------------------------------------------------------------------------|-------------|
| [コンテナスキャン](../../user/application_security/container_scanning/_index.md)            | 既知の脆弱性についてDockerイメージを分析します。 |
| [動的アプリケーションセキュリティテスト（DAST）](../../user/application_security/dast/_index.md) | 既知の脆弱性について、実行中のWebアプリケーションを分析します。 |
| [依存関係スキャン](../../user/application_security/dependency_scanning/_index.md)          | 既知の脆弱性について依存関係を分析します。 |
| [静的アプリケーションセキュリティテスト (SAST)](../../user/application_security/sast/_index.md)  | 既知の脆弱性についてソースコードを分析します。 |

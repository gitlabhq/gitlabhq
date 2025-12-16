---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitHubインポートのモニタリング
description: "Prometheusのメトリクスを使用して、GitLab Self-ManagedインスタンスへのGitHubインポートをモニタリングします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitHubインポーターは、インポーターのヘルスと進捗のモニタリングに使用できるさまざまなPrometheusのメトリクスを公開します。

## インポートの所要時間 {#import-duration-times}

| 名前                                     | 型      |
|------------------------------------------|-----------|
| `github_importer_total_duration_seconds` | ヒストグラム |

このメトリクスは、インポートされたすべてのプロジェクトについて、（プロジェクトの作成からインポートプロセスが完了するまでの）プロジェクトのインポートに費やされた合計時間を秒単位で追跡します。プロジェクトの名前は、`project`ラベルに`namespace/name`(`gitlab-org/gitlab`など)の形式で保存されます。

## インポートされたプロジェクト数 {#number-of-imported-projects}

| 名前                                | 型    |
|-------------------------------------|---------|
| `github_importer_imported_projects` | カウンター |

このメトリクスは、時間の経過とともにインポートされたプロジェクトの総数を追跡します。このメトリクスは、ラベルを公開しません。

## GitHub APIコール数 {#number-of-github-api-calls}

| 名前                            | 型    |
|---------------------------------|---------|
| `github_importer_request_count` | カウンター |

このメトリクスは、すべてのプロジェクトについて、時間の経過とともに実行されたGitHub APIコールの総数を追跡します。このメトリクスは、ラベルを公開しません。

## レート制限エラー {#rate-limit-errors}

| 名前                              | 型    |
|-----------------------------------|---------|
| `github_importer_rate_limit_hits` | カウンター |

このメトリクスは、すべてのプロジェクトについて、GitHubのレート制限に達した回数を追跡します。このメトリクスは、ラベルを公開しません。

## インポートされたイシュー数 {#number-of-imported-issues}

| 名前                              | 型    |
|-----------------------------------|---------|
| `github_importer_imported_issues` | カウンター |

このメトリクスは、すべてのプロジェクトでインポートされたイシューの数を追跡します。

プロジェクトの名前は、`project`ラベルに`namespace/name`(`gitlab-org/gitlab`など)の形式で保存されます。

## インポートされたプルリクエスト数 {#number-of-imported-pull-requests}

| 名前                                     | 型    |
|------------------------------------------|---------|
| `github_importer_imported_pull_requests` | カウンター |

このメトリクスは、すべてのプロジェクトでインポートされたプルリクエストの数を追跡します。

プロジェクトの名前は、`project`ラベルに`namespace/name`(`gitlab-org/gitlab`など)の形式で保存されます。

## インポートされたコメント数 {#number-of-imported-comments}

| 名前                             | 型    |
|----------------------------------|---------|
| `github_importer_imported_notes` | カウンター |

このメトリクスは、すべてのプロジェクトでインポートされたコメントの数を追跡します。

プロジェクトの名前は、`project`ラベルに`namespace/name`(`gitlab-org/gitlab`など)の形式で保存されます。

## インポートされたプルリクエストのレビューコメント数 {#number-of-imported-pull-request-review-comments}

| 名前                                  | 型    |
|---------------------------------------|---------|
| `github_importer_imported_diff_notes` | カウンター |

このメトリクスは、すべてのプロジェクトでインポートされたコメントの数を追跡します。

プロジェクトの名前は、`project`ラベルに`namespace/name`(`gitlab-org/gitlab`など)の形式で保存されます。

## インポートされたリポジトリ数 {#number-of-imported-repositories}

| 名前                                    | 型    |
|-----------------------------------------|---------|
| `github_importer_imported_repositories` | カウンター |

このメトリクスは、すべてのプロジェクトでインポートされたリポジトリの数を追跡します。このメトリクスは、ラベルを公開しません。

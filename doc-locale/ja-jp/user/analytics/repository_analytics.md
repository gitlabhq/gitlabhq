---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトのリポジトリ分析
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リポジトリ分析は、[GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss)の一部であり、リポジトリを複製する権限を持つユーザーが利用できます。

リポジトリ分析を使用して、プロジェクトのGitリポジトリに関する情報を表示します。以下に例を示します:

- リポジトリのデフォルトブランチで使用されているプログラミング言語。
- 過去3か月間のコードカバレッジ統計。
- 過去1か月のコミット統計。
- 1か月の日、曜日、時間ごとのコミット数。

## チャートデータ処理 {#chart-data-processing}

チャート内のデータはキューに登録されます。バックグラウンドワーカーは、デフォルトブランチへの各コミットから10分後にチャートを更新します。GitLabのインストールとバックグラウンドジョブキューのサイズによっては、データの更新に時間がかかる場合があります。

## リポジトリ分析を表示 {#view-repository-analytics}

前提要件:

- 初期化されたGitリポジトリが必要です。
- デフォルトブランチ（`main`がデフォルト）に少なくとも1つのコミットが存在する必要があります。プロジェクトの[Wiki](../project/wiki/_index.md#track-wiki-events)のコミットは除外され、分析には含まれません。

プロジェクトのリポジトリ分析を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **分析** > **リポジトリ分析**を選択します。
1. カテゴリの詳細を表示するには、チャート内のバーにカーソルを合わせます。
1. 特定のブランチのコードカバレッジとコミットの統計を表示するには、**Commit statistics**（Commit statistics）の横にあるドロップダウンリストから、ブランチを選択します。

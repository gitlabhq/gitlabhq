---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトのインポートとエクスポートRakeタスク
description: 大規模プロジェクトのインポートとエクスポートのためのRakeタスク。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、Rakeタスクで[プロジェクトのインポートとエクスポート](../../user/project/settings/import_export.md)を提供します。

[互換性のある](../../user/project/settings/import_export.md#compatibility)GitLabインスタンスからのみインポートできます。

## 大規模なプロジェクトをインポートする {#import-large-projects}

大規模なGitLabプロジェクトのエクスポートをインポートするには、[Rakeタスク](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/import_export/import.rake)を使用します。

このタスクの一部として、直接アップロードも無効にします。これにより、巨大なアーカイブがGCSにアップロードされるのを防ぎ、アイドル状態のトランザクションタイムアウトを引き起こす可能性があります。

このタスクはターミナルから実行できます:

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `username`      | 文字列 | はい | ユーザー名 |
| `namespace_path` | 文字列 | はい | ネームスペースパス |
| `project_path` | 文字列 | はい | プロジェクトパス |
| `archive_path` | 文字列 | はい | エクスポートされたプロジェクトのtarballをインポートするパス |

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]" RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## 大規模なプロジェクトをエクスポート {#export-large-projects}

Rakeタスクを使用して、大規模なプロジェクトをエクスポートできます。

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `username`      | 文字列 | はい | ユーザー名 |
| `namespace_path` | 文字列 | はい | ネームスペースパス |
| `project_path` | 文字列 | はい | プロジェクト名 |
| `archive_path` | 文字列 | はい | エクスポートされたプロジェクトのtarballを保存するファイルへのパス |

```shell
gitlab-rake "gitlab:import_export:export[username, namespace_path, project_path, archive_path]"
```

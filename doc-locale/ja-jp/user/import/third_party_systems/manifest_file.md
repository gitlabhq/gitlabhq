---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: マニフェストファイルを使って移行する
description: "マニフェストファイルを使用して、GitLabにリポジトリをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Androidリポジトリ](https://android.googlesource.com/platform/manifest/+/6dc9af1b583e5c6a4ab9c38e3f5646efd8079b7d/default.xml)が使用するもののようなマニフェストファイルに基づいてGitリポジトリをインポートします。マニフェストを使用して、Androidオープンソースプロジェクト (AOSP) のような多くのリポジトリを持つプロジェクトをインポートします。

## 前提条件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [マニフェストインポートソース](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)が有効になっています。有効になっていない場合は、GitLab管理者に有効にするように依頼してください。マニフェストインポートソースは、GitLab.comではデフォルトで有効になっています。
- インポート先のターゲットトップレベルグループにおけるメンテナーまたはオーナーロール。インポート用に新しいトップレベルグループを作成することをお勧めします。

## マニフェストファイル形式 {#manifest-file-format}

マニフェストファイルは、サイズが1 MBまでのXMLファイルである必要があります。ファイルには以下が必要です:

- GitサーバーへのURLを含む`review`属性を持つ`remote`タグが1つ。
- `name`と`path`属性を持つ`project`タグ。

GitLabは、`remote`タグからのURLをプロジェクト名と組み合わせることにより、リポジトリへのURLをビルドします。パス属性は、GitLabでのプロジェクトパスを表すために使用されます。

例: 

```xml
<manifest>
  <remote review="https://android.googlesource.com/" />

  <project path="build/make" name="platform/build" />
  <project path="build/blueprint" name="platform/build/blueprint" />
</manifest>
```

この例では、GitLabは以下のプロジェクトを作成します:

| GitLab                                            | インポートURL |
|:--------------------------------------------------|:-----------|
| `https://gitlab.com/<group_name>/build/make`      | <https://android.googlesource.com/platform/build> |
| `https://gitlab.com/<group_name>/build/blueprint` | <https://android.googlesource.com/platform/build/blueprint> |

## リポジトリをインポートする {#import-the-repositories}

マニフェストファイルを使用してリポジトリをインポートするには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択します。
1. **マニフェストファイル**を選択します。
1. インポート先のグループを選択します。
1. 使用するXML形式のマニフェストファイルを選択します。
1. **利用可能なリポジトリのリスト**を選択します。マニフェストファイルに基づいてプロジェクトのリストが表示されたインポートステータスページにリダイレクトされます。
1. インポートするには:
   - すべてのプロジェクトを初めてインポートするには、**Import all repositories**を選択します。
   - 個別のプロジェクトを再度インポートするには、**再インポート**を選択します。新しい名前を指定し、もう一度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。

## 関連トピック {#related-topics}

- [インポートとエクスポートの設定](../../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../../administration/sidekiq/processing_specific_job_classes.md)。

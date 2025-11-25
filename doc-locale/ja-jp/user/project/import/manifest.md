---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: マニフェストファイルをアップロードして複数のリポジトリをインポートする
description: "マニフェストファイルを使用して、複数のリポジトリをGitLabにインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- プロジェクトを再インポートする機能が、GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23905)されました。

{{< /history >}}

GitLabでは、[Androidリポジトリ](https://android.googlesource.com/platform/manifest/+/2d6f081a3b05d8ef7a2b1b52b0d536b2b74feab4/default.xml)で使用されているものと同様のマニフェストファイルに基づいて、必要なすべてのGitリポジトリをインポートできます。マニフェストを使用して、Androidオープンソースプロジェクト（AOSP）のような多数のリポジトリを持つプロジェクトをインポートします。

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [マニフェストインポートソース](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。有効になっていない場合は、GitLab管理者に有効にするように依頼してください。マニフェストインポートソースは、GitLab.comではデフォルトで有効になっています。
- GitLabが動作するにはマニフェストインポートに[サブグループ](../../group/subgroups/_index.md)が必要なため、データベースにPostgreSQLを使用する必要があります。[データベース要件](../../../install/requirements.md#postgresql)の詳細をご覧ください。
- インポート先の宛先グループに対する、少なくともメンテナーロールが必要です。

## マニフェストの形式 {#manifest-format}

マニフェストは、最大1 MBのXMLファイルである必要があります。GitサーバーへのURLを含む`review`属性を持つ`remote`タグが1つ必要です。また、各`project`タグには`name`属性と`path`属性が必要です。GitLabは、`remote`タグのURLとプロジェクト名を組み合わせて、リポジトリへのURLをビルドします。パス属性は、GitLabのプロジェクトパスを表すために使用されます。

以下は、有効なマニフェストファイルの例です:

```xml
<manifest>
  <remote review="https://android.googlesource.com/" />

  <project path="build/make" name="platform/build" />
  <project path="build/blueprint" name="platform/build/blueprint" />
</manifest>
```

その結果、次のプロジェクトが作成されます:

| GitLab                                          | インポートURL                                                  |
|:------------------------------------------------|:------------------------------------------------------------|
| `https://gitlab.com/YOUR_GROUP/build/make`      | <https://android.googlesource.com/platform/build>           |
| `https://gitlab.com/YOUR_GROUP/build/blueprint` | <https://android.googlesource.com/platform/build/blueprint> |

## リポジトリをインポートします {#import-the-repositories}

インポートを開始するには、次の手順に従います:

1. GitLabのダッシュボードで、**新規プロジェクト**を選択します。
1. **プロジェクトのインポート**タブに切り替えます。
1. **マニフェストファイル**を選択します。
1. マニフェストXMLファイルをGitLabに提供します。
1. インポート先のグループを選択します（グループがない場合は、最初にグループを作成する必要があります）。
1. **利用可能なリポジトリのリスト**を選択します。この時点で、マニフェストファイルに基づくプロジェクトリストを含むインポートステータスページにリダイレクトされます。
1. インポートするには、次の手順に従います:
   - 初めてすべてのプロジェクトをインポートする場合: **Import all repositories**（すべてのリポジトリをインポートする）を選択します。
   - 個々のプロジェクトを再度インポートする場合: **再インポート**を選択します。新しい名前を指定し、もう一度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。

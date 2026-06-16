---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: FogBugzからの移行
description: "FogBugzからGitLabへの移行。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

あなたのFogBugzプロジェクトをGitLabにインポートします。

FogBugzインポーターは、すべてのケースとコメントを元のケース番号とタイムスタンプとともにインポートします。FogBugzユーザーをGitLabユーザーにマップできます。

## 前提条件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [FogBugzインポートソース](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)が有効になっています。有効になっていない場合は、GitLab管理者に有効にするように依頼してください。FogBugzインポートソースは、GitLab.comでデフォルトで有効になっています。
- インポート先の宛先グループにおけるメンテナーまたはオーナーロール。

## FogBugzからプロジェクトをインポート {#import-project-from-fogbugz}

FogBugzからプロジェクトをインポートするには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択します。
1. **FogBugz**を選択します。
1. FogBugzのURL、メールアドレス、パスワードを入力します。
1. FogBugzユーザーからGitLabユーザーへのマッピングを作成します。各FogBugzユーザーについて:
   - FogBugzアカウントをフルネームにマップし、GitLabアカウントにマッピングしない場合は、**GitLabユーザー**テキストボックスを空のままにします。このマッピングにより、ユーザーのフルネームがすべてのイシューとコメントのdescriptionに追加されますが、イシューとコメントはプロジェクト作成者に割り当てられます。
   - FogBugzアカウントをGitLabアカウントにマップするには、**GitLabユーザー**で、イシューとコメントを関連付けるGitLabユーザーを選択します。
1. すべてのユーザーがマッピングされたら、**次のステップに進みます**を選択します。
1. プロジェクトをインポートするには、以下の手順に従います: 
   - 初回: **インポート**を選択します。
   - 再度: **再インポート**を選択します。新しい名前を指定し、もう一度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。
1. インポートが完了したら、リンクを選択してプロジェクトダッシュボードに移動します。既存のリポジトリをプッシュするための手順に従ってください。

## 関連トピック {#related-topics}

- [インポートとエクスポートの設定](../../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../../administration/sidekiq/processing_specific_job_classes.md)。

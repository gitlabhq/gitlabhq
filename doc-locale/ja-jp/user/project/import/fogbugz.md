---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: FogBugzからGitLabへプロジェクトをインポート
description: "FogBugzからGitLabへプロジェクトをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- プロジェクトを再インポートする機能が、GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23905)されました。

{{< /history >}}

インポーターを使用すると、FogBugzプロジェクトをGitLab.comまたはGitLab Self-Managedにインポートできます。

インポーターは、すべてのケースとコメントを元のケース番号とタイムスタンプとともにインポートします。FogBugzユーザーをGitLabユーザーにマップすることもできます。

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [FogBugzのインポート元](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。有効になっていない場合は、GitLab管理者に有効にするよう依頼してください。The FogBugzインポートソースは、GitLab.comでデフォルトで有効になっています。
- インポート先の宛先グループに対する少なくともメンテナーロール。

## FogBugzからプロジェクトをインポート {#import-project-from-fogbugz}

FogBugzからプロジェクトをインポートするには:

1. GitLabにサインインします。
1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このボタンは右上隅にあります。
1. **プロジェクトのインポート**を選択します。
1. **FogBugz**を選択します。
1. FogBugzのURL、メールアドレス、パスワードを入力します。
1. FogBugzユーザーからGitLabユーザーへのマッピングを作成します。FogBugzの各ユーザー:
   - FogBugzアカウントをGitLabアカウントにマップせずに、氏名にマップするには、**GitLabユーザー**のテキストボックスを空のままにします。このマッピングにより、すべてのイシューとコメントの説明にユーザーの氏名が追加されますが、イシューとコメントはプロジェクト作成者に割り当てられます。
   - FogBugzアカウントをGitLabアカウントにマップするには、**GitLabユーザー**で、イシューとコメントを関連付けるGitLabユーザーを選択します。
1. すべてのユーザーがマップされたら、**次のステップに進みます**を選択します。
1. インポートするプロジェクトごとに、**インポート**を選択します。
1. インポートが完了したら、リンクを選択してプロジェクトのダッシュボードに移動します。指示に従って、既存のリポジトリをプッシュします。
1. プロジェクトをインポートするには:
   - 初回: **インポート**を選択します。
   - もう一度: **再インポート**を選択します。新しい名前を指定し、再度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。再プルすると、ソースプロジェクトの新しいコピーが作成されます。

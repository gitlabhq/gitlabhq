---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Giteaから移行する
description: "GiteaからGitLabへ移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381902)されました。GitLabは、存在しないネームスペースまたはグループを自動的に作成しなくなりました。また、ネームスペースまたはグループ名が使用されている場合、GitLabはユーザーの個人ネームスペースの使用にフォールバックしなくなりました。
- デベロッパーロールではなくメンテナーロールを必要とするように変更されました。この変更はGitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にもバックポートされています。
- GitLab 16.11でパスに`.`が含まれるプロジェクトをインポートする機能が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/434175)されました。
- 一部のインポート項目の**インポート済み**バッジは、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461208)されました。
- [ユーザーコントリビュートとメンバーシップの移行後マッピング](mapping.md)に、GitLab 17.8の[GitLab.comで変更](https://gitlab.com/groups/gitlab-org/-/epics/14667)されました。
- ユーザーコントリビュートとメンバーシップの移行後マッピングが、GitLab 17.8の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675)になりました。

{{< /history >}}

GiteaからGitLabにプロジェクトをインポートします。

Giteaインポーターは、Giteaのアイテムの一部をインポートします。

| Giteaのアイテム                    | インポート済み |
|:------------------------------|:---------|
| リポジトリの説明        | {{< yes >}} |
| Gitリポジトリデータ           | {{< yes >}} |
| イシュー                        | {{< yes >}} |
| プルリクエスト                 | {{< yes >}} |
| マイルストーン                    | {{< yes >}} |
| ラベル                        | {{< yes >}} |
| プルリクエストの差分ノート |          |

## インポーターのワークフロー {#importer-workflow}

Giteaインポーターは、GitLab.comとGitLab Self-Managedのユーザーコントリビュートの移行後マッピングをサポートしています。このインポーターは、マッピングの[代替の方法](#alternative-method-of-mapping)もサポートしています。

インポート時: 

- リポジトリの公開アクセスは保持されます。リポジトリがGiteaで非公開の場合、GitLabでも非公開として作成されます。
- インポートされたイシュー、マージリクエスト、コメントには、GitLabで**インポート済み**バッジが付いています。
- GiteaはOAuthプロバイダーではないため、作成者または担当者をGitLabインスタンス上のユーザーにマッピングできません。プロジェクト作成者（通常はインポートプロセスを開始したユーザー）が作成者として設定されます。イシューについては、元のGiteaの作成者を引き続き確認できます。

## 前提条件 {#prerequisites}

- Giteaバージョン1.0.0以降。
- [Giteaのインポート元](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。無効な場合は、GitLab管理者に有効にするように依頼してください。GitLab.comではデフォルトで有効になっています。
- メンテナーまたはオーナーロールをインポート先グループに設定する必要があります。

## Giteaリポジトリをインポートする {#import-your-gitea-repositories}

インポート中、パーソナルアクセストークンを作成し、Giteaに対する1回限りの認可を行い、GitLabがリポジトリにアクセスできるようにします。

Giteaリポジトリをインポートするには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. インポートの認可プロセスを開始するため、**Gitea**を選択します。
1. `https://your-gitea-instance/user/settings/applications`に移動します。`your-gitea-instance`をGiteaインスタンスのホストに置き換えてください。
1. **Generate New Token**を選択します。
1. トークンの説明を入力します。
1. **Generate Token**を選択します。
1. トークンハッシュをコピーします。
1. GitLabに戻り、そのトークンをGiteaインポーターに入力します。
1. **Giteaリポジトリの一覧**を選択し、GitLabがリポジトリ情報を読み取るまで待ちます。完了すると、GitLabにインポーターページが表示され、インポートするリポジトリを選択できます。ここで、Giteaリポジトリのインポートステータスを確認できます:

   - インポート中のものは開始ステータスになります。
   - すでに正常にインポート済みのものは緑色で完了ステータスになります。
   - まだインポートしていないものは、テーブルの右側に**インポート**が表示されます。
   - すでにインポート済みのものは、テーブルの右側に**再インポート**が表示されます。

1. Giteaリポジトリのインポートを完了するには:

   - すべてのGiteaプロジェクトを一度にインポートします。左上隅で、**すべてのプロジェクトをインポート**を選択します。
   - 名前でプロジェクトをフィルタリングして、選択したプロジェクトのみをインポートします。フィルターを適用している場合、**すべてのプロジェクトをインポート**は、選択したプロジェクトのみをインポートします。
   - 権限がある場合は、プロジェクトの別名や別のネームスペースを選択できます。

## 代替のマッピング方法 {#alternative-method-of-mapping}

GitLab 18.5以前では、`gitea_user_mapping`機能フラグを無効にして、インポートにおける代替のユーザーコントリビュートマッピング方法を使用できます。

> [!flag]
> この機能フラグによって、この機能の可用性が制御されます。この機能は推奨されておらず、次の場合は使用できません:
>
> - GitLab.comへの移行。
> - GitLab Self-ManagedおよびGitLab Dedicated 18.6以降への移行。
>
> このマッピング方法で見つかった問題が修正される可能性は低いです。代わりに、これらの制限がない[移行後マッピング方法](mapping.md)を使用してください。
>
> 詳細については、[イシュー512211](https://gitlab.com/gitlab-org/gitlab/-/work_items/512211)を参照してください。

この方法を使用すると、ユーザーコントリビュートは、デフォルトでプロジェクト作成者（通常はインポートプロセスを開始したユーザー）に割り当てられます。

## 関連トピック {#related-topics}

- [インポートとエクスポートの設定](../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../administration/sidekiq/processing_specific_job_classes.md)。

---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Giteaから移行する
description: "GiteaからGitLabにプロジェクトをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381902)されました。GitLabは、存在しないネームスペースまたはグループを自動的に作成しなくなりました。また、ネームスペースまたはグループ名が使用されている場合、GitLabはユーザーの個人ネームスペースの使用にフォールバックしなくなりました。
- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。
- パスに`.`が含まれるプロジェクトをインポートする機能がGitLab 16.11で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/434175)されました。
- 一部のインポート項目の**インポート済み**バッジは、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461208)されました。
- [GitLab.comでの変更](https://gitlab.com/groups/gitlab-org/-/epics/14667)により、GitLab 17.8で[移行後のユーザーコントリビュートおよびメンバーシップマッピング](mapping.md)になりました。
- 移行後のユーザーおよびコントリビュートメンバーシップマッピングが、GitLab 17.8で[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675)になりました。

{{< /history >}}

GiteaからGitLabにプロジェクトをインポートします。

Giteaインポーターは、Giteaからアイテムのサブセットをインポートします。

| Giteaアイテム                    | インポート済み |
|:------------------------------|:---------|
| リポジトリの説明        | {{< yes >}} |
| Gitリポジトリデータ           | {{< yes >}} |
| イシュー                        | {{< yes >}} |
| プルリクエスト                 | {{< yes >}} |
| マイルストーン                    | {{< yes >}} |
| ラベル                        | {{< yes >}} |
| プルリクエストからの差分注釈 |          |

## インポーターのワークフロー {#importer-workflow}

Giteaインポーターは、GitLab.comとGitLab Self-Managedのユーザーコントリビュートの移行後マッピングをサポートしています。このインポーターは、マッピングの[代替メソッド](#alternative-method-of-mapping)もサポートしています。

インポート時: 

- リポジトリの公開アクセスは保持されます。リポジトリがGiteaでプライベートの場合、GitLabでもプライベートとして作成されます。
- インポートされたイシュー、マージリクエスト、コメントには、GitLabに**インポート済み**バッジが付いています。
- GiteaはOAuthプロバイダーではないため、作成者またはアサイン先をGitLabインスタンス上のユーザーにマップできません。プロジェクト作成者（通常はインポートプロセスを開始したユーザー）が作成者として設定されます。イシューについては、元のGitea作成者をまだ確認できます。

## 前提条件 {#prerequisites}

- Giteaバージョン1.0.0以降。
- [Giteaのインポート元](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にするか、GitLab管理者に有効にするように依頼する必要があります。GitLab.comではデフォルトで有効になっています。
- インポート先のグループに対して、メンテナーロール以上。

## Giteaリポジトリをインポートする {#import-your-gitea-repositories}

インポート中、パーソナルアクセストークンを作成し、Giteaとの1回限りの認可を実行して、リポジトリへのGitLabアクセスを許可します。

Giteaリポジトリをインポートするには、次の手順に従います:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. インポートの認可プロセスを開始するには、**Gitea**を選択します。
1. `https://your-gitea-instance/user/settings/applications`に移動します。`your-gitea-instance`をGiteaインスタンスのホストに置き換えます。
1. **Generate New Token**を選択します。
1. トークンの説明を入力します。
1. **Generate Token**を選択します。
1. トークンハッシュをコピーします。
1. GitLabに戻り、Giteaインポーターにトークンを提供します。
1. **Giteaリポジトリの一覧**を選択し、GitLabがリポジトリの情報を読み取るまで待ちます。完了すると、GitLabは、インポートするリポジトリを選択するためのインポーターページを表示します。そこから、Giteaリポジトリのインポートステータスを表示できます:

   - インポートされているものは、開始ステータスを示します。
   - 既に正常にインポートされたものは、完了ステータスで緑色で表示されます。
   - まだインポートされていないものは、テーブルの右側に**インポート**があります。
   - 既にインポートされているものは、テーブルの右側に**再インポート**があります。

1. Giteaリポジトリのインポートを完了するには、次の操作を実行できます:

   - すべてのGiteaプロジェクトを一度にインポートします。左上隅で、**Import all projects**を選択します。
   - 名前でプロジェクトをフィルタリングして、選択したプロジェクトのみをインポートします。フィルターを適用すると、**Import all projects**が選択したプロジェクトのみをインポートします。
   - 特権がある場合は、プロジェクトに別の名前を選択し、別のネームスペースを選択します。

## マッピングの代替メソッド {#alternative-method-of-mapping}

GitLab 18.5以前では、`gitea_user_mapping`機能フラグを無効にして、インポートの代替ユーザーコントリビュートマッピングメソッドを使用できます。

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。この機能はお勧めしません。以下の場合は使用できません:

- GitLab.comへの移行。
- GitLab Self-ManagedおよびGitLab Dedicated 18.6以降への移行。

このマッピングメソッドで見つかった問題は修正される可能性は低いです。代わりに、これらの制限がない[移行後のメソッド](mapping.md)を使用してください。

詳細については、[issue 512211](https://gitlab.com/gitlab-org/gitlab/-/work_items/512211)を参照してください。

{{< /alert >}}

このメソッドを使用すると、ユーザーコントリビュートは、デフォルトでプロジェクト作成者（通常はインポートプロセスを開始したユーザー）に割り当てられます。

## 関連トピック {#related-topics}

- [インポート/エクスポート設定](../../administration/settings/import_and_export_settings.md)。
- [インポートのSidekiq設定](../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../administration/sidekiq/processing_specific_job_classes.md)。

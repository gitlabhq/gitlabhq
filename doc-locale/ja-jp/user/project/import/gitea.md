---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GiteaからGitLabにプロジェクトをインポートするる
description: "GiteaからGitLabにプロジェクトをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381902)されました。GitLabは、存在しないネームスペースまたはグループを自動的に作成しなくなりました。また、ネームスペースまたはグループ名が使用されている場合、GitLabはユーザーの個人ネームスペースの使用にフォールバックしなくなりました。
- パスに`.`を含むプロジェクトをインポートする機能が、GitLab 16.11で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/434175)されました。
- GitLab 17.2で、一部のインポートしたアイテムで**インポート済み**バッジが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461208)されました。

{{< /history >}}

GiteaからGitLabにプロジェクトをインポートします。

Giteaインポーターは以下をインポートできます:

- リポジトリの説明
- Gitリポジトリデータ
- イシュー
- プルリクエスト
- マイルストーン
- ラベル

インポート時は、:

- リポジトリの公開アクセスは保持されます。リポジトリがGiteaでプライベートな場合、GitLabでもプライベートとして作成されます。
- イシュー、マージリクエスト、コメントには、GitLabに**インポート済み**バッジが付いています。

## 既知の問題 {#known-issues}

- GiteaはOAuthプロバイダーではないため、作成者またはアサインされたユーザーをGitLabインスタンスのユーザーにマップできません。プロジェクト作成者（通常はインポートプロセスを開始したユーザー）は、作成者として設定されます。イシューについては、元のGiteaの作成者をまだ確認できます。
- Giteaインポーターは、プルリクエストから差分の注釈をインポートしません。詳細については、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/450973)を参照してください。

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- バージョン1.0.0以降。
- [Giteaインポート元](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。有効になっていない場合は、GitLab管理者に有効にするように依頼してください。 インポート元は、でデフォルトで有効になっています。
- インポート先のグループに対するメンテナーロールが少なくとも必要です。

## Giteaリポジトリをインポートする {#import-your-gitea-repositories}

Giteaインポーターページは、新しいプロジェクトを作成するときに表示されます。Giteaインポートを開始するには、次のようにします:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **Gitea**を選択して、インポート認可プロセスを開始します。

### パーソナルアクセストークンを使用して、リポジトリへのアクセスを認可する {#authorize-access-to-your-repositories-using-a-personal-access-token}

この方法では、Giteaとの1回限りの認可を実行して、GitLabにリポジトリへのアクセスを許可します:

1. `https://your-gitea-instance/user/settings/applications`に移動します（`your-gitea-instance`をGiteaインスタンスのホストに置き換えます）。
1. **Generate New Token**（新規トークンを生成）を選択します。
1. トークンの説明を入力します。
1. **トークンを生成**を選択します。
1. トークンハッシュをコピーします。
1. GitLabに戻り、トークンをGiteaインポーターに提供します。
1. **Giteaリポジトリの一覧**を選択し、GitLabがリポジトリの情報を読み取るまで待ちます。完了すると、GitLabはインポートするリポジトリを選択するためのインポーターページを表示します。

### インポートするリポジトリを選択する {#select-which-repositories-to-import}

Giteaリポジトリへのアクセスを認可すると、Giteaインポーターページにリダイレクトされます。

そこから、Giteaリポジトリのインポートステータスを表示できます:

- インポート中のものは、開始されたステータスを示します。
- すでに正常にインポートされたものは、完了ステータスで緑色で表示されます。
- まだインポートされていないものには、テーブルの右側に**インポート**が表示されます。
- すでにインポートされているものには、テーブルの右側に**再インポート**が表示されます。

次のこともできます:

- 左上隅で**Import all projects**（すべてのプロジェクトをインポートする）を選択して、すべてのGiteaプロジェクトを一度にインポートします。
- プロジェクトを名前でフィルタリングします。フィルターが適用されている場合、**Import all projects**（すべてのプロジェクトをインポートする）では、選択したプロジェクトのみがインポートされます。
- プロジェクトの別の名前と、権限がある場合は別のネームスペースを選択します。

## ユーザーコントリビューションとメンバーシップのマッピング {#user-contribution-and-membership-mapping}

{{< history >}}

- GitLab 17.8にて、[GitLab.comで変更](https://gitlab.com/groups/gitlab-org/-/epics/14667)され、[ユーザーコントリビューションとメンバーシップのマッピング](_index.md#user-contribution-and-membership-mapping)が行われました。
- GitLab 17.8の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675)。

{{< /history >}}

 インポーターは、 およびSelf-Managed向けのユーザーコントリビューションのマッピングの[改善された方式](_index.md#user-contribution-and-membership-mapping)を使用します。

### 古いユーザーコントリビューションマッピングメソッド {#old-method-of-user-contribution-mapping}

GitLab Self-ManagedおよびGitLab Dedicatedインスタンスへのインポートには、ユーザーコントリビューションマッピングの古いメソッドを使用できます。この方式を使用するには、`gitea_user_mapping`を無効にする必要があります。GitLab.comへのインポートでは、代わりに[改善されたメソッド](_index.md#user-contribution-and-membership-mapping)を使用する必要があります。

古いメソッドを使用すると、ユーザーのコントリビューションは、デフォルトでプロジェクト作成者（通常はインポートプロセスを開始したユーザー）に割り当てられます。

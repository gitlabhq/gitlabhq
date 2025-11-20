---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bitbucket Cloudからプロジェクトをインポートする
description: "プロジェクトをBitbucket CloudからGitLabにインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- Bitbucket Cloudからの並列インポートは、`bitbucket_parallel_importer`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用して、GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412614)されました。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/423530)になりました。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/423530)になりました。機能フラグ`bitbucket_parallel_importer`は削除されました。
- GitLab 17.2で、一部のインポートしたアイテムで**インポート済み**バッジが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461210)されました。

{{< /history >}}

プロジェクトをBitbucket CloudからGitLabにインポートします。

Bitbucketインポーターでインポートできるもの:

- リポジトリの説明
- Gitリポジトリデータ
- イシュー（コメントを含む）
- プルリクエスト（コメントを含む）
- マイルストーン
- Wiki
- ラベル
- マイルストーン
- LFSオブジェクト

Bitbucketインポーターでインポートできないもの:

- プルリクエストの承認
- 承認ルール

インポート時は、:

- プルリクエストとイシューへの参照は保持される。
- リポジトリのパブリックアクセスは保持されます。リポジトリがBitbucketでプライベートな場合、GitLabでもプライベートとして作成されます。
- インポートされたイシュー、マージリクエスト、コメントには、GitLabに**インポート済み**バッジが付いています。

{{< alert type="note" >}}

Bitbucket Cloudインポーターは、[Bitbucket.org](https://bitbucket.org/)でのみ動作します。Bitbucket Server（別名Stash）では動作しません。Bitbucket Serverからプロジェクトをインポートしようとしている場合は、[Bitbucket Serverインポーター](bitbucket_server.md)を使用してください。

{{< /alert >}}

イシュー、プルリクエスト、およびコメントがインポートされると、Bitbucketインポーターは作成者/assigneeのBitbucketのニックネームを使用し、GitLabで同じBitbucket IDを検索しようとします。一致しない場合、またはGitLabデータベースにユーザーが見つからない場合、プロジェクト作成者（ほとんどの場合、インポートプロセスを開始した現在の認証済みユーザー）が作成者として設定されますが、元のBitbucket作成者に関するイシューの参照は保持されます。

プルリクエストの場合:

- リポジトリにソースSHAが存在しない場合、インポーターはソースコミットをマージコミットSHAに設定しようとします。
- マージリクエストのassigneeは作成者に設定されます。レビュアーは、GitLabのBitbucket IDと一致するユーザー名で設定されます。
- GitLabのマージリクエストは、`opened`、`closed`、または`merged`のいずれかになります。

イシューの場合:

- ラベルは、Bitbucketのイシューのタイプに対応して追加されます。`bug`、`enhancement`、`proposal`、`task`のいずれか。
- Bitbucketのイシューが、`resolved`、`invalid`、`duplicate`、`wontfix`、または`closed`のいずれかであった場合、そのイシューはGitLabで閉じられます。

インポーターは、新しいネームスペース（グループ）が存在しない場合、またはネームスペースが取得されている場合は、インポートプロセスを開始したユーザーのネームスペースの下にリポジトリがインポートされます。

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [Bitbucket Cloudインテグレーション](../../../integration/bitbucket.md)を有効にする必要があります。そのインテグレーションが有効になっていない場合は、GitLab管理者に有効にするように依頼してください。Bitbucket Cloudインテグレーションは、GitLab.comではデフォルトで有効になっています。
- [Bitbucket Cloudインポート元](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。有効になっていない場合は、GitLab管理者に有効にするよう依頼してください。Bitbucket Cloudインポート元は、GitLab.comではデフォルトで有効になっています。
- インポート先の宛先グループに対する少なくともメンテナーロール。
- Bitbucketのプルリクエストには、同じソースプロジェクトと宛先プロジェクトが必要であり、プロジェクトのフォークからのものであってはなりません。そうでない場合、プルリクエストは空のマージリクエストとしてインポートされます。

### ユーザーマッピングされたコントリビュートの要件 {#requirements-for-user-mapped-contributions}

ユーザーのコントリビュートをマップするには、各ユーザーはプロジェクトのインポートの前に以下を完了する必要があります:

1. [Bitbucketアカウント設定](https://bitbucket.org/account/settings/)のユーザー名が、[Atlassianアカウント設定の公開名と一致することを確認します。](https://id.atlassian.com/manage-profile/profile-and-visibility)一致しない場合は、Bitbucketアカウント設定のユーザー名と一致するように、Atlassianアカウント設定の公開名を変更します。

1. [GitLabプロファイルサービスサインイン](https://gitlab.com/-/profile/account)でBitbucketアカウントを接続します。

## Bitbucketリポジトリをインポートする {#import-your-bitbucket-repositories}

{{< history >}}

- プロジェクトを再インポートする機能が、GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23905)されました。

{{< /history >}}

1. GitLabにサインインします。
1. 左側のサイドバーの上部にある**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **Bitbucket Cloud**を選択します。
1. Bitbucketにサインインし、**アクセス許可**を選択して、GitLabにBitbucketアカウントへのアクセスを許可します。
1. インポートするプロジェクトを選択するか、すべてのプロジェクトをインポートします。プロジェクトを名前でフィルタリングし、各プロジェクトのインポート先のネームスペースを選択できます。

1. プロジェクトをインポートするには:
   - 初回: **インポート**を選択します。
   - もう一度: **再インポート**を選択します。新しい名前を指定し、再度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。再プルすると、ソースプロジェクトの新しいコピーが作成されます。

### Bitbucket Cloudアプリのパスワードを生成する {#generate-a-bitbucket-cloud-app-password}

[GitLab REST API](../../../api/import.md#import-repository-from-bitbucket-cloud)を使用してBitbucket Cloudリポジトリをインポートする場合は、Bitbucket Cloudアプリのパスワードを作成する必要があります。

Bitbucket Cloudアプリのパスワードを生成するには:

1. <https://bitbucket.org/account/settings/>に移動します。
1. **Access Management**（アクセス管理）セクションで、**App passwords**（アプリのパスワード）を選択します。
1. **Create app password**（アプリのパスワードを作成）を選択します。
1. パスワード名を入力します。
1. 少なくとも次のアクセス許可を選択します:

   ```plaintext
   Account: Email, Read
   Projects: Read
   Repositories: Read
   Pull Requests: Read
   Issues: Read
   Wiki: Read and Write
   ```

1. **作成**を選択します。

## トラブルシューティング {#troubleshooting}

### Bitbucketアカウントが複数ある場合 {#if-you-have-more-than-one-bitbucket-account}

正しいアカウントにサインインしてください。

誤ったアカウントでインポートプロセスを誤って開始した場合は、次の手順に従ってください:

1. BitbucketアカウントへのGitLabアクセスを失効させ、基本的に次の手順でプロセスを逆にします: [Bitbucketリポジトリをインポートする](#import-your-bitbucket-repositories)。

1. Bitbucketアカウントからサインアウトします。前の手順からリンクされている手順に従います。

### 名前が一致していてもユーザーマッピングに失敗する {#user-mapping-fails-despite-matching-names}

[ユーザーマッピングが機能するためには](#requirements-for-user-mapped-contributions)、Bitbucketアカウント設定のユーザー名がAtlassianアカウント設定の公開名と一致する必要があります。これらの名前が一致していてもユーザーマッピングがまだ失敗する場合は、ユーザーが[GitLabプロファイルサービスサインイン](https://gitlab.com/-/profile/account)でBitbucketアカウントを接続した後で、Bitbucketユーザー名を変更した可能性があります。

これを修正するには、ユーザーはGitLabデータベース内のBitbucketの外部UIDが現在のBitbucketの公開名と一致することを確認し、不一致がある場合は再接続する必要があります:

1. [APIを使用して、現在認証されているユーザーを取得します](../../../api/users.md#as-a-regular-user-2)。

1. APIレスポンスでは、`identities`属性には、GitLabデータベースに存在するBitbucketアカウントが含まれています。`extern_uid`が現在のBitbucket公開名と一致しない場合、ユーザーは[GitLabプロファイルサービスサインイン](https://gitlab.com/-/profile/account)でBitbucketアカウントを再接続する必要があります。

1. 再接続後、ユーザーは再度APIを使用して、GitLabデータベース内の`extern_uid`が現在のBitbucket公開名と一致することを確認する必要があります。

インポーターは、[インポートされたプロジェクトを削除](../working_with_projects.md#delete-a-project)してから、再度インポートする必要があります。

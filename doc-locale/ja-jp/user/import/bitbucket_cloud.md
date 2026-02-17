---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bitbucket Cloudから移行する
description: "プロジェクトをBitbucket CloudからGitLabにインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。
- Bitbucket Cloudからの並列インポートは、GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412614)されました（`bitbucket_parallel_importer`という名前の[フラグ付き](../../administration/feature_flags/_index.md)）。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/423530)になりました。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/423530)になりました。機能フラグ`bitbucket_parallel_importer`は削除されました。
- 一部のインポート項目の**インポート済み**バッジは、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461210)されました。

{{< /history >}}

プロジェクトをBitbucket CloudからGitLabにインポートします。

Bitbucket Cloudインポーターは、Bitbucket Cloudからアイテムのサブセットをインポートします。

| Bitbucket Cloudのアイテム              | インポート済み |
|:----------------------------------|:---------|
| リポジトリの説明            | {{< yes >}} |
| Gitリポジトリデータ               | {{< yes >}} |
| イシュー（コメントを含む）        | {{< yes >}} |
| プルリクエスト（コメントを含む） | {{< yes >}} |
| マイルストーン                        | {{< yes >}} |
| Wiki                              | {{< yes >}} |
| ラベル                            | {{< yes >}} |
| マイルストーン                        | {{< yes >}} |
| LFSオブジェクト                       | {{< yes >}} |
| プルリクエストの承認            | {{< no >}} |
| 承認ルール                    | {{< no >}} |

## インポーターのワークフロー {#importer-workflow}

Bitbucket Cloudのアイテムをインポートすると、次のようになります:

- プルリクエストとイシューへの参照は保持される。
- リポジトリの公開アクセスは保持されます。リポジトリがBitbucket Cloudでプライベートな場合、GitLabではプライベートとして作成されます。
- インポートされたイシュー、マージリクエスト、コメントには、GitLabに**インポート済み**バッジが表示されます。

イシュー、プルリクエスト、コメントをインポートする場合、Bitbucket Cloudインポーターは次のようになります:

- 作成者/割り当て先のBitbucketのニックネームを使用し、GitLabで同じBitbucket固有識別子を見つけようとします。
- 一致しない場合、またはユーザーがGitLabデータベースに見つからない場合、プロジェクト作成者（通常はインポート処理を開始した現在の認証済みユーザー）を作成者として設定し、元のBitbucket作成者に関するイシューに関する参照を保持します。

プルリクエストの場合、インポーターは次のようになります:

- ソースSHAを使用し、リポジトリに存在しない場合は、ソースコミットをマージコミットSHAに設定しようとします。
- マージリクエストの割り当て先を作成者に設定し、GitLabのBitbucket固有識別子に一致するユーザー名を持つレビュアーを設定します。
- GitLabのマージリクエストを、`opened`、`closed`、または`merged`のいずれかに設定します。

イシューの場合、インポーターは次のようになります:

- Bitbucketのイシューのタイプに対応するラベルを追加します。`bug`、`enhancement`、`proposal`、または`task`のいずれか。
- Bitbucketのイシューが、`resolved`、`invalid`、`duplicate`、`wontfix`、または`closed`のいずれかであった場合、GitLabのイシューを閉じます。

Bitbucket Cloudインポーターは、新しいネームスペース（グループ）が存在しない場合に作成します。ネームスペースが使用されている場合、リポジトリは、インポート処理を開始したユーザーのネームスペースの下にインポートされます。

## 前提条件 {#prerequisites}

- [Bitbucket Cloudインテグレーション](../../integration/bitbucket.md)を有効にするか、GitLab管理者に有効にするように依頼する必要があります。GitLab.comでは、デフォルトで有効になっています。
- [Bitbucket Cloudインポート元](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にするか、GitLab管理者に有効にするように依頼する必要があります。GitLab.comでは、デフォルトで有効になっています。
- インポート先の宛先グループに対するメンテナーロール以上が必要です。
- Bitbucketのプルリクエストは、同じソースおよび宛先プロジェクトを持ち、プロジェクトのフォークからのものであってはなりません。そうでない場合、プルリクエストは空のマージリクエストとしてインポートされます。

ユーザーのコントリビュートをマップするには、各ユーザーがプロジェクトのインポートの前に以下を完了する必要があります:

1. [Bitbucketアカウント設定](https://bitbucket.org/account/settings/)のユーザー名が、[Atlassianアカウント設定](https://id.atlassian.com/manage-profile/profile-and-visibility)の公開名と一致することを確認します。一致しない場合は、Atlassianアカウント設定の公開名を変更して、Bitbucketアカウント設定のユーザー名と一致させます。
1. [GitLabプロファイルサービスサインイン](https://gitlab.com/-/profile/account)でBitbucketアカウントを接続します。

### Bitbucket Cloudアプリパスワードを生成する {#generate-a-bitbucket-cloud-app-password}

インポートAPIを使用してBitbucket Cloudリポジトリをインポートする場合は、Bitbucket Cloudアプリパスワードを作成する必要があります。

Bitbucket Cloudアプリパスワードを生成するには:

1. <https://bitbucket.org/account/settings/>に移動します。
1. **Access Management**セクションで、**App passwords**を選択します。
1. **Create app password**を選択します。
1. パスワード名を入力します。
1. 少なくとも次の権限を選択します:

   ```plaintext
   Account: Email, Read
   Projects: Read
   Repositories: Read
   Pull Requests: Read
   Issues: Read
   Wiki: Read and Write
   ```

1. **Create**を選択します。

## Bitbucket Cloudリポジトリをインポートする {#import-your-bitbucket-cloud-repositories}

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択します。
1. **Bitbucket Cloud**を選択します。
1. Bitbucketにサインインし、**アクセス許可**を選択して、GitLabがBitbucketアカウントにアクセスできるようにします。
1. インポートするプロジェクトを選択するか、すべてのプロジェクトをインポートします。名前でプロジェクトをフィルタリングし、各プロジェクトのインポート先のネームスペースを選択できます。
1. プロジェクトをインポートするには: 
   - 初めての場合は、**インポート**を選択します。
   - 2回目以降は、**再インポート**を選択します。新しい名前を指定し、もう一度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。

## トラブルシューティング {#troubleshooting}

これらのセクションには、Bitbucket Cloudからのインポート時に発生する可能性のある問題に対する解決策が含まれています。

### インポート処理で誤ったアカウントが使用された {#import-process-used-wrong-account}

正しいアカウントにサインインしてください。誤ったアカウントでインポート処理を誤って開始した場合は、次の手順に従ってください:

1. GitLabのBitbucketアカウントへのアクセスを失効させます。これは、[Bitbucket Cloudリポジトリをインポートした](#import-your-bitbucket-cloud-repositories)ときの処理を本質的に元に戻します。
1. Bitbucketアカウントからサインアウトし、[Bitbucket Cloudリポジトリを再度インポートします](#import-your-bitbucket-cloud-repositories)。

### 名前が一致してもユーザーマッピングが失敗する {#user-mapping-fails-despite-matching-names}

[ユーザーマッピングが機能するため](mapping.md)、Bitbucketアカウント設定のユーザー名が、Atlassianアカウント設定の公開名と一致する必要があります。

これらの名前が一致していてもユーザーマッピングが失敗する場合は、ユーザーが[GitLabプロファイルサービスサインイン](https://gitlab.com/-/profile/account)でBitbucketアカウントを接続した後で、Bitbucketのユーザー名を変更した可能性があります。

この問題を修正するには、ユーザーはGitLabデータベース内のBitbucket外部固有識別子が現在のBitbucketの公開名と一致することを確認し、不一致がある場合は再接続する必要があります:

1. [APIを使用して認証済みユーザーを取得します](../../api/users.md#retrieve-the-current-user)。
1. API応答では、`identities`属性には、GitLabデータベースに存在するBitbucketアカウントが含まれています。`extern_uid`が現在のBitbucketの公開名と一致しない場合、ユーザーは[GitLabプロファイルサービスサインイン](https://gitlab.com/-/profile/account)でBitbucketアカウントを再接続する必要があります。
1. 再接続後、ユーザーはAPIを再度使用して、GitLabデータベース内の`extern_uid`が現在のBitbucketの公開名と一致することを確認する必要があります。

プロジェクトをインポートしたユーザーは、[インポートされたプロジェクトを削除](../project/working_with_projects.md#delete-a-project)してから、再度インポートする必要があります。

## 関連トピック {#related-topics}

- [Bitbucket Serverから移行する](bitbucket_server.md)
- [インポートAPI](../../api/import.md)
- [インポートとエクスポートの設定](../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスを実行する](../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスを処理する](../../administration/sidekiq/processing_specific_job_classes.md)。

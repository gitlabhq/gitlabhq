---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bitbucket Serverからプロジェクトをインポートする
description: "プロジェクトをBitbucket ServerからGitLabにインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- プロジェクトを再インポートする機能が、GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23905)されました。
- レビュアーをインポートする機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416611)されました (GitLab 16.3)。
- プルリクエストの承認インポートのサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135256)されました (GitLab 16.7)。
- GitLab 17.2で、一部のインポートしたアイテムで**インポート済み**バッジが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461211)されました。

{{< /history >}}

プロジェクトをBitbucket ServerからGitLabにインポートします。

## インポート期間を見積もる {#estimating-import-duration}

すべてのBitbucketサーバーからのインポートは異なり、実行するインポートの期間に影響します。ただし、インポートにかかる時間を見積もるために、以下のデータで構成されるプロジェクトの場合、インポートに8時間かかる可能性があります:

- 13,000件のプルリクエスト
- 10,00個のブランチ
- 7,000個のタグ
- 500 GiBリポジトリ

## 前提要件 {#prerequisites}

{{< history >}}

- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。

{{< /history >}}

- [Bitbucket Serverのインポート元](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にする必要があります。有効になっていない場合は、GitLabの管理者に有効にするように依頼してください。Bitbucket Serverのインポート元は、GitLab.comでデフォルトで有効になっています。
- インポート先のGitLabグループに対する少なくともメンテナーロール。
- 管理者権限を持つBitbucket Serverの認証トークン。管理者アクセス権がないと、一部のデータは[インポートされません](https://gitlab.com/gitlab-org/gitlab/-/issues/446218)。

## リポジトリのインポート {#import-repositories}

Bitbucketのリポジトリをインポートするには、次の手順に従います:

1. GitLabにサインインします。
1. 左側のサイドバーの上部にある**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. **Bitbucketサーバー**を選択します。
1. Bitbucketにサインインし、GitLabにBitbucketアカウントへのアクセスを許可します。
1. インポートするプロジェクトを選択するか、すべてのプロジェクトをインポートします。プロジェクトを名前でフィルタリングし、各プロジェクトをインポートするネームスペースを選択できます。
1. プロジェクトをインポートするには:
   - 初回: **インポート**を選択します。
   - 再度: **再インポート**を選択します。新しい名前を指定し、もう一度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。

## インポートされるアイテム {#items-that-are-imported}

- リポジトリの説明
- Gitリポジトリデータ
- コミット、ユーザーメンション、レビュアー、およびマージイベントを含むプルリクエスト
- LFSオブジェクト

インポート時: 

- リポジトリの公開アクセスは保持されます。リポジトリがBitbucketで非公開の場合、GitLabでも非公開として作成されます。
- インポートされたマージリクエストとコメントには、GitLabに**インポート済み**バッジが付いています。

クローズまたはマージされたプルリクエストがインポートされると、リポジトリに存在しないコミットSHAがBitbucketサーバーからフェッチされ、プルリクエストにコミットが関連付けられていることが確認されます:

- ソースコミットSHAは、`refs/merge-requests/<iid>/head`形式の参照とともに保存されます。
- ターゲットコミットSHAは、`refs/keep-around/<SHA>`形式の参照とともに保存されます。

ソースコミットがリポジトリに存在しない場合、コミットメッセージにSHAを含むコミットが代わりに使用されます。

## インポートされないアイテム {#items-that-are-not-imported}

以下のアイテムはインポートされません:

- Markdownの添付ファイル
- タスクリスト
- 絵文字リアクション
- プルリクエストの承認
- プルリクエストの承認ルール

## インポートされるが変更されるアイテム {#items-that-are-imported-but-changed}

以下のアイテムは、インポート時に変更されます:

- GitLabでは、任意のコード行にコメントを追加することはできません。範囲外のBitbucketのコメントは、マージリクエストにコメントとして挿入されます。
- 複数のスレッドレベルが1つのスレッドに折りたたまれ、引用符が元のコメントの一部として追加されます。
- プロジェクトのフィルタリングでは、あいまい検索はサポートされていません。**starts with**（先頭が一致する）文字列または**full match**（完全一致）文字列のみがサポートされています。

## ユーザーコントリビューションとメンバーシップのマッピング {#user-contribution-and-membership-mapping}

{{< history >}}

- メールアドレスまたはユーザー名によるユーザーマッピングが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36885)されました (GitLab 13.4)。名前が`bitbucket_server_user_mapping_by_username`[のフラグ付き](../../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。
- GitLabユーザーへのユーザーメンションマッピングが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/433008)されました (GitLab 16.8)。
- GitLab 17.1では、メールアドレスでのみユーザーをマップするように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153041)されました。
- GitLab 17.8にて、[GitLab.comで変更](https://gitlab.com/groups/gitlab-org/-/epics/14667)され、[ユーザーコントリビューションとメンバーシップのマッピング](_index.md#user-contribution-and-membership-mapping)が行われました。
- GitLab 17.8の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675)。

{{< /history >}}

Bitbucketサーバーインポーターは、GitLab.comおよびGitLab Self-Managed向けのユーザーコントリビュートのマッピングの[改善されたメソッド](_index.md#user-contribution-and-membership-mapping)を使用します。

### 古いユーザーコントリビューションマッピングメソッド {#old-method-of-user-contribution-mapping}

GitLab Self-ManagedおよびGitLab Dedicatedインスタンスへのインポートには、ユーザーコントリビューションマッピングの古いメソッドを使用できます。このメソッドを使用するには、`bitbucket_server_user_mapping`を無効にする必要があります。GitLab.comへのインポートでは、代わりに[改善されたメソッド](_index.md#user-contribution-and-membership-mapping)を使用する必要があります。

古いメソッドを使用すると、インポーターはBitbucket ServerユーザーのメールアドレスとGitLabユーザーデータベース内の確認済みのメールアドレスを照合しようとします。そのようなユーザーが見つからない場合:

- 代わりにプロジェクト作成者が使用されます。インポーターは、元の作成者をマークするために、コメントにメモを追加します。
- プルリクエストのレビュアーの場合、レビュアーは割り当てられません。
- プルリクエストの承認者の場合、承認は追加されません。

`@mentions`プルリクエストの説明とメモのメールアドレスを使用して、Bitbucket Serverのユーザープロファイルと一致します。同じメールアドレスを持つユーザーがGitLabで見つからない場合、`@mention`は静的になります。ユーザーを一致させるには、プロジェクトへの読み取りアクセス権を少なくとも提供するGitLabロールが必要です。

プロジェクトが公開されている場合、GitLabはプロジェクトに招待されたユーザーのみを照合します。

インポーターは、新しいネームスペース (グループ) が存在しない場合に作成します。ネームスペースが使用されている場合、リポジトリは、インポートプロセスを開始したユーザーのネームスペースの下にインポートされます。

## トラブルシューティング {#troubleshooting}

### 一般 {#general}

GUIベースのインポートツールが機能しない場合は、以下を試すことができます:

- [GitLab Import API](../../../api/import.md#import-repository-from-bitbucket-server) Bitbucket Serverエンドポイントを使用します。
- [リポジトリのミラーリング](../repository/mirror/_index.md)を設定します。詳細なエラー出力が提供されます。

Bitbucket Cloudの[トラブルシューティングセクション](bitbucket.md#troubleshooting)を参照してください。

### LFSオブジェクトはインポートされません {#lfs-objects-not-imported}

プロジェクトのインポートが完了してもLFSオブジェクトをダウンロードまたはクローンできない場合は、特殊文字を含むパスワードまたはパーソナルアクセストークンを使用している可能性があります。詳しくは、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/337769)をご覧ください。

### 無効/未解決のホストアドレスが原因でインポートが失敗するか、インポートURLがブロックされます {#import-fails-due-to-invalidunresolved-host-address-or-the-import-url-is-blocked}

Bitbucketサーバーへの初期接続が成功したにもかかわらず、`Importing the project failed: Import URL is blocked`のようなエラーメッセージでプロジェクトのインポートが失敗した場合、Bitbucketサーバーまたはリバースプロキシが正しく構成されていない可能性があります。

この問題を解決するには、[Projects API](../../../api/projects.md)を使用して、新しく作成されたプロジェクトを確認し、プロジェクトの`import_url`値を見つけます。

この値は、インポートに使用するためにBitbucketサーバーによって提供されるURLを示します。このURLが公開的に解決できない場合、解決できないアドレスエラーが発生する可能性があります。

この問題を解決するには、プロキシサーバーがBitbucketでのURLの構築方法と使用方法に影響を与える可能性があるため、Bitbucketサーバーがすべてのプロキシサーバーを認識していることを確認してください。詳細については、[プロキシとセキュアなBitbucket](https://confluence.atlassian.com/bitbucketserver/proxy-and-secure-bitbucket-776640099.html)を参照してください。

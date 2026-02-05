---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bitbucket Serverから移行する
description: "Bitbucket ServerからGitLabにプロジェクトをインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- メールアドレスまたはユーザー名によるユーザーマッピングは、`bitbucket_server_user_mapping_by_username`[フラグとともに](../../administration/feature_flags/_index.md)GitLab 13.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36885)されました。デフォルトでは無効になっています。
- GitLab 16.0で導入され、GitLab 15.11.1およびGitLab 15.10.5にバックポートされたメンテナーロールの要件（デベロッパーロールではない）。
- プロジェクトを再インポートする機能は、GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23905)されました。
- レビュアーをインポートする機能は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416611)されました。
- プルリクエストの承認インポートのサポートは、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135256)されました。
- ユーザーメンションをGitLabユーザーにマッピングする機能は、GitLab 16.8で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/433008)されました。
- GitLab 17.1で、メールアドレスでのみユーザーをマッピングするように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153041)されました。
- 一部のインポート項目の**インポート済み**バッジは、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461211)されました。
- [GitLab.comでの変更点](https://gitlab.com/groups/gitlab-org/-/epics/14667)：GitLab 17.8の[移行後のユーザーコントリビューションとメンバーシップのマッピング](mapping.md)。
- GitLab 17.8で[GitLab.comとGitLab Self-Managedで有効になった](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675)移行後のユーザーとコントリビューションメンバーシップのマッピング。

{{< /history >}}

Bitbucket ServerからGitLabにプロジェクトをインポートします。

Bitbucket Serverインポーターは、Bitbucket Serverからアイテムのサブセットをインポートします。

| Bitbucket Serverのアイテム                                                         | インポート済み |
|:------------------------------------------------------------------------------|:---------|
| リポジトリの説明                                                        | {{< yes >}} |
| Gitリポジトリデータ                                                           | {{< yes >}} |
| コメント、ユーザーメンション、レビュアー、マージイベントを含むプルリクエスト | {{< yes >}} |
| LFSオブジェクト                                                                   | {{< yes >}} |
| コード上のコメント<sup>1</sup>                                                  | {{< yes >}} |
| スレッド<sup>2</sup>                                                           | {{< yes >}} |
| プロジェクトフィルター<sup>3</sup>                                                   | {{< yes >}} |
| Markdownの添付ファイル                                                       | {{< no >}} |
| タスクリスト                                                                    | {{< no >}} |
| 絵文字リアクション                                                               | {{< no >}} |
| プルリクエストの承認                                                        | {{< no >}} |
| プルリクエストの承認ルール                                              | {{< no >}} |

補足説明:

1. GitLabでは、任意のコード行へのコメントは許可されていません。範囲外のBitbucketコメントは、マージリクエストのコメントとして挿入されます。
1. 複数のスレッドレベルは1つのスレッドに統合され、引用は元のコメントの一部として追加されます。
1. プロジェクトのフィルタリングはあいまい検索をサポートしていません。**先頭が一致**する文字列または**完全一致**の文字列のみがサポートされています。

## インポーターのワークフロー {#importer-workflow}

Bitbucket Serverインポーターは、GitLab.comおよびGitLab Self-Managedのユーザーコントリビューションの[移行後のマッピング](mapping.md)をサポートしています。インポーターは、マッピングの[代替メソッド](#alternative-method-of-mapping)もサポートしています。

Bitbucket Serverのアイテムがインポートされる場合:

- リポジトリの公開アクセスは保持されます。Bitbucketでリポジトリが非公開の場合、GitLabでは非公開として作成されます。
- インポートされたマージリクエストとコメントには、GitLabで**インポート済み**バッジが付いています。

クローズまたはマージされたプルリクエストがインポートされると、リポジトリに存在しないコミットSHAがBitbucket Serverからフェッチされ、プルリクエストがコミットに関連付けられるようになります:

- ソースコミットSHAは、`refs/merge-requests/<iid>/head`形式で参照として保存されます。
- ターゲットコミットSHAは、`refs/keep-around/<SHA>`形式で参照として保存されます。

ソースコミットがリポジトリに存在しない場合、代わりにコミットメッセージにSHAを含むコミットが使用されます。

## インポート時間を見積もる {#estimating-import-duration}

Bitbucket Serverからのインポートはそれぞれ異なるため、実行するインポートの所要時間に影響します。ただし、インポート時間を見積もる際の参考として、以下のデータで構成されるプロジェクトのインポートには約8時間かかる可能性があります: 

- 13,000件のプルリクエスト
- 7,000個のタグ
- 500 GiBのリポジトリ

## 前提条件 {#prerequisites}

- Bitbucket Serverは、GitLabインスタンスからアクセスできる必要があります。Bitbucket ServerのURLは、GitLabが実行されているネットワーク上で、パブリックに解決できるか、アクセスできる必要があります。
- [Bitbucket Serverインポート元](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を有効にするか、GitLab管理者に有効にするように依頼する必要があります。GitLab.comでは、デフォルトで有効になっています。
- インポート先のグループに対して、メンテナーロール以上。
- 管理者アクセス権を持つBitbucket Server認証トークン。管理者アクセス権がない場合、一部のデータは[インポートされません](https://gitlab.com/gitlab-org/gitlab/-/issues/446218)。

## Bitbucket Serverリポジトリをインポートする {#import-your-bitbucket-server-repositories}

Bitbucket Serverリポジトリをインポートするには:

1. GitLabにサインインします。
1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択します。
1. **Bitbucket Server**を選択します。
1. Bitbucketにサインインし、GitLabにBitbucketアカウントへのアクセスを許可します。
1. インポートするプロジェクトを選択するか、すべてのプロジェクトをインポートします。プロジェクトを名前でフィルタリングし、各プロジェクトをインポートするネームスペースを選択できます。
1. プロジェクトをインポートするには: 
   - 初めての場合は、**インポート**を選択します。
   - 2回目以降は、**再インポート**を選択します。新しい名前を指定し、もう一度**再インポート**を選択します。再インポートすると、ソースプロジェクトの新しいコピーが作成されます。

## マッピングの代替メソッド {#alternative-method-of-mapping}

`bitbucket_server_user_mapping`機能フラグを無効にすると、代替のユーザーコントリビューションマッピングメソッドをインポートに使用できます。

GitLab.comにインポートするには、代わりに[移行後の方法](mapping.md)を使用する必要があります。

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。この機能フラグはお勧めしません。移行をGitLab.comに移行する場合は使用できません。このマッピング方法で見つかった問題は修正されない可能性があります。代わりに、これらの制限がない[移行後の方法](mapping.md)を使用してください。

詳細については、[イシュー512213](https://gitlab.com/gitlab-org/gitlab/-/work_items/512213)を参照してください。

{{< /alert >}}

代替メソッドを使用すると、インポーターはBitbucket Serverユーザーのメールアドレスを、GitLabユーザーデータベース内の確認済みのメールアドレスと照合しようとします。該当するユーザーが見つからない場合: 

- 代わりにプロジェクト作成者が使用されます。インポーターは、元の作成者を示すメモをコメントに追加します。
- プルリクエストのレビュアーについては、レビュアーは割り当てられません。
- プルリクエストの承認者については、承認は追加されません。

プルリクエストの説明とメモのメンションは、ユーザーのメールアドレスを使用して、Bitbucket Serverのユーザープロファイルと照合されます。同じメールアドレスを持つユーザーがGitLabで見つからない場合、メンションは静的になります。ユーザーが照合されるには、プロジェクトへの読み取りアクセスを提供するGitLabロール以上を持っている必要があります。

プロジェクトが公開されている場合、GitLabはプロジェクトに招待されたユーザーのみを照合します。

インポーターは、新しいネームスペース（グループ）が存在しない場合に作成します。ネームスペースが使用されている場合、リポジトリはインポートプロセスを開始したユーザーのネームスペースの下にインポートされます。

## トラブルシューティング {#troubleshooting}

次のセクションでは、発生する可能性のある問題の解決策について説明します。

### 一般 {#general}

GUIベースのインポートツールが機能しない場合は、以下を試すことができます: 

- [GitLabインポートAPI](../../api/import.md#import-repository-from-bitbucket-server)のBitbucket Serverエンドポイントを使用する。
- [リポジトリのミラーリング](../project/repository/mirror/_index.md)をセットアップする。詳細なエラー出力が提供されます。

Bitbucket Cloudの[トラブルシューティングセクション](bitbucket_cloud.md#troubleshooting)を参照してください。

### LFSオブジェクトがインポートされない {#lfs-objects-not-imported}

プロジェクトのインポートが完了してもLFSオブジェクトをダウンロードまたはクローンできない場合は、特殊文字を含むパスワードまたはパーソナルアクセストークンを使用している可能性があります。詳細については、[こちらのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/337769)を参照してください。

### 無効/未解決のホストアドレスが原因でインポートが失敗する、またはインポートURLがブロックされる {#import-fails-due-to-invalidunresolved-host-address-or-the-import-url-is-blocked}

Bitbucketサーバーへの初期接続が成功したにもかかわらず、`Importing the project failed: Import URL is blocked`のようなエラーメッセージでプロジェクトのインポートが失敗する場合、Bitbucketサーバーまたはリバースプロキシが正しく設定されていない可能性があります。

この問題を解決するには、[プロジェクトAPI](../../api/projects.md)を使用して新しく作成されたプロジェクトを確認し、プロジェクトの`import_url`値を見つけます。

この値は、インポートに使用するためにBitbucketサーバーから提供されるURLを示します。このURLが公開的に解決できない場合、解決できないアドレスエラーが発生する可能性があります。

この問題を修正するには、プロキシサーバーがURLの構築と使用に影響を与える可能性があるため、Bitbucketサーバーがプロキシサーバーを認識していることを確認してください。詳細については、[Proxy and secure Bitbucket](https://confluence.atlassian.com/bitbucketserver/proxy-and-secure-bitbucket-776640099.html)を参照してください。

## 関連トピック {#related-topics}

- [Bitbucket Cloudから移行する](bitbucket_cloud.md)。
- [インポートとエクスポートの設定](../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスを実行する](../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスを処理する](../../administration/sidekiq/processing_specific_job_classes.md)。

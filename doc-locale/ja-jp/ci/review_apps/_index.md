---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: レビューアプリケーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

レビューアプリケーションは、製品の変更を掲載するための環境を提供するコラボレーションツールです。

{{< alert type="note" >}}

Kubernetesクラスターがある場合、[Auto DevOps](../../topics/autodevops/_index.md)を使用して、アプリケーションでこの機能を自動化できます。

{{< /alert >}}

レビューアプリケーション:

- マージリクエストの動的環境を起動することにより、フィーチャーブランチで行われた変更の自動ライブプレビューを提供します。
- デザイナーと製品マネージャーがブランチをチェックアウトし、変更をサンドボックス環境で実行しなくても、変更を確認できるようにします。
- [GitLab DevOpsライフサイクル](https://about.gitlab.com/stages-devops-lifecycle/)と完全に統合されています。
- 任意の場所に変更をデプロイできます。

![レビューアプリケーションから本番環境につながるmasterブランチとトピックブランチ](img/continuous-delivery-review-apps_v11_4.svg)

前の例では:

- コミットが`topic branch`にプッシュされるたびに、レビューアプリケーションがビルドされます。
- レビュアーは、3回目のレビューに合格する前に、2回のレビューに失敗します。
- レビューに合格すると、`topic branch`はデフォルトブランチにマージされ、stagingステージにデプロイされます。
- stagingステージで承認された後、デフォルトブランチにマージされた変更は本番環境にデプロイされます。

## レビューアプリケーションの仕組み

レビューアプリケーションは、ブランチと[環境](../environments/_index.md)のマッピングです。レビューアプリケーションへのアクセスは、ブランチに関連する[マージリクエスト](../../user/project/merge_requests/_index.md)でリンクとして利用できます。

次に、環境が動的に設定されたマージリクエストの例を示します。

![レビューアプリケーションへのリンクを含むマージ後の結果パイプラインの状態](img/review_apps_preview_in_mr_v16_0.png)

この例では、ブランチは次のように処理されました。

- 正常にビルドされました。
- **アプリを表示**を選択してアクセスできる動的環境にデプロイされました。

ワークフローにレビューアプリケーションを追加したら、分岐したGitフローに従います。つまり、次のようなフローになります。

1. ブランチをプッシュし、動的環境ジョブの`script`定義に基づいてRunnerにレビューアプリケーションをデプロイさせます。
1. Runnerがウェブアプリケーションをビルドしてデプロイするのを待ちます。
1. 変更をライブで表示するには、ブランチに関連するマージリクエストのリンクを選択します。

## レビューアプリケーションを設定する

レビューアプリケーションは[動的環境](../environments/_index.md#create-a-dynamic-environment)にビルドされ、ブランチごとに新しい環境を動的に作成できます。

レビューアプリケーションを設定するプロセスは次のとおりです。

1. レビューアプリケーションをホストおよびデプロイするためのインフラストラクチャを設定します（以下の[例](#review-apps-examples)を確認してください）。
1. デプロイを実行するRunnerを[インストール](https://docs.gitlab.com/runner/install/)して[設定](https://docs.gitlab.com/runner/commands/)します。
1. 動的環境を作成し、ブランチでのみ実行するように制限するために、`.gitlab-ci.yml`で[定義済みのCI/CD変数](../variables/_index.md)`${CI_COMMIT_REF_SLUG}`を使用するジョブを設定します。または、プロジェクトの[レビューアプリケーションを有効にする](#enable-review-apps-button)ことで、このジョブのYAMLテンプレートを取得できます。
1. 必要に応じて、レビューアプリケーションを[手動で停止](../environments/_index.md#stopping-an-environment)するジョブを設定します。

### レビューアプリケーションを有効にするボタン

プロジェクトのレビューアプリケーションを設定する場合、上記のように、`.gitlab-ci.yml`ファイルに新しいジョブを追加します。これを容易にするため、Kubernetesを使用している場合は、**レビューアプリケーションを有効にする**を選択すると、開始点としてコピーして`.gitlab-ci.yml`に貼り付けることができるテンプレートコードブロックが表示されます。

前提要件:

- プロジェクトのデベロッパーロール以上が必要です。

レビューアプリケーションテンプレートを使用するには:

1. 左側のサイドバーで**検索または移動**を選択し、レビューアプリケーションジョブを作成するプロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. **レビューアプリケーションを有効にする**を選択します。
1. ダイアログの指示に従います。必要に応じて、用意されている`.gitlab-ci.yml`テンプレートを編集できます。

## レビューアプリケーションの自動停止

指定された期間が過ぎた後に[レビューアプリケーションの環境を期限切れにして自動停止するように設定する](../environments/_index.md#stop-an-environment-after-a-certain-time-period)方法を参照してください。

## レビューアプリケーションの例

以下に、レビューアプリケーションの設定を示すプロジェクトの例を紹介します。

| プロジェクト                                                                                 | 設定ファイル |
| --------------------------------------------------------------------------------------- | ------------------ |
| [NGINX](https://gitlab.com/gitlab-examples/review-apps-nginx)                           | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-examples/review-apps-nginx/-/blob/b9c1f6a8a7a0dfd9c8784cbf233c0a7b6a28ff27/.gitlab-ci.yml#L20) |
| [OpenShift](https://gitlab.com/gitlab-examples/review-apps-openshift)                   | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-examples/review-apps-openshift/-/blob/82ebd572334793deef2d5ddc379f38942f3488be/.gitlab-ci.yml#L42) |
| [HashiCorp Nomad](https://gitlab.com/gitlab-examples/review-apps-nomad)                 | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-examples/review-apps-nomad/-/blob/ca372c778be7aaed5e82d3be24e98c3f10a465af/.gitlab-ci.yml#L110) |
| [GitLabドキュメント](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com) | [`build.gitlab-ci.yml`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/bdbf11814428a06e82d7b712c72b5cb53c750f29/.gitlab/ci/build.gitlab-ci.yml#L73-76) |
| [`https://about.gitlab.com/`](https://gitlab.com/gitlab-com/www-gitlab-com/)            | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/6ffcdc3cb9af2abed490cbe5b7417df3e83cd76c/.gitlab-ci.yml#L332) |
| [GitLabインサイト](https://gitlab.com/gitlab-org/gitlab-insights/)                       | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab-insights/-/blob/9e63f44ac2a5a4defc965d0d61d411a768e20546/.gitlab-ci.yml#L234) |

レビューアプリケーションのその他の例:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[Cloud Native Development with GitLab（GitLabを使用したクラウドネイティブ開発（英語））](https://www.youtube.com/watch?v=jfIyQEwrocw)
- [Android向けのレビューアプリケーション](https://about.gitlab.com/blog/2020/05/06/how-to-create-review-apps-for-android-with-gitlab-fastlane-and-appetize-dot-io/)

## ルートマップ

ルートマップを使用すると、レビューアプリケーション用に定義された[環境](../environments/_index.md)でソースファイルから公開ページに直接移動できます。

設定が完了すると、マージリクエストウィジェットのレビューアプリケーションリンクから変更されたページに直接移動できるため、提案された変更をより簡単かつ迅速にプレビューできます。

ルートマップを設定するには、ルートマップを使用してリポジトリ内のファイルのパスがウェブサイト上のページのパスにどのようにマップされるかをGitLabに指示します。ルートマップを設定すると、**表示**ボタンが表示されます。これらのボタンを選択して、マージリクエストから変更されたページに直接移動します。

ルートマップを設定するには、`.gitlab/route-map.yml`でリポジトリ内のファイルを追加します。これには、`source`パス（リポジトリ内）を`public`パス（ウェブサイト上）にマップするYAML配列が含まれています。

### ルートマップの例

以下は、[GitLabウェブサイト](https://about.gitlab.com)のビルドに使用される静的サイトジェネレーター（SSG）で、[GitLab.comのプロジェクト](https://gitlab.com/gitlab-com/www-gitlab-com)からデプロイされた[Middleman](https://middlemanapp.com)のルートマップの例です。

```yaml
# Team data
- source: 'data/team.yml'  # data/team.yml
  public: 'team/'  # team/

# Blogposts
- source: /source\/posts\/([0-9]{4})-([0-9]{2})-([0-9]{2})-(.+?)\..*/  # source/posts/2017-01-30-around-the-world-in-6-releases.html.md.erb
  public: '\1/\2/\3/\4/'  # 2017/01/30/around-the-world-in-6-releases/

# HTML files
- source: /source\/(.+?\.html).*/  # source/index.html.haml
  public: '\1'  # index.html

# Other files
- source: /source\/(.*)/  # source/images/blogimages/around-the-world-in-6-releases-cover.png
  public: '\1'  # images/blogimages/around-the-world-in-6-releases-cover.png
```

マッピングはルートYAML配列のエントリとして定義され、`-`プレフィックスで識別されます。エントリ内には、次の2つのキーを持つハッシュマップがあります。

- `source`
  - 完全一致の場合は、`'`で始まり、`'`で終わる文字列。
  - パターン一致の場合は、`/`で始まり、`/`で終わる正規表現。
    - 正規表現は、ソースパス全体と一致する必要があります-`^`アンカーと`$`アンカーが暗示されています。
    - `public`パスで参照できる`()`で示されるキャプチャグループを含めることができます。
    - スラッシュ（`/`）は、`\/`としてエスケープできますが、必須ではありません。
    - リテラルピリオド（`.`）は`\.`としてエスケープする必要があります。
- `public`、`'`で始まり、`'`で終わる文字列。
  - `\N`式を含めて、`\1`で始まる発生順に`source`正規表現のキャプチャグループを参照できます。

ソースパスのパブリックパスは、それに一致する最初の`source`式を見つけ、対応する`public`パスを返し、該当する場合は`\N`式を`()`キャプチャグループの値に置き換えることによって決定されます。

上記の例では、マッピングが定義順に評価されるという事実を使用して、`source/index.html.haml`が`/source\/(.*)/`ではなく`/source\/(.+?\.html).*/`と一致するようにし、`index.html.haml`ではなく`index.html`のパブリックパスが返されるようにします。

ルートマッピングを設定すると、次の場所で有効になります。

- マージリクエストウィジェット内:
  - **アプリを表示**ボタンをクリックすると、`.gitlab-ci.yml`ファイルに設定された環境URLに移動します。
  - リストには、ルートマップから一致した最初の5つの項目が表示されますが、一致する項目が6件以上ある場合はフィルタリングできます。

    ![一致した項目とフィルターバーを含むマージリクエストウィジェット](img/view_on_mr_widget_v11_5.png)

- 比較またはコミットの差分で、ファイルの横にある**表示**（{{< icon name="external-link" >}}）を選択します。

- blobファイルビューで、ファイルの横にある**表示**（{{< icon name="external-link" >}}）を選択します。

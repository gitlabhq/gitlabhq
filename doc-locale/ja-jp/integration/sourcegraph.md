---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sourcegraph
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

GitLab.comでは、この機能はパブリックプロジェクトでのみ利用可能です。

{{< /alert >}}

[Sourcegraph](https://sourcegraph.com)は、GitLabユーザーインターフェースでコードインテリジェンス機能を提供します。有効にすると、参加プロジェクトは、これらのコードインテリジェンスのポップオーバーをこれらのコードビューに表示します:

- マージリクエストの差分
- コミットビュー
- ファイルビュー

これらのビューのいずれかにアクセスすると、コード参照にカーソルを合わせると、次のポップオーバーが表示されます:

- この参照がどのように定義されたかの詳細。
- **定義へ移動**: この参照が定義されているコード行に移動します。
- **Find references**（参照を検索）: 設定されたSourcegraphインスタンスに移動し、強調表示されたコードへの参照のリストを表示します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、ビデオ[Sourcegraphの新しいGitLabネイティブインテグレーション](https://www.youtube.com/watch?v=LjVxkt4_sEA)をご覧ください。
<!-- Video published on 2019-11-12 -->

詳細については、[epic 2201](https://gitlab.com/groups/gitlab-org/-/epics/2201)を参照してください。

## GitLab Self-Managedのセットアップ {#set-up-for-gitlab-self-managed}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件: 

- Sourcegraphインスタンスが、外部サービスとしてGitLabインスタンスで[設定され、実行されている](https://sourcegraph.com/docs/admin)必要があります。
- SourcegraphインスタンスがGitLabへのHTTPS接続を使用している場合は、Sourcegraphインスタンスの[HTTPSを設定](https://sourcegraph.com/docs/admin/http_https_configuration)する必要があります。

Sourcegraph内:

1. **Site admin**（管理者エリア）に移動します。
1. オプション。[GitLab外部サービスを設定する](https://sourcegraph.com/docs/admin/code_hosts/gitlab)。GitLabリポジトリがSourcegraphで既に検索可能な場合は、このステップをスキップできます。
1. テストクエリを実行して、Sourcegraphインスタンス内のGitLabからリポジトリを検索できることを確認します。
1. Sourcegraph設定の[`corsOrigin`設定](https://sourcegraph.com/docs/admin/config/site_config#corsOrigin)にGitLabインスタンスのURLを追加します。

次に、Sourcegraphインスタンスに接続するようにGitLabインスタンスを設定します。

### SourcegraphとGitLabインスタンスを連携する {#configure-your-gitlab-instance-with-sourcegraph}

前提要件: 

- 管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **Sourcegraph**を展開します。
1. **Sourcegraphを有効にする**を選択します。
1. オプション。**非公開および内部プロジェクトのブロック**を選択します。
1. **Sourcegraph URL**をSourcegraphインスタンス（`https://sourcegraph.example.com`など）に設定します。
1. **変更を保存**を選択します。

## ユーザー環境設定でSourcegraphを有効にする {#enable-sourcegraph-in-user-preferences}

GitLab Self-Managedのユーザーは、Sourcegraphインテグレーションを使用するために、ユーザー設定も設定する必要があります。

GitLab.comでは、インテグレーションはすべてのパブリックプロジェクトで利用可能です。プライベートプロジェクトはサポートされていません。

前提要件: 

- GitLab Self-Managedの場合、Sourcegraphを有効にする必要があります。

GitLabのユーザー設定でこの機能を有効にするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **インテグレーション**セクションまでスクロールします。**Sourcegraph**で、**コードビューでコードインテリジェンスを有効にする**を選択します。
1. **変更を保存**を選択します。

## 参照 {#references}

- Sourcegraphドキュメントの[プライバシー情報](https://sourcegraph.com/docs/integration/browser_extension/references/privacy)

## トラブルシューティング {#troubleshooting}

### Sourcegraphが機能していません {#sourcegraph-is-not-working}

プロジェクトでSourcegraphを有効にしたのに機能しない場合、Sourcegraphがまだプロジェクトのインデックスを作成していない可能性があります。`https://sourcegraph.com/gitlab.com/<project-path>`にアクセスして、Sourcegraphがプロジェクトで使用できるかどうかを確認できます。`<project-path>`をGitLabプロジェクトへのパスに置き換えます。

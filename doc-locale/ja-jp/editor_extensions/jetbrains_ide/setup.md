---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: JetBrains IDEでGitLab Duoを接続して使用します。
title: JetBrains IDE用のGitLabプラグインをインストールして設定する
---

[JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)からプラグインをダウンロードして、インストールします。

前提要件: 

- JetBrains IDE: 2023.2.X以降。
- GitLabバージョン16.8以降。

古いバージョンのJetBrains IDEをご使用の場合は、ご使用のIDEと互換性のあるプラグインのバージョンをダウンロードしてください:

1. GitLab Duoの[プラグインページ](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)で、**バージョン**を選択します。
1. **Compatibility**（互換性）を選択し、ご使用のJetBrains IDEを選択します。
1. **Channel**（チャンネル）を選択して、安定リリースまたはアルファリリースを絞り込みます。
1. 互換性テーブルで、ご使用のIDEのバージョンを見つけて、**ダウンロード**を選択します。

## プラグインを有効にする {#enable-the-plugin}

プラグインを有効にするには:

1. IDEの上部のバーで、IDEの名前を選択し、**設定**を選択します。
1. 左側のサイドバーで**Plugins**（プラグイン）を選択します。
1. **GitLab Duo**プラグインを選択し、**インストール**を選択します。
1. **OK**または**保存**を選択します。

## GitLabに接続する {#connect-to-gitlab}

拡張機能をインストールしたら、GitLabアカウントに接続します。

### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

GitLab Self-Managedを使用している場合は、パーソナルアクセストークンを作成します。

1. GitLabの左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. 名前、説明、および有効期限を入力します。
1. `api`スコープを選択します。
1. **パーソナルアクセストークンを作成**を選択します。

### GitLabに対して認証する {#authenticate-with-gitlab}

IDEでプラグインを構成したら、GitLabアカウントに接続します:

1. IDEの上部のバーで、IDEの名前を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール**を展開し、**GitLab Duo**を選択します。
1. 認証方法を選択します:
   - GitLab.comの場合は、`OAuth`を使用します。
   - GitLab Self-ManagedおよびGitLab Dedicatedの場合、`Personal access token`を使用します。
1. **URL to GitLab instance**（GitLabインスタンスへのURL）を入力します。GitLab.comの場合は、`https://gitlab.com`を使用します。
1. **GitLab Personal Access Token**（GitLabパーソナルアクセストークン）には、作成したパーソナルアクセストークンを貼り付けます。トークンは表示されず、他のユーザーもアクセスできません。
1. **Verify setup**（セットアップの確認）を選択します。
1. **OK**または**保存**を選択します。

## デフォルトネームスペースを設定する {#set-the-default-namespace}

GitLab Duo Agent Platformは、プラグインが現在のGitLabプロジェクトを判別できない場合、**Default Namespace**（デフォルトのネームスペース）の値を使用します。この値を設定するには:

1. IDEの上部のバーで、IDEの名前を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール**を展開し、**GitLab Duo**を選択します。
1. **Default Namespace**（デフォルトのネームスペース）の値を入力します。
1. **OK**または**保存**を選択します。

## プラグインのアルファバージョンをインストールする {#install-alpha-versions-of-the-plugin}

GitLabは、プラグインのプレリリース（アルファ）ビルドをJetBrains Marketplaceの[`Alpha`リリースチャンネル](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/edit/versions/alpha)に公開しています。

プレリリースのビルドをインストールするには、次のいずれかの方法があります:

- JetBrains Marketplaceからビルドをダウンロードし、[ディスクからインストールします](https://www.jetbrains.com/help/idea/managing-plugins.html#install_plugin_from_disk)。
- ご使用のIDEに[`alpha`プラグインリポジトリを追加](https://www.jetbrains.com/help/idea/managing-plugins.html#add_plugin_repos)します。リポジトリのURLには、`https://plugins.jetbrains.com/plugins/alpha/list`を使用します。

  {{< alert type="note" >}} `alpha`プラグインリポジトリを追加した後でアルファリリースを表示するには、GitLab Duoプラグインをアンインストールしてから再インストールする必要がある場合があります。{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>このプロセスのビデオチュートリアルについては、[JetBrains用のGitLab Duoプラグインのアルファリリースのインストール](https://www.youtube.com/watch?v=Z9AuKybmeRU)を参照してください。
<!-- Video published on 2024-04-04 -->

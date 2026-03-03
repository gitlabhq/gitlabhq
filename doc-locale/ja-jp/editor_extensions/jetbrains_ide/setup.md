---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: JetBrains IDEでGitLab Duoを接続して使用します。
title: JetBrains IDE用のGitLabプラグインをインストールしてセットアップする
---

[JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)からプラグインをダウンロードしてインストールします。

前提条件: 

- JetBrains IDE: 2023.2.Xバージョン以降。
- GitLabバージョン16.8バージョン以降。

旧バージョンのJetBrains IDEを使用している場合は、お使いのIDEに対応したプラグインのバージョンをダウンロードしてください:

1. GitLab Duo [plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)ページで、**バージョン**を選択します。
1. **Compatibility**を選択し、次にJetBrains IDEを選択します。
1. **Channel**を選択して、安定リリースまたはアルファリリースを絞り込みます。
1. 互換性テーブルで、IDEのバージョンを見つけて**ダウンロード**を選択します。

## プラグインを有効にする {#enable-the-plugin}

プラグインを有効にするには:

1. IDEの上部バーで、IDE名を選択し、**Settings**を選択します。
1. 左側のサイドバーで、**Plugins**を選択します。
1. **GitLab Duo**プラグインを選択し、**インストール**を選択します。
1. **OK**または**Save**を選択します。

## GitLabに接続する {#connect-to-gitlab}

拡張機能をインストールしたら、GitLabアカウントに接続します。

### GitLabに対して認証する {#authenticate-with-gitlab}

前提条件: 

- OAuthを使用したGitLab Self-ManagedおよびGitLab Dedicated認証の場合:
  - JetBrains 3.30.30以降用のGitLab Duoプラグイン。
  - インスタンス全体の[JetBrains IDE用のOAuthアプリケーション](../../administration/settings/editor_extensions.md#jetbrains-ides)のアプリケーションID。
- PATを使用した認証の場合、`api`スコープを持つ[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)。
- 1Passwordで認証するには、[1Passwordと統合する手順](_index.md#integrate-with-1password-cli)とシークレット参照を完了します。

IDEでプラグインを構成したら、GitLabアカウントに接続します:

1. IDEの上部バーで、IDE名を選択し、**Settings**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。プラグインが一覧に表示されない場合は、IDEを再起動してください。
1. **URL to GitLab instance**を指定します。GitLab.comの場合は、`https://gitlab.com`を使用します。
1. 認証方法（**OAuth**、**PAT**、または**1Password CLI**）を選択します。
   - OAuthの場合は、プロンプトに従ってサインインし、認証を行います。
   - PATの場合は、パーソナルアクセストークンを入力してください。トークンの値は表示されず、他のユーザーもアクセスできません。
   - 1Passwordの場合は、**Integrate with 1Password CLI**を選択し、アカウントを選択して、オプションでシークレット参照を入力します。
1. **Verify setup**を選択します。
1. **OK**または**Save**を選択します。

## GitLab Duoを設定する {#configure-gitlab-duo}

前提条件: 

- エージェント型機能の場合は、[GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites)の前提条件を満たしている必要があります。
- GitLab Duoが[オン](../../user/gitlab_duo/turn_on_off.md)になっている。
- フローの場合は、[基本フローがオン](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)になっている必要があります。
- エージェントの場合は、必要に応じて、[基本エージェントがオン](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off)になっており、[カスタムエージェントが有効](../../user/duo_agent_platform/agents/custom.md#enable-an-agent)になっている必要があります。
- GitLabのリモートリポジトリにリンクされているGitLabプロジェクトを開くか、拡張機能でデフォルトのGitLab Duoネームスペースを設定します。

GitLab Duo機能を有効にするには:

1. JetBrains IDEで、**Settings** > **Tools** > **GitLab Duo**に移動します。
1. 有効にする機能を見つけて、チェックボックスをオンにします。
1. メッセージが表示されたら、IDEを再起動します。

GitLab Duoコード提案については、追加の前提条件と設定手順を確認してください:

- [GitLab Duoコード提案](../../user/duo_agent_platform/code_suggestions/set_up.md#prerequisites)
- [GitLab Duoコード提案 (クラシック)](../../user/project/repository/code_suggestions/set_up.md#prerequisites)

## デフォルトのネームスペースを設定する {#set-the-default-namespace}

現在のGitLabプロジェクトをプラグインが判別できない場合、GitLab Duoエージェントプラットフォームは**Default Namespace**値を使用します。この値を設定するには:

1. IDEの上部バーで、IDE名を選択し、**Settings**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。
1. **Default Namespace**の値を入力します。
1. **OK**または**Save**を選択します。

## プラグインのアルファバージョンをインストールする {#install-alpha-versions-of-the-plugin}

GitLabは、プラグインのプレリリース (アルファ)ビルドをJetBrains Marketplaceの[`Alpha`リリースチャネル](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/edit/versions/alpha)に公開しています。

プレリリースビルドをインストールするには、次のいずれかの手順を実行します:

- JetBrains Marketplaceからビルドをダウンロードし、[ディスクからインストール](https://www.jetbrains.com/help/idea/managing-plugins.html#install_plugin_from_disk)します。
- IDEに[`alpha`プラグインリポジトリ](https://www.jetbrains.com/help/idea/managing-plugins.html#add_plugin_repos)を追加します。リポジトリのURLには、`https://plugins.jetbrains.com/plugins/alpha/list`を使用します。

  > [!note]
  > `alpha`プラグインリポジトリを追加した後でアルファリリースを表示するには、GitLab Duoプラグインをアンインストールして再インストールする必要がある場合があります。

<i class="fa-youtube-play" aria-hidden="true"></i>このプロセスのビデオチュートリアルについては、[JetBrains用のGitLab Duoプラグインのアルファリリースのインストール](https://www.youtube.com/watch?v=Z9AuKybmeRU)を参照してください。
<!-- Video published on 2024-04-04 -->

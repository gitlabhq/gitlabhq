---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mattermostのスラッシュコマンド
description: "Mattermostのスラッシュコマンドを設定して、Mattermostのチャット環境から一般的なGitLab操作を実行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[スラッシュコマンド](gitlab_slack_application.md#slash-commands)を使用して、[Mattermost](https://mattermost.com/)チャット環境からイシューの作成など、一般的なGitLab操作を実行できます。

GitLabは、個別に設定された[Mattermost通知](mattermost.md)の一部として、（`issue created`など）のイベントをMattermostに送信することもできます。

利用可能なスラッシュコマンドの一覧については、[スラッシュコマンド](gitlab_slack_application.md#slash-commands)を参照してください。

## 設定オプション {#configuration-options}

GitLabでは、Mattermostのスラッシュコマンドを設定するさまざまな方法が用意されています。これらのオプションのいずれかを使用するには、Mattermost [3.4以降](https://mattermost.com/blog/category/platform/releases/)が必要です。

- Linuxパッケージインストール: Mattermostは[Linuxパッケージ](https://docs.gitlab.com/omnibus/)にバンドルされています。LinuxパッケージインストールのMattermostを設定するには、[LinuxパッケージMattermostドキュメント](../../../integration/mattermost/_index.md)をお読みください。
- MattermostがGitLabと同じサーバーにインストールされている場合: [自動設定](#configure-automatically)を使用します。
- その他すべてのインストールのmanual configuration: [手動設定](#configure-manually)を使用します。

## 自動設定 {#configure-automatically}

MattermostがGitLabと同じサーバーにインストールされている場合は、Mattermostスラッシュコマンドを自動的に設定できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Mattermostスラッシュコマンド**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスがオンになっていることを確認します。
1. **Mattermostに追加**を選択し、**変更を保存**を選択します。

## 手動設定 {#configure-manually}

Mattermostでスラッシュコマンドを手動で設定するには、次の手順を実行する必要があります:

1. [Mattermostでカスタムスラッシュコマンドを有効にする](#enable-custom-slash-commands-in-mattermost)。この手順は、セルフコンパイルインストールの場合にのみ必要です。
1. [GitLabから設定値を取得](#get-configuration-values-from-gitlab)。
1. [Mattermostでスラッシュコマンドを作成](#create-a-slash-command-in-mattermost)。
1. [MattermostトークンをGitLabに提供](#provide-the-mattermost-token-to-gitlab)。

### Mattermostでカスタムスラッシュコマンドを有効にする {#enable-custom-slash-commands-in-mattermost}

Mattermost管理者コンソールからカスタムスラッシュコマンドを有効にするには:

1. 管理者権限を持つユーザー名としてMattermostにサインインします。
1. ユーザー名の横にある{{< icon name="ellipsis_v" >}} **設定**アイコンを選択し、**System Console**（システムコンソール）を選択します。
1. **Integration Management**（インテグレーション管理）を選択し、これらの値を`TRUE`に設定します:
   - **Enable Custom Slash Commands**（カスタムスラッシュコマンドを有効にする）
   - **Enable integrations to override usernames**（インテグレーションでユーザー名をオーバーライドできるようにする）
   - **Enable integrations to override profile picture icons**（インテグレーションでプロフィール画像のアイコンをオーバーライドできるようにする）
1. **保存**を選択しますが、このブラウザータブは閉じないでください。これは後のステップで必要になります。

### GitLabから設定値を取得 {#get-configuration-values-from-gitlab}

GitLabから設定値を取得するには:

1. 別のブラウザータブで、管理者アクセス権を持つユーザー名としてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **Mattermostスラッシュコマンド**を選択します。GitLabに、Mattermost設定の候補の値が表示されます。
1. **リクエストURL**の値をコピーします。その他すべての値は提案です。
1. このブラウザータブを閉じないでください。これは後のステップで必要になります。

### Mattermostでスラッシュコマンドを作成 {#create-a-slash-command-in-mattermost}

Mattermostでスラッシュコマンドを作成するには:

1. [Mattermostブラウザータブ](#enable-custom-slash-commands-in-mattermost)で、チームページに移動します。
1. {{< icon name="ellipsis_v" >}} **設定**アイコンを選択し、**インテグレーション**を選択します。
1. 左側のサイドバーで、**Slash commands**（スラッシュコマンド）を選択します。
1. **Add Slash Command**（スラッシュコマンドを追加）を選択します。
1. 新しいコマンドの**Display Name**（表示名）と**説明**を入力します。
1. アプリケーションの設定に基づいて**Command Trigger Word**（コマンドトリガーワード）を指定します:

   - 1つのGitLabプロジェクトのみをMattermostチームに接続する場合は、`/gitlab`をトリガーワードに使用します。
   - 複数のGitLabプロジェクトを接続する場合は、`/project-name`や`/gitlab-project-name`など、GitLabプロジェクトに関連するトリガーワードを使用します。
1. **リクエストURL**には、[GitLabからコピーした値を貼り付け](#get-configuration-values-from-gitlab)ます。
1. その他すべての値については、GitLabからの提案値または推奨値を使用できます。
1. **パイプライントークン**の値をコピーして、**完了**を選択します。

### MattermostトークンをGitLabに提供 {#provide-the-mattermost-token-to-gitlab}

Mattermostでスラッシュコマンドを作成すると、GitLabに提供する必要があるトークンが生成されます:

1. [GitLabブラウザータブ](#get-configuration-values-from-gitlab)で、**有効**チェックボックスをオンにします。
1. **パイプライントークン**テキストボックスに、[Mattermostからコピーしたトークンを貼り付け](#create-a-slash-command-in-mattermost)ます。
1. **変更を保存**を選択します。

スラッシュコマンドがGitLabプロジェクトと通信できるようになりました。

## GitLabアカウントをMattermostに接続 {#connect-your-gitlab-account-to-mattermost}

前提要件: 

- [スラッシュコマンド](gitlab_slack_application.md#slash-commands)を実行するには、GitLabプロジェクトでアクションを実行するための[権限](../../permissions.md#project-members-permissions)が必要です。

Mattermostスラッシュコマンドを使用してGitLabとやり取りするには:

1. Mattermostのチャット環境で、新しいスラッシュコマンドを実行します。
1. **connect your GitLab account**（GitLabアカウントを接続する）を選択して、アクセスを承認します。

承認されたすべてのチャットアカウントは、Mattermostのプロファイルページの**チャット**に表示されます。

## 関連トピック {#related-topics}

- [Mattermost Linuxパッケージ](../../../integration/mattermost/_index.md)
- [Mattermostのスラッシュコマンド](https://developers.mattermost.com/integrate/slash-commands/)

## トラブルシューティング {#troubleshooting}

MattermostスラッシュコマンドがGitLabでイベントをトリガーしない場合:

- パブリックチャンネルを使用していることを確認してください。Mattermost Webhookは、プライベートチャンネルにアクセスできません。
- プライベートチャンネルが必要な場合は、Webhookチャンネルを編集し、プライベートなチャンネルを1つ選択します。すべてのイベントは、指定されたチャンネルに送信されます。

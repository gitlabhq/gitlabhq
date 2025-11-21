---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: EclipseでGitLab Duoを接続して使用します。
title: Eclipse用GitLabをインストールして設定する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 17.11で実験的機能からベータに[変更](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163)されました。

{{< /history >}}

{{< alert type="disclaimer" />}}

## GitLab for Eclipseプラグインをインストールします {#install-the-gitlab-for-eclipse-plugin}

前提要件: 

- Eclipse 4.33以降。
- GitLabバージョン16.8以降。

Eclipse用GitLabをインストールするには:

1. Eclipse IDEと、お好みのWebブラウザを開きます。
1. Webブラウザで、Eclipse Marketplaceの[GitLab for Eclipseプラグイン](https://marketplace.eclipse.org/content/gitlab-eclipse)のページに移動します。
1. プラグインのページで、**インストール**を選択し、Eclipse IDEにマウスをドラッグします。
1. **Eclipse Marketplace**ウィンドウで、**GitLab For Eclipse**カテゴリを選択します。
1. **Confirm（確認）>**を選択し、**Finish**（完了）を選択します。
1. **Trust Authorities**ウィンドウが表示されたら、**`https://gitlab.com`**アップデートサイトを選択し、**Trust Selected**を選択します。
1. **Restart Now**を選択します。

Eclipse Marketplaceが利用できない場合は、新しいソフトウェアサイトを追加するための[Eclipseのインストール手順](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.platform.doc.user%2Ftasks%2Ftasks-124.htm)に従ってください。**Work with**には、`https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases/permalink/latest/downloads/`を使用します。

## GitLabに接続する {#connect-to-gitlab}

拡張機能をインストールしたら、パーソナルアクセストークンを作成し、GitLabで認証して、GitLabアカウントに接続します。

### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

GitLab Self-Managedインスタンスを使用している場合は、パーソナルアクセストークンを作成します。

1. GitLabの左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. 名前、説明、および有効期限を入力します。
1. `api`スコープを選択します。
1. **パーソナルアクセストークンを作成**を選択します。

### GitLabに対して認証する {#authenticate-with-gitlab}

IDEでプラグインを構成したら、GitLabアカウントに接続します:

1. IDEで、**Eclipse** > **設定**を選択します。
1. 左側のサイドバーで、**GitLab**を選択します。
1. **Connection URL**を入力します。GitLab.comの場合は、`https://gitlab.com`を使用します。
1. **GitLab Personal Access Token**（GitLabパーソナルアクセストークン）には、作成したパーソナルアクセストークンを貼り付けます。トークンは、初回入力時に表示されます。適用後、トークンは表示されず、Eclipseのセキュアストレージを使用して保存されます。
1. GitLabの設定で、**適用**を選択します。
1. **Apply and Close**（適用して閉じる）を選択します。

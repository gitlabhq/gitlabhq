---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Visual Studio Code、JetBrains IDE、Visual Studio、Eclipse、NeovimなどのGitLabエディタ拡張機能を構成します。
title: エディタ拡張機能を設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンスのエディタ拡張機能の設定を構成します。

## OAuthアプリケーションを作成する {#create-an-oauth-application}

{{< history >}}

- GitLab Workflow 6.47.0で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2738)されました。

{{< /history >}}

OAuthアプリケーションIDを使用してVS Code用拡張機能を構成して、GitLabに接続し、認証できます。

OAuthアプリケーションを作成するには、次の手順に従います:

1. インスタンス全体で使用される[アプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)を作成します
1. **Redirect URI**（リダイレクトURI）に、`vscode://gitlab.gitlab-workflow/authentication`と入力します。
   - Code InsidersやCursorのような追加のIDEを指定するには、改行で区切られた複数のリダイレクトURIを追加します。
1. `api`スコープを選択します。
1. **送信**を選択します。
1. **アプリケーションID**をコピーします。VS Codeの設定で、`gitlab.authentication.oauthClientIds`設定にこれを使用します。

## 最小言語サーバーバージョンを要求する {#require-a-minimum-language-server-version}

{{< history >}}

- GitLab 18.1で`enforce_language_server_version`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/541744)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`enforce_language_server_version`という名前の[機能フラグを有効にする](../feature_flags/_index.md)と、この機能を使用できるようになります。GitLab.comでは、この機能は利用できますが、GitLab.comの管理者のみが設定できます。GitLab Dedicatedでは、この機能を利用できます。

{{< /alert >}}

デフォルトでは、パーソナルアクセストークンが有効になっている場合、任意のGitLab言語サーバーバージョンをGitLabインスタンスに接続できます。古いバージョンのクライアントからのリクエストをブロックするには、最小言語サーバーバージョンを構成します。許可されている最小言語サーバーバージョンより古いクライアントは、APIエラーを受け取ります。

前提要件: 

- 管理者である必要があります。

  ```ruby
  # For a specific user
  Feature.enable(:enforce_language_server_version, User.find(1))

  # For this GitLab instance
  Feature.enable(:enforce_language_server_version)
  ```

最小GitLab言語サーバーバージョンを適用するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **エディタ拡張機能**を展開します。
1. **言語サーバーの制限を有効にする**をオンにします。
1. **GitLab言語サーバークライアントの最小バージョン**に、有効なGitLab言語サーバーのバージョンを入力します。

任意のGitLab言語サーバークライアントを許可するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **エディタ拡張機能**を展開します。
1. **言語サーバーの制限を有効にする**をオフにします。
1. **GitLab言語サーバークライアントの最小バージョン**に、有効なGitLab言語サーバーのバージョンを入力します。

{{< alert type="note" >}}

すべてのリクエストを許可することはお勧めできません。GitLabのバージョンが拡張機能のバージョンよりも進んでいる場合、非互換性が発生する可能性があります。最新の機能改善、バグ修正、およびセキュリティ修正を受け取るには、拡張機能を更新する必要があります。

{{< /alert >}}

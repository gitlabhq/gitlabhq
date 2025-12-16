---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: EclipseでGitLab Duoを接続して使用します。
title: Eclipseのトラブルシューティング
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

このページのステップで問題が解決しない場合は、Eclipseプラグインのプロジェクトで[未解決のイシューの一覧](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)を確認してください。イシューが問題と一致する場合は、そのイシューを更新してください。お使いの問題に一致するイシューがない場合は、[イシューを新規作成](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/new)して、[サポートに必要な情報](#required-information-for-support)を記入してください。

## エラーログを確認する {#review-the-error-log}

1. お使いのIDEのメニューバーで、**Window**（ウインドウ）を選択します。
1. **Show View**（ビューの表示）を展開し、**Error Log**（エラーログ）を選択します。
1. `gitlab-eclipse-plugin`プラグインを参照しているエラーを検索します。

## ワークスペースログファイルの場所を特定する {#locate-the-workspace-log-file}

ワークスペースログファイル（`.log`という名前）は、`<your-eclipse-workspace>/.metadata`ディレクトリにあります。

## GitLab言語サーバーのデバッグログを有効にする {#enable-gitlab-language-server-debug-logs}

GitLab言語サーバーのデバッグログを有効にするには:

1. IDEで、**Eclipse** > **設定**を選択します。
1. 左側のサイドバーで、**GitLab**を選択します。
1. **Language Server Log Level**（言語サーバーのログレベル）に、`debug`と入力します。
1. **Apply and Close**（適用して閉じる）を選択します。

デバッグログは、`language_server.log`ファイルにあります。このファイルを表示するには、次のいずれかの操作を行います:

- `/Users/<user>/eclipse/<eclipse-version>/Eclipse.app/Contents/MacOS/.gitlab_plugin`ディレクトリに移動し、`<user>`と`<eclipse-version>`を適切な値に置き換えます。
- [エラーログ](#review-the-error-log)を開きます。`Language server logs saved to: <file>.`ログを探します。`<file>`は、`language_server.log`ファイルへの絶対パスです。

## サポートに必要な情報 {#required-information-for-support}

サポートリクエストを作成する際は、次の情報を提供してください:

1. 現在のEclipse用プラグインのGitLabのバージョン。
   1. `About Eclipse IDE`ダイアログを開きます。
      - Windowsの場合は、IDEで、**ヘルプ** > **About Eclipse IDE**（Eclipse IDEについて）を選択します。
      - MacOSの場合は、IDEで、**Eclipse** > **About Eclipse IDE**（Eclipse IDEについて）を選択します。

   1. ダイアログで、**Installation details**（インストール詳細）を選択します。
   1. **GitLab for Eclipse**（Eclipse用GitLab）を見つけて、**バージョン**の値をコピーします。

1. お使いのEclipseのバージョン。
   1. `About Eclipse IDE`ダイアログを開きます。
      - Windowsの場合は、IDEで、**ヘルプ** > **About Eclipse IDE**（Eclipse IDEについて）を選択します。
      - MacOSの場合は、IDEで、**Eclipse** > **About Eclipse IDE**（Eclipse IDEについて）を選択します。

1. 使用しているオペレーティングシステム。
1. GitLab.com、GitLab Self-Managed、またはGitLab Dedicatedのいずれかのインスタンスを使用していますか？
1. プロキシを使用していますか？
1. 自己署名証明書を使用していますか？
1. [ワークスペースログ](#locate-the-workspace-log-file)。
1. [言語サーバー](#enable-gitlab-language-server-debug-logs)のデバッグログ。
1. 該当する場合は、問題のビデオまたはスクリーンショット。
1. 該当する場合は、問題を再現する手順。
1. 該当する場合は、問題を解決するために試みた手順。

## 証明書エラー {#certificate-errors}

お使いのマシンがプロキシ経由でGitLabのインスタンスに接続している場合は、EclipseでSSL証明書エラーが発生することがあります。GitLab Duoは、システムストア内の証明書を検出を試みますが、言語サーバーはこれを実行できません。言語サーバーからの証明書に関するエラーが表示される場合は、認証局（CA）証明書を渡すオプションを有効にしてみてください:

これを行うには、次の手順を実行します:

1. IDEの右下隅にあるGitLabアイコンを選択します。
1. ダイアログで、**Show Settings**（設定を表示）を選択します。これにより、**設定**ダイアログが**ツール** > **GitLab Duo**に開きます。
1. **GitLab Language Server**（GitLab言語サーバー）を選択して、セクションを展開します。
1. **HTTP Agent Options**（HTTPエージェントオプション）を選択して展開します。
1. 次のいずれかの操作を行います:
   - オプション**Pass CA certificate from Duo to the Language Server**（Duoから言語サーバーにCA証明書を渡す）を選択します。
   - **Certificate authority (CA)**で、CA証明書を含む`.pem`ファイルへのパスを指定します。
1. IDEを再起動します。

### 証明書エラーを無視する {#ignore-certificate-errors}

GitLab Duoがまだ接続に失敗する場合は、証明書エラーを無視する必要があるかもしれません。デバッグモードを有効にした後、GitLab言語サーバーのログにエラーが表示されることがあります:

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

意図的に、この設定はセキュリティ漏洩のリスクを表します。これらのエラーは、潜在的なセキュリティ漏洩を警告します。プロキシが問題の原因であると確信できる場合にのみ、この設定を有効にしてください。

前提要件: 

- システムのブラウザを使用して証明書チェーンが有効であることを確認したか、マシンの管理者にこのエラーを無視しても安全であることを確認してもらったものとします。

これを行うには、次の手順を実行します:

1. SSL証明書に関するEclipseのドキュメントを参照してください。
1. IDEの上部のメニューバーに移動し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. デフォルトのブラウザが、使用している**URL to GitLab instance**（GitLabインスタンスへのURL）を信頼していることを確認します。
1. **Ignore certificate errors**（証明書エラーを無視する）オプションを有効にします。
1. **Verify setup**（セットアップの確認）を選択します。
1. **OK**または**保存**を選択します。

---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: JetBrains IDEでGitLab Duoを接続して使用します。
title: JetBrainsのトラブルシューティング
---

このページのトラブルシューティングの手順で問題が解決しない場合は、JetBrainsプラグインプロジェクトの[未解決のイシュー一覧](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)を確認してください。イシューが問題と一致する場合は、そのイシューを更新してください。問題と一致するイシューがない場合は、[新しいイシューを作成](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/new)し、[サポートに必要な情報](#required-information-for-support)を提供してください。

GitLab Duoコード提案に関するJetBrains IDEのトラブルシューティングについては、[コード提案のトラブルシューティング](../../user/project/repository/code_suggestions/troubleshooting.md#jetbrains-ides-troubleshooting)を参照してください。

## デバッグモードを有効にする {#enable-debug-mode}

JetBrainsでデバッグログを有効にするには:

1. 上部のバーで、**ヘルプ** > **Diagnostic Tools** > **Debug Log Settings**に移動するか、**ヘルプ** > **Find Action** > **Debug log settings**に移動してアクションを検索します。
1. 次の行を追加します: `com.gitlab.plugin`
1. **OK**または**保存**を選択します。

[証明書エラー](#certificate-errors)またはその他の接続エラーが発生し、HTTPプロキシを使用してGitLabインスタンスに接続する場合は、GitLab言語サーバーのために、[プロキシを使用するように言語サーバーを構成](../language_server/_index.md#configure-the-language-server-to-use-a-proxy)する必要があります。

[プロキシ認証を有効にする](../language_server/_index.md#enable-proxy-authentication)こともできます。

## GitLab言語サーバーのデバッグログを有効にする {#enable-gitlab-language-server-debug-logs}

GitLab言語サーバーのデバッグログを有効にするには:

1. IDEの上部バーで、IDE名を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. **GitLab Language Server**を選択して、セクションを展開します。
1. **Logging** > **Log Level**で、`debug`と入力します。
1. **適用**を選択します。
1. **Enable GitLab Language Server**の下にある**Restart Language Server**を選択します。

## デバッグログを取得する {#get-debug-logs}

デバッグログは`idea.log`ログファイルで確認できます。このファイルを表示するには、次のいずれかの操作を行います:

<!-- vale gitlab_base.SubstitutionWarning = NO -->

- IDEで、**ヘルプ** > **Show Log in Finder**に移動します。
- `/Users/<user>/Library/Logs/JetBrains/IntelliJIdea<build_version>`ディレクトリに移動し、`<user>`と`<build_version>`を適切な値に置き換えます。

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## 証明書エラー {#certificate-errors}

マシンがプロキシ経由でGitLabインスタンスに接続する場合、JetBrainsでSSL証明書エラーが発生する可能性があります。GitLab Duoは、システムストア内の証明書を検出を試みますが、言語サーバーはこれを実行できません。言語サーバーからの証明書に関するエラーが表示される場合は、認証局（CA）証明書を渡すオプションを有効にしてみてください:

これを行うには、次の手順を実行します:

1. IDEの右下隅にあるGitLabアイコンを選択します。
1. ダイアログで、**Show Settings**を選択します。これにより、**設定**ダイアログが**ツール** > **GitLab Duo**に開きます。
1. **GitLab Language Server**を選択して、セクションを展開します。
1. **HTTP Agent Options**を選択して展開します。
1. 次のいずれかの操作を行います:
   - オプション**Pass CA certificate from Duo to the Language Server**を選択します。
   - **Certificate authority (CA)**で、CA証明書を含む`.pem`ファイルへのパスを指定します。
1. IDEを再起動します。

### 証明書エラーを無視する {#ignore-certificate-errors}

GitLab Duoがまだ接続に失敗する場合は、証明書エラーを無視する必要があるかもしれません。[デバッグモード](jetbrains_troubleshooting.md#enable-debug-mode)を有効にした後、GitLab言語サーバーのログにエラーが表示される場合があります:

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

意図的に、この設定はセキュリティ漏洩のリスクを表します。これらのエラーは、潜在的なセキュリティ漏洩を警告します。プロキシが問題の原因であると確信できる場合にのみ、この設定を有効にしてください。

前提要件: 

- システムのブラウザを使用して証明書チェーンが有効であることを確認したか、マシンの管理者にこのエラーを無視しても安全であることを確認してもらったものとします。

これを行うには、次の手順を実行します:

1. [SSL証明書](https://www.jetbrains.com/help/idea/ssl-certificates.html)に関するJetBrainsのドキュメントを参照してください。
1. IDEの上部のメニューバーに移動し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. デフォルトのブラウザが、使用している**URL to GitLab instance**を信頼していることを確認します。
1. **Ignore certificate errors**オプションを有効にします。
1. **Verify setup**を選択します。
1. **OK**または**保存**を選択します。

### PyCharmで認証が失敗する {#authentication-fails-in-pycharm}

GitLab認証の**Verify setup**フェーズで問題が発生した場合は、サポートされているバージョンのPyCharmを実行していることを確認してください:

1. [プラグインの互換性](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions)ページに移動します。
1. **Compatibility**については、`PyCharm Community`または`PyCharm Professional`を選択してください。
1. **Channels**の場合は、GitLabプラグインに必要な安定レベルを選択します。
1. 使用しているPyCharmのバージョンに対して、**ダウンロード**を選択して正しいGitLabプラグインのバージョンをダウンロードし、インストールします。

## JCEFエラー {#jcef-errors}

JCEF（Java Chromium Embedded Framework）に関連するGitLab Duoチャットで問題が発生した場合は、次の手順を試してください:

1. 上部のバーで、**ヘルプ** > **Find Action**に移動し、`Registry`を検索します。
1. `ide.browser.jcef.sandbox.enable`を検索します。
1. チェックボックスをオフにして、この設定を無効にします。
1. レジストリダイアログを閉じます。
1. IDEを再起動します。
1. 上部のバーで、**ヘルプ** > **Find Action**に移動し、`Choose Boot Java Runtime for the IDE`を検索します。
1. 現在のIDEのバージョンと同じで、JCEFがバンドルされているブートJavaランタイムバージョンを選択します: ![JCEFサポートランタイム例](img/jcef_supporting_runtime_example_v17_3.png)
1. IDEを再起動します。

## サポートに必要な情報 {#required-information-for-support}

サポートに問い合わせる前に、最新のGitLabワークフロー拡張機能がインストールされていることを確認してください。すべてのリリースは、[JetBrains Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions)の**バージョン**タブで入手できます。

影響を受けるユーザーからこの情報を収集し、バグレポートで提供してください:

1. ユーザーに表示されるエラーメッセージ。
1. ワークフローと言語サーバーのログ:
   - [デバッグログ](#enable-debug-mode)
   - [言語サーバーのデバッグログ](#enable-gitlab-language-server-debug-logs)。
   - [ログ出力](#get-debug-logs)
1. 診断出力。IntelliJ製品で、**ヘルプ** > **Diagnostics Tools** > **Collect Troubleshooting Information**に移動します。
   - **GitLabについて**セクションで、**Build Version**をコピーします。
   - プラグイン固有のバージョンの場合: **Plugins**セクションで、出力をコピーします。
1. システムの詳細。IntelliJ製品で、**ヘルプ** > **Diagnostics Tools** > **Collect Troubleshooting Information**に移動します。
   - オペレーティングシステムの種類とバージョンの場合: ダイアログで**オペレーティングシステム**をコピーします。
   - マシンの仕様については、`System`セクションをコピーします。
1. 影響のスコープについて説明します。影響を受けるユーザーは何人ですか?
1. エラーを再現する方法を説明します。可能であれば、画面録画を含めてください。
1. 他のGitLab Duo機能がどのように影響を受けるかを説明します:
   - GitLab Quickチャットは機能していますか?
   - コード提案は機能していますか?
   - Web IDE Duoチャットは応答を返しますか?
1. 拡張機能の分離テストを実行します。他の拡張機能をすべて無効にするかアンインストールして、別の拡張機能が問題の原因になっているかどうかを確認してください。これにより、問題が拡張機能にあるのか、外部ソースにあるのかを判断できます。

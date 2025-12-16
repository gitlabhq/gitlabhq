---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: JetBrains IDEでGitLab Duoを接続して使用します。
title: JetBrains IDE用のGitLabプラグイン
---

[GitLab Duoプラグイン](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)は、IntelliJ、PyCharm、GoLand、Webstorm、RubymineなどのJetBrains IDEとGitLab Duoを統合します。

拡張機能をインストールして設定するには、[インストールとセットアップ](setup.md)を参照してください。

## 実験的またはベータ機能を有効にする {#enable-experimental-or-beta-features}

プラグインの一部の機能は、実験的またはベータステータスです。これらを使用するには、オプトインする必要があります:

1. IDEの上部のメニューバーに移動し、**設定**を選択します:
   - MacOS: <kbd>⌘</kbd>+<kbd>,</kbd>を押します
   - WindowsまたはLinux: <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd>を押します
1. 左側のサイドバーで、**ツール**を展開し、**GitLab Duo**を選択します。
1. **Enable Experiment or BETA features**（実験的またはベータ機能を有効にする）を選択します。
1. 変更を適用するには、IDEを再起動します。

## 拡張機能を更新する {#update-the-extension}

拡張機能を最新バージョンに更新するには、次の手順に従います:

1. JetBrains IDEで、**設定** > **Plugins**（プラグイン）に移動します。
1. **Marketplace**から、**GitLab Duo**（発行元: **GitLab, Inc.**）を選択します。
1. **更新**を選択して、最新のプラグインバージョンに更新します。

## テレメトリを有効にする {#enable-telemetry}

GitLab Duoプラグインは、JetBrains IDEのテレメトリ設定を使用して、使用状況とエラー情報をGitLabに送信します。JetBrains IDEでテレメトリを有効にするには:

1. IDEの上部のメニューバーに移動し、**設定**を選択します。たとえば、PyCharmで、**PyCharm** > **設定**を選択します。
1. 左側のサイドバーで、**ツール**を**GitLab Duo**を選択します。
1. **高度な設定**で、**Enable telemetry**（テレメトリを有効にする）チェックボックスをオンにします。
1. **OK**または**適用**を選択して、変更を保存します。

## 1Password CLIとの統合 {#integrate-with-1password-cli}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.11バージョン以降のGitLab Duo 2.1で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291)。

{{< /history >}}

パーソナルアクセストークンをハードコードされたではなく、1Passwordシークレット参照を使用するようにプラグインを設定できます。

前提要件: 

- [1Password](https://1password.com)デスクトップアプリがインストールされている。
- [1Password CLI](https://developer.1password.com/docs/cli/get-started/)ツールがインストールされている。

JetBrains用GitLabを1Password CLIと統合する方法:

1. GitLabに対して認証する次のいずれかの操作を行います:
   - [`glab`](../gitlab_cli/_index.md#install-the-cli) CLIをインストールし、[1Password Shellプラグイン](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)を設定します。
   - JetBrains用GitLabの[手順](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#setup)に従ってください。
1. 1Passwordアイテムを開きます。
1. [シークレット参照をコピー](https://developer.1password.com/docs/cli/secret-references/#step-1-copy-secret-references)します。

   `gitlab` 1Password Shellプラグインを使用している場合、トークンは`"op://Private/GitLab Personal Access Token/token"`のパスワードとして保存されます。

IDEから:

1. IDEの上部のメニューバーに移動し、**設定**を選択します。
1. 左側のサイドバーで、**ツール**を展開し、**GitLab Duo**を選択します。
1. **認証**で、**1Password CLI**タブを選択します。
1. **Integrate with 1Password CLI**（1Password CLIと統合）を選択します。
1. オプション。**Secret reference**（シークレット参照）で、1Passwordからコピーしたシークレット参照を貼り付けます。
1. オプション。認証情報を確認するには、**Verify setup**（セットアップの確認）を選択します。
1. **OK**または**保存**を選択します。

## プラグインに関するイシューのレポート {#report-issues-with-the-plugin}

[`gitlab-jetbrains-plugin`イシュートラッカー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues)で、イシュー、バグ、または機能リクエストを報告してください。`Bug`または`Feature Proposal`テンプレートを使用します。

GitLab Duoの使用中にエラーが発生した場合は、IDEに組み込まれているエラーレポートツールでレポートすることもできます:

1. ツールにアクセスするには、次のいずれかの操作を行います:
   - エラーが発生した場合、エラーメッセージで**See details and submit report**（詳細を表示してレポートを送信）を選択します。
   - ステータスバーの右下にある感嘆符を選択します。
1. **IDE Internal Errors**（IDE内部エラー）ダイアログで、エラーについて説明します。
1. **Report and clear all**（すべてレポートしてクリア）を選択します。
1. デバッグ情報が入力されたGitLabイシューフォームがブラウザーで開きます。
1. イシューテンプレートのプロンプトに従って、説明を入力し、できるだけ多くのコンテキストを提供します。
1. **イシューの作成**を選択して、バグレポートを提出します。

## 関連トピック {#related-topics}

- [コード提案](../../user/project/repository/code_suggestions/_index.md)
- [JetBrainsトラブルシューティング](jetbrains_troubleshooting.md)
- [GitLab言語サーバードキュメント](../language_server/_index.md)
- [このプラグインに関するオープンイシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/)
- [プラグインドキュメント](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [ソースコードを表示する](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)

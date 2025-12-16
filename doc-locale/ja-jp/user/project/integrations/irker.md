---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: irker（IRCゲートウェイ）
description: "irkerインテグレーションを構成して、GitLabプッシュ通知をIRCチャンネルに送信します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、irkerサーバーに更新メッセージをプッシュする方法を提供します。インテグレーションを設定すると、プロジェクトへの各プッシュは、データをirkerサーバーに直接送信するインテグレーションをトリガーします。

詳細については、[irkerインテグレーションAPIドキュメント](../../../api/project_integrations.md)を参照してください。

詳細については、[irkerプロジェクトのホームページ](https://gitlab.com/esr/irker)を参照してください。

## irkerデーモンをセットアップします {#set-up-an-irker-daemon}

irkerデーモンをセットアップする必要があります。これを行うには、次の手順に従います:

1. [リポジトリから](https://gitlab.com/esr/irker)irkerコードをダウンロードします:

   ```shell
   git clone https://gitlab.com/esr/irker.git
   ```

1. `irkerd`という名前のPythonスクリプトを実行します。これはゲートウェイスクリプトです。これは、IRCサーバーにメッセージを送信するためのIRCクライアントと、GitLabサービスからメッセージを受信するためのTCPサーバーの両方として機能します。

irkerサーバーが同じマシンで実行されている場合は完了です。そうでない場合は、次のセクションの最初の手順に従う必要があります。

{{< alert type="warning" >}}

irkerには認証機能が組み込まれて**いない**ため、ファイアウォールの外でホストされている場合、IRCチャンネルのスパムに対して脆弱になります。不正使用を防ぐために、保護されたネットワーキング上でデーモンを実行してください。詳細については、[irkerのセキュリティ分析](http://www.catb.org/~esr/irker/security.html)をお読みください。

{{< /alert >}}

## GitLabでこれらの手順を完了します {#complete-these-steps-in-gitlab}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **irker (IRCゲートウェイ)**を選択します。
1. **有効**トグルが有効になっていることを確認します。
1. オプション。**Server host**（サーバーホスト）に、`irkerd`が実行されているサーバーホストアドレスを入力します。空の場合、`localhost`にデフォルト設定されます。
1. オプション。**Server port**（サーバーポート）に、`irkerd`のサーバーポートを入力します。空の場合、`6659`にデフォルト設定されます。
1. オプション。**デフォルトIRC URI**に、`irc[s]://domain.name`形式でデフォルトのIRCを入力します。これは、**受信者**で指定された完全なURI形式でない各チャンネルまたはユーザーの先頭に付加されます。
1. **受信者**に、更新を受信するユーザーまたはチャンネルをスペースで区切って入力します（例: `#channel1 user1`）。詳細については、[irker受信者の入力](#enter-irker-recipients)を参照してください。
1. オプション。メッセージを強調表示するには、**メッセージに色を付ける**チェックボックスを選択します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

## irker受信者の入力 {#enter-irker-recipients}

**デフォルトIRC URI**フィールドを空のままにした場合は、受信者を完全なURI形式で入力します: `irc[s]://irc.network.net[:port]/#channel`。デフォルトIRC URIを入力した場合は、受信者をチャンネル名またはユーザー名のみで指定できます。

メッセージを送信するには:

- チャンネル（たとえば、`#chan`）の場合、irkerは`chan`および`#chan`形式のチャンネル名を受け入れます。
- パスワードで保護されたチャンネルの場合は、`?key=thesecretpassword`をチャンネル名に追加し、`thesecretpassword`の代わりにチャンネルパスワードを使用します。たとえば`chan?key=hunter2`などです。チャンネル名の前に`#`記号を**付けない**でください。そうすると、irkerは`#chan?key=password`という名前のチャンネルへの参加を試み、`/whois` IRCコマンドを介してチャンネルパスワードをリークする可能性があります。これは、長年のirkerのバグによるものです。
- ユーザークエリでは、ユーザー名の後に`,isnick`を追加します。たとえば`UserSmith,isnick`などです。

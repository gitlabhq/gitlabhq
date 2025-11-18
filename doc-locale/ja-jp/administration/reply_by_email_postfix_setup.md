---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 受信メール用にPostfixを設定する
description: 受信メール用にPostfixを構成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントでは、UbuntuでIMAP認証を使用した基本的なPostfixメールサーバーをセットアップし、[受信メール](incoming_email.md)で使用する手順について説明します。

この手順では、`incoming@gitlab.example.com`というメールアドレス（つまり、ホスト`gitlab.example.com`上のユーザー名`incoming`）を使用していることを前提としています。コード例を実行するときは、実際のホストに変更することを忘れないでください。

## サーバーファイアウォールを構成する {#configure-your-server-firewall}

1. ユーザーがSMTP経由でメールをサーバーに送信できるように、サーバーのポート25を開きます。
1. メールサーバーがGitLabを実行しているサーバーと異なる場合は、GitLabがIMAP経由でサーバーからメールを読み取りできるように、サーバーのポート143を開きます。

## パッケージをインストールする {#install-packages}

1. `postfix`パッケージがまだインストールされていない場合は、インストールします:

   ```shell
   sudo apt-get install postfix
   ```

   環境について質問されたら、[インターネットサイト]を選択します。ホスト名の確認を求められたら、`gitlab.example.com`と一致していることを確認してください。

1. `mailutils`パッケージをインストールします。

   ```shell
   sudo apt-get install mailutils
   ```

## ユーザーを作成する {#create-user}

1. 受信メール用のユーザーを作成します。

   ```shell
   sudo useradd -m -s /bin/bash incoming
   ```

1. このユーザーのパスワードを設定します。

   ```shell
   sudo passwd incoming
   ```

   忘れないようにしてください。後で必要になります。

## すぐに使える設定をテストする {#test-the-out-of-the-box-setup}

1. ローカルSMTPサーバーに接続します:

   ```shell
   telnet localhost 25
   ```

   次のようなプロンプトが表示されます:

   ```shell
   Trying 127.0.0.1...
   Connected to localhost.
   Escape character is '^]'.
   220 gitlab.example.com ESMTP Postfix (Ubuntu)
   ```

   代わりに`Connection refused`エラーが発生した場合は、`postfix`が実行されていることを確認します:

   ```shell
   sudo postfix status
   ```

   実行されていない場合は、起動します:

   ```shell
   sudo postfix start
   ```

1. SMTPをテストするために、次のスニペットをSMTPプロンプトに入力して、新しい`incoming`ユーザーにメールを送信します:

   ```plaintext
   ehlo localhost
   mail from: root@localhost
   rcpt to: incoming@localhost
   data
   Subject: Re: Some issue

   Sounds good!
   .
   quit
   ```

   {{< alert type="note" >}}

   `.`は、それ自体の行にあるリテラルピリオドです。

   {{< /alert >}}

   `rcpt to: incoming@localhost`を入力した後にエラーが表示される場合は、Postfix `my_network`設定が正しくありません。エラーには「一時的な検索失敗」と表示されます。[インターネットからメールを受信するようにPostfixを構成する](#configure-postfix-to-receive-email-from-the-internet)を参照してください。

1. `incoming`ユーザーがメールを受信したかどうかを確認します:

   ```shell
   su - incoming
   mail
   ```

   次のような出力が表示されます:

   ```plaintext
   "/var/mail/incoming": 1 message 1 unread
   >U   1 root@localhost                           59/2842  Re: Some issue
   ```

   メールアプリを終了します:

   ```shell
   q
   ```

1. `incoming`アカウントからサインアウトし、`root`に戻ります:

   ```shell
   logout
   ```

## Maildirスタイルのメールボックスを使用するようにPostfixを構成する {#configure-postfix-to-use-maildir-style-mailboxes}

後でIMAP認証を追加するためにインストールするCourierでは、メールボックスがmboxではなく、Maildir形式である必要があります。

1. Maildirスタイルのメールボックスを使用するようにPostfixを構成します:

   ```shell
   sudo postconf -e "home_mailbox = Maildir/"
   ```

1. Postfixを再起動します:

   ```shell
   sudo /etc/init.d/postfix restart
   ```

1. 新しいセットアップをテストします:

   1. _[すぐに使える設定をテストする](#test-the-out-of-the-box-setup)_の手順1と2に従います。
   1. `incoming`ユーザーがメールを受信したかどうかを確認します:

      ```shell
      su - incoming
      MAIL=/home/incoming/Maildir
      mail
      ```

      次のような出力が表示されます:

      ```plaintext
      "/home/incoming/Maildir": 1 message 1 unread
      >U   1 root@localhost                           59/2842  Re: Some issue
      ```

      メールアプリを終了します:

      ```shell
      q
      ```

   `mail`がエラー`Maildir: Is a directory`を返す場合、`mail`のバージョンはMaildirスタイルのメールボックスをサポートしていません。`heirloom-mailx`をインストールするには、`sudo apt-get install heirloom-mailx`を実行します。次に、前の手順をもう一度試し、`heirloom-mailx`を`mail`コマンドに置き換えます。

1. `incoming`アカウントからサインアウトし、`root`に戻ります:

   ```shell
   logout
   ```

## Courier IMAPサーバーをインストールする {#install-the-courier-imap-server}

1. `courier-imap`パッケージをインストールします:

   ```shell
   sudo apt-get install courier-imap
   ```

   そして、`imapd`を起動します:

   ```shell
   imapd start
   ```

1. `courier-authdaemon`はインストール後に開始されません。それがないと、IMAP認証が失敗します:

   ```shell
   sudo service courier-authdaemon start
   ```

   ブート時に起動するように`courier-authdaemon`を構成することもできます:

   ```shell
   sudo systemctl enable courier-authdaemon
   ```

## インターネットからメールを受信するようにPostfixを構成する {#configure-postfix-to-receive-email-from-the-internet}

1. Postfixに、ローカルと見なす必要があるドメインを知らせます:

   ```shell
   sudo postconf -e "mydestination = gitlab.example.com, localhost.localdomain, localhost"
   ```

1. Postfixに、LANの一部と見なす必要があるIPを知らせます:

   `192.168.1.0/24`がローカルLANであると仮定しましょう。同じローカルネットワークに他のマシンがない場合は、この手順を安全にスキップできます。

   ```shell
   sudo postconf -e "mynetworks = 127.0.0.0/8, 192.168.1.0/24"
   ```

1. インターネットを含むすべてのインターフェースでメールを受信するようにPostfixを構成します:

   ```shell
   sudo postconf -e "inet_interfaces = all"
   ```

1. サブアドレス指定に`+`デリミターを使用するようにPostfixを構成します:

   ```shell
   sudo postconf -e "recipient_delimiter = +"
   ```

1. Postfixを再起動します:

   ```shell
   sudo service postfix restart
   ```

## 最終セットアップをテストする {#test-the-final-setup}

1. 新しいセットアップでSMTPをテストします:

   1. SMTPサーバーに接続します:

      ```shell
      telnet gitlab.example.com 25
      ```

      次のようなプロンプトが表示されます:

      ```shell
      Trying 123.123.123.123...
      Connected to gitlab.example.com.
      Escape character is '^]'.
      220 gitlab.example.com ESMTP Postfix (Ubuntu)
      ```

      代わりに`Connection refused`エラーが発生した場合は、ファイアウォールがポート25での受信トラフィックを許可するように設定されていることを確認してください。

   1. SMTPをテストするために、次のスニペットをSMTPプロンプトに入力して、`incoming`ユーザーにメールを送信します:

      ```plaintext
      ehlo gitlab.example.com
      mail from: root@gitlab.example.com
      rcpt to: incoming@gitlab.example.com
      data
      Subject: Re: Some issue

      Sounds good!
      .
      quit
      ```

      {{< alert type="note" >}}

      `.`は、それ自体の行にあるリテラルピリオドです。

      {{< /alert >}}

   1. `incoming`ユーザーがメールを受信したかどうかを確認します:

      ```shell
      su - incoming
      MAIL=/home/incoming/Maildir
      mail
      ```

      次のような出力が表示されます:

      ```plaintext
      "/home/incoming/Maildir": 1 message 1 unread
      >U   1 root@gitlab.example.com                           59/2842  Re: Some issue
      ```

      メールアプリを終了します:

      ```shell
      q
      ```

   1. `incoming`アカウントからサインアウトし、`root`に戻ります:

      ```shell
      logout
      ```

1. 新しいセットアップでIMAPをテストします:

   1. IMAPサーバーに接続します:

      ```shell
      telnet gitlab.example.com 143
      ```

      次のようなプロンプトが表示されます:

      ```shell
      Trying 123.123.123.123...
      Connected to mail.gitlab.example.com.
      Escape character is '^]'.
      - OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION] Courier-IMAP ready. Copyright 1998-2011 Double Precision, Inc.  See COPYING for distribution information.
      ```

   1. `incoming`ユーザーとしてサインインしてIMAPをテストするには、次のスニペットをIMAPプロンプトに入力します:

      ```plaintext
      a login incoming PASSWORD
      ```

      `incoming`ユーザーに以前に設定したパスワードでPASSWORDを置き換えます。

      次のような出力が表示されます:

      ```plaintext
      a OK LOGIN Ok.
      ```

   1. IMAPサーバーから切断します:

      ```shell
      a logout
      ```

## 完了 {#done}

すべてのテストが成功した場合、Postfixはすべて設定され、メールを受信する準備ができています。GitLabを構成するには、[受信メール](incoming_email.md)ガイドに進みます。

---

_このドキュメントは、UbuntuドキュメントWikiのコントリビューターによる<https://help.ubuntu.com/community/PostfixBasicSetupHowto>を基に作成されました。_

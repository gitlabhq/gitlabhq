---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabとKerberosの連携のトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

KerberosインテグレーションでGitLabを使用する場合、次の問題が発生する可能性があります。

## Windows ADに対するKerberos認証でのGoogle Chromeの使用 {#using-google-chrome-with-kerberos-authentication-against-windows-ad}

Google Chromeを使用してKerberosでGitLabにサインインする場合は、完全なユーザー名を入力する必要があります。たとえば`username@domain.com`などです。

完全なユーザー名を入力しないと、サインインに失敗します。ログを確認して、このサインインの失敗の証拠として、次のイベントメッセージが表示されることを確認してください:

```plain
"message":"OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested\nUnknown error".
```

## GitLabサーバーとKerberosサーバー間の接続をテストする {#test-connectivity-between-the-gitlab-and-kerberos-servers}

ユーティリティ（[`kinit`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/kinit.html)や[`klist`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/klist.html)など）を使用して、GitLabサーバーとKerberosサーバー間の接続をテストできます。これらのインストール方法は、特定のOSによって異なります。

`klist`を使用して、`keytab`ファイルで使用可能なサービスプリンシパル名（SPN）と、各SPNの暗号化タイプを表示します:

```shell
klist -ke /etc/http.keytab
```

Ubuntuサーバーでは、出力は次のようになります:

```shell
Keytab name: FILE:/etc/http.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   3 HTTP/my.gitlab.domain@MY.REALM (des-cbc-crc)
   3 HTTP/my.gitlab.domain@MY.REALM (des-cbc-md5)
   3 HTTP/my.gitlab.domain@MY.REALM (arcfour-hmac)
   3 HTTP/my.gitlab.domain@MY.REALM (aes256-cts-hmac-sha1-96)
   3 HTTP/my.gitlab.domain@MY.REALM (aes128-cts-hmac-sha1-96)
```

詳細モードで`kinit`を使用して、GitLabがキータブファイルを使用してKerberosサーバーに接続できるかどうかをテストします:

```shell
KRB5_TRACE=/dev/stdout kinit -kt /etc/http.keytab HTTP/my.gitlab.domain@MY.REALM
```

このコマンドは、認証プロセスの詳細な出力を表示します。

## サポートされていないGSSAPIメカニズム {#unsupported-gssapi-mechanism}

Kerberos SPNEGO認証では、ブラウザはサポートするメカニズムのリストをGitLabに送信することが期待されます。サポートされているメカニズムをGitLabがサポートしていない場合、認証は失敗し、ログに次のようなメッセージが表示されます:

```plaintext
OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested Unknown error
```

このエラーメッセージには、多くの潜在的な原因と解決策があります。

### 専用ポートを使用していないKerberosインテグレーション {#kerberos-integration-not-using-a-dedicated-port}

Kerberosインテグレーションが[専用ポートを使用](kerberos.md#http-git-access-with-kerberos-token-passwordless-authentication)するように構成されていない限り、GitLab継続的インテグレーション/継続的デリバリーは、Kerberos対応のGitLabインスタンスでは機能しません。

### クライアントマシンとKerberosサーバー間の接続不足 {#lack-of-connectivity-between-client-machine-and-kerberos-server}

これは通常、ブラウザがKerberosサーバーに直接接続できない場合に発生します。サポートされていないメカニズム（[`IAKERB`](https://k5wiki.kerberos.org/wiki/Projects/IAKERB)）にフォールバックします。これは、Kerberosサーバーへの仲介役としてGitLabサーバーを使用しようとします。

このエラーが発生している場合は、クライアントマシンとKerberosサーバーの間に接続があることを確認してください。これは前提条件です。トラフィックはファイアウォールによってブロックされるか、DNSレコードが正しくない可能性があります。

### エラー: `GitLab DNS record is a CNAME record` {#gitlab-dns-record-is-a-cname-record-error}

GitLabが`CNAME`レコードで参照されている場合、Kerberosは次のエラーで失敗します。この問題を解決するには、GitLabのDNSレコードが`A`レコードであることを確認してください。

### GitLabインスタンスのホスト名のフォワードDNSレコードとリバースDNSレコードが一致しません {#mismatched-forward-and-reverse-dns-records-for-gitlab-instance-hostname}

別の失敗モードは、GitLabサーバーのフォワードDNSレコードとリバースDNSレコードが一致しない場合に発生します。多くの場合、Windowsクライアントはこの場合に機能しますが、Linuxクライアントは失敗します。Kerberosレルムを検出する際に、リバースドメインネームシステムを使用します。間違ったレルムを取得すると、通常のKerberosメカニズムが失敗するため、クライアントは`IAKERB`のネゴシエートを試行することにフォールバックし、以前の認証エラーメッセージが表示されます。

これを修正するには、GitLabサーバーのフォワードドメインネームシステムとリバースドメインネームシステムが一致することを確認してください。たとえば、GitLabに`gitlab.example.com`としてアクセスし、IPアドレス`10.0.2.2`に解決する場合、`2.2.0.10.in-addr.arpa`は`gitlab.example.com`の`PTR`レコードである必要があります。

### ブラウザまたはクライアントマシンにKerberosライブラリがありません {#missing-kerberos-libraries-on-browser-or-client-machine}

最後に、ブラウザまたはクライアントマシンにKerberosサポートがまったくない可能性があります。Kerberosライブラリがインストールされていること、および他のKerberosサービスに対して認証できることを確認してください。

## HTTP Basic: クローン作成時にアクセスが拒否されました {#http-basic-access-denied-when-cloning}

```shell
remote: HTTP Basic: Access denied
fatal: Authentication failed for '<KRB5 path>'
```

Git v2.11以降を使用している場合にクローン作成時に上記のエラーが表示される場合は、`http.emptyAuth` Gitオプションを`true`に設定して、これを修正できます:

```shell
git config --global http.emptyAuth true
```

## プロキシHTTPS経由でのKerberosを使用したGitクローン作成 {#git-cloning-with-kerberos-over-proxied-https}

以下に該当する場合は、コメントする必要があります:

- `http://`URLが**KRB5 Gitクローン作成でクローン**オプションに表示される場合に、`https://`URLが予期されます。
- HTTPSはGitLabインスタンスで終了しませんが、代わりにロードバランサーまたはローカルトラフィックマネージャーによってプロキシされます。

```shell
# gitlab_rails['kerberos_https'] = false
```

こちらも参照してください: [Git v2.11リリースノート](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.adoc?plain=1#L482-L486)

## お役立ちリンク {#helpful-links}

- <https://help.ubuntu.com/community/Kerberos>
- <https://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html>
- <https://www.roguelynn.com/words/explain-like-im-5-kerberos/>

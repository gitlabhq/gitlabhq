---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SSHキーを使用してGitLabと通信する
description: セキュアな認証とリポジトリアクセスのためSSHキーをGitLabで使用する方法について説明します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitは分散型バージョン管理システムです。ローカルで作業してから、変更をサーバーに共有または*プッシュ*できます。この場合、プッシュ先のサーバーはGitLabです。

GitLabはSSHプロトコルを使用して、Gitと安全に通信します。SSHキーを使用してGitLabリモートサーバーに対して認証する場合、毎回ユーザー名とパスワードを入力する必要はありません。

## SSHキーとは {#what-are-ssh-keys}

SSHは、公開キーと秘密キーの2つのキーを使用します。

- 公開キーは配布できます。
- 秘密キーは保護する必要があります。

公開キーをアップロードしても、機密データが漏洩することはありません。SSH公開キーをコピーまたはアップロードする際に、誤って秘密キーをコピーまたはアップロードしないように注意してください。

秘密キーを使用して[コミットに署名](project/repository/signed_commits/ssh.md)することができ、これによりGitLabの使用とデータの安全性がさらに向上します。この署名は、公開キーを使用して誰でも検証できます。

詳細については、[公開キー暗号としても知られる非対称暗号](https://en.wikipedia.org/wiki/Public-key_cryptography)を参照してください。

## 前提要件 {#prerequisites}

SSHを使用してGitLabと通信するには、以下が必要です。

- GNU/Linux、macOS、およびWindows 10にプリインストールされているOpenSSHクライアント。
- SSHバージョン6.5以降。それ以前のバージョンではMD5署名を使用していましたが、これは安全ではありません。

システムにインストールされているSSHのバージョンを確認するには、`ssh -V`を実行します。

## サポートされているSSHキーの種類 {#supported-ssh-key-types}

GitLabとの通信には、次のSSHキーの種類を使用できます。

- [ED25519](#ed25519-ssh-keys)
- [ED25519_SK](#ed25519_sk-ssh-keys)
- [ECDSA_SK](#ecdsa_sk-ssh-keys)
- [RSA](#rsa-ssh-keys)
- ECDSA（[Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa)（実用的な暗号化とGo）で述べられているように、DSAに関連するセキュリティの問題はECDSAにも適用されます）。

管理者は、[許可されるキーとその最小長を制限](../security/ssh_keys_restrictions.md)できます。

### ED25519 SSHキー {#ed25519-ssh-keys}

[Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-chapter-5-digital-signatures)（実用的な暗号化とGo）の書籍では、[ED25519](https://ed25519.cr.yp.to/)キーはRSAキーよりも安全で高性能であることが示唆されています。

OpenSSH 6.5は2014年にED25519 SSHキーを導入するなど、ほとんどのオペレーティングシステムで利用可能になっています。

{{< alert type="note" >}}

ED25519キーは、すべてのFIPSシステムで完全にサポートされていない可能性があります。詳細については、[イシュー367429](https://gitlab.com/gitlab-org/gitlab/-/issues/367429)を参照してください。

{{< /alert >}}

### ED25519_SK SSHキー {#ed25519_sk-ssh-keys}

GitLabでED25519_SK SSHキーを使用するには、ローカルクライアントとGitLabサーバーに[OpenSSH 8.2](https://www.openssh.com/releasenotes.html#8.2)以降がインストールされている必要があります。

### ECDSA_SK SSHキー {#ecdsa_sk-ssh-keys}

GitLabでECDSA_SK SSHキーを使用するには、ローカルクライアントとGitLabサーバーに[OpenSSH 8.2](https://www.openssh.com/releasenotes.html#8.2)以降がインストールされている必要があります。

### RSA SSHキー {#rsa-ssh-keys}

{{< history >}}

- GitLab 16.3でRSAキーの最大長が[変更](https://gitlab.com/groups/gitlab-org/-/epics/11186)されました。

{{< /history >}}

入手可能なドキュメントでは、ED25519がRSAよりも安全であることが示唆されています。

RSAキーを使用する場合、米国立標準技術研究所の[Publication 800-57 Part 3 (PDF)](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf)は、少なくとも2048ビットのキーサイズを推奨しています。Goの制限により、RSAキーは[8192ビットを超えることはできません](ssh_troubleshooting.md#tls-server-sent-certificate-containing-rsa-key-larger-than-8192-bits)。

デフォルトのキーサイズは、`ssh-keygen`のバージョンによって異なります。詳細については、インストールされている`ssh-keygen`コマンドの`man`ページを確認してください。

## 既存のSSHキーペアの有無を確認する {#see-if-you-have-an-existing-ssh-key-pair}

キーペアを作成する前に、キーペアがすでに存在するかどうかを確認します。

1. ホームディレクトリに移動します。
1. `.ssh/`サブディレクトリに移動します。`.ssh/`サブディレクトリが存在しない場合は、ホームディレクトリにいないか、以前に`ssh`を使用したことがないかのどちらかです。後者の場合は、[SSHキーペアを生成する](#generate-an-ssh-key-pair)必要があります。
1. 次のいずれかの形式のファイルが存在するかどうかを確認します。

   | アルゴリズム             | 公開キー | 秘密キー |
   |-----------------------|------------|-------------|
   |  ED25519（推奨）  | `id_ed25519.pub` | `id_ed25519` |
   |  ED25519_SK           | `id_ed25519_sk.pub` | `id_ed25519_sk` |
   |  ECDSA_SK             | `id_ecdsa_sk.pub` | `id_ecdsa_sk` |
   |  RSA（少なくとも2048ビットのキーサイズ） | `id_rsa.pub` | `id_rsa` |
   |  DSA（非推奨）     | `id_dsa.pub` | `id_dsa` |
   |  ECDSA                | `id_ecdsa.pub` | `id_ecdsa` |

## SSHキーペアを生成する {#generate-an-ssh-key-pair}

既存のSSHキーペアがない場合は、新しいキーペアを生成します。

1. ターミナルを開きます。
1. 末尾にキーの種類とオプションのコメントを付けて`ssh-keygen -t`を実行します。このコメントは、作成される`.pub`ファイルに含まれています。コメントにメールアドレスを使用することもできます。

   例（ED25519の場合）:

   ```shell
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   2048ビットRSAの場合:

   ```shell
   ssh-keygen -t rsa -b 2048 -C "<comment>"
   ```

1. <kbd>Enter</kbd>キーを押します。次のような出力が表示されます。

   ```plaintext
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/user/.ssh/id_ed25519):
   ```

1. [デプロイキー](project/deploy_keys/_index.md)を生成する場合、または他のキーを保存する特定のディレクトリに保存したい場合を除き、提案されたファイル名とディレクトリをそのまま使用します。

   SSHキーペアを[特定のホスト専用](#configure-ssh-to-point-to-a-different-directory)にすることもできます。

1. [パスフレーズ](https://www.ssh.com/academy/ssh/passphrase)を指定します。

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   ファイルの保存場所に関する情報を含む確認メッセージが表示されます。

公開キーと秘密キーが生成されます。[GitLabアカウントに公開SSHキーを追加](#add-an-ssh-key-to-your-gitlab-account)し、秘密キーを安全に保管してください。

### 別のディレクトリを指定するようにSSHを設定する {#configure-ssh-to-point-to-a-different-directory}

SSHキーペアをデフォルトディレクトリに保存しなかった場合は、秘密キーが保存されているディレクトリを指すようにSSHクライアントを設定します。

1. ターミナルを開き、次のコマンドを実行します。

   ```shell
   eval $(ssh-agent -s)
   ssh-add <directory to private SSH key>
   ```

1. これらの設定を`~/.ssh/config`ファイルに保存します。次に例を示します。

   ```conf
   # GitLab.com
   Host gitlab.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/gitlab_com_rsa

   # Private GitLab instance
   Host gitlab.company.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/example_com_rsa
   ```

これらの設定の詳細については、SSH設定マニュアルの[`man ssh_config`](https://man.openbsd.org/ssh_config)ページを参照してください。

公開SSHキーはアカウントに紐付けられるため、GitLabに対して一意である必要があります。SSHを使用してコードをプッシュする際、SSHキーは唯一の識別子となります。SSHキーは単一のユーザーに一意にマップする必要があります。

## GitLabアカウントにSSHキーを追加する {#add-an-ssh-key-to-your-gitlab-account}

{{< history >}}

- キーに推奨されるデフォルトの有効期限は、GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/271239)されました。
- SSHキーの使用タイプは、GitLab 15.7で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/383046)されました。

{{< /history >}}

SSHをGitLabで使用するには、公開キーをGitLabアカウントにコピーします。

1. 公開キーファイルの内容をコピーします。これは手動で行うことも、スクリプトを使用することもできます。

   これらの例では、`id_ed25519.pub`をファイル名に置き換えてください。たとえば、RSAの場合は、`id_rsa.pub`を使用します。

   {{< tabs >}}

   {{< tab title="macOS" >}}

   ```shell
   tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
   ```

   {{< /tab >}}

   {{< tab title="Linux（xclipパッケージが必要）" >}}

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   {{< /tab >}}

   {{< tab title="Windows上のGit Bash" >}}

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. GitLabにサインインします。
1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで**SSHキー**を選択します。
1. **新しいキーを追加**を選択します。
1. **キー**ボックスに、公開キーの内容を貼り付けます。キーを手動でコピーする場合は、`ssh-rsa`、`ssh-dss`、`ecdsa-sha2-nistp256`、`ecdsa-sha2-nistp384`、`ecdsa-sha2-nistp521`、`ssh-ed25519`、`sk-ecdsa-sha2-nistp256@openssh.com`、または`sk-ssh-ed25519@openssh.com`で始まり、コメントで終わる可能性があるキー全体をコピーしていることを確認してください。
1. **タイトル**ボックスに、`Work Laptop`や`Home Workstation`などの説明を入力します。
1. オプション。キーの**使用タイプ**を選択します。`Authentication`（認証）または`Signing`（署名）のいずれか、またはその両方で使用できます。`Authentication & Signing`（認証と署名）がデフォルト値です。
1. オプション。**有効期限**を更新して、デフォルトの有効期限を変更します。
   - 管理者は有効期限を確認し、[キーを削除](../administration/credentials_inventory.md#delete-ssh-keys)する際の判断材料として活用できます。
   - GitLabは毎日午前01:00（UTC）にすべてのSSHキーをチェックします。7日後に有効期限切れになるすべてのSSHキーについて、有効期限をメールで通知します。
   - GitLabは毎日午前02:00（UTC）にすべてのSSHキーをチェックします。当日有効期限切れになるすべてのSSHキーについて、有効期限をメールで通知します。
1. **キーを追加**を選択します。

## 接続できることを確認する {#verify-that-you-can-connect}

SSHキーが正しく追加されたことを確認します。

1. 正しいサーバーに接続していることを確認するには、サーバーのSSHホストキーのフィンガープリントを確認してください。詳細は以下の説明を参照してください。
   - GitLab.comの場合は、[SSHホストキーのフィンガープリント](gitlab_com/_index.md#ssh-host-keys-fingerprints)に関するドキュメントを参照してください。
   - GitLab Self-ManagedまたはGitLab Dedicatedの場合は、`https://gitlab.example.com/help/instance_configuration#ssh-host-keys-fingerprints`を参照してください（`gitlab.example.com`はGitLabインスタンスのURLです）。
1. ターミナルを開き、このコマンドを実行します。`gitlab.example.com`をGitLabのインスタンスURLに置き換えてください。

   ```shell
   ssh -T git@gitlab.example.com
   ```

1. 今回初めて接続する場合は、GitLabホストの信頼性を検証する必要があります。次のようなメッセージが表示された場合:

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)? yes
   Warning: Permanently added 'gitlab.example.com' (ECDSA) to the list of known hosts.
   ```

   `yes`と入力して<kbd>Enter</kbd>キーを押します。

1. `ssh -T git@gitlab.example.com`コマンドをもう一度実行します。_Welcome to GitLab, `@username`!_というメッセージが表示されます。

ウェルカムメッセージが表示されない場合は、verboseモードで`ssh`を実行して問題を解決します。

```shell
ssh -Tvvv git@gitlab.example.com
```

デフォルトでは、GitLabは`git`ユーザー名を使用して認証します。[管理者によって変更](https://docs.gitlab.com/omnibus/settings/configuration.html#change-the-name-of-the-git-user-or-group)されている場合は、異なる可能性があります。

## SSHキーのパスフレーズを更新する {#update-your-ssh-key-passphrase}

次の手順で、SSHキーのパスフレーズを更新できます。

1. ターミナルを開き、次のコマンドを実行します。

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. プロンプトでパスフレーズを入力し、<kbd>Enter</kbd>キーを押します。

## RSAキーペアをより安全な形式にアップグレードする {#upgrade-your-rsa-key-pair-to-a-more-secure-format}

OpenSSHのバージョンが6.5 ～ 7.8の場合は、秘密RSA SSHキーをより安全なOpenSSH形式で保存できます。ターミナルを開いて次のコマンドを実行します。

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

または、次のコマンドを実行して、より安全な暗号化形式で新しいRSAキーを生成することもできます。

```shell
ssh-keygen -o -t rsa -b 4096 -C "<comment>"
```

## FIDO2ハードウェアセキュリティキー向けのSSHキーペアを生成する {#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key}

ED25519_SKまたはECDSA_SK SSHキーを生成するには、OpenSSH 8.2以降を使用する必要があります。

1. ハードウェアセキュリティキーをコンピューターに挿入します。
1. ターミナルを開きます。
1. 末尾にキーの種類とオプションのコメントを付けて`ssh-keygen -t`を実行します。このコメントは、作成される`.pub`ファイルに含まれています。コメントにメールアドレスを使用することもできます。

   たとえば、ED25519_SKの場合:

   ```shell
   ssh-keygen -t ed25519-sk -C "<comment>"
   ```

   ECDSA_SKの場合:

   ```shell
   ssh-keygen -t ecdsa-sk -C "<comment>"
   ```

   セキュリティキーがFIDO2レジデントキーをサポートしている場合は、SSHキーの作成時に有効にできます。

   ```shell
   ssh-keygen -t ed25519-sk -O resident -C "<comment>"
   ```

   `-O resident`は、キーをFIDO認証システム自体に保存する必要があることを示します。レジデントキーは、[`ssh-add -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-add.1#K)または[`ssh-keygen -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-keygen#K)を使用してセキュリティキーから直接読み込むことができるため、新しいコンピューターへのインポートが簡単です。

1. <kbd>Enter</kbd>キーを押します。次のような出力が表示されます。

   ```plaintext
   Generating public/private ed25519-sk key pair.
   You may need to touch your authenticator to authorize key generation.
   ```

1. ハードウェアセキュリティキーのボタンを押します。

1. 提案されたファイル名とディレクトリをそのまま使用します。

   ```plaintext
   Enter file in which to save the key (/home/user/.ssh/id_ed25519_sk):
   ```

1. [パスフレーズ](https://www.ssh.com/academy/ssh/passphrase)を指定します。

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   ファイルの保存場所に関する情報を含む確認メッセージが表示されます。

公開キーと秘密キーが生成されます。[GitLabアカウントに公開SSHキーを追加](#add-an-ssh-key-to-your-gitlab-account)します。

## 1PasswordでSSHキーペアを生成する {#generate-an-ssh-key-pair-with-1password}

[1Password](https://1password.com/)と[1Passwordブラウザ拡張機能](https://support.1password.com/getting-started-browser/)を使用して、次のいずれかを行うことができます。

- 新しいSSHキーを自動的に生成する。
- 1Password Vaultにある既存のSSHキーを使用してGitLabで認証する。

1. GitLabにサインインします。
1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで**SSHキー**を選択します。
1. **新しいキーを追加**を選択します。
1. **キー**を選択すると、1Passwordヘルパーが表示されます。
1. 1Passwordアイコンを選択し、1Passwordのロックを解除します。
1. **SSHキーの作成**を選択するか、既存のSSHキーを選択して公開キーを入力できます。
1. **タイトル**ボックスに、`Work Laptop`や`Home Workstation`などの説明を入力します。
1. オプション。キーの**使用タイプ**を選択します。`Authentication`（認証）または`Signing`（署名）のいずれか、またはその両方で使用できます。`Authentication & Signing`（認証と署名）がデフォルト値です。
1. オプション。**有効期限**を更新して、デフォルトの有効期限を変更します。
1. **キーを追加**を選択します。

1PasswordでSSHキーを使用する詳しい方法については、[1Passwordドキュメント](https://developer.1password.com/docs/ssh/get-started/)を参照してください。

## リポジトリごとに異なるキーを使用する {#use-different-keys-for-different-repositories}

リポジトリごとに異なるキーを使用できます。

ターミナルを開き、次のコマンドを実行します。

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

このコマンドはSSHエージェントを使用せず、Git 2.10以降が必要です。`ssh`コマンドオプションの詳細については、`ssh`と`ssh_config`の両方の`man`ページを参照してください。

## SSHキーを表示する {#view-your-ssh-keys}

次の手順でアカウントのSSHキーを表示できます。

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで**SSHキー**を選択します。

既存のSSHキーがページの下部に一覧表示されます。情報には次のものが含まれます。

- キーのタイトル
- 公開フィンガープリント
- 許可されている使用タイプ
- 作成日
- 最終使用日
- 有効期限

## SSHキーを削除する {#remove-an-ssh-key}

SSHキーを取り消すか削除して、アカウントから完全に削除できます。

SSHキーでコミットに署名している場合、SSHキーを削除すると、他の影響もあります。詳細については、[削除されたSSHキーで署名されたコミット](project/repository/signed_commits/ssh.md#signed-commits-with-removed-ssh-keys)を参照してください。

### SSHキーを取り消す {#revoke-an-ssh-key}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108344)されました。

{{< /history >}}

SSHキーのセキュリティが侵害された場合は、キーを取り消します。

前提要件:

- SSHキーには、`Signing`（署名）または`Authentication & Signing`（認証と署名）の使用タイプが必要です。

次の手順でSSHキーを取り消せます。

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで**SSHキー**を選択します。
1. 取り消したいSSHキーの横にある**取り消し**を選択します。
1. **取り消し**を選択します。

### SSHキーを削除する {#delete-an-ssh-key}

次の手順でSSHキーを削除できます。

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで**SSHキー**を選択します。
1. 削除したいキーの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. **削除**を選択します。

## 単一のGitLabインスタンスで異なるアカウントを使用する {#use-different-accounts-on-a-single-gitlab-instance}

複数のアカウントを使用して、GitLabの単一インスタンスに接続できます。[前のトピック](#use-different-keys-for-different-repositories)で説明したコマンドを使用すると、これを行うことができます。ただし、`IdentitiesOnly`を`yes`に設定しても、`IdentityFile`が`Host`ブロックの外に存在する場合、サインインできません。

代わりに、`~/.ssh/config`ファイルでホストにエイリアスを割り当てることができます。

- `Host`には、`user_1.gitlab.com`や`user_2.gitlab.com`のようなエイリアスを使用します。高度な構成は維持が難しく、`git remote`のようなツールを使用する場合、これらの文字列の方が理解しやすくなります。
- `IdentityFile`には、秘密キーのパスを使用します。

```conf
# User1 Account Identity
Host <user_1.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key1>

# User2 Account Identity
Host <user_2.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key2>
```

`user_1`のリポジトリをクローンするには、`git clone`コマンドで`user_1.gitlab.com`を使用します。

```shell
git clone git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

`origin`としてエイリアスされている、以前にクローンしたリポジトリを更新するには、次のコマンドを使用します。

```shell
git remote set-url origin git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

{{< alert type="note" >}}

秘密キーと公開キーには機密データが含まれています。ファイルに対する権限を調節し、自分には読み取り可能でも他のユーザーにはアクセスできないように設定してください。

{{< /alert >}}

## 2FA（2要素認証）を設定する {#configure-two-factor-authentication-2fa}

[SSH経由のGit](../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations)に2要素認証（2FA）を設定できます。[ED25519_SK](#ed25519_sk-ssh-keys)または[ECDSA_SK](#ecdsa_sk-ssh-keys) SSHキーを使用する必要があります。

## EclipseでEGitを使用する {#use-egit-on-eclipse}

[EGit](https://projects.eclipse.org/projects/technology.egit)を使用している場合は、[EclipseにSSHキーを追加](https://wiki.eclipse.org/EGit/User_Guide/#Eclipse_SSH_Configuration)できます。

## Microsoft WindowsでSSHを使用する {#use-ssh-on-microsoft-windows}

Windows 10を実行している場合は、`git`と`ssh`の両方がプリインストールされている[WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2)を備えた[Linux用Windowsサブシステム（WSL）](https://learn.microsoft.com/en-us/windows/wsl/install)を使用するか、[Git for Windows](https://gitforwindows.org)をインストールしてPowerShell経由でSSHを使用できます。

WSLで生成されたSSHキーは、Git for Windowsでは直接利用できません。その逆も同様です。これはホームディレクトリが異なるためです。

- WSL: `/home/<user>`
- Git for Windows: `C:\Users\<user>`

`.ssh/`ディレクトリをコピーして同じキーを使用するか、各環境でキーを生成します。

Windows 11を実行していて、[OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/OpenSSH/openssh-overview)を使用している場合は、`HOME`環境変数が正しく設定されていることを確認してください。正しく設定されていない場合、秘密SSHキーが見つからない可能性があります。

代替ツールは次のとおりです。

- [Cygwin](https://www.cygwin.com)
- [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 0.81以降（以前のバージョンは[情報漏洩攻撃に対して脆弱](https://www.openwall.com/lists/oss-security/2024/04/15/6)です）

## GitLabサーバー上のSSH設定をオーバーライドする {#overriding-ssh-settings-on-the-gitlab-server}

GitLabはシステムにインストールされたSSHデーモンと統合し、すべてのアクセス要求が処理されるユーザー（通常は`git`という名前）を指定します。SSH経由でGitLabサーバーに接続するユーザーは、ユーザー名ではなくSSHキーによって識別されます。

GitLabサーバーで実行されるSSH*クライアント*操作は、このユーザーとして実行されます。このSSH設定は変更できます。たとえば、認証リクエストに使用する秘密SSHキーをこのユーザーに指定できます。ただし、この方法は**サポートされていません**。重大なセキュリティリスクがあるため、きわめて非推奨とされています。

GitLabはこの状態をチェックし、サーバーがこの方法で設定されている場合は、このセクションに誘導します。次に例を示します。

```shell
$ gitlab-rake gitlab:check

Git user has default SSH configuration? ... no
  Try fixing it:
  mkdir ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa.pub ~/gitlab-check-backup-1504540051
  For more information see:
  doc/user/ssh.md#overriding-ssh-settings-on-the-gitlab-server
  Please fix the error above and rerun the checks.
```

できるだけ早くカスタム設定を削除してください。これらのカスタマイズは**明示的にサポートされていません**。予告なく動作しなくなる可能性があります。

## GitLab SSHの所有権と権限を確認する {#verify-gitlab-ssh-ownership-and-permissions}

GitLab SSHフォルダとファイルには、次の権限が必要です。

- `/var/opt/gitlab/.ssh/`フォルダは、`git`グループと`git`ユーザーが所有し、権限は`700`に設定されている必要があります。
- `authorized_keys`ファイルの権限は`600`に設定されている必要があります。
- `authorized_keys.lock`ファイルの権限は`644`に設定されている必要があります。

これらの権限が正しいことを確認するには、次のスクリプトを実行します。

```shell
stat -c "%a %n" /var/opt/gitlab/.ssh/.
```

### 権限を設定する {#set-permissions}

権限が間違っている場合は、アプリケーションサーバーにサインインして次を実行します。

```shell
cd /var/opt/gitlab/
chown git:git /var/opt/gitlab/.ssh/
chmod 700  /var/opt/gitlab/.ssh/
chmod 600  /var/opt/gitlab/.ssh/authorized_keys
chmod 644  /var/opt/gitlab/.ssh/authorized_keys.lock
```

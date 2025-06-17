---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SSH鍵を使用してGitLabと通信する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitは分散型バージョン管理システムです。ローカルで作業してから、変更をサーバーに共有または*プッシュ*できます。この場合、プッシュ先のサーバーはGitLabです。

GitLabはSSHプロトコルを使用して、Gitと安全に通信します。SSH鍵を使用してGitLabリモートサーバーに対して認証する場合、毎回ユーザー名とパスワードを入力する必要はありません。

## SSH鍵とは

SSHは、公開キーと秘密キーの2つのキーを使用します。

- 公開キーは配布できます。
- 秘密キーは保護する必要があります。

公開キーをアップロードしても、機密データが漏えいすることはありません。SSH公開鍵をコピーまたはアップロードする必要がある場合は、誤って秘密キーをコピーまたはアップロードしないように注意してください。

秘密キーを使用して[コミットに署名する](project/repository/signed_commits/ssh.md)と、GitLabの使用とデータの安全性がさらに向上します。この署名は、公開キーを使用して誰でも検証できます。

詳細については、[公開鍵暗号としても知られる非対称暗号](https://en.wikipedia.org/wiki/Public-key_cryptography)を参照してください。

## 前提要件

SSHを使用してGitLabと通信するには、以下が必要です。

- GNU/Linux、macOS、およびWindows 10にプリインストールされているOpenSSHクライアント。
- SSHバージョン6.5以降。以前のバージョンではMD5署名を使用していましたが、これは安全ではありません。

システムにインストールされているSSHのバージョンを表示するには、`ssh -V`を実行します。

## サポートされているSSH鍵の種類

GitLabとの通信には、次の種類のSSH鍵を使用できます。

- [ED25519](#ed25519-ssh-keys)
- [ED25519_SK](#ed25519_sk-ssh-keys)
- [ECDSA_SK](#ecdsa_sk-ssh-keys)
- [RSA](#rsa-ssh-keys)
- ECDSA（『[Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa)』で述べられているように、DSAに関連するセキュリティ上の問題はECDSAにも適用されます）。

管理者は、[許可されるキーとその最小長を制限](../security/ssh_keys_restrictions.md)できます。

### ED25519 SSH鍵

『[Practical Cryptography With Go](https://leanpub.com/gocrypto/read#leanpub-auto-chapter-5-digital-signatures)』の書籍では、[ED25519](https://ed25519.cr.yp.to/)キーはRSAキーよりも安全で高性能であることが示唆されています。

OpenSSH 6.5は、2014年にED25519 SSH鍵を導入するなど、ほとんどのオペレーティングシステムで利用可能になっています。

{{< alert type="note" >}}

ED25519キーは、すべてのFIPSシステムで完全にサポートされていない可能性があります。詳細については、[イシュー367429](https://gitlab.com/gitlab-org/gitlab/-/issues/367429)を参照してください。

{{< /alert >}}

### ED25519_SK SSH鍵

GitLabでED25519_SK SSH鍵を使用するには、ローカルクライアントとGitLabサーバーに[OpenSSH 8.2](https://www.openssh.com/releasenotes.html#8.2)以降がインストールされている必要があります。

### ECDSA_SK SSH鍵

GitLabでECDSA_SK SSH鍵を使用するには、ローカルクライアントとGitLabサーバーに[OpenSSH 8.2](https://www.openssh.com/releasenotes.html#8.2)以降がインストールされている必要があります。

### RSA SSH鍵

{{< history >}}

- GitLab 16.3で、RSAキーの最大長が[変更](https://gitlab.com/groups/gitlab-org/-/epics/11186)されました。

{{< /history >}}

入手可能なドキュメントでは、ED25519がRSAよりも安全であることが示唆されています。

RSAキーを使用する場合、米国立標準技術研究所の「[Publication 800-57 Part 3（PDF）](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf)」では、少なくとも2048ビットのキーサイズが推奨されています。Goの制限により、RSAキーは[8192ビットを超えることはできません](ssh_troubleshooting.md#tls-server-sent-certificate-containing-rsa-key-larger-than-8192-bits)。

デフォルトのキーサイズは、`ssh-keygen`のバージョンによって異なります。詳細については、インストールされている`ssh-keygen`コマンドの`man`ページを参照してください。

## 既存のSSH鍵ペアの有無を確認する

キーペアを作成する前に、キーペアがすでに存在するかどうかを確認します。

1. ホームディレクトリに移動します。
1. `.ssh/`サブディレクトリに移動します。`.ssh/`サブディレクトリが存在しない場合は、ホームディレクトリにいないか、以前に`ssh`を使用したことがありません。後者の場合は、[SSH鍵ペアを生成](#generate-an-ssh-key-pair)する必要があります。
1. 次のいずれかの形式のファイルが存在するかどうかを確認します。

   | アルゴリズム             | 公開キー | 秘密キー |
   |-----------------------|------------|-------------|
   |  ED25519（推奨）  | `id_ed25519.pub` | `id_ed25519` |
   |  ED25519_SK           | `id_ed25519_sk.pub` | `id_ed25519_sk` |
   |  ECDSA_SK             | `id_ecdsa_sk.pub` | `id_ecdsa_sk` |
   |  RSA（少なくとも2048ビットのキーサイズ） | `id_rsa.pub` | `id_rsa` |
   |  DSA（非推奨）     | `id_dsa.pub` | `id_dsa` |
   |  ECDSA                | `id_ecdsa.pub` | `id_ecdsa` |

## SSH鍵ペアを生成する

既存のSSH鍵ペアがない場合は、新しいキーペアを生成します。

1. ターミナルを開きます。
1. `ssh-keygen -t`の後にキータイプとオプションのコメントを入力して実行します。このコメントは、作成される`.pub`ファイルに含まれます。コメントにメールアドレスを使用することもできます。

   たとえば、ED25519の場合は次のようになります。

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

1. [デプロイキー](project/deploy_keys/_index.md)を生成する場合、または他のキーを格納する特定のディレクトリに保存する場合を除き、推奨されるファイル名とディレクトリを受け入れます。

   SSH鍵ペアを[特定のホスト専用](#configure-ssh-to-point-to-a-different-directory)にすることもできます。

1. [パスフレーズ](https://www.ssh.com/academy/ssh/passphrase)を指定します。

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   ファイルが保存されている場所に関する情報を含む確認メッセージが表示されます。

公開キーと秘密キーが生成されます。[GitLabアカウントに公開SSH鍵を追加](#add-an-ssh-key-to-your-gitlab-account)し、秘密キーを安全に保管してください。

### 別のディレクトリを指すようにSSHを設定する

デフォルトディレクトリにSSH鍵ペアを保存しなかった場合は、秘密キーが保存されているディレクトリを指すようにSSHクライアントを設定します。

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

公開SSH鍵はアカウントにバインドされるため、GitLabで一意である必要があります。SSH鍵は、SSHでコードをプッシュするときに使用する唯一の識別子です。単一のユーザーに一意にマップする必要があります。

### SSH鍵のパスフレーズを更新する

次の手順で、SSH鍵のパスフレーズを更新できます。

1. ターミナルを開き、次のコマンドを実行します。

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. プロンプトが表示されたら、パスフレーズを入力して<kbd>Enter</kbd>を押します。

### RSAキーペアをより安全な形式にアップグレードする

OpenSSHのバージョンが6.5～7.8の場合は、ターミナルを開いて次のコマンドを実行することにより、秘密RSA SSH鍵をより安全なOpenSSH形式で保存できます。

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

または、次のコマンドを実行して、より安全な暗号化形式で新しいRSAキーを生成することもできます。

```shell
ssh-keygen -o -t rsa -b 4096 -C "<comment>"
```

## FIDO2ハードウェアセキュリティキーのSSH鍵ペアを生成する

ED25519_SKまたはECDSA_SK SSH鍵を生成するには、OpenSSH 8.2以降を使用する必要があります。

1. ハードウェアセキュリティキーをコンピューターに挿入します。
1. ターミナルを開きます。
1. `ssh-keygen -t`の後にキータイプとオプションのコメントを入力して実行します。このコメントは、作成される`.pub`ファイルに含まれます。コメントにメールアドレスを使用することもできます。

   たとえば、ED25519_SKの場合は次のようになります。

   ```shell
   ssh-keygen -t ed25519-sk -C "<comment>"
   ```

   ECDSA_SKの場合:

   ```shell
   ssh-keygen -t ecdsa-sk -C "<comment>"
   ```

   セキュリティキーがFIDO2レジデントキーをサポートしている場合は、SSH鍵の作成時に有効にできます。

   ```shell
   ssh-keygen -t ed25519-sk -O resident -C "<comment>"
   ```

   `-O resident`は、キーをFIDO認証器自体に保存する必要があることを示します。レジデントキーは、[`ssh-add -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-add.1#K)または[`ssh-keygen -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-keygen#K)によってセキュリティキーから直接読み込むことができるため、新しいコンピューターへのインポートが簡単です。

1. <kbd>Enter</kbd>キーを押します。次のような出力が表示されます。

   ```plaintext
   Generating public/private ed25519-sk key pair.
   You may need to touch your authenticator to authorize key generation.
   ```

1. ハードウェアセキュリティキーのボタンを押します。

1. 推奨されるファイル名とディレクトリを受け入れます。

   ```plaintext
   Enter file in which to save the key (/home/user/.ssh/id_ed25519_sk):
   ```

1. [パスフレーズ](https://www.ssh.com/academy/ssh/passphrase)を指定します。

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   ファイルが保存されている場所に関する情報を含む確認メッセージが表示されます。

公開キーと秘密キーが生成されます。[GitLabアカウントにSSH公開鍵を追加](#add-an-ssh-key-to-your-gitlab-account)します。

## パスワードマネージャーでSSH鍵ペアを生成する

### 1PasswordでSSH鍵ペアを生成する

[1Password](https://1password.com/)と[1Passwordブラウザ拡張機能](https://support.1password.com/getting-started-browser/)を使用して、次のいずれかを行うことができます。

- 新しいSSH鍵を自動的に生成する。
- 1Password Vaultにある既存のSSH鍵を使用してGitLabで認証する。

1. GitLabにサインインします。
1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで**SSH鍵**を選択します。
1. **新しいキーを追加**を選択します。
1. **キー**を選択すると、1Passwordヘルパーが表示されます。
1. 1Passwordアイコンをクリックし、1Passwordのロックを解除します。
1. **SSHキーを作成**を選択するか、既存のSSH鍵を選択して公開キーを入力できます。
1. **タイトル**ボックスに、`Work Laptop`や`Home Workstation`などの説明を入力します。
1. オプション: キーの**使用タイプ**を選択します。`Authentication`または`Signing`のいずれか、またはその両方に使用できます。`Authentication & Signing`がデフォルト値です。
1. オプション: **有効期限**を更新して、デフォルトの有効期限を変更します。
1. **キーを追加**を選択します。

1PasswordでSSH鍵を使用する詳細については、[1Passwordのドキュメント](https://developer.1password.com/docs/ssh/get-started/)を参照してください。

## GitLabアカウントにSSH鍵を追加する

{{< history >}}

- GitLab 15.4で、キーに推奨されるデフォルトの有効期限が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/271239)されました。
- GitLab 15.7で、SSH鍵の使用タイプが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/383046)されました。

{{< /history >}}

SSHをGitLabで使用するには、公開キーをGitLabアカウントにコピーします。

1. 公開キーファイルの内容をコピーします。これは手動で行うことも、スクリプトを使用することもできます。たとえば、次のようにED25519キーをクリップボードにコピーします。

   **macOS**

   ```shell
   tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
   ```

   **Linux**（`xclip`パッケージが必要です）

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   **Windows上のGit Bash**

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   `id_ed25519.pub`をファイル名に置き換えます。たとえば、RSAには`id_rsa.pub`を使用します。

1. GitLabにサインインします。
1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで**SSH鍵**を選択します。
1. **新しいキーを追加**を選択します。
1. **キー**ボックスに、公開キーの内容を貼り付けます。キーを手動でコピーする場合は、必ずキー全体をコピーしてください。`ssh-rsa`、`ssh-dss`、`ecdsa-sha2-nistp256`、`ecdsa-sha2-nistp384`、`ecdsa-sha2-nistp521`、`ssh-ed25519`、`sk-ecdsa-sha2-nistp256@openssh.com`、または`sk-ssh-ed25519@openssh.com`で始まり、コメントで終わる可能性があります。
1. **タイトル**ボックスに、`Work Laptop`や`Home Workstation`などの説明を入力します。
1. オプション: キーの**使用タイプ**を選択します。`Authentication`または`Signing`のいずれか、またはその両方に使用できます。`Authentication & Signing`がデフォルト値です。
1. オプション: **有効期限**を更新して、デフォルトの有効期限を変更します。
   - 管理者は有効期限を表示し、[キーを削除](../administration/credentials_inventory.md#delete-ssh-keys)する際のガイダンスとして使用できます。
   - GitLabは毎日午前01:00（UTC）にすべてのSSH鍵をチェックします。7日後に期限切れになるすべてのSSH鍵について、有効期限をメールで通知します。
   - GitLabは毎日午前02:00（UTC）にすべてのSSH鍵をチェックします。今日の日付で期限切れになるすべてのSSH鍵について、有効期限をメールで通知します。
1. **キーを追加**を選択します。

## 接続できることを確認する

SSH鍵が正しく追加されたことを確認します。

次のコマンドでは、ホスト名の例として`gitlab.example.com`を使用しています。このホスト名の例を、GitLabインスタンスのホスト名（例: `git@gitlab.com`）に置き換えます。デフォルトでは、GitLabは認証に`git`ユーザー名を使用します。[管理者によって変更された](https://docs.gitlab.com/omnibus/settings/configuration.html#change-the-name-of-the-git-user-or-group)場合は、異なる場合があります。

1. 正しいサーバーに接続していることを確認するには、サーバーのSSHホストキーのフィンガープリントを確認してください。次のようにします。
   - GitLab.comについては、[SSHホストキーのフィンガープリント](gitlab_com/_index.md#ssh-host-keys-fingerprints)に関するドキュメントを参照してください。
   - GitLab.comまたは別のGitLabインスタンスの場合は、`gitlab.example.com/help/instance_configuration#ssh-host-keys-fingerprints`を参照してください。`gitlab.example.com`は`gitlab.com`（GitLab.comの場合）またはGitLabインスタンスのアドレスです。
1. ターミナルを開き、次のコマンドを実行します。`gitlab.example.com`はGitLabインスタンスのURLに置き換えてください。

   ```shell
   ssh -T git@gitlab.example.com
   ```

1. 今回が初めての接続の場合は、GitLabホストの信頼性を確認する必要があります。次のようなメッセージが表示された場合:

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)? yes
   Warning: Permanently added 'gitlab.example.com' (ECDSA) to the list of known hosts.
   ```

   `yes`と入力して<kbd>Enter</kbd>キーを押します。

1. `ssh -T git@gitlab.example.com`コマンドを再度実行します。「_GitLabへようこそ、`@username`さん！_」というメッセージが表示されます。

ウェルカムメッセージが表示されない場合は、verboseモードで`ssh`を実行して問題を解決することができます。

```shell
ssh -Tvvv git@gitlab.example.com
```

## リポジトリごとに異なるキーを使用する

リポジトリごとに異なるキーを使用できます。

ターミナルを開き、次のコマンドを実行します。

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

このコマンドはSSHエージェントを使用せず、Git 2.10以降が必要です。`ssh`コマンドオプションの詳細については、`ssh`と`ssh_config`の両方の`man`ページを参照してください。

## SSH鍵を表示する

アカウントのSSH鍵を表示するには:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで**SSH鍵**を選択します。

既存のSSH鍵がページの下部に一覧表示されます。情報には以下が含まれます。

- キーのタイトル
- 公開フィンガープリント
- 許可されている使用タイプ
- 作成日
- 最終使用日
- 有効期限

## SSH鍵を削除する

SSH鍵を取り消すか削除して、アカウントから完全に削除できます。

キーでコミットに署名している場合、SSH鍵を削除すると他にも影響があります。詳細については、「[削除されたSSH鍵で署名されたコミット](project/repository/signed_commits/ssh.md#signed-commits-with-removed-ssh-keys)」を参照してください。

### SSH鍵を取り消す

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108344)されました。

{{< /history >}}

SSH鍵が侵害された場合は、キーを取り消します。

前提要件:

- SSH鍵には、`Signing`または`Authentication & Signing`の使用タイプが必要です。

SSH鍵を取り消すには:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで**SSH鍵**を選択します。
1. 取り消すSSH鍵の横にある**取り消し**を選択します。
1. **取り消し**を選択します。

### SSH鍵を削除する

SSH鍵を削除するには:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで**SSH鍵**を選択します。
1. 削除するキーの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. **削除**を選択します。

## 単一のGitLabインスタンスで異なるアカウントを使用する

複数のアカウントを使用して、GitLabの単一インスタンスに接続できます。これを行うには、[前のトピック](#use-different-keys-for-different-repositories)のコマンドを使用します。ただし、`IdentitiesOnly`を`yes`に設定しても、`IdentityFile`が`Host`ブロックの外に存在する場合はサインインできません。

代わりに、`~/.ssh/config`ファイルでホストにエイリアスを割り当てることができます。

- `Host`には、`user_1.gitlab.com`や`user_2.gitlab.com`のようなエイリアスを使用します。高度な設定は保持するのが難しいため、`git remote`のようなツールを使用すると、これらの文字列が理解しやすくなります。
- `IdentityFile`には、プライベートキーのパスを使用します。

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

ここで、`user_1`のリポジトリのクローンを作成するには、`git clone`コマンドで`user_1.gitlab.com`を使用します。

```shell
git clone git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

`origin`としてエイリアスされていて、前にクローンが作成されたリポジトリを更新するには、次のコマンドを実行します。

```shell
git remote set-url origin git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

{{< alert type="note" >}}

プライベートキーと公開キーには機密データが含まれています。ファイルに対する権限を調節し、自分だけが読み取り可能で他のユーザーはアクセスできないようにしてください。

{{< /alert >}}

## 2要素認証（2FA）を設定する

[Git over SSH](../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations)に2要素認証（2FA）を設定できます。[ED25519_SK](#ed25519_sk-ssh-keys)または[ECDSA_SK](#ecdsa_sk-ssh-keys) SSH鍵を使用する必要があります。

## EclipseでEGitを使用する

[EGit](https://projects.eclipse.org/projects/technology.egit)を使用している場合は、[EclipseにSSH鍵を追加](https://wiki.eclipse.org/EGit/User_Guide/#Eclipse_SSH_Configuration)できます。

## Microsoft WindowsでSSHを使用する

Windows 10を実行している場合は、`git`と`ssh`の両方がプリインストールされている[WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2)で[Linux用Windowsサブシステム（WSL）](https://learn.microsoft.com/en-us/windows/wsl/install)を使用するか、[Git for Windows](https://gitforwindows.org)をインストールしてPowerShell経由でSSHを使用できます。

WSLで生成されたSSH鍵は、Git for Windowsでは直接利用できません。どちらもホームディレクトリが異なるためです。

- WSL: `/home/<user>`
- Git for Windows: `C:\Users\<user>`

同じキーを使用するには、`.ssh/`ディレクトリをコピーするか、各環境でキーを生成します。

Windows 11を実行していて、[OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/OpenSSH/openssh-overview)を使用している場合は、`HOME`環境変数が正しく設定されていることを確認してください。正しく設定されていない場合は、プライベートSSH鍵が見つからない可能性があります。

代替ツールは次のとおりです。

- [Cygwin](https://www.cygwin.com)
- [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 0.81以降（以前のバージョンは[開示攻撃に対して脆弱](https://www.openwall.com/lists/oss-security/2024/04/15/6)です）

## GitLabサーバー上のSSH設定をオーバーライドする

GitLabはシステムにインストールされたSSHデーモンと統合し、すべてのアクセス要求を処理するユーザー（通常は`git`という名前）を指定します。SSH経由でGitLabサーバーに接続するユーザーは、ユーザー名ではなくSSH鍵によって識別されます。

GitLabサーバーで実行されるSSH*クライアント*操作は、このユーザーとして実行されます。このSSH 設定は変更できます。たとえば、認証リクエストに使用するプライベートSSH鍵をこのユーザーに指定できます。ただし、この方法は**サポートされていません**。重大なセキュリティリスクがあるため、使用しないことを強くおすすめします。

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

## GitLab SSHの所有権と権限を確認する

GitLab SSHフォルダーとファイルには、次の権限が必要です。

- `/var/opt/gitlab/.ssh/`フォルダーは、`git`グループと`git`ユーザーが所有し、権限は`700`に設定する必要があります。
- `authorized_keys`ファイルの権限は`600`に設定する必要があります。
- `authorized_keys.lock`ファイルの権限は`644`に設定する必要があります。

これらの権限が正しいことを検証するには、次のコマンドを実行します。

```shell
stat -c "%a %n" /var/opt/gitlab/.ssh/.
```

### 権限を設定する

権限が間違っている場合は、アプリケーションサーバーにサインインして、次のコマンドを実行します。

```shell
cd /var/opt/gitlab/
chown git:git /var/opt/gitlab/.ssh/
chmod 700  /var/opt/gitlab/.ssh/
chmod 600  /var/opt/gitlab/.ssh/authorized_keys
chmod 644  /var/opt/gitlab/.ssh/authorized_keys.lock
```

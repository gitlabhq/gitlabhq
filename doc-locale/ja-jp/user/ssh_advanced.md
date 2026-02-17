---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 詳細SSHキーの設定
description: セキュアな認証とGitLabリポジトリとの通信にSSHキーを使用します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特殊なワークフロー向けに、高度なSSHキーオプションを設定します。
> [!note] GitLabアカウントでの基本的なSSHキーの使用方法については、[GitLabでSSHキーを使用する](ssh.md)を参照してください。

## FIDO2ハードウェアセキュリティキー向けのSSHキーペアを生成する {#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key}

ED25519_SKまたはECDSA_SK SSHキーを生成するには、OpenSSH 8.2以降を使用する必要があります。

1. ハードウェアセキュリティキーをコンピューターに挿入します。
1. ターミナルを開きます。
1. キーの種類と、後でキーを識別するのに役立つオプションのコメントを指定して、`ssh-keygen -t`を実行します。一般的なオプションは、メールアドレスをコメントとして使用することです。コメントは`.pub`ファイルに含まれています。

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

公開キーと秘密キーが生成されます。[GitLabアカウントに公開SSHキーを追加](ssh.md#add-an-ssh-key-to-your-gitlab-account)します。

## 1PasswordでSSHキーペアを生成する {#generate-an-ssh-key-pair-with-1password}

[1Password](https://1password.com/)と[1Passwordブラウザ拡張機能](https://support.1password.com/getting-started-browser/)を使用して、次のいずれかを行うことができます。

- 新しいSSHキーを自動的に生成する。
- 1Password Vaultにある既存のSSHキーを使用してGitLabで認証する。

1. GitLabにサインインします。
1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
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

## エンタープライズのユーザーのSSHキーを無効にする {#disable-ssh-keys-for-enterprise-users}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)されました。

{{< /history >}}

前提条件: 

- エンタープライズのユーザーが所属するグループのオーナーロールを持っている必要があります。

グループの[エンタープライズのユーザー](enterprise_user/_index.md)のSSHキーを無効にすると:

- エンタープライズのユーザーが新しいSSHキーを追加できなくなります。
- エンタープライズのユーザーの既存のSSHキーが無効になります。

これは、グループの管理者であるEnterpriseユーザーにも適用されます。

エンタープライズのユーザーのSSHキーを無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **エンタープライズのユーザー**の下で、**SSHキーを無効にする**を選択します。
1. **変更を保存**を選択します。

## RSAキーペアをより安全な形式にアップグレードする {#upgrade-your-rsa-key-pair-to-a-more-secure-format}

OpenSSHのバージョンが6.5 ～ 7.8の場合は、秘密RSA SSHキーをより安全なOpenSSH形式で保存できます。ターミナルを開いて次のコマンドを実行します。

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

または、次のコマンドを実行して、より安全な暗号化形式で新しいRSAキーを生成することもできます。

```shell
ssh-keygen -o -t rsa -b 4096 -C "<comment>"
```

## SSHキーのパスフレーズを更新する {#update-your-ssh-key-passphrase}

次の手順で、SSHキーのパスフレーズを更新できます。

1. ターミナルを開き、次のコマンドを実行します。

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. プロンプトでパスフレーズを入力し、<kbd>Enter</kbd>キーを押します。

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

> [!note]プライベートキーとパブリックキーには、機密データが含まれています。ファイルに対する権限を調節し、自分には読み取り可能でも他のユーザーにはアクセスできないように設定してください。

## リポジトリごとに異なるキーを使用する {#use-different-keys-for-different-repositories}

リポジトリごとに異なるキーを使用できます。

ターミナルを開き、次のコマンドを実行します。

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

このコマンドはSSHエージェントを使用せず、Git 2.10以降が必要です。`ssh`コマンドオプションの詳細については、`ssh`と`ssh_config`の両方の`man`ページを参照してください。

## 別のディレクトリでSSHキーを使用する {#use-ssh-keys-in-another-directory}

SSHキーペアがデフォルトのディレクトリにない場合は、プライベートキーを保存した場所を指すようにSSHクライアントを設定します。

1. ターミナルを開き、次のコマンドを実行します。

   ```shell
   eval $(ssh-agent -s)
   ssh-add <directory to private SSH key>
   ```

1. これらの設定を`~/.ssh/config`ファイルに保存します。例: 

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

## EclipseでSSHとEGitを使用する {#use-ssh-with-egit-on-eclipse}

[EGit](https://projects.eclipse.org/projects/technology.egit)を使用している場合は、[EclipseにSSHキーを追加](https://wiki.eclipse.org/EGit/User_Guide/#Eclipse_SSH_Configuration)できます。

## Microsoft WindowsでSSHを使用する {#use-ssh-on-microsoft-windows}

Windows 10では、[Linux用Windowsサブシステム(WSL)](https://learn.microsoft.com/en-us/windows/wsl/install)を[WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2)と組み合わせて使用​​できます。`git`と`ssh`がプリインストールされているか、[Git for Windows](https://gitforwindows.org)をインストールしてPowerShell経由でSSHを使用できます。

WSLで生成されたSSHキーは、Git for Windowsでは直接利用できません。その逆も同様です。これはホームディレクトリが異なるためです。

- WSL: `/home/<user>`
- Git for Windows: `C:\Users\<user>`

`.ssh/`ディレクトリをコピーして同じキーを使用するか、各環境でキーを生成します。

Windows 11を実行していて、[OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/OpenSSH/openssh-overview)を使用している場合は、`HOME`環境変数が正しく設定されていることを確認してください。正しく設定されていない場合、秘密SSHキーが見つからない可能性があります。

代替ツールは次のとおりです。

- [Cygwin](https://www.cygwin.com)
- [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 0.81以降（以前のバージョンは[情報漏洩攻撃に対して脆弱](https://www.openwall.com/lists/oss-security/2024/04/15/6)です）

## SSH経由のGitに2要素認証を使用する {#use-two-factor-authentication-for-git-over-ssh}

[Git over SSH](../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations)に2要素認証を使用できます。`ED25519_SK`または`ECDSA_SK` SSHキーを使用する必要があります。詳細については、[サポートされているSSHキーの種類](ssh.md#supported-ssh-key-types)を参照してください。

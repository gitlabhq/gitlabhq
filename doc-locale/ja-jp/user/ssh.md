---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabでSSHキーを使用する
description: GitLabリポジトリとのセキュアな認証および通信にSSHキーを使用します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabにコードをプッシュするまたはプルするたびに、ユーザー名とパスワードを入力することなく、SSHキーを使用して安全に認証することができます。

GitLabでSSHキーを使用するには、次の手順を実行する必要があります:

1. ローカルシステムでSSHキーペアを生成します。
1. あなたのSSHキーをGitLabアカウントに追加します。
1. GitLabへの接続を確認します。

> [!note]
> 高度なSSHキー設定については、[高度なSSHキー設定](ssh_advanced.md)を参照してください。

## SSHキーとは {#what-are-ssh-keys}

SSHは、公開キーと秘密キーの2つのキーを使用します。

- 公開キーは配布できます。
- 秘密キーは保護する必要があります。

公開キーをアップロードしても、機密データが漏洩することはありません。SSH公開キーをコピーまたはアップロードする際に、誤って秘密キーをコピーまたはアップロードしないように注意してください。

秘密キーを使用して[コミットに署名](project/repository/signed_commits/ssh.md)することができ、これによりGitLabの使用とデータの安全性がさらに向上します。この署名は、公開キーを使用して誰でも検証できます。

詳細については、[公開キー暗号としても知られる非対称暗号](https://en.wikipedia.org/wiki/Public-key_cryptography)を参照してください。

## 前提条件 {#prerequisites}

SSHを使用してGitLabと通信するには、以下が必要です。

- GNU/Linux、macOS、およびWindows 10にプリインストールされているOpenSSHクライアント。
- SSHバージョン6.5以降。それ以前のバージョンではMD5署名を使用していましたが、これは安全ではありません。

> [!note]
> システムにインストールされているSSHのバージョンを表示するには、`ssh -V`を実行します。

## サポートされているSSHキーの種類 {#supported-ssh-key-types}

{{< history >}}

- GitLab 16.3でRSAキーの最大長が[変更](https://gitlab.com/groups/gitlab-org/-/epics/11186)されました。

{{< /history >}}

GitLabとの通信には、次のSSHキーの種類を使用できます。

| アルゴリズム           | 備考 |
| ------------------- | ----- |
| ED25519（推奨） | RSAキーよりも安全で高性能です。OpenSSH 6.5 (2014) で導入され、ほとんどのオペレーティングシステムで利用可能です。すべてのFIPSシステムで完全にサポートされていない場合があります。詳細については、[イシュー367429](https://gitlab.com/gitlab-org/gitlab/-/issues/367429)を参照してください。 |
| ED25519_SK          | ローカルクライアントとGitLabサーバーの両方でOpenSSH 8.2以降が必要です。 |
| ECDSA_SK            | ローカルクライアントとGitLabサーバーの両方でOpenSSH 8.2以降が必要です。 |
| RSA                 | ED25519よりも安全性が低いです。使用する場合は、GitLabは少なくとも4096ビットのキーサイズを推奨します。Goの制限により、最大キー長は8192ビットです。デフォルトのキーサイズは、`ssh-keygen`のバージョンによって異なります。 |
| ECDSA               | DSAに関連する[セキュリティ上の問題](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa)は、ECDSAキーにも適用されます。 |

## 既存のSSHキーペアを確認する {#check-for-existing-ssh-key-pairs}

キーペアを作成する前に、キーペアがすでに存在するかどうかを確認します。

1. ホームディレクトリに移動します。
1. `.ssh/`サブディレクトリに移動します。`.ssh/`サブディレクトリが存在しない場合は、ホームディレクトリにいないか、以前に`ssh`を使用したことがないかのどちらかです。後者の場合は、[SSHキーペアを生成する](#generate-an-ssh-key-pair)必要があります。
1. 次のいずれかの形式のファイルが存在するかどうかを確認します。

   | アルゴリズム             | 公開キー | 秘密キー |
   |-----------------------|------------|-------------|
   |  ED25519（推奨）  | `id_ed25519.pub` | `id_ed25519` |
   |  ED25519_SK           | `id_ed25519_sk.pub` | `id_ed25519_sk` |
   |  ECDSA_SK             | `id_ecdsa_sk.pub` | `id_ecdsa_sk` |
   |  RSA（少なくとも4096ビットのキーサイズ） | `id_rsa.pub` | `id_rsa` |
   |  DSA（非推奨）     | `id_dsa.pub` | `id_dsa` |
   |  ECDSA                | `id_ecdsa.pub` | `id_ecdsa` |

## SSHキーペアを生成する {#generate-an-ssh-key-pair}

既存のSSHキーペアがない場合は、新しいキーペアを生成します。

1. ターミナルを開きます。
1. キータイプと、後でキーを識別するのに役立つオプションのコメントを指定して、`ssh-keygen -t`を実行します。一般的には、メールアドレスをコメントとして使用します。このコメントは`.pub`ファイルに含まれます。

   例（ED25519の場合）:

   ```shell
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   4096ビットRSAの場合:

   ```shell
   ssh-keygen -t rsa -b 4096 -C "<comment>"
   ```

1. <kbd>Enter</kbd>キーを押します。次のような出力が表示されます。

   ```plaintext
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/user/.ssh/id_ed25519):
   ```

1. [デプロイキー](project/deploy_keys/_index.md)を生成する場合、または他のキーを保存する特定のディレクトリに保存したい場合を除き、提案されたファイル名とディレクトリをそのまま使用します。

   SSHキーペアを[特定のホスト専用](ssh_advanced.md#use-ssh-keys-in-another-directory)にすることもできます。

1. [パスフレーズ](https://www.ssh.com/academy/ssh/passphrase)を指定します。

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   ファイルの保存場所に関する情報を含む確認メッセージが表示されます。公開キーと秘密キーが生成されます。

1. 秘密SSHキーを`ssh-agent`に追加します。

   例（ED25519の場合）:

   ```shell
   ssh-add ~/.ssh/id_ed25519
   ```

## GitLabアカウントにSSHキーを追加する {#add-an-ssh-key-to-your-gitlab-account}

{{< history >}}

- キーに推奨されるデフォルトの有効期限は、GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/271239)されました。
- SSHキーの使用タイプは、GitLab 15.7で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/383046)されました。

{{< /history >}}

GitLabでSSHを使用するには、公開キーをGitLabアカウントにコピーします。GitLabは秘密キーにアクセスできません。

SSHキーを追加すると、GitLabは既知の侵害されたキーのリストと照合してチェックします。侵害されたキーは、関連する秘密キーが公に知られており、アカウントにアクセスするために使用される可能性があるため、追加できません。この制限は設定できません。

キーがブロックされている場合は、[新しいSSHキーペアを生成](#generate-an-ssh-key-pair)します。

GitLabアカウントにSSHキーを追加するには:

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
1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **SSHキー**を選択します。
1. **新しいキーを追加**を選択します。
1. **キー**ボックスに、公開キーの内容を貼り付けます。キーを手動でコピーする場合は、`ssh-rsa`、`ssh-dss`、`ecdsa-sha2-nistp256`、`ecdsa-sha2-nistp384`、`ecdsa-sha2-nistp521`、`ssh-ed25519`、`sk-ecdsa-sha2-nistp256@openssh.com`、または`sk-ssh-ed25519@openssh.com`で始まり、コメントで終わる可能性があるキー全体をコピーしていることを確認してください。
1. **タイトル**ボックスに、`Work Laptop`や`Home Workstation`などの説明を入力します。
1. オプション。キーの**使用タイプ**を選択します。`Authentication`（認証）または`Signing`（署名）のいずれか、またはその両方で使用できます。`Authentication & Signing`（認証と署名）がデフォルト値です。
1. オプション。**有効期限**を更新して、デフォルトの有効期限を変更します。詳細については、[SSHキーの有効期限](#ssh-key-expiration)を参照してください。
1. **キーを追加**を選択します。

## SSH接続を確認する {#verify-your-ssh-connection}

SSHキーが正しく追加されていること、およびGitLabインスタンスに接続できることを確認します:

1. 正しいサーバーに接続していることを確認するには、SSHホストキーのフィンガープリントを特定します:
   - GitLab.comについては、[SSHホストキーのフィンガープリント](gitlab_com/_index.md#ssh-host-keys-fingerprints)ドキュメントを参照してください。
   - GitLab Self-ManagedまたはGitLab Dedicatedの場合は、`gitlab.example.com`がGitLabインスタンスのURLである`https://gitlab.example.com/help/instance_configuration#ssh-host-keys-fingerprints`を参照してください。
1. ターミナルを開き、次のコマンドを実行します。
   - GitLab.comの場合は、`ssh -T git@gitlab.com`を使用します。
   - GitLab Self-ManagedまたはGitLab Dedicatedの場合は、`gitlab.example.com`がGitLabインスタンスのURLである`ssh -T git@gitlab.example.com`を使用します。

デフォルトでは、接続には`git`ユーザー名を使用しますが、GitLab Self-ManagedまたはGitLab Dedicatedの管理者は[ユーザー名を変更](https://docs.gitlab.com/omnibus/settings/configuration/#change-the-name-of-the-git-user-or-group)できます。

1. 最初の接続時に、GitLabホストの信頼性を確認する必要がある場合があります。次のようなメッセージが表示された場合は、画面のプロンプトに従ってください:

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)?
   ```

   ウェルカムメッセージが表示されます。

   ```plaintext
   Welcome to GitLab, <username>!
   ```

   メッセージが表示されない場合は、SSH接続の[トラブルシューティングを行う](ssh_troubleshooting.md#general-ssh-troubleshooting)ことができます。

## SSHキーを表示する {#view-your-ssh-keys}

次の手順でアカウントのSSHキーを表示できます。

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **SSHキー**を選択します。

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

前提条件: 

- SSHキーには、`Signing`（署名）または`Authentication & Signing`（認証と署名）の使用タイプが必要です。

次の手順でSSHキーを取り消せます。

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **SSHキー**を選択します。
1. 取り消したいSSHキーの横にある**取り消し**を選択します。
1. **取り消し**を選択します。

### SSHキーを削除する {#delete-an-ssh-key}

次の手順でSSHキーを削除できます。

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **SSHキー**を選択します。
1. 削除したいキーの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. **削除**を選択します。

## SSHキーの有効期限 {#ssh-key-expiration}

SSHキーをアカウントに追加するときに、有効期限を設定できます。このオプションの設定は、セキュリティ漏洩のリスクを制限するのに役立ちます。

SSHキーの有効期限が切れると、認証することやコミットへの署名に使用できなくなります。新しい[SSHキーを生成](#generate-an-ssh-key-pair)し、[アカウントに追加](#add-an-ssh-key-to-your-gitlab-account)する必要があります。

GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者は有効期限を表示し、[キーを削除](../administration/credentials_inventory.md#delete-ssh-keys)する際のガイダンスとして使用できます。

GitLabは、期限切れのSSHキーを毎日チェックし、通知を送信します:

- 01:00 AM UTC、有効期限の7日前。
- 02:00 AM UTC、有効期限当日。

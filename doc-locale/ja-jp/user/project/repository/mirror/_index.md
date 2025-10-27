---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: リポジトリのミラーリングを使用して、Gitリポジトリの内容を別のリポジトリとの間でプッシュまたはプルします。
title: リポジトリのミラーリング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リポジトリを外部ソースとの間でミラーリングできます。ソースとして機能するリポジトリを選択できます。ブランチ、タグ、コミットは自動的に同期されます。

ミラーリングには複数の方法があります:

- [プッシュ](push.md): GitLabから別の場所にリポジトリをミラーリングします。
- [プル](pull.md): 別の場所からリポジトリをミラーリングします。PremiumプランおよびUltimateプランで利用できます。
- [双方向](bidirectional.md)ミラーリングも利用できますが、競合が発生する可能性があります。

以下の場合にリポジトリをミラーリングします:

- プロジェクトの標準的なバージョンがGitLabに移行された場合。以前のホームでプロジェクトのコピーを提供し続けるには、GitLabリポジトリを[プッシュミラー](push.md)として設定します。GitLabリポジトリに加えた変更は、古い場所にコピーされます。
- GitLabインスタンスはプライベートだが、一部のプロジェクトをオープンソースにしたい場合。
- GitLabに移行したが、プロジェクトの標準的なバージョンは別の場所にある場合。GitLabリポジトリを他のプロジェクトの[プルミラー](pull.md)として設定します。GitLabリポジトリは、プロジェクトのコミット、タグ、およびブランチのコピーをプルします。それらはGitLabで利用できるようになります。

以下はサポートされていません:

- SCP形式のURL。SCP形式のURLを実装する作業を実行中です。詳細および進捗状況の追跡については、[イシュー18993](https://gitlab.com/gitlab-org/gitlab/-/issues/18993)を参照してください。
- [簡易HTTPプロトコル](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#_dumb_http)を介したリポジトリのミラーリング。

## リポジトリのミラーを作成する {#create-a-repository-mirror}

前提要件:

- プロジェクトのメンテナーロール以上を持っている必要があります。
- ミラーが`ssh://`で接続する場合は、サーバー上でホストキーが検出可能であるか、キーのローカルコピーを持っている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **新規を追加**を選択します。
1. **GitリポジトリのURL**を入力します。リポジトリは、`http://`、`https://`、`ssh://`、または`git://`経由でアクセスできる必要があります。
1. **ミラーの方向**を選択します。詳細については、[プルミラーリング](pull.md)および[プッシュミラーリング](push.md)を参照してください。
1. `ssh://`のURLを入力した場合は、次のいずれかを選択します:
   - **ホストキーを検出**: GitLabはサーバーからホストキーをフェッチして、フィンガープリントを表示します。
   - **ホストキーの手動入力**し、**SSH host key**（SSHホストキー）にホストキーを入力します。

   リポジトリをミラーリングする場合、GitLabは接続する前に、保存されたホストキーの少なくとも1つが一致することを確認します。このチェックにより、悪意のあるコードインジェクションやパスワードの盗難からミラーを保護することができます。

   - SSH認証でリポジトリのミラーを作成するには、[次の例](#example-create-mirror-with-ssh-authentication)を参照してください。

1. **認証方法**を選択します。詳細については、[ミラーの認証方法](#authentication-methods-for-mirrors)を参照してください。
1. SSHホストキーで認証する場合は、[ホストキーを検証](#verify-a-host-key)し、正しいことを確認します。
1. 分岐した参照に対する強制プッシュを防ぐには、**分岐した参照を保持する**を選択します。詳細については、[分岐した参照を保持する](push.md#keep-divergent-refs)を参照してください。
1. オプション。ミラーリングするブランチの数を制限するには、**保護ブランチのみミラー**を選択するか、**特定のブランチをミラー**に正規表現を入力します。
1. **ミラーリポジトリ**を選択します。

### 例: SSH認証を使用してミラーを作成する {#example-create-mirror-with-ssh-authentication}

認証方法として`SSH public key`を選択すると、GitLabはGitLabリポジトリの公開キーを生成します。このキーをGitLab以外のサーバーに提供する必要があります。詳細については、[SSH公開キーを取得する](#get-your-ssh-public-key)を参照してください。

SSH認証を使用してリポジトリをミラーリングするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **新規を追加**を選択します。
1. **GitリポジトリのURL**を入力します。`ssh://gitlab.com/gitlab-org/gitlab.git`形式でURLを指定します。

   {{< alert type="note" >}}

   SSH URLは、SCP形式のURL（`git@host:path/to/repo.git`）ではなく、`ssh://host/path/to/repo.git`形式で使用する必要があります。コロン（`:`）をスラッシュ（`/`）に置き換え、`ssh://`プレフィックスを追加します。

   {{< /alert >}}

1. **ミラーの方向**を選択します。詳細については、[プルミラーリング](pull.md)および[プッシュミラーリング](push.md)を参照してください。
1. **ホストキーを検出**または**ホストキーの手動入力**を選択します。
1. **認証方法**フィールドで、**SSH公開キー**を選択します
1. **ユーザー名**フィールドに、`git`を追加します。
1. オプション。**ミラーユーザー**および**ブランチをミラー**を設定します。
1. **ミラーリポジトリ**を選択します。
1. SSH公開キーをコピーして、GitLab以外のサーバーに提供します。

### 保護されたブランチのみをミラーリングする {#mirror-only-protected-branches}

リモートリポジトリとの間で、ミラーリングプロジェクトの[保護ブランチ](../branches/protected.md)のみをミラーリングするように選択できます。[プルミラーリング](pull.md)の場合、ミラーリングプロジェクトの保護されていないブランチはミラーリングされず、分岐する可能性があります。

このオプションを使用するには、リポジトリミラーを作成するときに**Only mirror protected branches**（保護されたブランチのみミラー）を選択します。

### 特定のブランチをミラーリングする {#mirror-specific-branches}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/381667)。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/410354)になりました。機能フラグ`mirror_only_branches_match_regex`は削除されました。

{{< /history >}}

[re2正規表現](https://github.com/google/re2/wiki/Syntax)に一致する名前のブランチのみをミラーリングするには、**特定のブランチをミラー**フィールドに正規表現を入力します。正規表現に一致しない名前のブランチはミラーリングされません。

## ミラーを更新する {#update-a-mirror}

ミラーリポジトリが更新されると、すべての新しいブランチ、タグ、およびコミットがプロジェクトのアクティビティーフィードに表示されます。GitLabのリポジトリミラーは自動的に更新されます。手動で更新をトリガーすることもできます:

- GitLab.comでは、最大で5分ごとに1回更新します。
- GitLab Self-Managedインスタンスで、管理者が設定した[プルミラーリング間隔の制限](../../../../administration/instance_limits.md#pull-mirroring-interval)に従って更新します。

{{< alert type="note" >}}

[GitLabサイレントモード](../../../../administration/silent_mode/_index.md)は、プッシュとプルの両方の更新を無効にします。

{{< /alert >}}

### 強制的に更新する {#force-an-update}

ミラーは自動的に更新されるようにスケジュール済みですが、次の場合を除き、強制的に即時更新を実行することができます:

- ミラーが既に更新されている。
- プルミラーリング制限の[間隔（秒）](../../../../administration/instance_limits.md#pull-mirroring-interval)が、最後の更新から経過していない。

前提要件:

- プロジェクトのメンテナーロール以上を持っている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **ミラーリングされたリポジトリ**までスクロールし、更新するミラーを特定します。
1. **今すぐ更新**（{{< icon name="retry" >}}）を選択します。

## ミラーの認証方法 {#authentication-methods-for-mirrors}

ミラーを作成する際は、認証方法を設定する必要があります。GitLabは、以下の認証方法をサポートしています:

- [SSH認証](#ssh-authentication)。
- ユーザー名とパスワード。

[プロジェクトアクセストークン](../../settings/project_access_tokens.md)または[グループアクセストークン](../../../group/settings/group_access_tokens.md)の場合は、ユーザー名として空白でない値を、パスワードとしてトークンを使用します。

### SSH認証 {#ssh-authentication}

SSH認証は相互認証です:

- リポジトリへのアクセスが許可されていることをサーバーに証明する必要があります。
- サーバーも、そのサーバーが誰であるかを証明する必要があります。

SSH認証では、認証情報をパスワードまたは公開キーとして提供します。他のリポジトリが存在するサーバーでは、その認証情報をホストキーとして提供します。手動でこのホストキーの[フィンガープリントを検証](#verify-a-host-key)する必要があります。

SSH経由でミラーリングする場合（`ssh://`URLを使用する）は、以下を使用して認証できます:

- HTTPS経由と同様に、パスワードベースの認証。
- 公開キー認証。これは、特に他のリポジトリが[デプロイキー](../../deploy_keys/_index.md)をサポートしている場合に、パスワード認証よりも安全性が高いことが多い方法です。

### SSH公開キーを取得する {#get-your-ssh-public-key}

リポジトリをミラーリングし、認証方法として**SSH公開キー**を選択すると、GitLabは公開キーを生成します。GitLab以外のサーバーは、GitLabリポジトリとの信頼性を確立するためにこのキーを必要とします。SSH公開キーをコピーするには、以下の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **ミラーリングされたリポジトリ**までスクロールします。
1. 正しいリポジトリを特定し、**SSH公開キーをコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。
1. SSH公開キーを他のリポジトリの設定に追加します:
   - 他のリポジトリがGitLabでホストされている場合は、SSH公開キーを[デプロイキー](../../deploy_keys/_index.md)として追加します。
   - 他のリポジトリが他の場所でホストされている場合は、キーをユーザーの`authorized_keys`ファイルに追加します。すべてのSSH公開キーをファイルの独自の行に貼り付けて保存します。

キーを変更する必要がある場合はいつでも、ミラーを削除して再度追加して新しいキーを生成できます。ミラーの実行を維持するには、新しいキーで他のリポジトリを更新します。

{{< alert type="note" >}}

生成されたキーは、ファイルシステムではなくGitLabデータベースに保存されます。そのため、ミラー用のSSH公開キーの認証は、事前受信フックでは使用できません。

{{< /alert >}}

### ホストキーを検証する {#verify-a-host-key}

ホストキーを使用する場合は、フィンガープリントが希望するものと一致することを必ず確認してください。以下のGitLab.comおよびその他のコードホスティングサイトでは、確認用のフィンガープリントを公開しています:

- [AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/regions.html#regions-fingerprints)
- [Bitbucket](https://support.atlassian.com/bitbucket-cloud/docs/configure-ssh-and-two-step-verification/)
- [Codeberg](https://docs.codeberg.org/security/ssh-fingerprint/)
- [GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
- [GitLab.com](../../../gitlab_com/_index.md#ssh-host-keys-fingerprints)
- [Launchpad](https://help.launchpad.net/SSHFingerprints)
- [Savannah](https://savannah.gnu.org/maintenance/SshAccess/)
- [SourceForge](https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/)

他のプロバイダーではさまざまです。以下の場合は、次のコマンドを使用して安全にキーのフィンガープリントを収集することができます:

- GitLab Self-Managedを実行する場合。
- 他のリポジトリのサーバーにアクセスできる場合。

```shell
$ cat /etc/ssh/ssh_host*pub | ssh-keygen -E md5 -l -f -
256 MD5:f4:28:9f:23:99:15:21:1b:bf:ed:1f:8e:a0:76:b2:9d root@example.com (ECDSA)
256 MD5:e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73 root@example.com (ED25519)
2048 MD5:3f:72:be:3d:62:03:5c:62:83:e8:6e:14:34:3a:85:1d root@example.com (RSA)
```

古いバージョンのSSHでは、コマンドから`-E md5`を削除する必要がある場合があります。

## 関連トピック {#related-topics}

- リポジトリのミラーリングに関する[トラブルシューティング](troubleshooting.md)。
- [プルミラーリングの間隔](../../../../administration/instance_limits.md#pull-mirroring-interval)を設定する
- [プロジェクトのミラーを無効にする](../../../../administration/settings/visibility_and_access_controls.md#enable-project-mirroring)
- [シークレットファイルとミラーリング](../../../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)

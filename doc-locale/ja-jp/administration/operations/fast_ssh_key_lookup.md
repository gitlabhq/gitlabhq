---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
description: 多数のユーザーがいるGitLabインスタンス向けに、より高速なSSH認証方法を設定します。
title: SSHキーの高速ルックアップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ユーザー数が増加すると、OpenSSHが認証済みユーザーを認証するために、`authorized_keys`ファイル全体を線形検索するため、SSH操作が遅くなります。このプロセスにはかなりの時間とディスクI/Oが必要となり、ユーザーがリポジトリにプッシュまたはプルする際に遅延が発生します。ユーザーがキーを頻繁に追加または削除すると、オペレーティングシステムが`authorized_keys`ファイルをキャッシュしない場合があり、ディスクI/Oが繰り返し発生します。

`authorized_keys`ファイルを使用する代わりに、GitLab Shellを設定してSSHキーをルックアップできます。GitLabデータベースでルックアップがインデックス化されているため、より高速です。

{{< alert type="note" >}}

標準(デプロイキーではない)認証済みユーザーの場合は、[SSH証明書](ssh_certificates.md)の使用を検討してください。データベースルックアップよりも高速ですが、`authorized_keys`ファイルのドロップイン代替にはなりません。

{{< /alert >}}

## Geoには高速ルックアップが必要です {#fast-lookup-is-required-for-geo}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Cloud Native GitLab](https://docs.gitlab.com/charts/)とは異なり、Linuxパッケージのインストールでは、`git`ユーザーのホームディレクトリにある`authorized_keys`ファイルがデフォルトで管理されます。ほとんどのインスタンスでは、このファイルは`/var/opt/gitlab/.ssh/authorized_keys`にあります。システム上の`authorized_keys`を特定するには、次のコマンドを使用します:

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

`authorized_keys`ファイルには、GitLabへのアクセスを許可されたユーザーのすべての公開SSHキーが含まれています。ただし、信頼できる唯一の情報源を維持するには、[Geo](../geo/_index.md)を構成して、データベースルックアップでSSHのフィンガープリントルックアップを実行する必要があります。

[Geoを設定する](../geo/setup/_index.md)場合は、プライマリノードとセカンダリノードの両方について、以下の手順に従う必要があります。プライマリノードで**Write to `authorized keys` file**（ファイルに書き込む） を選択しないでください。データベースレプリケーションが機能している場合、セカンダリで自動的に反映されるためです。

## 高速ルックアップの設定 {#set-up-fast-lookup}

GitLab Shellは、GitLabデータベースへの高速なインデックス付きルックアップを使用して、SSHユーザーを認可する方法を提供します。GitLab Shellは、SSHキーのフィンガープリントを使用して、ユーザーがGitLabにアクセスする権限があるかどうかを確認します。

高速ルックアップは、次のSSHサーバーで有効にできます:

- [`gitlab-sshd`](gitlab_sshd.md)
- OpenSSH

サービスごとに個別のポートを使用することで、両方のサービスを同時に実行できます。

### `gitlab-sshd`を使用する場合 {#with-gitlab-sshd}

`gitlab-sshd`を設定するには、[`gitlab-sshd`ドキュメント](gitlab_sshd.md)を参照してください。`gitlab-sshd`を有効にすると、GitLab Shellと`gitlab-sshd`が自動的に高速ルックアップを使用するように構成されます。

### OpenSSHの場合 {#with-openssh}

前提要件: 

- `AuthorizedKeysCommand`がフィンガープリントを受け入れる必要があるため、OpenSSH 6.9以降が必要です。バージョンを確認するには、`sshd -V`を実行します。

OpenSSHで高速ルックアップを設定するには:

1. 次の内容を`sshd_config`ファイルに追加します:

   ```plaintext
   Match User git    # Apply the AuthorizedKeysCommands to the git user only
     AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
     AuthorizedKeysCommandUser git
   Match all    # End match, settings apply to all users again
   ```

   このファイルは通常、次の場所にあります:

   - Linuxパッケージのインストール: `/etc/ssh/sshd_config`
   - Dockerのインストール: `/assets/sshd_config`
   - 自己コンパイルによるインストール: [ソースからGitLab Shellをインストールする](../../install/self_compiled/_index.md#install-gitlab-shell)手順に従った場合、コマンドは`/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check`にあります。このコマンドは`root`が所有権を持ち、グループや他のユーザーが書き込み可能でないため、他の場所にラッパースクリプトを作成することを検討してください。必要に応じて、このコマンドの所有権の変更も検討してください。ただし、`gitlab-shell`のアップグレード中に一時的な所有権の変更が必要になる場合があります。

1. OpenSSHをリロードします:

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. SSHが機能していることを確認します:

   1. `authorized_keys`ファイルで、ユーザーのキーをコメントアウトします。これを行うには、行を`#`で開始します。
   1. ローカルマシンから、リポジトリをプルするか、以下を実行します:

      ```shell
      ssh -T git@gitlab.example.com
      ```

      プルが成功するか、[ウェルカムメッセージ](../../user/ssh.md#verify-that-you-can-connect)は、キーがファイルに存在しないため、GitLabがデータベースでキーを見つけたことを意味します。

ルックアップに失敗した場合でも、`authorized_keys`ファイルはスキャンされます。ファイルが大きい限り、多くのユーザーにとってGit SSHのパフォーマンスは依然として遅い可能性があります。

これを解決するには、`authorized_keys`ファイルへの書き込みを無効にすることができます:

1. SSHが動作することを確認してください。そうしないと、ファイルがすぐに最新ではない状態になるため、この手順は重要です。
1. `authorized_keys`ファイルへの書き込みを無効にします:

   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
   1. **パフォーマンスの最適化**を展開します。
   1. **Use `authorized_keys` file to authenticate SSH keys**チェックボックスをオフにします。
   1. **変更を保存**を選択します。

1. 変更を確認します:

   1. UIでSSHキーを削除します。
   1. 新しいキーを追加します。
   1. リポジトリをプルしてみてください。

1. `authorized_keys`ファイルをバックアップして削除します。現在のユーザーのキーはすでにデータベースに存在するため、移行やユーザーがキーを再追加する必要はありません。

### `authorized_keys`ファイルの使用に戻る方法 {#how-to-go-back-to-using-the-authorized_keys-file}

この概要は簡単です。詳細については、前の手順を参照してください。

1. `authorized_keys`ファイルへの書き込みを有効にします。
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**設定**>**ネットワーク**を選択します。
   1. **パフォーマンスの最適化**を展開します。
   1. **Use `authorized_keys` file to authenticate SSH keys**チェックボックスをオンにします。
1. [`authorized_keys`ファイルを再構築](../raketasks/maintenance.md#rebuild-authorized_keys-file)します。
1. LinuxパッケージのインストールからDockerを使用している場合は、`/etc/ssh/sshd_config`または`/assets/sshd_config`から`AuthorizedKeysCommand`行を削除します。
1. `sshd`をリロードします: `sudo service sshd reload`。

## SELinuxのサポート {#selinux-support}

GitLabは、[SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux)を使用した`authorized_keys`データベースルックアップをサポートしています。

SELinuxポリシーは静的であるため、GitLabは内部ウェブサーバーポートの変更をサポートしていません。管理者は、動的に生成されないため、環境用に特別な`.te`ファイルを作成する必要があります。

### 追加ドキュメント {#additional-documentation}

`gitlab-sshd`に関する追加の技術ドキュメントは、GitLab Shellドキュメントにあります。

## トラブルシューティング {#troubleshooting}

### SSHトラフィックが遅いか、CPU負荷が高い {#ssh-traffic-slow-or-high-cpu-load}

SSHトラフィックが[遅い](https://github.com/linux-pam/linux-pam/issues/270)か、CPU負荷が高い場合:

- `/var/log/btmp`のサイズを確認してください。
- 定期的に、または特定のサイズに達した後にローテーションされていることを確認してください。

このファイルが非常に大きい場合、GitLab SSH高速ルックアップにより、ボトルネックがより頻繁に発生し、パフォーマンスがさらに低下する可能性があります。`/var/log/btmp`を完全に読み取らないように、[`UsePAM`を`sshd_config`で無効にすることを検討してください。](https://linux.die.net/man/5/sshd_config)

実行中の`sshd: git`プロセスで`strace`と`lsof`を実行すると、デバッグ情報が返されます。IP `x.x.x.x`の進行中のGit over SSH接続で`strace`を取得するには、次を実行します:

```plaintext
sudo strace -s 10000 -p $(sudo netstat -tp | grep x.x.x.x | egrep 'ssh.*: git' | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```

または、実行中のGit over SSHプロセスの`lsof`を取得します:

```plaintext
sudo lsof -p $(sudo netstat -tp | egrep 'ssh.*: git' | head -1 | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```

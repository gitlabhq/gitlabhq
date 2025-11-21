---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "`gitlab-sshd`、OpenSSHの軽量な代替品をGitLabインスタンス用に設定します。"
title: '`gitlab-sshd`'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitlab-sshd`は、[Goで記述されたスタンドアロンのSSHサーバー](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd)です。これは、OpenSSHの軽量な代替手段です。これは`gitlab-shell`パッケージの一部であり、[SSH操作](https://gitlab.com/gitlab-org/gitlab-shell/-/blob/71a7f34a476f778e62f8fe7a453d632d395eaf8f/doc/features.md)を処理します。

OpenSSHは制限されたシェルアプローチを使用しますが、`gitlab-sshd`には次のような特徴があります:

- 最新のマルチスレッドサーバーアプリケーションとして機能します。
- SSHトランスポートプロトコルの代わりに、リモートプロシージャ呼び出し（RPCs）を使用します。
- OpenSSHよりも使用するメモリが少なくなります。
- プロキシの背後で実行されているアプリケーションに対して、[IPアドレスによるグループアクセス制限](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address)をサポートします。

実装の詳細については、[ブログ投稿](https://about.gitlab.com/blog/2022/08/17/why-we-have-implemented-our-own-sshd-solution-on-gitlab-sass/)を参照してください。

OpenSSHから`gitlab-sshd`への切り替えを検討している場合は、以下を検討してください:

- PROXYプロトコル: `gitlab-sshd`はPROXYプロトコルをサポートしており、HAProxyなどのプロキシサーバーの背後で実行できます。この機能はデフォルトでは有効になっていませんが、[有効にできます](#proxy-protocol-support)。
- SSH証明書: `gitlab-sshd`はSSH証明書をサポートしていません。詳細については、[issue 655](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/655)を参照してください。
- 2FAリカバリーコード: `gitlab-sshd`は2FAリカバリーコードの再生成をサポートしていません。`2fa_recovery_codes`を実行しようとすると、エラー: `remote: ERROR: Unknown command: 2fa_recovery_codes`が発生します。詳細については、[ディスカッション](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/766#note_1906707753)を参照してください。

GitLab Shellの機能は、Git操作を超えて拡張され、GitLabとのさまざまなSSHベースのインタラクションに使用できます。

## `gitlab-sshd`を有効にする {#enable-gitlab-sshd}

`gitlab-sshd`を使用するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

次の手順では、OpenSSHとは異なるポートで`gitlab-sshd`を有効にします:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_sshd['enable'] = true
   gitlab_sshd['listen_address'] = '[::]:2222' # Adjust the port accordingly
   ```

1. オプション。デフォルトでは、`gitlab-sshd`のキーが`/var/opt/gitlab/gitlab-sshd`に存在しない場合、LinuxパッケージインストールはSSHホストキーを生成します。この自動生成を無効にする場合は、次の行を追加します:

   ```ruby
   gitlab_sshd['generate_host_keys'] = false
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

デフォルトでは、`gitlab-sshd`は`git`ユーザーとして実行されます。その結果、`gitlab-sshd`は1024より小さい特権ポート番号では実行できません。これは、ユーザーが`gitlab-sshd`ポートでGitにアクセスするか、SSHトラフィックを`gitlab-sshd`ポートに転送してこれを隠すロードバランサーを使用する必要があることを意味します。

新しく生成されたホストキーがOpenSSHホストキーと異なるため、ホストキーに関する警告が表示される場合があります。これが問題である場合は、ホストキーの生成を無効にし、既存のOpenSSHホストキーを`/var/opt/gitlab/gitlab-sshd`にコピーすることを検討してください。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

次の手順では、OpenSSHを`gitlab-sshd`に切り替えます:

1. `gitlab-shell`チャートの`sshDaemon`オプションを[`gitlab-sshd`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options)に設定します。例: 

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
   ```

1. Helmアップグレードを実行します。

デフォルトでは、`gitlab-sshd`は以下をリッスンします:

- ポート22（`global.shell.port`）での外部リクエスト。
- ポート2222（`gitlab.gitlab-shell.service.internalPort`）での内部リクエスト。

[Helmチャートで異なるポートを設定](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#configuration)できます。

{{< /tab >}}

{{< /tabs >}}

## PROXYプロトコルのサポート {#proxy-protocol-support}

`gitlab-sshd`の前面にあるロードバランサーにより、GitLabはクライアントIPアドレスの代わりにプロキシIPアドレスをレポートします。実際のIPアドレスを取得するために、`gitlab-sshd`は[PROXYプロトコル](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)をサポートしています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

PROXYプロトコルを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_sshd['proxy_protocol'] = true
   # Proxy protocol policy ("use", "require", "reject", "ignore"), "use" is the default value
   gitlab_sshd['proxy_policy'] = "use"
   ```

   `gitlab_sshd['proxy_policy']`オプションの詳細については、[`go-proxyproto`ライブラリ](https://github.com/pires/go-proxyproto/blob/4ba2eb817d7a57a4aafdbd3b82ef0410806b533d/policy.go#L20-L35)を参照してください。

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [`gitlab.gitlab-shell.config`オプション](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options)を設定します。例: 

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         proxyProtocol: true
         proxyPolicy: "use"
   ```

1. Helmアップグレードを実行します。

{{< /tab >}}

{{< /tabs >}}

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 強化 - オペレーティングシステムに関する推奨事項
---

一般的な強化のガイドラインは、[メインの強化ドキュメント](hardening.md)に概説されています。

基盤となるオペレーティングシステムを設定して、全体的なセキュリティを向上させることができます。GitLab Self-Managedインスタンスのような制御された環境では、追加の手順が必要であり、実際には特定のデプロイメントでしばしば必要とされます。FedRAMPはそのようなデプロイメントの一例です。

## SSH設定 {#ssh-configuration}

### SSHクライアント設定 {#ssh-client-configuration}

クライアントアクセス（GitLabインスタンスまたは基盤となるオペレーティングシステムへのアクセス）の場合、SSHキー生成に関する推奨事項をいくつか示します。最初のものは一般的なSSHキーです:

```shell
ssh-keygen -a 64 -t ed25519 -f ~/.ssh/id_ed25519 -C "ED25519 Key"
```

連邦情報処理規格準拠のSSHキーには、以下を使用します:

```shell
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "RSA FIPS-compliant Key"
```

### SSHサーバー設定 {#ssh-server-configuration}

オペレーティングシステムレベルで、SSHアクセスを許可している場合（通常はOpenSSHを介して）、`sshd_config`ファイル（正確な場所はオペレーティングシステムによって異なる場合がありますが、通常は`/etc/ssh/sshd_config`です）の設定オプションの例を次に示します:

```shell
#
# Example sshd config file. This supports public key authentication and
# turns off several potential security risk areas
#
PubkeyAuthentication yes
PasswordAuthentication yes
UsePAM yes
UseDNS no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
PermitTunnel no
PermitRootLogin no

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# Change default od 120 seconds to 60
LoginGraceTime 60

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Protocol adjustments, these would be needed/recommended in a FIPS or
# FedRAMP deployment, and use only strong and proven algorithm choices
Protocol 2
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
HostKeyAlgorithms ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521
KexAlgorithms ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521
Macs hmac-sha2-256,hmac-sha2-512

```

## ファイアウォールルール {#firewall-rules}

ファイアウォールルールの場合、基本的な使用にはTCPポート`80`と`443`のみを開放する必要があります。デフォルトでは、`5050`はコンテナレジストリへのリモートアクセス用に開かれていますが、強化された環境では、これは別のホスト上に存在するか、一部の環境ではまったく開かれていない可能性があります。したがって、推奨されるポートは`80`と`443`のみであり、ポート`80`は`443`へのリダイレクトのみに使用されるべきです。

FedRAMPのような真に強化された、または隔離された環境では、アクセスするネットワークを除くすべてのポートを制限するようにファイアウォールルールを調整する必要があります。たとえば、IPアドレスが`192.168.1.2`で、認証されたすべてのクライアントも`192.168.1.0/24`上にある場合、アクセスが別のファイアウォールで制限されている場合でも、ポート`80`と`443`へのアクセスを`192.168.1.0/24`のみに制限します（安全対策として）。

理想的には、GitLab Self-Managedインスタンスをインストールする場合は、インストールが始まる前に管理者とインストーラーへのアクセスを制限するファイアウォールルールを実装し、インスタンスがインストールされ適切に強化された後にのみ、ユーザー用の追加のIPアドレス範囲を追加する必要があります。

`iptables`または`ufw`を使用して、ホストごとにポート`80`および`443`へのアクセスを実装し適用することは許容されます。そうでない場合は、GCP Google ComputeまたはAWS Security Groupsを介したクラウドベースのファイアウォールルールによってこれを強制する必要があります。その他のすべてのポートはブロックするか、少なくとも特定の範囲に制限する必要があります。ポートの詳細については、[パッケージ](../administration/package_information/defaults.md)のデフォルトを参照してください。

## GitLabインスタンスからの送信接続を許可する {#allow-outbound-connections-from-the-gitlab-instance}

 送信と受信の両方の設定を確認します:

- ファイアウォールとHTTP/Sプロキシサーバーは、`https://`を使用してポート`443`で`cloud.gitlab.com`と`customers.gitlab.com`への送信接続を許可する必要があります。これらのホストはCloudflareによって保護されています。ファイアウォールの設定を更新して、[Cloudflareが公開しているIP範囲のリスト](https://www.cloudflare.com/ips/)内のすべてのIPアドレスへのトラフィックを許可します。
- HTTP/Sプロキシを使用するには、`gitLab_workhorse`と`gitLab_rails`の両方に必要な[Webプロキシ環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables.html)を設定する必要があります。
- マルチノードのGitLabインストールでは、すべての**Rails**および**Sidekiq**ノードでHTTP/Sプロキシを設定します。
- GitLab Self-ManagedインスタンスでGitLab Duoを設定するには、[GitLabインスタンスからGitLab Duoへの送信接続を許可](../administration/gitlab_duo/configure/gitlab_self_managed.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)します。

### ファイアウォールの追加 {#firewall-additions}

さまざまなサービスが有効になっており、外部アクセス（例: Sidekiq）を必要とし、ネットワークアクセスを開放する必要がある場合があります。これらの種類のサービスを特定のIPアドレスまたは特定のクラスCに制限します。多層的な追加の予防策として、可能な限りこれらの追加サービスをGitLabの特定のノードまたはサブネットワークに制限します。

## カーネル調整 {#kernel-adjustments}

カーネル調整は、`/etc/sysctl.conf`または`/etc/sysctl.d/`内のファイルを編集することによって行うことができます。カーネル調整は、攻撃の脅威を完全に排除するものではありませんが、追加のレイヤーのセキュリティを追加します。次の注意事項は、これらの調整の利点のいくつかについて説明しています。

```shell
## Kernel tweaks for sysctl.conf ##
##
## The following help mitigate out of bounds, null pointer dereference, heap and
## buffer overflow bugs, use-after-free etc from being exploited. It does not 100%
## fix the issues, but seriously hampers exploitation.
##
# Default is 65536. Higher values provide stronger protection against NULL-pointer dereference exploits.
# Use 4096 only if required for application compatibility, as it reduces the range of protected low memory addresses.
vm.mmap_min_addr=4096
# Default is 0, randomize virtual address space in memory, makes vuln exploitation
# harder
kernel.randomize_va_space=2
# Restrict kernel pointer access (for example, cat /proc/kallsyms) for exploit assistance
kernel.kptr_restrict=2
# Restrict verbose kernel errors in dmesg
kernel.dmesg_restrict=1
# Restrict eBPF
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
# Prevent common use-after-free exploits
vm.unprivileged_userfaultfd=0
# Mitigation CVE-2024-1086 by preventing unprivileged users from creating namespaces
kernel.unprivileged_userns_clone=0

## Networking tweaks ##
##
## Prevent common attacks at the IP stack layer
##
# Prevent SYNFLOOD denial of service attacks
net.ipv4.tcp_syncookies=1
# Prevent time wait assassination attacks
net.ipv4.tcp_rfc1337=1
# IP spoofing/source routing protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.accept_ra=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
# IP redirection protection
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
```

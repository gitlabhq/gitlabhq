---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: 単一ノードGitLabインスタンスをインストールしてセキュリティを設定する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、最大[20 RPSまたは1,000人のユーザー](../../administration/reference_architectures/1k_users.md)に対応できる、単一ノードのGitLabインスタンスをインストールして安全に設定する方法を学びます。

単一ノードのGitLabインスタンスをインストールし、安全に設定するには、次の手順を実行します:

1. [サーバーを保護する](#secure-the-server)
1. [GitLabをインストールする](#install-gitlab)
1. [GitLabを設定する](#configure-gitlab)
1. [次の手順](#next-steps)

## はじめる前 {#before-you-begin}

- ドメイン名、および正しい[DNSのセットアップ](https://docs.gitlab.com/omnibus/settings/dns.html)。
- 次の最小仕様のDebianベースのサーバー:
  - 8 vCPU
  - 7.2 GBメモリ
  - すべてのリポジトリに十分なハードドライブの空き容量。[ストレージ要件](../../install/requirements.md)の詳細をご覧ください。

## サーバーを保護する {#secure-the-server}

GitLabをインストールする前に、サーバーをより安全にするための設定から始めてください。

### ファイアウォールを設定する {#configure-the-firewall}

ポート22（SSH）、80（HTTP）、および443（HTTPS）を開く必要があります。これは、クラウドプロバイダーのコンソールを使用するか、サーバーレベルで実行できます。

この例では、[`ufw`](https://wiki.ubuntu.com/UncomplicatedFirewall)を使用してファイアウォールを設定します。すべてのポートへのアクセスを拒否し、ポート80と443を許可し、最後にポート22へのアクセスをレート制限します。`ufw`は、過去30秒間に6回以上の接続を試みたIPアドレスからの接続を拒否できます。

1. `ufw`をインストールします:

   ```shell
   sudo apt install ufw
   ```

1. `ufw`サービスを有効にして起動します:

   ```shell
   sudo systemctl enable --now ufw
   ```

1. 必要なポートを除く、他のすべてのポートを拒否します:

   ```shell
   sudo ufw default deny
   sudo ufw allow http
   sudo ufw allow https
   sudo ufw limit ssh/tcp
   ```

1. 最後に、設定をアクティブにします。以下は、パッケージを最初にインストールするときに1回だけ実行する必要があります。プロンプトが表示されたら、はい（`y`）と答えます:

   ```shell
   sudo ufw enable
   ```

1. ルールが存在することを確認します:

   ```shell
   $ sudo ufw status

   Status: active

   To                         Action      From
   --                         ------      ----
   80/tcp                     ALLOW       Anywhere
   443                        ALLOW       Anywhere
   22/tcp                     LIMIT       Anywhere
   80/tcp (v6)                ALLOW       Anywhere (v6)
   443 (v6)                   ALLOW       Anywhere (v6)
   22/tcp (v6)                LIMIT       Anywhere (v6)
   ```

### SSHサーバーを設定する {#configure-the-ssh-server}

サーバーをさらに保護するために、公開キー認証を受け入れるようにSSHを設定し、潜在的なセキュリティリスクとなるいくつかの機能を無効にします。

1. `/etc/ssh/sshd_config`をエディタで開き、以下が存在することを確認します:

   ```plaintext
   PubkeyAuthentication yes
   PasswordAuthentication yes
   UsePAM yes
   UseDNS no
   AllowTcpForwarding no
   X11Forwarding no
   PrintMotd no
   PermitTunnel no
   # Allow client to pass locale environment variables
   AcceptEnv LANG LC_*
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

1. ファイルを保存し、SSHサーバーを再起動します:

   ```shell
   sudo systemctl restart ssh
   ```

   SSHの再起動に失敗した場合は、`/etc/ssh/sshd_config`に重複するエントリがないことを確認してください。

### 許可されたユーザーのみがGitアクセスにSSHを使用していることを確認する {#ensure-only-authorized-users-are-using-ssh-for-git-access}

次に、SSH経由でGit操作を実行できる有効なGitLabアカウントを持っていない限り、ユーザーがSSHを使用してプロジェクトをプルできないようにします。

許可されたユーザーのみがGitアクセスにSSHを使用していることを確認するには:

1. 次の内容を`/etc/ssh/sshd_config`ファイルに追加します:

   ```plaintext
   # Ensure only authorized users are using Git
   AcceptEnv GIT_PROTOCOL
   ```

1. ファイルを保存し、SSHサーバーを再起動します:

   ```shell
   sudo systemctl restart ssh
   ```

### いくつかのカーネル調整を行う {#make-some-kernel-adjustments}

カーネルを調整しても、攻撃の脅威が完全になくなるわけではありませんが、セキュリティレイヤーが追加されます。

1. `/etc/sysctl.d`の下にエディタで新しいファイルを開き（たとえば、`/etc/sysctl.d/99-gitlab-hardening.conf`）、次を追加します。

   {{< alert type="note" >}}

   名前とソースディレクトリによって処理の順序が決まります。これは、最後に処理されたパラメータが以前のパラメータをオーバーライドする可能性があるため重要です。

   {{< /alert >}}

   ```plaintext
   ##
   ## The following help mitigate out of bounds, null pointer dereference, heap and
   ## buffer overflow bugs, use-after-free etc from being exploited. It does not 100%
   ## fix the issues, but seriously hampers exploitation.
   ##
   # Default is 65536, 4096 helps mitigate memory issues used in exploitation
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

1. 次回のサーバー再起動時に、値が自動的に読み込まれます。すぐに読み込むには:

   ```shell
   sudo sysctl --system
   ```

すばらしい、サーバーを保護する手順は完了しました。これで、GitLabをインストールする準備ができました。

## GitLabをインストールする {#install-gitlab}

サーバーがセットアップされたので、GitLabをインストールします:

1. 必要な依存関係をインストールして設定します:

   ```shell
   sudo apt update
   sudo apt install -y curl openssh-server ca-certificates perl locales
   ```

1. システムの言語を設定します:

   1. `/etc/locale.gen`を編集し、`en_US.UTF-8`がコメント解除されていることを確認します。
   1. 言語を再生成します:

      ```shell
      sudo locale-gen
      ```

1. GitLabパッケージリポジトリを追加し、パッケージをインストールします:

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   スクリプトの内容を表示するには、<https://packages.gitlab.com/gitlab/gitlab-ee/install>にアクセスしてください。

1. GitLabパッケージをインストールします。`GITLAB_ROOT_PASSWORD`で強力なパスワードを指定し、`EXTERNAL_URL`を独自のものに置き換えます。Let's Encrypt証明書が発行されるように、URLに`https`を含めることを忘れないでください。

   ```shell
   sudo GITLAB_ROOT_PASSWORD="strong password" EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ee
   ```

   Let's Encrypt証明書の詳細、または独自の証明書を使用する方法については、[TLSでGitLabを設定する](https://docs.gitlab.com/omnibus/settings/ssl/)方法をお読みください。

   設定したパスワードが取得されなかった場合は、[rootアカウントのパスワードのリセット](../../security/reset_user_password.md#reset-the-root-password)の詳細をお読みください。

1. 数分後、GitLabがインストールされます。`EXTERNAL_URL`で設定したURLを使用してサインインします。`root`をユーザー名として使用し、`GITLAB_ROOT_PASSWORD`で設定したパスワードを使用します。

さあ、GitLabを設定しましょう。

## GitLabを設定する {#configure-gitlab}

GitLabには、いくつかの健全なデフォルト設定オプションが付属しています。このセクションでは、それらを変更して機能を追加し、GitLabをより安全にします。

一部のオプションでは、**管理者**エリアユーザーインターフェースを使用し、一部のオプションでは、GitLab設定ファイルである`/etc/gitlab/gitlab.rb`を編集します。

### NGINXを設定する {#configure-nginx}

NGINXは、GitLabインスタンスへのアクセスに使用されるWebインターフェースを提供するために使用されます。NGINXをより安全に設定する方法の詳細については、[NGINXの強化](../../security/hardening_configuration_recommendations.md#nginx)をお読みください。

### メールを設定する {#configure-emails}

次に、メールサービスをセットアップして設定します。メールは、新しいサインアップの確認、パスワードのリセット、GitLabアクティビティーの通知に不可欠です。

#### SMTPを設定する {#configure-smtp}

このチュートリアルでは、[SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html)サーバーをセットアップし、[Mailgun](https://www.mailgun.com/) SMTPプロバイダーを使用します。

まず、ログイン認証情報を含む暗号化されたファイルを作成し、LinuxパッケージのSMTPを設定します:

1. SMTPサーバーの認証情報を含むYAMLファイル（たとえば、`smtp.yaml`）を作成します。

   SMTPパスワードには、設定設定の処理中に予期しない動作が発生するのを防ぐために、RubyまたはYAMLで使用される文字列区切り文字（たとえば、`'`）を含めないでください。

   ```shell
   user_name: '<SMTP user>'
   password: '<SMTP password>'
   ```

1. ファイルを暗号化します:

   ```shell
   cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
   ```

   デフォルトでは、暗号化されたファイルは`/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/smtp.yaml.enc`に保存されます。

1. YAMLファイルを削除します:

   ```shell
   rm -f smtp.yaml
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、残りのSMTP設定をセットアップします。`gitlab_rails['smtp_user_name']`と`gitlab_rails['smtp_password']`は、すでに暗号化されたものとして設定済みのため、存在**しない**ことを確認してください。

   ```ruby
   gitlab_rails['smtp_enable'] = true
   gitlab_rails['smtp_address'] = "smtp.mailgun.org" # or smtp.eu.mailgun.org
   gitlab_rails['smtp_port'] = 587
   gitlab_rails['smtp_authentication'] = "plain"
   gitlab_rails['smtp_enable_starttls_auto'] = true
   gitlab_rails['smtp_domain'] = "<mailgun domain>"
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

これで、メールを送信できるはずです。設定が機能したことをテストするには:

1. Railsコンソールを使用します:

   ```shell
   sudo gitlab-rails console
   ```

1. コンソールのプロンプトで次のコマンドを実行して、GitLabにテストメールを送信させます:

   ```ruby
   Notify.test_email('<email_address>', 'Message Subject', 'Message Body').deliver_now
   ```

メールを送信できない場合は、[SMTPトラブルシューティングセクション](https://docs.gitlab.com/omnibus/settings/smtp.html#troubleshooting)を参照してください。

#### ロックされたアカウントにメール検証を要求する {#require-email-verification-for-locked-accounts}

アカウントメール検証は、GitLabアカウントセキュリティの追加レイヤーを提供します。一部の条件が満たされた場合、たとえば、24時間以内に3回以上サインインに失敗した場合、アカウントはロックされます。

前提要件:

- 管理者である必要があります。

ロックされたアカウントにメール検証を要求するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **サインインの制限**を展開します。
1. **ロックしたアカウントのメール認証**チェックボックスを選択します。
1. **変更を保存**を選択します。

詳細については、[アカウントメール検証](../../security/email_verification.md)をお読みください。

#### S/MIMEで送信メールに署名する {#sign-outgoing-email-with-smime}

GitLabから送信された通知メールには、セキュリティを向上させるために[S/MIME](https://en.wikipedia.org/wiki/S/MIME)で署名できます。

キーファイルと認証局ファイルの単一のペアを指定する必要があります:

- 両方のファイルがPEMエンコードされている必要があります。
- キーファイルは、GitLabがユーザーの操作なしでそれを読み取りできるように、暗号化されていない必要があります。
- RSAキーのみがサポートされています。
- オプション。各署名に含める認証局（CA）認証局（PEMエンコード）のバンドルを指定できます。これは通常、中間CAです。

1. CAから認証局を購入します。
1. `/etc/gitlab/gitlab.rb`を編集し、ファイルパスを調整します:

   ```ruby
   gitlab_rails['gitlab_email_smime_enabled'] = true
   gitlab_rails['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
   gitlab_rails['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

詳細については、[S/MIMEを使用した送信メールへの署名](../../administration/smime_signing_email.md)をお読みください。

## 次の手順 {#next-steps}

このチュートリアルでは、サーバーをより安全にする方法、GitLabをインストールする方法、およびいくつかのセキュリティ標準を満たすようにGitLabを設定する方法を学びました。GitLabを保護するために実行できる[その他の手順](../../security/hardening_application_recommendations.md)には、次のようなものがあります:

- サインアップを無効にします。デフォルトでは、新しいGitLabインスタンスは、サインアップがデフォルトで有効になっています。GitLabインスタンスを公開する予定がない場合は、サインアップを無効にする必要があります。
- 特定のメールドメイン名を使用してサインアップを許可または拒否します。
- 新しいユーザーの最小パスワード長の制限を設定します。
- すべてのユーザーに対して2要素認証を強制します。

GitLabインスタンスの強化とは別に、GitLabが提供するCI/CD機能を活用するために独自のRunnerを設定したり、インスタンスを適切にバックアップしたりするなど、設定できることは他にもたくさんあります。

[インストール後に実行する手順](../../install/next_steps.md)の詳細をお読みください。

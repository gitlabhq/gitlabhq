---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'チュートリアル: 単一ノードGitLabインスタンスをインストールしてセキュリティを設定する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、最大[20 RPSまたは1,000ユーザー](../../administration/reference_architectures/1k_users.md)に対応できる単一ノードのGitLabインスタンスを安全にインストールおよび設定する方法を学びます。

単一ノードのGitLabインスタンスをインストールし、安全に設定するには:

1. [サーバーを保護する](#secure-the-server)
1. [GitLabをインストールする](#install-gitlab)
1. [GitLabを設定する](#configure-gitlab)
1. [次の手順](#next-steps)

## はじめる前 {#before-you-begin}

- ドメイン名、および正しい[DNSの設定](https://docs.gitlab.com/omnibus/settings/dns/)。
- 次の最小仕様を持つDebianベースのサーバー:
  - 8 vCPU
  - 7.2 GBメモリ
  - すべてのリポジトリに十分なハードドライブ容量。[ストレージ要件](../../install/requirements.md)の詳細については、こちらをご覧ください。

## サーバーを保護する {#secure-the-server}

GitLabをインストールする前に、サーバーをより安全に設定することから始めます。

### ファイアウォールを設定する {#configure-the-firewall}

ポート22（SSH）、80（HTTP）、および443（HTTPS）を開く必要があります。これは、クラウドプロバイダーのコンソールを使用するか、サーバーレベルで行うことができます。

この例では、[`ufw`](https://wiki.ubuntu.com/UncomplicatedFirewall)を使用してファイアウォールを設定します。すべてのポートへのアクセスを拒否し、ポート80および443を許可し、最後にポート22へのアクセスをレート制限します。`ufw`は、過去30秒間に6回以上接続を試みたIPアドレスからの接続を拒否できます。

1. `ufw`をインストールします:

   ```shell
   sudo apt install ufw
   ```

1. `ufw`サービスを有効にして開始します:

   ```shell
   sudo systemctl enable --now ufw
   ```

1. 必要なポートを除くすべてのポートを拒否します:

   ```shell
   sudo ufw default deny
   sudo ufw allow http
   sudo ufw allow https
   sudo ufw limit ssh/tcp
   ```

1. 最後に、設定を有効にします。以下は、パッケージを初めてインストールするときに1回だけ実行する必要があります。プロンプトが表示されたらyes（`y`）と答えます:

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

サーバーのセキュリティをさらに強化するには、SSHが公開鍵認証を受け入れるように設定し、潜在的なセキュリティリスクとなる一部の機能を無効にします。

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

   SSHの再起動が失敗した場合は、`/etc/ssh/sshd_config`に重複するエントリがないことを確認してください。

### 承認されたユーザーのみがGitアクセスにSSHを使用していることを確認する {#ensure-only-authorized-users-are-using-ssh-for-git-access}

次に、SSH経由でGit操作を実行できる有効なGitLabアカウントを持っていない限り、ユーザーがSSHを使用してプロジェクトをプルできないようにします。

承認されたユーザーのみがGitアクセスにSSHを使用していることを確認するには:

1. お使いの`/etc/ssh/sshd_config`ファイルに以下を追加します:

   ```plaintext
   # Ensure only authorized users are using Git
   AcceptEnv GIT_PROTOCOL
   ```

1. ファイルを保存し、SSHサーバーを再起動します:

   ```shell
   sudo systemctl restart ssh
   ```

### いくつかのカーネル調整を行う {#make-some-kernel-adjustments}

カーネル調整は攻撃の脅威を完全に排除するものではありませんが、セキュリティのレイヤーをさらに追加します。

1. お使いのエディタで`/etc/sysctl.d`の下に新しいファイル（例: `/etc/sysctl.d/99-gitlab-hardening.conf`）を開き、以下を追加します。

   > [!note]
   > 
   > 命名規則とソースディレクトリによって処理の順序が決まります。これは、最後に処理されたパラメータが以前のパラメータをオーバーライドする可能性があるため重要です。

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

1. 次回のサーバー再起動時に、値は自動的に読み込まれます。すぐに読み込むには:

   ```shell
   sudo sysctl --system
   ```

お疲れ様でした。サーバーを保護する手順が完了しました！これでGitLabをインストールする準備ができました。

## GitLabをインストールする {#install-gitlab}

サーバーの設定が完了したので、GitLabをインストールします:

1. 必要な依存関係をインストールして設定します:

   ```shell
   sudo apt update
   sudo apt install -y curl openssh-server ca-certificates perl locales
   ```

1. システム言語を設定します:

   1. `/etc/locale.gen`をエディタで開き、`en_US.UTF-8`がコメントアウトされていないことを確認します。
   1. 言語を再生成します:

      ```shell
      sudo locale-gen
      ```

1. GitLabパッケージリポジトリを追加し、パッケージをインストールします:

   ```shell
   curl --location "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   スクリプトの内容を見るには、<https://packages.gitlab.com/gitlab/gitlab-ee/install>にアクセスしてください。

1. GitLabパッケージをインストールします。`GITLAB_ROOT_PASSWORD`で強力なパスワードを指定し、`EXTERNAL_URL`をご自身のものに置き換えます。URLに`https`を含めることを忘れないでください。Let's Encrypt証明書が発行されます。

   ```shell
   sudo GITLAB_ROOT_PASSWORD="strong password" EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ee
   ```

   Let's Encrypt証明書の詳細、または独自の証明書を使用する方法については、[TLSでGitLabを設定](https://docs.gitlab.com/omnibus/settings/ssl/)する方法をお読みください。

   設定したパスワードが適用されなかった場合は、[ルートアカウントパスワードのリセット](../../security/reset_user_password.md#reset-the-root-password)について詳細をお読みください。

1. 数分後、GitLabがインストールされます。`EXTERNAL_URL`で設定したURLを使用してサインインします。`root`をユーザー名として使用し、`GITLAB_ROOT_PASSWORD`で設定したパスワードを使用します。

さあ、GitLabを設定しましょう！

## GitLabを設定する {#configure-gitlab}

GitLabには、いくつかの適切なデフォルトの設定オプションが付属しています。このセクションでは、より多くの機能を追加し、GitLabをより安全にするためにそれらを変更します。

オプションの一部では**管理者**エリアUIを使用し、他のオプションではGitLabの設定ファイルである`/etc/gitlab/gitlab.rb`を編集します。

### NGINXを設定する {#configure-nginx}

NGINXは、GitLabインスタンスにアクセスするために使用されるWebインターフェースを提供するために使用されます。NGINXをより安全に設定する方法の詳細については、[NGINXの強化](../../security/hardening_configuration_recommendations.md#nginx)についてお読みください。

### メールを設定する {#configure-emails}

次に、メールサービスをセットアップして設定します。メールは、新規登録の確認、パスワードのリセット、GitLabアクティビティの通知に重要です。

#### SMTPを設定する {#configure-smtp}

このチュートリアルでは、[SMTP](https://docs.gitlab.com/omnibus/settings/smtp/)サーバーをセットアップし、[Mailgun](https://www.mailgun.com/) SMTPプロバイダーを使用します。

まず、ログイン認証情報を含む暗号化されたファイルを作成し、次にLinuxパッケージ用にSMTPを設定します:

1. SMTPサーバーの認証情報を含むYAMLファイル（例: `smtp.yaml`）を作成します。

   SMTPパスワードには、RubyまたはYAMLで使用される文字列デリミタ（例: `'`）を含めないでください。設定の処理中に予期せぬ動作が発生するのを避けるためです。

   ```shell
   user_name: '<SMTP user>'
   password: '<SMTP password>'
   ```

1. ファイルを暗号化します:

   ```shell
   cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
   ```

   デフォルトでは、暗号化されたファイルは`/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/smtp.yaml.enc`の下に保存されます。

1. YAMLファイルを削除します:

   ```shell
   rm -f smtp.yaml
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、残りのSMTP設定を行います。`gitlab_rails['smtp_user_name']`と`gitlab_rails['smtp_password']`は、すでに暗号化されたものとして設定済みのため、存在**しない**ことを確認してください。

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

これでメールを送信できるようになります。設定が機能したことをテストするには:

1. Railsコンソールを入力します:

   ```shell
   sudo gitlab-rails console
   ```

1. コンソールプロンプトで次のコマンドを実行して、GitLabからテストメールを送信します:

   ```ruby
   Notify.test_email('<email_address>', 'Message Subject', 'Message Body').deliver_now
   ```

メールを送信できない場合は、[SMTPトラブルシューティングセクション](https://docs.gitlab.com/omnibus/settings/smtp/#troubleshooting)を参照してください。

#### ロックされたアカウントのメール確認を必須にする {#require-email-verification-for-locked-accounts}

アカウントのメール確認は、GitLabアカウントのセキュリティにさらなるレイヤーを提供します。特定の条件（たとえば、24時間以内に3回以上サインインに失敗した場合）が満たされると、アカウントがロックされます。

前提条件: 

- 管理者である必要があります。

ロックされたアカウントのメール確認を必須にするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **サインインの制限**を展開します。
1. **ロックしたアカウントのメール認証**チェックボックスを選択します。
1. **変更の保存**を選択します。

詳細については、[アカウントメール確認](../../security/email_verification.md)についてお読みください。

#### S/MIMEで送信メールに署名する {#sign-outgoing-email-with-smime}

GitLabから送信される通知メールは、セキュリティを向上させるために[S/MIME](https://en.wikipedia.org/wiki/S/MIME)で署名できます。

単一のキーと証明書ファイルのペアを提供する必要があります:

- 両方のファイルはPEMエンコードされている必要があります。
- キーファイルは、GitLabがユーザーの介入なしにそれを読み取りできるように、暗号化されていない状態である必要があります。
- RSAキーのみがサポートされています。
- （オプション）各署名に含める認証局（CA）証明書のバンドル（PEMエンコード済み）を提供できます。これは通常、中間CAです。

1. CAから証明書を購入してください。
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

詳細については、[S/MIMEで送信メールに署名する方法](../../administration/smime_signing_email.md)についてお読みください。

## 次の手順 {#next-steps}

このチュートリアルでは、サーバーをより安全に設定する方法、GitLabをインストールする方法、および一部のセキュリティ標準を満たすようにGitLabを設定する方法を学びました。GitLabを保護するために実行できる[その他の手順](../../security/hardening_application_recommendations.md)には、次のようなものがあります:

- サインアップを無効にする。デフォルトでは、新しいGitLabインスタンスではサインアップがデフォルトで有効になっています。GitLabインスタンスを公開する予定がない場合は、サインアップを無効にする必要があります。
- 特定のメールドメインを使用したサインアップの許可または拒否。
- 新規ユーザーのパスワード長の最小制限を設定する。
- すべてのユーザーに対して2要素認証を強制する。

GitLabインスタンスの強化以外にも、GitLabが提供するCI/CD機能を活用するために独自のRunnerを設定したり、インスタンスを適切にバックアップしたりするなど、設定できることはたくさんあります。

[インストール後の手順](../../install/next_steps.md)について詳しくお読みいただけます。

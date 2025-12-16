---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenSSHのAuthorizedPrincipalsCommand経由でのユーザー検索
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabのSSHの認証のデフォルトでは、ユーザーがSSHトランスポートを使用する前に、SSH公開キーをアップロードする必要があります。

集中化された（例えば、企業）環境では、特にSSHキーが、発行から24時間後に期限切れになるものを含め、ユーザーに発行される一時キーである場合、これは運用上面倒な場合があります。

このような設定では、新しいキーをGitLabに常にアップロードするために、外部の自動化されたプロセスが必要です。

{{< alert type="warning" >}}

`AuthorizedKeysCommand`がフィンガープリントを受け入れられる必要があるため、OpenSSHバージョン6.9以降が必要です。サーバーのOpenSSHのバージョンを確認してください。

{{< /alert >}}

## OpenSSH証明書を使用する理由 {#why-use-openssh-certificates}

OpenSSH証明書を使用すると、どのGitLabユーザーがキーを所有しているかの情報がキー自体にエンコードされます。OpenSSHは、ユーザーが秘密CA署名キーへのアクセスを必要とするため、これを偽装できないことを保証します。

正しく設定すると、これにより、ユーザーのSSHキーをGitLabにアップロードする必要が完全になくなります。

## GitLab Shell経由でのSSH証明書検索の設定 {#setting-up-ssh-certificate-lookup-via-gitlab-shell}

SSH証明書を完全に設定する方法は、このドキュメントのスコープ外です。その仕組みについては[OpenSSHの`PROTOCOL.certkeys`](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?annotate=HEAD)を参照してください。たとえば、[RedHatのドキュメント](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_openssh_certificate_authentication)を参照してください。

すでにSSH証明書が設定されており、CAの`TrustedUserCAKeys`を`sshd_config`に追加していることを前提としています。例:

```plaintext
TrustedUserCAKeys /etc/security/mycompany_user_ca.pub
```

通常、`TrustedUserCAKeys`は、`Match User git`の下にはスコープされません。これは、GitLabサーバー自体へのシステムログインにも使用されるためですが、セットアップは異なる場合があります。CAがGitLabにのみ使用される場合は、（下記で説明する）`Match User git`セクションにこれを配置することを検討してください。

そのCAによって発行されるSSH証明書には、**必ず**、GitLab上のそのユーザーのユーザー名に対応する「キーID」が必要です（簡潔にするために一部の出力は省略されています）:

```shell
$ ssh-add -L | grep cert | ssh-keygen -L -f -

(stdin):1:
        Type: ssh-rsa-cert-v01@openssh.com user certificate
        Public key: RSA-CERT SHA256:[...]
        Signing CA: RSA SHA256:[...]
        Key ID: "aearnfjord"
        Serial: 8289829611021396489
        Valid: from 2018-07-18T09:49:00 to 2018-07-19T09:50:34
        Principals:
                sshUsers
                [...]
        [...]
```

厳密に言うとそれは必ずしも真実ではありません。たとえば、通常`prod-aearnfjord`ユーザーとしてサーバーにサインインするSSH証明書である場合は`prod-aearnfjord`になる可能性がありますが、提供されているデフォルトを使用する代わりに、独自の`AuthorizedPrincipalsCommand`を指定してそのマッピングを行う必要があります。

重要な部分は、`AuthorizedPrincipalsCommand`が「キーID」からGitLabのユーザー名にマップできる必要があるということです。これは、私たちが提供するデフォルトのコマンドが、2つの間に1=1のマッピングがあると想定しているためです。これの要点は、デフォルトの公開キーからユーザー名へのマッピングのようなものに依存するのではなく、キー自体からGitLabのユーザー名を抽出できるようにすることです。

次に、`sshd_config`で、`git`ユーザーの`AuthorizedPrincipalsCommand`を設定します。うまくいけば、GitLabに付属しているデフォルトのものを使用できます:

```plaintext
Match User git
    AuthorizedPrincipalsCommandUser root
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers
```

このコマンドは、次のような出力を出力します:

```shell
command="/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell username-{KEY_ID}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty {PRINCIPAL}
```

ここで、`{KEY_ID}`はスクリプトに渡される`%i`の引数（例えば、`aeanfjord`）、`{PRINCIPAL}`はそれに渡されるプリンシパル（例えば、`sshUsers`）です。

その`sshUsers`の部分をカスタマイズする必要があります。これは、GitLabにサインインできるすべてのユーザーのキーの一部であることが保証されているプリンシパルであるか、ユーザーに存在するプリンシパルのリストを提供する必要があります。例:

```plaintext
    [...]
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers windowsUsers
```

## プリンシパルとセキュリティ {#principals-and-security}

プリンシパルは必要なだけ指定できます。これらは、`sshd_config(5)`の`AuthorizedPrincipalsFile`ドキュメントで説明されているように、`authorized_keys`出力の複数の行に変換されます。

通常、OpenSSHで`AuthorizedKeysCommand`を使用する場合、プリンシパルはそのサーバーへのサインインを許可されている「グループ」です。ただし、GitLabでは、OpenSSHの要件を満たすためにのみ使用され、「キーID」が正しいことのみを効果的に気にします。それが抽出されると、GitLabはそのユーザーに対して独自のACLを適用します（例えば、ユーザーがアクセスできるプロジェクト）。

したがって、受け入れるものを過度に寛大にしてもかまいません。例えば、ユーザーがGitLabにアクセスできない場合、無効なユーザーに関するメッセージとともにエラーが生成されます。これは無効なユーザーであるというメッセージ。

## `authorized_keys`ファイルとのインタラクション {#interaction-with-the-authorized_keys-file}

SSH証明書が前述のように設定されている場合は、`authorized_keys`ファイルとともに使用して、`authorized_keys`ファイルがフォールバックとして機能するようにすることができます。

`AuthorizedPrincipalsCommand`がユーザーを認証できない場合、OpenSSHは`~/.ssh/authorized_keys`ファイルのチェックまたは`AuthorizedKeysCommand`の使用に戻ります。したがって、SSH証明書で[データベース内の承認されたSSHキーの高速検索](fast_ssh_key_lookup.md)を使用する必要がある場合があります。

ほとんどのユーザーにとって、SSH証明書は`AuthorizedPrincipalsCommand`を使用して認証を処理し、`~/.ssh/authorized_keys`ファイルは主にデプロイキーなどの特定のケースのフォールバックとして機能します。ただし、セットアップによっては、典型的なユーザーに対して`AuthorizedPrincipalsCommand`を排他的に使用することが十分であると判断する場合があります。このような場合、`authorized_keys`ファイルは、自動化されたデプロイキーアクセスまたはその他の特定のシナリオにのみ必要です。

典型的なユーザーのキーの数（特に頻繁に更新される場合）とデプロイキーのバランスを考慮して、環境で`authorized_keys`フォールバックを維持する必要があるかどうかを判断してください。

## その他のセキュリティに関する注意点 {#other-security-caveats}

ユーザーは、SSH公開キーを手動でプロファイルにアップロードし、`~/.ssh/authorized_keys`フォールバックに依存して認証することで、SSH証明書の認証を回避することができます。

デプロイキーではないSSHキーをユーザーがアップロードできないようにする設定を追加するための[未解決のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/23260)があります。

この制限を強制するためのチェックを自分で作成できます。例えば、`gitlab-shell-authorized-keys-check`から返された検出されたキー-IDがデプロイキーであるかどうかを確認するカスタム`AuthorizedKeysCommand`を提供します（デプロイキー以外のすべてのキーは拒否される必要があります）。

## SSHキーがないユーザーに関するグローバルな警告の無効化 {#disabling-the-global-warning-about-users-lacking-ssh-keys}

デフォルトでは、GitLabは、プロファイルにSSHキーをアップロードしていないユーザーに対して、「SSH経由でプロジェクトコードをプルまたはプッシュすることはできません」という警告を表示します。

これは、ユーザーが自分のキーをアップロードすることを期待されていないため、SSH証明書を使用する場合には逆効果です。

この警告をグローバルに無効にするには、「アプリケーション設定 -> アカウントと制限設定」に移動し、「ユーザー追加SSHキーメッセージを表示する」設定を無効にします。

この設定は、SSH証明書で使用するために特に追加されましたが、他の理由で警告を非表示にする場合は、使用せずにオフにすることができます。

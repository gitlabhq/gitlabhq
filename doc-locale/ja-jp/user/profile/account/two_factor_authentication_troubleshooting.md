---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 2要素認証のトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## エラー: `HTTP Basic: Access denied. If a password was provided for Git authentication ...` {#error-http-basic-access-denied-if-a-password-was-provided-for-git-authentication-}

リクエストを行うと、次のエラーが返されることがあります:

```plaintext
HTTP Basic: Access denied. If a password was provided for Git authentication,
the password was incorrect or you're required to use a token instead of a password.
If a token was provided, it was either incorrect, expired, or improperly scoped.
```

このエラーは、以下の場合に発生します:

- 2FAを有効にしていて、ユーザー名とパスワードで認証を試みた。
- 2FAを有効にしておらず、正しくないユーザー名またはパスワードで認証を試みた。
- 2FAを有効にしておらず、[すべてのユーザーに対して2FAを強制する](../../../security/two_factor_authentication.md#enforce-2fa-for-all-users)設定が有効になっている。
- 2FAを有効にしておらず、[HTTP(S)経由のGitに対してパスワード認証を有効にする](../../../administration/settings/sign_in_restrictions.md#password-authentication-enabled)設定が有効になっていない。

このエラーを解決するには:

- 正しいスコープを持つ[パーソナルアクセストークン](../personal_access_tokens.md)を使用します:
  - HTTP(S)経由のGitリクエストの場合: `read_repository`または`write_repository`
  - [GitLabコンテナレジストリ](../../packages/container_registry/authenticate_with_container_registry.md)リクエストの場合: `read_registry`または`write_registry`
  - [依存プロキシ](../../packages/dependency_proxy/_index.md#authenticate-with-the-dependency-proxy-for-container-images)リクエストの場合: `read_registry`および`write_registry`
- LDAPを設定している場合は、[LDAPパスワード](../../../administration/auth/ldap/_index.md)を使用します。
- [OAuth認証情報ヘルパー](two_factor_authentication.md#oauth-credential-helpers)を使用します。

## エラー: `invalid pin code` {#error-invalid-pin-code}

`invalid pin code`エラーは、認証アプリケーションとGitLabインスタンス自体の間に時刻同期の問題があることを示している可能性があります。

この問題を解決するには、2FAコードを生成するデバイスの時刻同期をオンにします。

{{< tabs >}}

{{< tab title="Android" >}}

  1. **Settings > System > Date & time**（設定 > システム > 日付と時刻）に移動します。
  1. **Set time automatically**（時刻を自動的に設定）をオンにします。この設定がすでにオンになっている場合は、オフにして数秒待ってから、もう一度オンにします。

{{< /tab >}}

{{< tab title="iOS" >}}

  1. **Settings > General > Date & Time**（設定 > 一般 > 日付と時刻）に移動します。
  1. **Set Automatically**（自動設定）をオンにします。この設定がすでにオンになっている場合は、オフにして数秒待ってから、もう一度オンにします。

{{< /tab >}}

{{< /tabs >}}

## エラー: リカバリーコードを生成する際の`Permission denied (publickey)` {#error-permission-denied-publickey-when-generating-recovery-codes}

`Permission denied (publickey)`というエラーが表示されることがあります。

この問題は、デフォルト以外のSSHキーペアファイルのパスを使用しており、[SSHを使用してリカバリーコードを生成する](two_factor_authentication_troubleshooting.md#generate-new-recovery-codes-using-ssh)ことを試みた場合に発生します。

これを解決するには、`ssh-agent`を使用して[別のディレクトリを指定するようにSSHを設定](../../ssh.md#configure-ssh-to-point-to-a-different-directory)します。

## リカバリーオプションと2FAリセット {#recovery-options-and-2fa-reset}

2FAを有効にしていて、コードを生成できない場合は、次のいずれかの方法でアカウントにアクセスしてください:

### リカバリーコードを使用する {#use-a-recovery-code}

2FAを有効にしたときに、GitLabにより一連のリカバリーコードが提供されています。これらのコードを使用してアカウントにサインインできます。

リカバリーコードを使用するには:

1. GitLabサインインページで、ユーザー名またはメールアドレスとパスワードを入力します。
1. 2要素コードの入力を求められたら、リカバリーコードを入力します。

リカバリーコードを使用した後、同じコードを再度使用することはできません。他のリカバリーコードは引き続き有効です。

### SSHを使用して新しいリカバリーコードを生成する {#generate-new-recovery-codes-using-ssh}

GitLabアカウントにSSHキーを追加した場合、SSHで新しいリカバリーコードセットを生成できます:

1. ターミナルで、次のコマンドを実行します:

   ```shell
   ssh git@gitlab.com 2fa_recovery_codes
   ```

   GitLab Self-Managedインスタンスで、`gitlab.com`をGitLabサーバーのホスト名（`gitlab.example.com`）に置き換えます。

1. 確認メッセージで、`yes`を入力します。
1. GitLabが生成するリカバリーコードを保存します。以前のリカバリーコードは無効になりました。
1. サインインページで、ユーザー名またはメールアドレスとパスワードを入力します。
1. 2要素コードの入力を求められたら、新しいリカバリーコードの1つを入力します。

サインインしたら、すぐに新しいデバイスで2FAを設定します。

### アカウントで2FAをリセットする {#reset-2fa-on-your-account}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

以前のリカバリーオプションが機能せず、アカウントにサインインできない場合は、サポートリクエストを作成して、アカウントの2FAを無効にすることができます。2FAが無効になったら、アカウントを安全に保つために、できるだけ早く再度有効にします。

このサービスは、GitLab.comサブスクリプションがあるアカウントでのみ利用できます。詳細については、[ブログ記事](https://about.gitlab.com/blog/2020/08/04/gitlab-support-no-longer-processing-mfa-resets-for-free-users/)を参照してください。

サポートリクエストを作成するには:

1. [GitLabサポート](https://support.gitlab.com)に移動します。
1. **Submit a Ticket**（チケットを送信）を選択します。
1. GitLabサポートアカウントでサインインしてください。サポートアカウントはGitLabアカウントとは異なり、2FAの問題の影響を受けません。
1. イシュードロップダウンリストで、**GitLab.com user accounts and login issues**（GitLab.comユーザーアカウントとログインの問題）を選択します。
1. サポートフォームのフィールドに記入します。
1. **送信**を選択します。

### エンタープライズユーザーの2FAをリセットする {#reset-2fa-for-enterprise-users}

有料プランのトップレベルグループのオーナーである場合は、エンタープライズユーザーの2FAを無効にできます。詳細については、[エンタープライズユーザーの2FAを無効にする](../../../security/two_factor_authentication.md#enterprise-users)を参照してください。

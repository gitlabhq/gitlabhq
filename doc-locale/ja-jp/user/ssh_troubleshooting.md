---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SSHのトラブルシューティング
---

SSHキーを使用する場合、以下の問題が発生することがあります。

## TLS: サーバーから8192ビットより大きいRSAキーを含む証明書が送信されました {#tls-server-sent-certificate-containing-rsa-key-larger-than-8192-bits}

GitLab 16.3バージョン以降、Go言語はRSAキーを最大8192ビットに制限します。キーの長さを確認するには、次のようにします:

```shell
openssl rsa -in <your-key-file> -text -noout | grep "Key:"
```

8192ビットより長いキーは、より短いキーに置き換えてください。

## `git clone`を使用したパスワードプロンプト {#password-prompt-with-git-clone}

`git clone`を実行すると、`git@gitlab.example.com's password:`のようなパスワードの入力を求められる場合があります。これは、SSHの設定に問題があることを示しています。

- SSHキーペアが正しく生成されていることと、公開SSHキーがGitLabプロファイルに追加されていることを確認してください。
- SSHキーの形式が、サーバーOSの設定と互換性があることを確認してください。たとえば、ED25519キーペアは、[FIPSシステム](https://gitlab.com/gitlab-org/gitlab/-/issues/367429)では動作しない場合があります。
- `ssh-agent`を使用して、プライベートSSHキーを手動で登録してみてください。
- `ssh -Tv git@example.com`を実行して接続をデバッグしてみてください。`example.com`をGitLab URLに置き換えます。
- [Microsoft WindowsでSSHを使用する](ssh.md#use-ssh-on-microsoft-windows)のすべての手順に従っていることを確認してください。
- [GitLab SSHの所有権と権限を確認する](ssh.md#verify-gitlab-ssh-ownership-and-permissions)があることを確認します。複数のホストがある場合は、すべてのホストで権限が正しいことを確認してください。

## `Could not resolve hostname`エラー {#could-not-resolve-hostname-error}

[接続できることの確認](ssh.md#verify-that-you-can-connect)時に、次のエラーが表示されることがあります:

```shell
ssh: Could not resolve hostname gitlab.example.com: nodename nor servname provided, or not known
```

このエラーが表示された場合は、ターミナルを再起動して、コマンドをもう一度実行してください。

### `Key enrollment failed: invalid format`エラー {#key-enrollment-failed-invalid-format-error}

[FIDO2ハードウェアセキュリティキーのSSHキーペアを生成する](ssh.md#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key)ときに、次のエラーが表示されることがあります:

```shell
Key enrollment failed: invalid format
```

これは、次の方法でトラブルシューティングできます:

- `ssh-keygen`コマンドを`sudo`で使用して実行します。
- FIDO2ハードウェアセキュリティキーが、指定されたキータイプをサポートしていることを確認します。
- `ssh -V`を実行して、OpenSSHのバージョンが8.2以上であることを確認します。

## エラー: `SSH host keys are not available on this system.` {#error-ssh-host-keys-are-not-available-on-this-system}

GitLabがホストSSHキーにアクセスできない場合、`gitlab.example/help/instance_configuration`にアクセスすると、インスタンスのSSHフィンガープリントの代わりに、**SSHホストキーのフィンガープリント**ヘッダーの下に次のエラーメッセージが表示されます:

```plaintext
SSH host keys are not available on this system. Please use ssh-keyscan command or contact your GitLab administrator for more information.
```

このエラーを解決するには:

- Helmチャート (Kubernetes) デプロイメントでは、`values.yaml`を更新して、`webservice`セクションの[`sshHostKeys.mount`](https://docs.gitlab.com/charts/charts/gitlab/webservice/)を`true`に設定します。
- GitLabセルフマネージドインスタンスで、ホストキーの`/etc/ssh`ディレクトリを確認します。

## 一般的なSSHのトラブルシューティング {#general-ssh-troubleshooting}

前のセクションで問題が解決しない場合は、詳細モードでSSH接続を実行します。詳細モードでは、接続に関する有用な情報が返されることがあります。

SSHを詳細モードで実行するには、次のコマンドを使用し、`gitlab.example.com`をGitLabインスタンスのURLに置き換えます:

```shell
ssh -Tvvv git@gitlab.example.com
```

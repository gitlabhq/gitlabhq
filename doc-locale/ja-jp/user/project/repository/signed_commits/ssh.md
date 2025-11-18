---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: SSHキーを使用して、GitLabリポジトリ内のコミットに署名します。
title: SSHキーでコミットに署名する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SSHキーでコミットに署名すると、GitLabはGitLabアカウントに関連付けられたSSH公開キーを使用して、コミットの署名を暗号学的に検証します。成功すると、GitLabはコミットに**検証済み**ラベルを表示します。

使用タイプが**認証と署名**である限り、GitLabへの`git+ssh`認証とコミット署名に同じSSHキーを使用できます。[SSHキーをGitLabアカウントに追加する](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account)ページで確認できます。

GitLabアカウントに関連付けられたSSHキーの管理の詳細については、[SSHキーを使用してGitLabと通信する](../../../ssh.md)を参照してください。

## SSHキーでコミットに署名するようにGitを設定する {#configure-git-to-sign-commits-with-your-ssh-key}

[SSHキーを作成](../../../ssh.md#generate-an-ssh-key-pair)し、[GitLabアカウントに追加](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account)したら、そのキーを使用するようにGitを設定します。

前提要件: 

- Git 2.34.0以降。
- OpenSSH 8.1以降。

  {{< alert type="note" >}}

  OpenSSH 8.7には、壊れた署名機能があります。OpenSSH 8.7を使用している場合は、OpenSSH 8.8にアップグレードしてください。

  {{< /alert >}}

- **使用タイプ**が`Authentication & Signing`または`Signing`のSSHキー。次のSSHキータイプがサポートされています:
  - ED25519
  - RSA
  - ECDSA

キーを使用するようにGitを設定するには、次の手順に従います:

1. コミット署名にSSHを使用するようにGitを設定します:

   ```shell
   git config --global gpg.format ssh
   ```

1. 署名キーとして使用する公開SSHキーを指定し、ファイル名（`~/.ssh/examplekey.pub`）をキーの場所に変更します。ファイル名は、キーの生成方法によって異なる場合があります:

   ```shell
   git config --global user.signingkey ~/.ssh/examplekey.pub
   ```

## SSHキーでコミットに署名する {#sign-commits-with-your-ssh-key}

前提要件:

- [SSHキーを作成](../../../ssh.md#generate-an-ssh-key-pair)しました。
- GitLabアカウントに[キーを追加](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account)しました。
- SSHキーを使用して[コミットに署名するようにGitを設定](#configure-git-to-sign-commits-with-your-ssh-key)しました。

コミットに署名するには、次の手順に従います:

1. コミットに署名するときは、`-S`フラグを使用します:

   ```shell
   git commit -S -m "My commit msg"
   ```

1. オプション。コミットするたびに`-S`フラグを入力したくない場合は、次のようにコミットに自動的に署名するようにGitに指示します:

   ```shell
   git config --global commit.gpgsign true
   ```

1. SSHキーが保護されている場合、Gitはパスフレーズの入力を求めます。
1. GitLabにプッシュします。
1. コミットが[検証されている](#verify-commits)ことを確認します。署名の検証では、`allowed_signers`ファイルを使用してメールとSSHキーを関連付けます。このファイルの設定については、[コミットをローカルで検証する](#verify-commits-locally)を参照してください。

## コミットを検証する {#verify-commits}

GitLab UIで、署名されたすべてのタイプのコミットを[検証](_index.md#verify-commits)できます。SSHキーで署名されたコミットは、ローカルでも検証できます。

### コミットをローカルで検証する {#verify-commits-locally}

コミットをローカルで検証するには、Gitの[許可された署名者ファイル](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html#ALLOWED_SIGNERS)を作成して、SSH公開キーをユーザーに関連付けます:

1. 次のように許可された署名者ファイルを作成します:

   ```shell
   touch allowed_signers
   ```

1. 次のようにGitで`allowed_signers`ファイルを設定します:

   ```shell
   git config gpg.ssh.allowedSignersFile "$(pwd)/allowed_signers"
   ```

1. 許可された署名者ファイルにエントリを追加します。このコマンドを使用して、メールアドレスと公開SSHキーを`allowed_signers`ファイルに追加します。`<MY_KEY>`をキーの名前に、`~/.ssh/allowed_signers`をプロジェクトの`allowed_signers`ファイルの場所に置き換えます:

   ```shell
   # Modify this line to meet your needs.
   # Declaring the `git` namespace helps prevent cross-protocol attacks.
   echo "$(git config --get user.email) namespaces=\"git\" $(cat ~/.ssh/<MY_KEY>.pub)" >> ~/.ssh/allowed_signers
   ```

   `allowed_signers`ファイルの結果のエントリには、次のように、メールアドレス、キータイプ、およびキーの内容が含まれています:

   ```plaintext
   example@gitlab.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmaTS47vRmsKyLyK1jlIFJn/i8wdGQ3J49LYyIYJ2hv
   ```

1. 署名を検証する各ユーザーに対して、前の手順を繰り返します。多くの異なるコントリビューターの署名をローカルで検証する場合は、このファイルをGitリポジトリにチェックインすることを検討してください。

1. `git log --show-signature`を使用して、コミットの署名ステータスを表示します:

   ```shell
   $ git log --show-signature

   commit e2406b6cd8ebe146835ceab67ff4a5a116e09154 (HEAD -> main, origin/main, origin/HEAD)
   Good "git" signature for johndoe@example.com with ED25519 key SHA256:Ar44iySGgxic+U6Dph4Z9Rp+KDaix5SFGFawovZLAcc
   Author: John Doe <johndoe@example.com>
   Date:   Tue Nov 29 06:54:15 2022 -0600

       SSH signed commit
   ```

## 削除されたSSHキーで署名されたコミット {#signed-commits-with-removed-ssh-keys}

コミットの署名に使用したSSHキーを失効または削除できます。詳細については、[SSHキーを削除する](../../../ssh.md#remove-an-ssh-key)を参照してください。

SSHキーを削除すると、キーで署名されたコミットに影響を与える可能性があります:

- SSHキーを失効すると、以前のコミットが**未検証**としてマークされます。新しいSSHキーを追加するまで、新しいコミットも**未検証**としてマークされます。
- SSHキーを削除しても、以前のコミットには影響しません。新しいSSHキーを追加するまで、新しいコミットは**未検証**としてマークされます。

## 関連トピック {#related-topics}

- [X.509証明書でコミットとタグに署名する](x509.md)
- [GPGでコミットに署名する](gpg.md)
- [コミットAPI](../../../../api/commits.md)

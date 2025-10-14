---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでSSHキーを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabには、（GitLab Runnerが実行される）ビルド環境でSSHキーを管理するためのサポートが組み込まれていません。

SSHキーは、次の操作を行う場合に使用します。

- 内部サブモジュールをチェックアウトする。
- パッケージマネージャーを使用して、プライベートパッケージをダウンロードする（Bundlerなど）。
- 独自のサーバーやHerokuなどにアプリケーションをデプロイする。
- ビルド環境からリモートサーバーにSSHコマンドを実行する。
- ビルド環境からリモートサーバーにRsyncでファイルを転送する。

最も広くサポートされている方法は、`.gitlab-ci.yml`を拡張してSSHキーをビルド環境に挿入することです。これは、あらゆるタイプの[executor](https://docs.gitlab.com/runner/executors/)（DockerやShellなど）と連携するソリューションです。

## SSHキーを作成して使用する {#create-and-use-an-ssh-key}

GitLab CI/CDでSSHキーを作成して使用するには、次のようにします。

1. `ssh-keygen`を使用して、ローカルに[新しいSSHキーペアを作成](../../user/ssh.md#generate-an-ssh-key-pair)します。
1. 秘密キーを[ファイルタイプのCI/CD変数](../variables/_index.md#for-a-project)としてプロジェクトに追加します。変数の値は、改行コード（`LF`文字）で終わる必要があります。改行コードを追加するには、CI/CD設定に保存する前に、SSHキーの最終行の末尾で<kbd>Enter</kbd>キーまたは<kbd>Return</kbd>キーを押します。
1. ジョブで[`ssh-agent`](https://linux.die.net/man/1/ssh-agent)を実行し、秘密キーを読み込みます。
1. アクセスするサーバーに公開キーをコピーします（通常は`~/.ssh/authorized_keys`）。プライベートGitLabリポジトリにアクセスする場合は、公開キーを[デプロイキー](../../user/project/deploy_keys/_index.md)として追加する必要もあります。

次の例では、`ssh-add -`コマンドでジョブログに`$SSH_PRIVATE_KEY`の値は表示されませんが、[デバッグログの生成](../variables/variables_troubleshooting.md#enable-debug-logging)を有効にすると表示される可能性があります。[パイプラインの表示レベル](../pipelines/settings.md#change-which-users-can-view-your-pipelines)を確認する必要が生じる可能性もあります。

## Docker executor使用時のSSHキー {#ssh-keys-when-using-the-docker-executor}

CI/CDジョブがDockerコンテナ内で実行され（つまり、環境がコンテナ内に隔離されていて）、プライベートサーバーにコードをデプロイする場合は、アクセスする方法が必要です。この場合、SSHキーペアを使用できます。

1. まず、SSHキーペアを作成する必要があります。詳細については、[SSHキーを生成する](../../user/ssh.md#generate-an-ssh-key-pair)の手順に従ってください。SSHキーにパスフレーズを追加**しないでください**。追加すると、`before_script`で入力を求められます。

1. 新しい[ファイルタイプのCI/CD変数](../variables/_index.md#for-a-project)を作成します。
   - **キー**フィールドに、`SSH_PRIVATE_KEY`と入力します。
   - **値**フィールドに、先ほど作成したキーペアの秘密キーの内容を貼り付けます。ファイルが改行コードで終わっていることを確認してください。改行コードを追加するには、変更を保存する前に、SSHキーの最終行の末尾で<kbd>Enter</kbd>キーまたは<kbd>Return</kbd>キーを押します。

1. `.gitlab-ci.yml`に`before_script`アクションを追加します。次の例では、Debianベースのイメージが想定されています。必要に応じて編集してください。

   ```yaml
   before_script:
     ##
     ## Install ssh-agent if not already installed, it is required by Docker.
     ## (change apt-get to yum if you use an RPM-based image)
     ##
     - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'

     ##
     ## Run ssh-agent (inside the build environment)
     ##
     - eval $(ssh-agent -s)

     ##
     ## Give the right permissions, otherwise ssh-add will refuse to add files
     ## Add the SSH key stored in SSH_PRIVATE_KEY file type CI/CD variable to the agent store
     ##
     - chmod 400 "$SSH_PRIVATE_KEY"
     - ssh-add "$SSH_PRIVATE_KEY"

     ##
     ## Create the SSH directory and give it the right permissions
     ##
     - mkdir -p ~/.ssh
     - chmod 700 ~/.ssh

     ##
     ## Optionally, if you will be using any Git commands, set the user name and
     ## and email.
     ##
     # - git config --global user.email "user@example.com"
     # - git config --global user.name "User name"
   ```

   [`before_script`](../yaml/_index.md#before_script)は、デフォルトとして、またはジョブごとに設定できます。

1. プライベートサーバーの[SSHホストキーが検証されている](#verifying-the-ssh-host-keys)ことを確認してください。

1. 最後のステップとして、最初に作成した公開キーを、ビルド環境内からアクセス先のサービスに追加します。プライベートGitLabリポジトリにアクセスする場合は、その公開キーを[デプロイキー](../../user/project/deploy_keys/_index.md)として追加する必要があります。

これで、ビルド環境内からプライベートサーバーまたはリポジトリにアクセスできるようになります。

## Shell executor使用時のSSHキー {#ssh-keys-when-using-the-shell-executor}

DockerではなくShell executorを使用している場合は、SSHキーの設定がさらに簡単になります。

GitLab RunnerがインストールされているマシンからSSHキーを生成し、このマシンで実行されるすべてのプロジェクトにそのキーを使用できます。

1. まず、ジョブを実行するサーバーにサインインします。

1. 次に、ターミナルから、`gitlab-runner`ユーザーとしてサインインします。

   ```shell
   sudo su - gitlab-runner
   ```

1. [SSHキーを生成する](../../user/ssh.md#generate-an-ssh-key-pair)手順に従って、SSHキーペアを生成します。SSHキーにパスフレーズを追加**しないでください**。追加すると、`before_script`で入力を求められます。

1. 最後のステップとして、先ほど作成した公開キーを、ビルド環境からアクセスする必要があるサービスに追加します。プライベートGitLabリポジトリにアクセスする場合は、その公開キーを[デプロイキー](../../user/project/deploy_keys/_index.md)として追加する必要があります。

キーを生成したら、リモートサーバーにサインインして、フィンガープリントを受け入れます。

```shell
ssh example.com
```

GitLab.com上のリポジトリにアクセスするには、`git@gitlab.com`を使用します。

## SSHホストキーを検証する {#verifying-the-ssh-host-keys}

中間者攻撃の標的になっていないことを確認するために、プライベートサーバー自体の公開キーを確認することをおすすめします。何か疑わしいことが起きると、ジョブが失敗する（公開キーが一致しない場合はSSH接続が失敗する）ため、気づくことができます。

サーバーのホストキーを調べるには、信頼できるネットワークから（理想的には、プライベートサーバー自体から）`ssh-keyscan`コマンドを実行します。

```shell
## Use the domain name
ssh-keyscan example.com

## Or use an IP
ssh-keyscan 10.0.2.2
```

[ファイルタイプのCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)を新規作成し、「キー」に`SSH_KNOWN_HOSTS`を設定し、「値」に`ssh-keyscan`の出力を追加します。ファイルが改行コードで終わっていることを確認してください。改行コードを追加するには、変更を保存する前に、SSHキーの最終行の末尾で<kbd>Enter</kbd>キーまたは<kbd>Return</kbd>キーを押します。

複数のサーバーに接続する必要がある場合は、すべてのサーバーのホストキーを1行に1つずつ記載し、変数の**値**に収集する必要があります。

{{< alert type="note" >}}

`.gitlab-ci.yml`内で`ssh-keyscan`を直接使用する代わりに、ファイルタイプのCI/CD変数を使用すると、何らかの理由でホストのドメイン名が変更されても`.gitlab-ci.yml`を変更する必要がないという利点があります。また、値はユーザーによって事前定義されているため、ホストキーが突然変更されてもCI/CDジョブは失敗しません。そのため、サーバーまたはネットワークに問題があると判断できます。

{{< /alert >}}

`SSH_KNOWN_HOSTS`変数を作成したら、上記の[`.gitlab-ci.yml`の内容](#ssh-keys-when-using-the-docker-executor)に加えて、以下を追加する必要があります。

```yaml
before_script:
  ##
  ## Assuming you created the SSH_KNOWN_HOSTS file type CI/CD variable, uncomment the
  ## following two lines.
  ##
  - cp "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts

  ##
  ## Alternatively, use ssh-keyscan to scan the keys of your private server.
  ## Replace example.com with your private server's domain name. Repeat that
  ## command if you have more than one server to connect to. Include the -t
  ## flag to specify the key type.
  ##
  # - ssh-keyscan -t rsa,ed25519 example.com >> ~/.ssh/known_hosts
  # - chmod 644 ~/.ssh/known_hosts

  ##
  ## You can optionally disable host key checking. Be aware that by adding that
  ## you are susceptible to man-in-the-middle attacks.
  ## WARNING: Use this only with the Docker executor, if you use it with shell
  ## you will overwrite your user's SSH config.
  ##
  # - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" >> ~/.ssh/config'
```

## ファイルタイプのCI/CD変数を使用せずにSSHキーを使用する {#use-ssh-key-without-a-file-type-cicd-variable}

ファイルタイプのCI/CD変数を使用したくない場合は、[SSHプロジェクトの例](https://gitlab.com/gitlab-examples/ssh-private-key/)に別の方法が示されています。この方法では、前述の推奨されているファイルタイプ変数ではなく、標準のCI/CD変数を使用します。

## トラブルシューティング {#troubleshooting}

### `Error loading key "/builds/path/SSH_PRIVATE_KEY": error in libcrypto`（キー「/builds/path/SSH_PRIVATE_KEY」の読み込みエラー: libcrypto内のエラー）メッセージ {#error-loading-key-buildspathssh_private_key-error-in-libcrypto-message}

このメッセージは、SSHキーに形式エラーがある場合に返される可能性があります。

SSHキーを[ファイルタイプのCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)として保存する場合、値は改行コード（`LF`文字）で終わる必要があります。改行コードを追加するには、変数を保存する前に、SSHキーの`-----END OPENSSH PRIVATE KEY-----`行の末尾で、<kbd>Enter</kbd>キーまたは<kbd>Return</kbd>キーを押します。

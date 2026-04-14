---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

最も広くサポートされている方法は、`.gitlab-ci.yml`を拡張して、ビルド環境にSSHキーを挿入することです。このアプローチは、DockerやShellのような、あらゆる種類の[executor](https://docs.gitlab.com/runner/executors/)で機能します。

> [!note]
> CI/CDでSSHキーを使用する場合は、秘密キーを安全に保管し、自動ジョブに個人のSSHキーを再利用しないでください。不正アクセスリスクを軽減するために、キーを定期的にローテーションしてください。

## SSHキーを作成して使用する {#create-and-use-an-ssh-key}

GitLab CI/CDでSSHキーを作成して使用するには、次のようにします。

1. 新しいSSHキーペアを[生成します](../../user/ssh.md#generate-an-ssh-key-pair)。
1. プライベートキーを`SSH_PRIVATE_KEY`という名前の[ファイルタイプのCI/CD変数](#add-an-ssh-key-as-a-file-type-variable)として追加します。
1. ジョブで[`ssh-agent`](https://linux.die.net/man/1/ssh-agent)を実行し、秘密キーを読み込みます。
1. アクセスするサーバーに公開キーをコピーします（通常は`~/.ssh/authorized_keys`）。プライベートGitLabリポジトリにアクセスする場合は、公開キーを[デプロイキー](../../user/project/deploy_keys/_index.md)として追加する必要もあります。

次の例では、`ssh-add -`コマンドでジョブログに`$SSH_PRIVATE_KEY`の値は表示されませんが、[デバッグログの生成](../variables/variables_troubleshooting.md#enable-debug-logging)を有効にすると表示される可能性があります。[パイプラインの表示レベル](../pipelines/settings.md#change-which-users-can-view-your-pipelines)を確認する必要が生じる可能性もあります。

### SSHキーをファイルタイプの変数として追加する {#add-an-ssh-key-as-a-file-type-variable}

プロジェクトにSSHキーを追加するには、キーを[ファイルタイプのCI/CD変数](../variables/_index.md#for-a-project)として追加します:

1. **表示レベル**を**表示**に設定します。

   > [!note]
   > **表示レベル**が**マスクする**、または**マスクして非表示**に設定されている場合、SSHキーには空白文字が含まれるため、保存できません。

1. **キー**テキストボックスに、変数の名前を入力します。例: `SSH_PRIVATE_KEY`。
1. **値**テキストボックスに、プライベートキーのコンテンツを貼り付けます。値は改行文字（`LF`文字）で終わる必要があります。改行を追加するには、保存する前に最終行の末尾で<kbd>Enter</kbd>または<kbd>Return</kbd>を押します。

### SSHキーを通常の変数として追加する {#add-an-ssh-key-as-a-regular-variable}

ファイルタイプのCI/CD変数を使用したくない場合は、[例のSSHプロジェクト](https://gitlab.com/gitlab-examples/ssh-private-key/)を参照してください。この方法は、ファイルタイプの変数の代わりに通常のCI/CD変数を使用します。一般的に、ファイルタイプの変数は、複数行の書式を維持し、書式設定関連のエラーのリスクを軽減するため、推奨されます。

## Docker executor使用時のSSHキー {#ssh-keys-when-using-the-docker-executor}

CI/CDジョブがDockerコンテナで実行される場合、環境は分離されています。プライベートサーバーにコードをデプロイするには、SSHキーペアを使用できます。

1. 新しいSSHキーペアを[生成します](../../user/ssh.md#generate-an-ssh-key-pair)。SSHキーにパスフレーズを追加しないでください。そうしないと、`before_script`がパスフレーズの入力を求めます。
1. プライベートキーを`SSH_PRIVATE_KEY`という名前の[ファイルタイプのCI/CD変数](#add-an-ssh-key-as-a-file-type-variable)として追加します。
1. `.gitlab-ci.yml`に`before_script`アクションを追加します。次の例では、Debianベースのイメージと、ジョブがパッケージをインストールする権限を持つコンテナで実行されることを想定しています。

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
     ## Optionally, if you use Git commands, set the user name and email.
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

1. 新しいSSHキーペアを[生成します](../../user/ssh.md#generate-an-ssh-key-pair)。SSHキーにパスフレーズを追加しないでください。そうしないと、`before_script`がパスフレーズの入力を求めます。

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

ホストを[ファイルタイプのCI/CD変数](#add-an-ssh-key-as-a-file-type-variable)としてプロジェクトに追加します。ただし、次の点を除きます:

- `SSH_KNOWN_HOSTS`を**キー**として使用します。
- `ssh-keyscan`の出力を**値**として使用します。

複数のサーバーに接続する必要がある場合は、すべてのサーバーのホストキーを1行に1つずつ記載し、変数の**値**に収集する必要があります。

> [!note] 
> 
> `.gitlab-ci.yml`内で`ssh-keyscan`を直接使用する代わりに、ファイルタイプのCI/CD変数を使用すると、何らかの理由でホストのドメイン名が変更されても`.gitlab-ci.yml`を変更する必要がないという利点があります。また、値はユーザーによって事前定義されているため、ホストキーが突然変更されてもCI/CDジョブは失敗しません。そのため、サーバーまたはネットワークに問題があると判断できます。
>
> `ssh-keyscan`は、中間者攻撃に対して脆弱なセキュリティリスクであるため、CI/CDジョブで直接実行しないでください。

`SSH_KNOWN_HOSTS`変数を作成したら、上記の[`.gitlab-ci.yml`の内容](#ssh-keys-when-using-the-docker-executor)に加えて、以下を追加する必要があります。

```yaml
before_script:
  ##
  ## Assuming you created the SSH_KNOWN_HOSTS file type CI/CD variable:
  ##
  - cp "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts
```

## トラブルシューティング {#troubleshooting}

### エラー: `... error in libcrypto` {#error--error-in-libcrypto}

CI/CDジョブでSSHキーを読み込むときに、次のエラーが発生する場合があります:

```plaintext
Error loading key "/builds/path/SSH_PRIVATE_KEY": error in libcrypto
```

この問題は、SSHキーの値が改行文字（`LF`文字）で終わっていない場合に発生する可能性があります。

この問題を解決するには、[ファイルタイプのCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)を編集し、変数を保存する前にSSHキーの`-----END OPENSSH PRIVATE KEY-----`行の末尾で<kbd>Enter</kbd>または<kbd>Return</kbd>を押します。

### エラー: `... value cannot contain...` {#error--value-cannot-contain}

SSHキーをCI/CD変数として保存するときに、エラーが発生する場合があります:

```plaintext
Unable to create masked variable because: The value cannot contain the
following characters: whitespace characters.
```

この問題は、変数の**表示レベル**が**マスクする**または**マスクして非表示**に設定されている場合に発生します。マスクされた変数はスペースのない単一行である必要がありますが、SSHキーにはマスクすると互換性のない空白文字が含まれています。

この問題を解決するには、[SSHキーをファイルタイプの変数として追加](#add-an-ssh-key-as-a-file-type-variable)するときに、**表示レベル**を**表示**に設定します。ファイルタイプの変数はジョブログで公開されないため、キーの値に追加の保護レイヤーが提供されます。

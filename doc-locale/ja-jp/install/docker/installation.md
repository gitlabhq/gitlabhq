---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: DockerコンテナにGitLabをインストールするための前提要件、戦略、手順について説明します。
title: DockerコンテナにGitLabをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

DockerコンテナにGitLabをインストールするには、Docker Compose、Docker Engine、またはDocker Swarmモードを使用します。

前提要件:

- Docker for Windowsではない、動作する[Dockerインストール](https://docs.docker.com/engine/install/#server)が必要です。Docker for Windowsは、イメージにボリューム権限に関する既知の互換性の問題やその他の不明な問題があるため、公式にはサポートされていません。Docker for Windowsで実行しようとしている場合は、[ヘルプページ](https://about.gitlab.com/get-help/)を参照してください。このページには、他のユーザーに助けを求めることができるコミュニティリソース（IRCやフォーラムなど）へのリンクが含まれています。
- PostfixやSendmailなどのメール転送エージェント（MTA）が必要です。GitLabイメージにはMTAは含まれていません。MTAは別のコンテナにインストールできます。GitLabと同じコンテナにMTAをインストールすることもできますが、アップグレードまたは再起動のたびにMTAを再インストールする必要がでてきます。
- GitLab DockerイメージをKubernetesにデプロイしないでください。単一障害点が発生してしまいます。GitLabをKubernetesにデプロイする場合は、代わりに[GitLab Helmチャート](https://docs.gitlab.com/charts/)または[GitLab Operator](https://docs.gitlab.com/operator/)を使用してください。
- Dockerインストール用に、有効で外部からアクセス可能なホスト名が必要です。`localhost`は使用しないでください。

## SSHポートを設定する {#configure-the-ssh-port}

デフォルトでは、GitLabはポート`22`を使用してSSH経由でGitとやり取りします。ポート`22`を使用するには、このセクションをスキップしてください。

別のポートを使用するには、次のいずれかを実行します。

- 今すぐサーバーのSSHポートを変更します（推奨）。すると、SSHクローンURLに新しいポート番号は不要になります。

  ```plaintext
  ssh://git@gitlab.example.com/user/project.git
  ```

- インストール後に[GitLab Shell SSHポートを変更](configuration.md#expose-gitlab-on-different-ports)します。すると、SSHクローンURLには設定されたポート番号が含まれます。

  ```plaintext
  ssh://git@gitlab.example.com:<portNumber>/user/project.git
  ```

サーバーのSSHポートを変更するには:

1. エディタで`/etc/ssh/sshd_config`を開き、SSHポートを変更します。

   ```conf
   Port = 2424
   ```

1. ファイルを保存し、SSHサービスを再起動します。

   ```shell
   sudo systemctl restart ssh
   ```

1. SSH経由で接続できることを確認します。新しいターミナルセッションを開き、新しいポートを使用してサーバーにSSH接続します。

## ボリュームのディレクトリを作成する {#create-a-directory-for-the-volumes}

{{< alert type="warning" >}}

Gitalyデータをホスティングするボリュームには、特定の推奨設定があります。NFSベースのファイルシステムはパフォーマンスのイシューを引き起こす可能性があるため、[EFSは推奨されません](../aws/_index.md#elastic-file-system-efs)。

{{< /alert >}}

設定ファイル、ログファイル、およびデータファイルのディレクトリを作成します。ディレクトリは、ユーザーのホームディレクトリ（`~/gitlab-docker`など）または`/srv/gitlab`などのディレクトリに配置できます。

1. ディレクトリを作成します。

   ```shell
   sudo mkdir -p /srv/gitlab
   ```

1. `root`以外のユーザーでDockerを実行している場合は、新しいディレクトリに対する適切な権限をユーザーに付与します。

1. 作成したディレクトリへのパスを設定する新しい環境変数`$GITLAB_HOME`を設定します。

   ```shell
   export GITLAB_HOME=/srv/gitlab
   ```

1. オプションで、今後のすべてのターミナルセッションに適用されるように、Shellのプロファイルに`GITLAB_HOME`環境変数を追加できます。

   - Bash: `~/.bash_profile`
   - ZSH: `~/.zshrc`

GitLabコンテナは、ホストマウントされたボリュームを使用して永続データを保存します。

| ローカルの場所       | コンテナの場所 | 使用法                                       |
|----------------------|--------------------|---------------------------------------------|
| `$GITLAB_HOME/data`  | `/var/opt/gitlab`  | アプリケーションデータを保存。                    |
| `$GITLAB_HOME/logs`  | `/var/log/gitlab`  | ログを保存。                                |
| `$GITLAB_HOME/config`| `/etc/gitlab`      | GitLab設定ファイルを保存。      |

## 使用するGitLabのバージョンとエディションを見つける {#find-the-gitlab-version-and-edition-to-use}

本番環境では、デプロイを特定のGitLabバージョンに固定する必要があります。利用可能なバージョンを確認し、Dockerタグページで使用するバージョンを選択します。

- [GitLab Enterprise Editionタグ](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
- [GitLab Community Editionタグ](https://hub.docker.com/r/gitlab/gitlab-ce/tags/)

タグ名は次の要素で構成されています。

```plaintext
gitlab/gitlab-ee:<version>-ee.0
```

`<version>`にはGitLabのバージョンを指定します（例: `16.5.3`）。バージョン名には常に`<major>.<minor>.<patch>`が含まれています。

テスト目的では、最新の安定版リリースを指す`latest`タグ（例: `gitlab/gitlab-ee:latest`）を使用できます。

次の例では、安定版のEnterprise Editionバージョンを使用します。Release Candidate (RC)またはnightlyイメージを使用する場合は、代わりに`gitlab/gitlab-ee:rc`または`gitlab/gitlab-ee:nightly`を使用してください。

Community Editionをインストールするには、`ee`を`ce`に置き換えます。

## インストール {#installation}

GitLab Dockerイメージは、次を使用して実行できます。

- [Docker Compose](#install-gitlab-by-using-docker-compose)（推奨）
- [Docker Engine](#install-gitlab-by-using-docker-engine)
- [Docker Swarmモード](#install-gitlab-by-using-docker-swarm-mode)

### Docker Composeを使用してGitLabをインストールする {#install-gitlab-by-using-docker-compose}

[Docker Compose](https://docs.docker.com/compose/)を使用すると、DockerベースのGitLabインストールを設定、インストール、およびアップグレードできます。

1. [Docker Composeをインストール](https://docs.docker.com/compose/install/linux/)します。
1. `docker-compose.yml`ファイルを作成します。次に例を示します。

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Add any other gitlab.rb configuration here, each on its own line
           external_url 'https://gitlab.example.com'
       ports:
         - '80:80'
         - '443:443'
         - '22:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   {{< alert type="note" >}}

   `GITLAB_OMNIBUS_CONFIG`変数の仕組みについては、[Dockerコンテナの事前設定](configuration.md#pre-configure-docker-container)セクションを参照してください。

   {{< /alert >}}

   これは、カスタムHTTPおよびSSHポートで実行されているGitLabを使用した別の`docker-compose.yml`の例です。`GITLAB_OMNIBUS_CONFIG`変数が`ports`セクションと一致することに注意してください。

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           external_url 'http://gitlab.example.com:8929'
           gitlab_rails['gitlab_shell_ssh_port'] = 2424
       ports:
         - '8929:8929'
         - '443:443'
         - '2424:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   この設定は、`--publish 8929:8929 --publish 2424:22`を使用するのと同じです。

1. `docker-compose.yml`と同じディレクトリで、GitLabを起動します。

   ```shell
   docker compose up -d
   ```

### Docker Engineを使用してGitLabをインストールする {#install-gitlab-by-using-docker-engine}

Docker Engineを使用してGitLabをインストールすることもできます。

1. `GITLAB_HOME`変数を設定している場合は、要件を満たすようにディレクトリを調整し、イメージを実行します。

   - SELinuxを使用していない場合は、次のコマンドを実行します。

     ```shell
     sudo docker run --detach \
       --hostname gitlab.example.com \
       --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
       --publish 443:443 --publish 80:80 --publish 22:22 \
       --name gitlab \
       --restart always \
       --volume $GITLAB_HOME/config:/etc/gitlab \
       --volume $GITLAB_HOME/logs:/var/log/gitlab \
       --volume $GITLAB_HOME/data:/var/opt/gitlab \
       --shm-size 256m \
       gitlab/gitlab-ee:<version>-ee.0
     ```

     このコマンドは、GitLabコンテナをダウンロードして起動し、SSH、HTTP、およびHTTPSへのアクセスに必要な[ポートを公開](https://docs.docker.com/network/#published-ports)します。すべてのGitLabデータは、`$GITLAB_HOME`のサブディレクトリとして保存されます。システム再起動後、コンテナは自動的に再起動します。

   - SELinuxを使用している場合は、代わりにこれを実行します。

     ```shell
     sudo docker run --detach \
       --hostname gitlab.example.com \
       --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
       --publish 443:443 --publish 80:80 --publish 22:22 \
       --name gitlab \
       --restart always \
       --volume $GITLAB_HOME/config:/etc/gitlab:Z \
       --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
       --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
       --shm-size 256m \
       gitlab/gitlab-ee:<version>-ee.0
     ```

     このコマンドは、Dockerプロセスに、マウントされたボリュームに設定ファイルを作成するのに十分な権限があることを保証します。

1. [Kerberosインテグレーション](../../integration/kerberos.md)を使用している場合は、Kerberosポートも公開する必要があります（例: `--publish 8443:8443`）。そうしないと、Kerberosを使用したGitオペレーションを実行できません。初期化プロセスには時間がかかる場合があります。このプロセスは、次のコマンドで追跡できます。

   ```shell
   sudo docker logs -f gitlab
   ```

   コンテナの起動後、`gitlab.example.com`にアクセスできます。Dockerコンテナがクエリへの応答を開始するまでに時間がかかる場合があります。

1. GitLab URLにアクセスし、ユーザー名`root`と次のコマンドからのパスワードでサインインします。

   ```shell
   sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
   ```

{{< alert type="note" >}}

パスワードファイルは、最初のコンテナ再起動後、24時間後に自動的に削除されます。

{{< /alert >}}

### Docker Swarmモードを使用してGitLabをインストールする {#install-gitlab-by-using-docker-swarm-mode}

[Docker Swarmモード](https://docs.docker.com/engine/swarm/)を使用すると、 Swarmクラスター内のDockerでGitLabインストールを設定およびデプロイできます。

Swarmモードでは、[Dockerシークレット](https://docs.docker.com/engine/swarm/secrets/)および[Docker設定](https://docs.docker.com/engine/swarm/configs/)を利用して、GitLabインスタンスを効率的かつ安全にデプロイできます。シークレットを使用すると、初期ルートパスワードを環境変数として公開せずに安全に渡すことができます。設定は、GitLabイメージを可能な限り汎用的に保つのに役立ちます。

次に、シークレットと設定を使用して、4つのRunnerを[スタック](https://docs.docker.com/get-started/swarm-deploy/#describe-apps-using-stack-files)としてGitLabをデプロイする例を示します。

1. [Docker Swarmをセットアップ](https://docs.docker.com/engine/swarm/swarm-tutorial/)します。
1. `docker-compose.yml`ファイルを作成します。

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       ports:
         - "22:22"
         - "80:80"
         - "443:443"
       volumes:
         - $GITLAB_HOME/data:/var/opt/gitlab
         - $GITLAB_HOME/logs:/var/log/gitlab
         - $GITLAB_HOME/config:/etc/gitlab
       shm_size: '256m'
       environment:
         GITLAB_OMNIBUS_CONFIG: "from_file('/omnibus_config.rb')"
       configs:
         - source: gitlab
           target: /omnibus_config.rb
       secrets:
         - gitlab_root_password
     gitlab-runner:
       image: gitlab/gitlab-runner:alpine
       deploy:
         mode: replicated
         replicas: 4
   configs:
     gitlab:
       file: ./gitlab.rb
   secrets:
     gitlab_root_password:
       file: ./root_password.txt
   ```

   複雑さを軽減するために、先程の例では`network`設定を除外しています。詳細については、公式の[Composeファイルリファレンス](https://docs.docker.com/compose/compose-file/)を参照してください。

1. `gitlab.rb`ファイルを作成します。

   ```ruby
   external_url 'https://my.domain.com/'
   gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password').gsub("\n", "")
   ```

1. パスワードを含む`root_password.txt`という名前のファイルを作成します。

   ```plaintext
   MySuperSecretAndSecurePassw0rd!
   ```

1. `docker-compose.yml`と同じディレクトリにいることを確認し、次を実行します。

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

Dockerをインストールしたら、[GitLabインスタンスを設定](configuration.md)する必要があります。

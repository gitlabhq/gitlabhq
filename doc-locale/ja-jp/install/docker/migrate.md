---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LinuxパッケージのGitLabインスタンスをDockerに移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

既存のLinuxパッケージのGitLabインスタンスを、次のいずれかのアプローチを使用してDockerに移行します:

- **Reuse existing data directories**: 既存のデータディレクトリをDockerボリュームパスに移動します。このアプローチを使用して、完全なバックアップと復元のサイクルなしでデータを維持します。
- **Back up and restore**: LinuxパッケージインスタンスでGitLabのバックアップを作成し、新しいDockerインスタンスをセットアップして、それに復元する。このアプローチは、必要に応じてロールバックをサポートするクリーンな移行に利用できます。

## 前提条件 {#prerequisites}

- Linuxパッケージインスタンス上のGitLabとDockerイメージのバージョンは一致している必要があります。必要に応じて、Dockerに移行する前にLinuxパッケージインスタンスをアップグレードしてください。
- ターゲットサーバーに[Docker](installation.md)がインストールされている必要があります。

## 既存のデータディレクトリを再利用する {#reuse-existing-data-directories}

既存のデータディレクトリを再利用して、LinuxパッケージのGitLabインスタンスをDockerに移行する。

### Linuxパッケージインスタンスを停止する {#stop-the-linux-package-instance}

すべてのGitLabサービスを停止します:

```shell
sudo gitlab-ctl stop
```

### ボリュームディレクトリを準備する {#prepare-the-volume-directories}

ボリュームディレクトリの準備方法は、Dockerの実行場所によって異なります:

- DockerがLinuxパッケージインスタンスと同じサーバーで実行されている場合は、既存のディレクトリをコピーせずに直接マウントできます。Docker Composeファイル内のボリュームパスをLinuxパッケージの場所に設定します:

  ```yaml
  volumes:
    - '/etc/gitlab:/etc/gitlab'
    - '/var/log/gitlab:/var/log/gitlab'
    - '/var/opt/gitlab:/var/opt/gitlab'
  ```

- 別のサーバーに移動する場合、またはDockerボリュームをLinuxパッケージパスから分離したい場合は、まずディレクトリを新しい場所にコピーしてください。

  1. `$GITLAB_HOME`をターゲットディレクトリに設定します:

     ```shell
     export GITLAB_HOME=/srv/gitlab
     sudo mkdir -p $GITLAB_HOME
     ```

  1. データ、ログ、および設定ディレクトリをコピー（または移動）します:

     ```shell
     sudo cp -a /var/opt/gitlab $GITLAB_HOME/data
     sudo cp -a /var/log/gitlab $GITLAB_HOME/logs
     sudo cp -a /etc/gitlab     $GITLAB_HOME/config
     ```

     コピーではなく移動するには、`mv`を`cp -a`の代わりに使用します。

> [!warning]
> コンテナを起動する前に、ホストディレクトリの所有権を`root:root`に変更しないでください。そうすると、コンテナの起動が妨げられ、`update-permissions`スクリプトによるその後の所有権の修正も妨げられます。

リポジトリディレクトリが存在し、破損したシンボリックリンクではなく、実際のディレクトリであることを確認します:

```shell
ls -la $GITLAB_HOME/data/git-data/repositories
```

ディレクトリが見つからないか、破損したシンボリックリンクである場合は、作成します:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
```

### ユーザーとグループ識別子を調整する {#align-user-and-group-identifiers}

GitLabDockerイメージには、すべてのGitLabディレクトリに正しい所有権を設定する`update-permissions`と呼ばれる組み込みスクリプトが含まれています。Linuxパッケージインスタンスが、Dockerイメージが想定する固有識別子とは異なる固有識別子（ディストリビューションによって異なるOSのデフォルト、または[明示的に設定された値](https://docs.gitlab.com/omnibus/settings/configuration/#specify-numeric-user-and-group-identifiers)）を使用している場合は、コンテナを開始する前に、ボリュームをマウントした一時的なコンテナから`update-permissions`を実行します。これにより、最初の起動前に所有権が修正されます:

```shell
docker run --rm \
  -v <config_path>:/etc/gitlab \
  -v <logs_path>:/var/log/gitlab \
  -v <data_path>:/var/opt/gitlab \
  --entrypoint /bin/bash \
  gitlab/gitlab-ee:<version> \
  -c "update-permissions"
```

[ボリュームディレクトリを準備する](#prepare-the-volume-directories)で特定したホストパスに、`<config_path>`、`<logs_path>`、および`<data_path>`を置き換えます。

### GitLabをDockerで起動する {#start-gitlab-in-docker}

準備したディレクトリをマウントするDocker ComposeファイルまたはDocker Engineコマンドを作成するには、[インストール手順](installation.md)に従ってください:

```yaml
volumes:
  - '$GITLAB_HOME/config:/etc/gitlab'
  - '$GITLAB_HOME/logs:/var/log/gitlab'
  - '$GITLAB_HOME/data:/var/opt/gitlab'
```

コンテナの起動後、再設定を実行します:

```shell
docker exec -it <container_name> gitlab-ctl reconfigure
```

インストールを確認します:

```shell
docker exec -it <container_name> gitlab-rake gitlab:check
```

## Linuxパッケージインスタンスをバックアップし、Dockerインスタンスに復元する {#back-up-the-linux-package-instance-and-restore-to-the-docker-instance}

### Linuxパッケージインスタンスでバックアップを作成する {#create-a-backup-on-the-linux-package-instance}

Linuxパッケージインスタンスを停止する前に、バックアップを作成します:

```shell
sudo gitlab-backup create
```

シークレットファイルを安全な場所にコピーします:

```shell
sudo cp /etc/gitlab/gitlab-secrets.json /your/backup/location/
```

詳細については、[GitLabをバックアップする](../../administration/backup_restore/backup_gitlab.md)を参照してください。

### Linuxパッケージインスタンスを停止する {#stop-the-linux-package-instance-1}

すべてのGitLabサービスを停止します:

```shell
sudo gitlab-ctl stop
```

### Dockerインスタンスをセットアップする {#set-up-the-docker-instance}

新しいDockerインスタンスをセットアップするには、[インストール手順](installation.md)に従ってください。たとえば、ボリューム用に作成するディレクトリに`$GITLAB_HOME`を設定します:

```shell
export GITLAB_HOME=/srv/gitlab
```

コンテナを一度起動してボリュームディレクトリを初期化し、復元する前に停止します:

```shell
docker compose up -d
docker compose stop
```

### バックアップを復元する {#restore-the-backup}

1. バックアップアーカイブをDockerデータボリュームにコピーします:

   ```shell
   sudo cp <timestamp>_gitlab_backup.tar $GITLAB_HOME/data/backups/
   ```

1. シークレットファイルをDocker設定ボリュームにコピーします:

   ```shell
   sudo cp gitlab-secrets.json $GITLAB_HOME/config/gitlab-secrets.json
   ```

1. コンテナを起動し、復元を実行します:

   ```shell
   docker compose start
   docker exec -it <container_name> gitlab-backup restore BACKUP=<timestamp>
   ```

1. 復元完了後に再設定して再起動します:

   ```shell
   docker exec -it <container_name> gitlab-ctl reconfigure
   docker exec -it <container_name> gitlab-ctl restart
   ```

1. インストールを確認します:

   ```shell
   docker exec -it <container_name> gitlab-rake gitlab:check
   ```

## トラブルシューティング {#troubleshooting}

LinuxパッケージのGitLabインスタンスをDockerに移行する際に、以下の問題が発生する可能性があります。

### 起動後の権限エラー {#permission-errors-after-starting}

コンテナが起動しても権限エラーがレポートされる場合は、以下を実行します:

```shell
sudo docker exec <container_name> update-permissions
sudo docker restart <container_name>
```

これは、Linuxパッケージインスタンスが、Dockerイメージが想定する固有識別子とは異なる固有識別子をシステムアカウントに使用した場合に発生します。これを防ぐには、[ユーザーとグループ識別子を調整する](#align-user-and-group-identifiers)に記載されているように、開始する前に`update-permissions`を実行します。

### 別のインスタンスからデータを再利用する際のエラー {#errors-when-reusing-data-from-another-instance}

別のインスタンスからデータを再利用する際に、以下の問題が発生する可能性があります。

#### 起動時の`stat: missing operand`エラー {#stat-missing-operand-error-on-startup}

このエラーは、コンテナが`git-data/repositories`ディレクトリを見つけられない場合に発生します:

```plaintext
stat: missing operand
Expected process to exit with [0], but received '1'
Ran stat --printf='%U' $(readlink -f /var/opt/gitlab/git-data/repositories) returned 1
```

ホスト上で、不足しているディレクトリを作成し、コンテナを再起動します:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
sudo docker restart <container_name>
```

#### コンテナがすぐに終了し、再起動ループによって`docker exec`がブロックされる {#container-exits-immediately-and-restart-loop-blocks-docker-exec}

コンテナが起動後すぐに終了する場合、調査のために`docker exec`を使用したり、`update-permissions`を実行したりすることはできません。代わりに、[ユーザーとグループ識別子を調整する](#align-user-and-group-identifiers)と同じコマンドを使用して`update-permissions`を直接実行します。これにより、メインのコンテナを実行することなく、ボリュームがマウントされた一時的なコンテナが起動され、所有権が修正されます。

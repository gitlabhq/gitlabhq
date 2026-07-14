---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dockerインスタンスをアップグレードする
description: 単一ノードのDockerベースインスタンスをアップグレードします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Dockerベースのインスタンスを、GitLabの以降のバージョンにアップグレードします。

## 前提条件 {#prerequisites}

Dockerインスタンスをアップグレードする前に、まず[必要な情報と手順を確認してください](../plan_your_upgrade.md)。

## Dockerベースのインスタンスをアップグレードする {#upgrade-a-docker-based-instance}

Dockerベースのインスタンスをアップグレードするには:

1. アップグレード中は、[メンテナンスモードを有効にする](../../administration/maintenance_mode/_index.md)ことを検討してください。
1. [実行中のCI/CDパイプラインとジョブ](../plan_your_upgrade.md#pause-cicd-pipelines-and-jobs)を一時停止します。
1. ターゲットのGitLabバージョンと同じバージョンに[GitLab Runner](https://docs.gitlab.com/runner/install/)をアップグレードします。
1. GitLab自体を以下のいずれかの方法でアップグレードします:
   - [Docker Engineを使用する](#upgrade-with-docker-engine)。
   - [Docker Composeを使用する](#upgrade-with-docker-compose)。

アップグレード後:

1. [実行中のCI/CDパイプラインとジョブ](../plan_your_upgrade.md#pause-cicd-pipelines-and-jobs)の一時停止を解除します。
1. 有効になっている場合は、[メンテナンスモードをオフにします](../../administration/maintenance_mode/_index.md#disable-maintenance-mode)。
1. [アップグレードヘルスチェック](../plan_your_upgrade.md#run-upgrade-health-checks)を実行します。

### Docker Engineでアップグレードする {#upgrade-with-docker-engine}

[Docker Engineを使用してインストールされた](../../install/docker/installation.md#install-gitlab-by-using-docker-engine) GitLabインスタンスをアップグレードするには:

1. [バックアップ](../../install/docker/backup.md)を作成します。最低限、[データベース](../../install/docker/backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。
1. 実行中のコンテナを停止します。

   ```shell
   sudo docker stop gitlab
   ```

1. 既存のコンテナを削除します。

   ```shell
   sudo docker rm gitlab
   ```

1. 新しいイメージをプルします。

   {{< tabs >}}

   {{< tab title="GitLab Enterprise Edition" >}}

   ```shell
   sudo docker pull gitlab/gitlab-ee:<version>-ee.0
   ```

   {{< /tab >}}

   {{< tab title="GitLab Community Edition" >}}

   ```shell
   sudo docker pull gitlab/gitlab-ce:<version>-ce.0
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. `GITLAB_HOME`環境変数が[定義](../../install/docker/installation.md#create-a-directory-for-the-volumes)されていることを確認してください。

   ```shell
   echo $GITLAB_HOME
   ```

1. [以前に指定した](../../install/docker/installation.md#install-gitlab-by-using-docker-engine)オプションを使用して、コンテナを再度作成します。

   ```shell
   sudo docker run --detach \
   --hostname gitlab.example.com \
   --publish 443:443 --publish 80:80 --publish 22:22 \
   --name gitlab \
   --restart always \
   --volume $GITLAB_HOME/config:/etc/gitlab \
   --volume $GITLAB_HOME/logs:/var/log/gitlab \
   --volume $GITLAB_HOME/data:/var/opt/gitlab \
   --shm-size 256m \
   gitlab/gitlab-ee:<version>-ee.0
   ```

初回実行時に、GitLabは自身を再構成し、アップグレードします。

### Docker Composeでアップグレードする {#upgrade-with-docker-compose}

[Docker Composeを使用してインストールされた](../../install/docker/installation.md#install-gitlab-by-using-docker-compose) GitLabインスタンスをアップグレードするには:

1. [バックアップ](../../install/docker/backup.md)を作成します。最低限、[データベース](../../install/docker/backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。
1. `docker-compose.yml`を編集して、プルするバージョンを変更します。
1. 最新リリースをダウンロードして、GitLabインスタンスをアップグレードします。

   ```shell
   docker compose pull
   docker compose up -d
   ```

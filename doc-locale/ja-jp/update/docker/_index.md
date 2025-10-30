---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dockerインスタンスをアップグレード
description: Dockerベースのインスタンスをアップグレードします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Dockerベースのインスタンスを、GitLabの以降のバージョンにアップグレードします。

アップグレードする前に、[アップグレード前に必要な情報](../plan_your_upgrade.md)を確認してください。

## Docker Engineを使用してGitLabをアップグレードする {#upgrade-gitlab-by-using-docker-engine}

[Docker Engineを使用してインストール](../../install/docker/installation.md#install-gitlab-by-using-docker-engine)されたGitLabインスタンスをアップグレードするには、次のようにします:

1. [バックアップ](../../install/docker/backup.md)を作成します。最低限、[データベース](../../install/docker/backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。

1. 実行中のコンテナを停止します:

   ```shell
   sudo docker stop gitlab
   ```

1. 既存のコンテナを削除します:

   ```shell
   sudo docker rm gitlab
   ```

1. 新しいイメージをプルします:

   {{< tabs >}}

   {{< tab title="GitLab Enterprise Edition（EE）" >}}

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

1. `GITLAB_HOME`環境変数が[定義](../../install/docker/installation.md#create-a-directory-for-the-volumes)されていることを確認してください:

   ```shell
   echo $GITLAB_HOME
   ```

1. [以前に指定した](../../install/docker/installation.md#install-gitlab-by-using-docker-engine)オプションを使用して、コンテナを再度作成します:

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

## Docker Composeを使用してGitLabをアップグレードする {#upgrade-gitlab-by-using-docker-compose}

[Docker Composeを使用してインストール](../../install/docker/installation.md#install-gitlab-by-using-docker-compose)されたGitLabインスタンスをアップグレードするには、次のようにします:

1. [バックアップ](../../install/docker/backup.md)を作成します。最低限、[データベース](../../install/docker/backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。
1. `docker-compose.yml`を編集して、プルするバージョンを変更します。
1. 最新リリースをダウンロードして、GitLabインスタンスをアップグレードします:

   ```shell
   docker compose pull
   docker compose up -d
   ```

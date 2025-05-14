---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップグレード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ほとんどの場合、GitLabのアップグレードは最新のDockerイメージタグをダウンロードするのと同じくらい簡単です。

## Docker Engineを使用してGitLabをアップグレードする

[Docker Engineを使用してインストール](installation.md#install-gitlab-by-using-docker-engine)されたGitLabインスタンスをアップグレードするには:

1. [バックアップ](backup.md)を作成します。最低限、[データベース](backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。

1. 実行中のコンテナを停止します。

   ```shell
   sudo docker stop gitlab
   ```

1. 既存のコンテナを削除します。

   ```shell
   sudo docker rm gitlab
   ```

1. 新しいイメージをプルします。

   ```shell
   sudo docker pull gitlab/gitlab-ee:<version>-ee.0
   ```

1. `GITLAB_HOME`環境変数が[定義](installation.md#create-a-directory-for-the-volumes)されていることを確認してください。

   ```shell
   echo $GITLAB_HOME
   ```

1. [以前に指定した](installation.md#install-gitlab-by-using-docker-engine)オプションを使用して、コンテナを再度作成します。

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

異なるバージョンにアップグレードする場合は、GitLab[アップグレードの推奨事項](../../policy/maintenance.md#upgrade-recommendations)を参照してください。

## Docker Composeを使用してGitLabをアップグレードする

[Docker Composeを使用してインストール](installation.md#install-gitlab-by-using-docker-compose)されたGitLabインスタンスをアップグレードするには:

1. [バックアップ](backup.md)を作成します。最低限、[データベース](backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。
1. `docker-compose.yml`を編集して、プルするバージョンを変更します。
1. 最新リリースをダウンロードして、GitLabインスタンスをアップグレードします。

   ```shell
   docker compose pull
   docker compose up -d
   ```

## CommunityエディションをEnterpriseエディションに変換する

Docker用の既存のGitLab Communityエディション(CE)コンテナをGitLab [Enterpriseエディション](https://about.gitlab.com/pricing/)(EE)コンテナに変換するには、[バージョンをアップグレード](upgrade.md)するのと同じ方法を使用します。

CEの同じバージョンからEEに変換することをおすすめします(たとえば、CE 14.1からEE 14.1)。ただし、これは必須ではありません。標準的なアップグレード(たとえば、CE 14.0からEE 14.1)はすべて機能するはずです。次の手順では、同じバージョンに変換することを前提としています。

1. [バックアップ](backup.md)を作成します。最低限、[データベース](backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。

1. 現在のCEコンテナを停止し、削除または名前を変更します。

1. GitLab EEで新しいコンテナを作成するには、`docker run`コマンドまたは`docker-compose.yml`ファイルで`ce`を`ee`に置き換えます 。CEコンテナ名、ポートマッピング、ファイルマッピング、およびバージョンを再利用します。

## GitLabをダウングレードする

復元により、新しいすべてのGitLabデータベースコンテンツを古い状態に上書きします。ダウングレードは、必要な場合にのみ推奨されます。たとえば、アップグレード後のテストで、すぐに解決できない問題が明らかになった場合などです。

{{< alert type="warning" >}}

ダウングレードするバージョンおよびエディションとまったく同じバージョンで作成されたデータベースのバックアップが少なくとも1つ必要です。バックアップは、アップグレード中に行われたスキーマの変更(移行)を元に戻すために必要です。

{{< /alert >}}

アップグレード直後にGitLabをダウングレードするには:

1. インストールしたバージョンより[以前のバージョンを指定](installation.md#find-the-gitlab-version-and-edition-to-use)して、アップグレード手順に従います。

1. アップグレード前に[作成したデータベースバックアップ](backup.md#create-a-database-backup)を復元します。

   - PumaとSidekiqの停止を含め、[Dockerイメージの復元手順に従います](../../administration/backup_restore/restore_gitlab.md#restore-for-docker-image-and-gitlab-helm-chart-installations)。データベースのみを復元する必要があるため、`SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state`を`gitlab-backup restore`コマンドライン引数に追加します。

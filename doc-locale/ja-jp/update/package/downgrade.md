---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 以前のGitLabバージョンにロールバックする
description: LinuxパッケージまたはDockerインスタンスを以前のバージョンにロールバックします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

LinuxパッケージまたはDockerを使用してインストールされたGitLabインスタンスを以前のバージョンにロールバックできます。

ロールバックする際は、以前アップグレードした際に発生した[バージョン固有の変更](../versions/_index.md)を考慮する必要があります。

## 前提条件 {#prerequisites}

インスタンスがアップグレードされた際に行われたデータベーススキーマの変更（移行）を元に戻す必要があるため、以下のものが必要です:

- ロールバックしようとしているものと全く同じバージョンおよびエディションで作成されたデータベースバックアップが少なくとも1つ必要です。
- ロールバックしようとしているものと全く同じバージョンおよびエディションの[完全なバックアップアーカイブ](../../administration/backup_restore/_index.md)があることが理想的です。

## Linuxパッケージインスタンスのロールバック {#roll-back-a-linux-package-instance}

Linuxパッケージインスタンスを以前のGitLabバージョンにロールバックするには:

1. GitLabを停止し、現在のパッケージを削除します:

   ```shell
   # If running Puma
   sudo gitlab-ctl stop puma

   # Stop sidekiq
   sudo gitlab-ctl stop sidekiq

   # If on Ubuntu: remove the current package
   sudo dpkg -r gitlab-ee

   # If on Centos: remove the current package
   sudo yum remove gitlab-ee
   ```

1. ロールバックしたいGitLabバージョンを特定します:

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt-cache madison gitlab-ee

   # CentOS:
   sudo yum --showduplicates list gitlab-ee
   ```

1. GitLabを希望するバージョンにロールバックします（例えば、GitLab 15.0.5に）:

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt install gitlab-ee=15.0.5-ee.0

   # CentOS:
   sudo yum install gitlab-ee-15.0.5-ee.0.el8
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [GitLabを復元する](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations)ことで、ロールバックを完了します。

## Dockerインスタンスのロールバック {#roll-back-a-docker-instance}

復元により、新しいすべてのGitLabデータベースコンテンツを古い状態に上書きします。ロールバックは、必要な場合にのみ推奨されます。たとえば、アップグレード後のTestで、すぐに解決できない問題が明らかになった場合などです。

> [!warning]
> ダウングレードしようとしているものと全く同じバージョンおよびエディションで作成されたデータベースバックアップが少なくとも1つ必要です。バックアップは、アップグレード中に行われたスキーマの変更（移行）を取り消しために必要です。

アップグレード後すぐにGitLabをロールバックするには:

1. インストールした[以前](../../install/docker/installation.md#find-the-gitlab-version-and-edition-to-use)のバージョンを指定して、アップグレード手順に従います。
1. [アップグレード](../../install/docker/backup.md#create-a-database-backup)前に作成したデータベースバックアップを復元します。

   - PumaとSidekiqの停止を含め、[Dockerイメージの復元手順](../../administration/backup_restore/restore_gitlab.md#restore-for-docker-image-and-gitlab-helm-chart-installations)に従います。データベースのみを復元する必要があるため、`SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state`を`gitlab-backup restore`コマンドライン引数に追加します。

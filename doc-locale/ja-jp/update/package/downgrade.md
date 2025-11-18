---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 以前のGitLabバージョンにロールバックする
description: LinuxパッケージまたはDockerインスタンスを以前のバージョンにロールバックします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

LinuxパッケージまたはDockerを使用してインストールされたGitLabインスタンスの以前のバージョンにロールバックできます。

ロールバックする際は、以前にアップグレードしたときに発生した[バージョン固有の変更点](../versions/_index.md)を考慮する必要があります。

## 前提要件 {#prerequisites}

インスタンスのアップグレード時に行われたデータベーススキーマの変更（移行）を元に戻す必要があるため、以下が必要です:

- ロールバック先の正確なバージョンおよびエディションで作成されたデータベースバックアップが少なくとも1つ必要です。
- 理想的には、ロールバック先の正確なバージョンおよびエディションの[完全なバックアップアーカイブ](../../administration/backup_restore/_index.md)。

## Linuxパッケージインスタンスをロールバックする {#roll-back-a-linux-package-instance}

Linuxパッケージインスタンスを以前のGitLabバージョンにロールバックするには、次の手順に従います:

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

1. ロールバック先のGitLabバージョンを特定します:

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt-cache madison gitlab-ee

   # CentOS:
   sudo yum --showduplicates list gitlab-ee
   ```

1. 目的のバージョンにGitLabをロールバックします（たとえば、GitLab 15.0.5にロールバックする場合）:

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

1. [GitLabを復元する](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations)して、ロールバックを完了します。

## Dockerインスタンスをロールバックする {#roll-back-a-docker-instance}

復元により、新しいすべてのGitLabデータベースコンテンツを古い状態に上書きします。ロールバックは、必要な場合にのみ推奨されます。たとえば、アップグレード後のTestで、すぐに解決するできない問題が明らかになった場合などです。

{{< alert type="warning" >}}

ダウングレードするバージョンおよびエディションとまったく同じバージョンで作成されたデータベースのバックアップが少なくとも1つ必要です。バックアップは、アップグレード中に行われたスキーマの変更（移行）を取り消しために必要です。

{{< /alert >}}

アップグレード直後にGitLabをロールバックするには、次の手順に従います:

1. インストールした[以前](../../install/docker/installation.md#find-the-gitlab-version-and-edition-to-use)のバージョンを指定して、アップグレード手順に従います。

1. [アップグレード](../../install/docker/backup.md#create-a-database-backup)前に作成したデータベースバックアップを復元します。

   - PumaとSidekiqの停止を含め、[Dockerイメージの復元手順](../../administration/backup_restore/restore_gitlab.md#restore-for-docker-image-and-gitlab-helm-chart-installations)に従います。データベースのみを復元する必要があるため、`SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state`を`gitlab-backup restore`コマンドライン引数に追加します。

---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dockerコンテナで実行されているGitLabをバックアップする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabのバックアップは、以下で作成できます。

```shell
docker exec -t <container name> gitlab-backup create
```

詳しくは、[GitLabのバックアップと復元](../../administration/backup_restore/_index.md)をご覧ください。

{{< alert type="note" >}}

GitLab設定をすべて`GITLAB_OMNIBUS_CONFIG`環境変数で提供している場合（GitLabの[「Dockerコンテナを事前設定する」](configuration.md#pre-configure-docker-container)の手順を使用している場合）、構成設定は`gitlab.rb`ファイルに保存されないため、`gitlab.rb`ファイルをバックアップする必要はありません。

{{< /alert >}}

{{< alert type="warning" >}}

バックアップからGitLabを復元する際に[複雑な手順](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)を回避するには、[GitLabシークレットファイルのバックアップ](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files)の手順にも従ってください。シークレットファイルは、コンテナ内の`/etc/gitlab/gitlab-secrets.json`ファイル、または[コンテナホスト上の](installation.md#create-a-directory-for-the-volumes)`$GITLAB_HOME/config/gitlab-secrets.json`ファイルに保存されます。

{{< /alert >}}

## データベースのバックアップを作成する

GitLabをアップグレードする前に、データベースのみのバックアップを作成します。GitLabのアップグレード中に問題が発生した場合、データベースのバックアップを復元して、アップグレードをロールバックできます。データベースのバックアップを作成するには、次のコマンドを実行します。

```shell
docker exec -t <container name> gitlab-backup create SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state
```

バックアップは`/var/opt/gitlab/backups`に書き込まれますが、これは[Dockerによってマウントされたボリューム](installation.md#create-a-directory-for-the-volumes)上にあるはずです。

アップグレードをロールバックするためのバックアップの使用方法について詳しくは、[GitLabをダウングレードする](upgrade.md#downgrade-gitlab)をご覧ください。

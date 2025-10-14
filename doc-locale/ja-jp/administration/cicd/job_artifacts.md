---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブアーティファクトの管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

これは管理者向けのドキュメントです。GitLab CI/CDパイプラインでのジョブアーティファクトの使用方法については、[ジョブアーティファクトの設定に関するドキュメント](../../ci/jobs/job_artifacts.md)を参照してください。

アーティファクトとは、ジョブの完了後にジョブにアタッチされるファイルやディレクトリのリストです。この機能は、すべてのGitLabインストールにおいてデフォルトで有効になっています。

## ジョブアーティファクトを無効にする {#disabling-job-artifacts}

アーティファクトをサイト全体で無効にするには、次の手順に従います。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['artifacts_enabled'] = false
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       artifacts:
         enabled: false
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['artifacts_enabled'] = false
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     artifacts:
       enabled: false
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## ジョブアーティファクトを保存する {#storing-job-artifacts}

GitLab Runnerは、ジョブアーティファクトを含むアーカイブをGitLabにアップロードできます。これは、デフォルトではジョブが成功した場合に実行されます。しかし、[`artifacts:when`](../../ci/yaml/_index.md#artifactswhen)パラメータを使用することで、失敗時または常にアップロードするように設定することもできます。

ほとんどのアーティファクトは、コーディネーターに送信される前にGitLab Runnerによって圧縮されます。ただし、[レポートアーティファクト](../../ci/yaml/_index.md#artifactsreports)は例外で、アップロード後に圧縮されます。

### ローカルストレージを使用する {#using-local-storage}

Linuxパッケージまたは自己コンパイルでインストールしている場合は、アーティファクトをローカルに保存する場所を変更できます。

{{< alert type="note" >}}

Dockerインストールの場合、データがマウントされるパスを変更できます。Helmチャートの場合は、[オブジェクトストレージ](https://docs.gitlab.com/charts/advanced/external-object-storage/)を使用します。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

アーティファクトはデフォルトで`/var/opt/gitlab/gitlab-rails/shared/artifacts`に保存されます。

1. ストレージパスを`/mnt/storage/artifacts`に変更するには、`/etc/gitlab/gitlab.rb`を編集し、次の行を追加します。

   ```ruby
   gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

アーティファクトはデフォルトで`/home/git/gitlab/shared/artifacts`に保存されます。

1. たとえば、ストレージパスを`/mnt/storage/artifacts`に変更するには、`/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します。

   ```yaml
   production: &base
     artifacts:
       enabled: true
       path: /mnt/storage/artifacts
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### オブジェクトストレージを使用する {#using-object-storage}

GitLabがインストールされているローカルディスクにアーティファクトを保存したくない場合は、代わりにAWS S3などのオブジェクトストレージを使用できます。

オブジェクトストレージにアーティファクトを保存するようGitLabを設定する場合は、[ジョブログによるローカルディスクの使用を回避する](job_logs.md#prevent-local-disk-usage)こともあわせて検討するとよいでしょう。どちらの場合も、ジョブが完了するとジョブログはアーカイブされ、オブジェクトストレージに移動されます。

{{< alert type="warning" >}}

マルチサーバーのセットアップでは、[ジョブログをローカルディスクに保存しないようにする](job_logs.md#prevent-local-disk-usage)いずれかのオプションを必ず使用してください。そうしないと、ジョブログが失われる可能性があります。

{{< /alert >}}

[統合されたオブジェクトストレージ設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用する必要があります。

### オブジェクトストレージに移行する {#migrating-to-object-storage}

ジョブアーティファクトをローカルストレージからオブジェクトストレージに移行できます。この処理はバックグラウンドワーカーで実行され、**ダウンタイムは不要**です。

1. [オブジェクトストレージを設定](#using-object-storage)します。
1. アーティファクトを移行します。

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo gitlab-rake gitlab:artifacts:migrate
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:artifacts:migrate
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. （オプション）PostgreSQLコンソールを使用して、進行状況を追跡し、すべてのジョブアーティファクトを正常に移行したことを確認します。
   1. PostgreSQLコンソールを開きます。

      {{< tabs >}}

      {{< tab title="Linuxパッケージ（Omnibus）" >}}

      ```shell
      sudo gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Docker" >}}

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="自己コンパイル（ソース）" >}}

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. 次のSQLクエリを使用して、すべてのアーティファクトをオブジェクトストレージに移行したことを確認します。`objectstg`の数が`total`と同じである必要があります。

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM ci_job_artifacts;

      total | filesystem | objectstg
      ------+------------+-----------
         19 |          0 |        19
      ```

1. ディスク上の`artifacts`ディレクトリにファイルがないことを確認します。

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   `/var/opt/gitlab`を`/srv/gitlab`にマウントしている場合は、次のようになります。

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo find /home/git/gitlab/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. [Geo](../geo/_index.md)が有効になっている場合は、[すべてのジョブアーティファクトを再検証](../geo/replication/troubleshooting/synchronization_verification.md#reverify-one-component-on-all-sites)してください。

場合によっては、[孤立したアーティファクトファイルのクリーンアップ用Rakeタスク](../raketasks/cleanup.md#remove-orphan-artifact-files)を実行して、孤立したアーティファクトのクリーンアップが必要となることがあります。

### オブジェクトストレージからローカルストレージに移行する {#migrating-from-object-storage-to-local-storage}

アーティファクトをローカルストレージに戻すには、次の手順に従います。

1. `gitlab-rake gitlab:artifacts:migrate_to_local`を実行します。
1. `gitlab.rb`で、[必要に応じてアーティファクトのストレージを無効にします](../object_storage.md#disable-object-storage-for-specific-features)。
1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## アーティファクトの有効期限を設定する {#expiring-artifacts}

[`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in)を使用してアーティファクトの有効期限を設定した場合、その期限を過ぎるとすぐに削除対象としてマークされます。設定していない場合は、[デフォルトのアーティファクトの有効期限設定](../settings/continuous_integration.md#set-default-artifacts-expiration)に従って期限切れとなります。

Sidekiqが7分ごとに実行する`expire_build_artifacts_worker` cronジョブが、アーティファクトを削除します（[Cron](../../topics/cron/_index.md)構文`*/7 * * * *`）。

期限切れのアーティファクトを削除するデフォルトのスケジュールを変更するには、次の手順に従います。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します（すでに存在しておりコメントアウトされている場合は、コメントを解除します）。スケジュールはCron構文で変更してください。

   ```ruby
   gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       cron_jobs:
         expire_build_artifacts_worker:
           cron: "*/7 * * * *"
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     cron_jobs:
       expire_build_artifacts_worker:
         cron: "*/7 * * * *"
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## アーティファクトの最大ファイルサイズを設定する {#set-the-maximum-file-size-of-the-artifacts}

アーティファクトが有効になっている場合は、[**管理者**エリアの設定](../settings/continuous_integration.md#set-maximum-artifacts-size)からアーティファクトの最大ファイルサイズを変更できます。

## ストレージ統計 {#storage-statistics}

グループおよびプロジェクトごとのジョブアーティファクトの合計ストレージ使用量は、次の手段で確認できます。

- **管理者**エリア
- [グループ](../../api/groups.md) APIおよび[プロジェクト](../../api/projects.md) API

## 実装の詳細 {#implementation-details}

GitLabがアーティファクトのアーカイブを受信すると、[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse)によってアーカイブメタデータファイルも生成されます。このメタデータファイルには、アーティファクトアーカイブ内のすべてのエントリに関する情報が含まれています。メタデータファイルはバイナリ形式で、さらにGzip圧縮が施されています。

GitLabは、容量、メモリ、およびディスクI/Oを節約するために、アーティファクトアーカイブを展開することはありません。代わりに、すべての関連情報を含むメタデータファイルを調べます。これは、アーティファクトが大量にある場合や、アーカイブが非常に大きなファイルである場合に特に重要です。

特定のファイルを選択すると、[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse)はアーカイブからそのファイルを抽出し、ダウンロードを開始します。この実装により、容量、メモリ、およびディスクI/Oを節約できます。

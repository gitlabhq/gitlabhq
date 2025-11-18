---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブログ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ジョブのジョブログは、Runnerがジョブを処理している間に送信されます。ログファイルは、ジョブページ、パイプライン、メール通知などで確認できます。

## データの流れ {#data-flow}

一般に、ジョブログには2つの状態があります。`log`と`archived log`です。次の表では、ログファイルがたどるフェーズを確認できます: 

| フェーズ          | ステート        | 条件               | データの流れ                                | 保存パス |
| -------------- | ------------ | ----------------------- | -----------------------------------------| ----------- |
| 1: パッチ    | ログファイル          | ジョブの実行時   | Runner => Puma => ファイルストレージ | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 2：アーカイブ   | アーカイブ済みログファイル | ジョブの完了後 | Sidekiqは、アーティファクトフォルダーにログファイルを移動します    | `#{ROOT_PATH}/gitlab-rails/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |
| 3：アップロード   | アーカイブ済みログファイル | ログファイルのアーカイブ後 | Sidekiqは、アーカイブされたログファイルを（構成されている場合）[オブジェクトストレージ](#uploading-logs-to-object-storage)に移動します | `#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |

`ROOT_PATH`は環境によって異なります: 

- Linuxパッケージの場合、`/var/opt/gitlab`です。
- セルフコンパイルインストールの場合、`/home/git/gitlab`です。

## ジョブのログファイルのローカルロケーションの変更 {#changing-the-job-logs-local-location}

{{< alert type="note" >}}

Dockerインストールの場合、データがマウントされるパスを変更できます。Helmチャートの場合は、オブジェクトストレージを使用します。

{{< /alert >}}

ジョブのログファイルの保存場所を変更するには、次の手順を実行します: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. オプション。既存のジョブログがある場合は、Sidekiqを一時的に停止して、継続的インテグレーションデータ処理を一時停止します: 

   ```shell
   sudo gitlab-ctl stop sidekiq
   ```

1. `/etc/gitlab/gitlab.rb`に新しいストレージロケーションを設定します: 

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/gitlab-ci/builds'
   ```

1. ファイルを保存して、GitLabを再設定します: 

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `rsync`を使用して、ジョブログを現在の場所から新しい場所に移動します: 

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /var/opt/gitlab/gitlab-ci/builds/ /mnt/gitlab-ci/builds/
   ```

   `--ignore-existing`を使用すると、同じログファイルの古いバージョンで新しいジョブログをオーバーライドすることがなくなります。

1. 継続的インテグレーションデータ処理の一時停止を選択した場合は、Sidekiqを再起動できます: 

   ```shell
   sudo gitlab-ctl start sidekiq
   ```

1. 古いジョブログのストレージロケーションを削除します: 

   ```shell
   sudo rm -rf /var/opt/gitlab/gitlab-ci/builds
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. オプション。既存のジョブログがある場合は、Sidekiqを一時的に停止して、継続的インテグレーションデータ処理を一時停止します: 

   ```shell
   # For systems running systemd
   sudo systemctl stop gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab stop
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集して、新しいストレージロケーションを設定します: 

   ```yaml
   production: &base
     gitlab_ci:
       builds_path: /mnt/gitlab-ci/builds
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. `rsync`を使用して、ジョブログを現在の場所から新しい場所に移動します: 

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /home/git/gitlab/builds/ /mnt/gitlab-ci/builds/
   ```

   `--ignore-existing`を使用すると、同じログファイルの古いバージョンで新しいジョブログをオーバーライドすることがなくなります。

1. 継続的インテグレーションデータ処理の一時停止を選択した場合は、Sidekiqを再起動できます: 

   ```shell
   # For systems running systemd
   sudo systemctl start gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab start
   ```

1. 古いジョブログのストレージロケーションを削除します: 

   ```shell
   sudo rm -rf /home/git/gitlab/builds
   ```

{{< /tab >}}

{{< /tabs >}}

## オブジェクトストレージへのアップロード {#uploading-logs-to-object-storage}

アーカイブされたログファイルは、[ジョブアーティファクト](job_artifacts.md)と見なされます。したがって、[オブジェクトストレージインテグレーションをセットアップする](job_artifacts.md#using-object-storage)と、他のジョブアーティファクトとともに、ジョブログは自動的に移行されます。

プロセスの詳細については、[データの流れ](#data-flow)の「フェーズ3：アップロード」を参照してください。

## ログファイルの最大サイズ {#maximum-log-file-size}

GitLabのジョブログファイルサイズの制限は、デフォルトで100 MBです。制限を超過したジョブは失敗とマークされ、Runnerによって破棄されます。詳細については、[ジョブのログファイルの最大ファイルサイズ](../instance_limits.md#maximum-file-size-for-job-logs)を参照してください。

## ローカルディスクの使用量の抑制 {#prevent-local-disk-usage}

ジョブログのローカルディスクの使用を回避する場合は、次のいずれかのオプションを使用します: 

- [増分ロギング](#configure-incremental-logging)をオンにします。
- [ジョブログの場所](#changing-the-job-logs-local-location)をNFSドライブに設定します。

## ジョブログの削除方法 {#how-to-remove-job-logs}

古いジョブログを自動的に期限切れにする方法はありません。ただし、容量を使いすぎている場合は、削除しても安全です。ログファイルを手動で削除すると、UIのジョブ出力が空になります。

GitLab CLIを使用してジョブログを削除する方法の詳細については、[ジョブログの削除](../../user/storage_management_automation.md#delete-job-logs)を参照してください。

または、Shellコマンドでジョブログを削除することもできます。たとえば、60日より古いすべてのジョブログを削除するには、GitLabインスタンスのShellから次のコマンドを実行します。

{{< alert type="note" >}}

Helm Chartの場合は、オブジェクトストレージに付属しているストレージ管理ツールを使用します。

{{< /alert >}}

{{< alert type="warning" >}}

次のコマンドは、ログファイルを完全に削除し、元に戻すことはできません。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
find /var/opt/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Docker" >}}

`/var/opt/gitlab`を`/srv/gitlab`にマウントしている場合は、次のようになります: 

```shell
find /srv/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
find /home/git/gitlab/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< /tabs >}}

ログファイルを削除したら、アップロードされたファイルの[整合性](../raketasks/check.md#uploaded-files-integrity)をチェックするRakeタスクを実行して、破損したファイル参照を検索できます。詳細については、[欠落しているアーティファクトへの参照を削除する](../raketasks/check.md#delete-references-to-missing-artifacts)方法を参照してください。

## 増分ロギング {#incremental-logging}

増分ロギングは、ジョブログが処理および保存される方法を変更し、スケールアウトされたデプロイでのパフォーマンスを向上させます。

デフォルトでは、ジョブログはチャンク単位でGitLab Runnerから送信され、ディスクに一時的にキャッシュされます。ジョブの完了後、バックグラウンドジョブはログファイルをアーティファクトディレクトリ、または構成されている場合はオブジェクトストレージにアーカイブします。

増分ロギングでは、ログファイルはファイルストレージではなく、Redisおよび永続ストレージに保存されます。このアプローチは次のことを可能にします: 

- ジョブログにローカルディスクを使用しないようにします。
- RailsサーバーとSidekiqサーバー間のNFS共有の必要性を排除します。
- マルチノードインストールでのパフォーマンスが向上します。

増分ロギングプロセスは、一時ストレージとしてRedisを使用し、次のフローに従います: 

1. Runnerは、GitLabからジョブを選択します。
1. Runnerは、ログファイルの一部をGitLabに送信します。
1. GitLabは、`Gitlab::Redis::TraceChunks`ネームスペースのRedisにデータを追加します。
1. Redisのデータが128 KBに達すると、データは永続ストレージにフラッシュされます。
1. ジョブが完了するまで、前の手順が繰り返されます。
1. ジョブが完了すると、GitLabはSidekiqワーカーをスケジュールしてログファイルをアーカイブします。
1. Sidekiqワーカーは、ログファイルをオブジェクトストレージにアーカイブし、一時データをクリーンアップします。

Redisクラスタリングは、増分ロギングではサポートされていません。詳細については、[イシュー224171](https://gitlab.com/gitlab-org/gitlab/-/issues/224171)を参照してください。

### 増分ログの生成を設定する {#configure-incremental-logging}

増分ロギングをオンにする前に、[CI/CDアーティファクト、ログファイル、およびビルドのオブジェクトストレージを構成](job_artifacts.md#using-object-storage)する必要があります。増分ロギングがオンになると、ファイルはディスクに書き込むことができなくなり、設定ミスに対する保護はなくなります。

増分ロギングをオンにすると、実行中のジョブのログファイルは引き続きディスクに書き込まれますが、新しいジョブは増分ロギングを使用します。

増分ロギングをオフにすると、実行中のジョブは引き続き増分ロギングを使用しますが、新しいジョブはディスクに書き込みます。

増分ログを設定するには:

- [管理者エリア](../settings/continuous_integration.md#access-job-log-settings)または[設定](../../api/settings.md)で設定を使用します。

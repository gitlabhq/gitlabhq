---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDインスタンスの設定
description: GitLab CI/CDの設定を管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabの管理者は、インスタンスのGitLab CI/CD設定を管理できます。

## 新規プロジェクトでGitLab CI/CDを無効にする {#disable-gitlab-cicd-in-new-projects}

GitLab CI/CDは、インスタンス上のすべての新しいプロジェクトでデフォルトで有効になっています。CI/CDが新しいプロジェクトでデフォルトで無効になるように設定を変更できます:

- 自己コンパイルによるインストールの場合: `gitlab.yml`。
- Linuxパッケージインストールの場合: `gitlab.rb`。

すでにCI/CDが有効になっている既存のプロジェクトは変更されません。また、この設定はプロジェクトのデフォルトのみを変更するため、プロジェクトオーナーは[プロジェクト設定でCI/CDを有効にすることができます](../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines)。

自己コンパイルによるインストールの場合: 

1. エディタで`gitlab.yml`を開き、`builds`を`false`に設定します:

   ```yaml
   ## Default project features settings
   default_projects_features:
     issues: true
     merge_requests: true
     wiki: true
     snippets: false
     builds: false
   ```

1. `gitlab.yml`ファイルを保存します。

1. GitLabを再起動します:

   ```shell
   sudo service gitlab restart
   ```

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['gitlab_default_projects_features_builds'] = false
   ```

1. `/etc/gitlab/gitlab.rb`ファイルを保存します。

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## `needs`ジョブ制限を設定する {#set-the-needs-job-limit}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`needs`で定義できるジョブの最大数は、デフォルトで50です。

[GitLab Railsコンソールにアクセス](../operations/rails_console.md#starting-a-rails-console-session)できるGitLab管理者は、カスタム制限を選択できます。たとえば、制限を`100`に設定するには、次のようにします:

```ruby
Plan.default.actual_limits.update!(ci_needs_size_limit: 100)
```

`needs`依存関係を無効にするには、制限を`0`に設定します。`needs`を使用するように構成されたジョブを持つパイプラインは、エラー`job can only need 0 others`を返します。

## スケジュールされたパイプラインの最大頻度を変更する {#change-maximum-scheduled-pipeline-frequency}

[パイプラインスケジュール](../../ci/pipelines/schedules.md)は任意の[cron値](../../topics/cron/_index.md)で設定できますが、スケジュールどおりに正確に実行されるとは限りません。内部プロセスである_パイプラインスケジュールワーカー_は、スケジュールされたすべてのパイプラインをキューに入れますが、継続的には実行されません。ワーカーは独自のスケジュールで実行され、開始する準備ができているスケジュールされたパイプラインは、ワーカーが次に実行されるときにのみキューに入れられます。スケジュールされたパイプラインは、ワーカーよりも頻繁に実行することはできません。

パイプラインスケジュールワーカーのデフォルトの頻度は、`3-59/10 * * * *`（10分ごと、`0:03`、`0:13`、`0:23`などで開始）です。GitLab.comのデフォルトの頻度は、[GitLab.comの設定](../../user/gitlab_com/_index.md#cicd)にリストされています。

パイプラインスケジュールワーカーの頻度を変更するには、次のようにします:

1. インスタンスの`gitlab.rb`ファイルで、`gitlab_rails['pipeline_schedule_worker_cron']`の値を編集します。
1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

たとえば、パイプラインの最大頻度を1日に2回に設定するには、`pipeline_schedule_worker_cron`を`0 */12 * * *` (`00:00`および`12:00`毎日) のcron値に設定します。

パイプラインスケジュールの多くが同時に実行されると、遅延が発生する可能性があります。パイプラインスケジュールワーカーは、システム負荷を分散するために、各バッチ間に短い遅延を置いて[バッチ](https://gitlab.com/gitlab-org/gitlab/-/blob/3426be1b93852c5358240c5df40970c0ddfbdb2a/app/workers/pipeline_schedule_worker.rb#L13-14)でパイプラインを処理します。これにより、システム負荷に応じて、スケジュールされた時刻より数分から1時間以上遅れてパイプラインスケジュールが開始される可能性があります。

## ディザスターリカバリー {#disaster-recovery}

継続的なダウンタイム中にデータベースへのストレスを軽減するために、アプリケーションの計算コストの高い重要な部分を無効にすることができます。

### インスタンスRunnerでのフェアスケジューリングを無効にする {#disable-fair-scheduling-on-instance-runners}

大量のバックログのジョブをクリアするときに、一時的に`ci_queueing_disaster_recovery_disable_fair_scheduling` [機能フラグ](../feature_flags/_index.md)を有効にすることができます。この機能フラグは、インスタンスRunnerでのフェアスケジューリングを無効にし、`jobs/request`エンドポイントでのシステムリソースの使用量を削減します。

有効にすると、ジョブは、多くのプロジェクト間でバランスが取られるのではなく、システムに投入された順に処理されます。

### コンピューティングクォータの適用を無効にする {#disable-compute-quota-enforcement}

インスタンスRunnerでの[コンピューティング時間](compute_minutes.md)クォータの適用を無効にするには、一時的に`ci_queueing_disaster_recovery_disable_quota` [機能フラグ](../feature_flags/_index.md)を有効にすることができます。この機能フラグは、`jobs/request`エンドポイントでのシステムリソースの使用量を削減します。

有効にすると、過去1時間に作成されたジョブは、クォータを超えているプロジェクトで実行できます。以前のジョブは、定期的なバックグラウンドワーカー (`StuckCiJobsWorker`) によってすでにキャンセルされています。

---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ファイルエクスポートのプロジェクト移行のトラブルシューティング
description: "ファイルエクスポートのプロジェクト移行のトラブルシューティング。一般的なエラー、パフォーマンスに関するイシュー、および解決策について説明します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[ファイルエクスポートを使用したプロジェクトの移行](import_export.md)で問題が発生した場合は、以下の解決策を参照してください。

## トラブルシューティングコマンド {#troubleshooting-commands}

JIDを使用してインポートのステータスおよび追加ログに関する情報を、[Railsコンソール](../../../administration/operations/rails_console.md)を使用して検索します:

```ruby
Project.find_by_full_path('group/project').import_state.slice(:jid, :status, :last_error)
> {"jid"=>"414dec93f941a593ea1a6894", "status"=>"finished", "last_error"=>nil}
```

```shell
# Logs
grep JID /var/log/gitlab/sidekiq/current
grep "Import/Export error" /var/log/gitlab/sidekiq/current
grep "Import/Export backtrace" /var/log/gitlab/sidekiq/current
tail /var/log/gitlab/gitlab-rails/importer.log
```

## プロジェクトが不一致のためインポートに失敗しました {#project-fails-to-import-due-to-mismatch}

[インスタンスRunner](../../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project)の有効化が、エクスポートされたプロジェクトとプロジェクトのインポート間で一致しない場合、プロジェクトのインポートは失敗します。[イシュー276930](https://gitlab.com/gitlab-org/gitlab/-/issues/276930)を確認し、以下のいずれかを実行します:

- ソースプロジェクトとデスティネーションプロジェクトの両方でインスタンスRunnerが有効になっていることを確認します。
- プロジェクトをインポートする際に、親グループのインスタンスRunnerを無効にします。

## インポートされたプロジェクトからユーザーが不足しています {#users-missing-from-imported-project}

ユーザーがインポートされたプロジェクトにインポートされていない場合は、[ユーザーコントリビュートの保持](import_export.md#preserving-user-contributions)要件を参照してください。

ユーザーが見つからない一般的な理由は、[公開メール設定](../../profile/_index.md#set-your-public-email)がユーザーに対して構成されていないことです。このイシューを解決するには、GitLab UIを使用してこの設定を構成するようユーザーに依頼してください。

手動での設定が現実的ではないほど多数のユーザーがいる場合は、[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を使用して、すべてのユーザープロファイルで公開メールアドレスを使用するように設定できます:

```ruby
User.where("public_email IS NULL OR public_email = '' ").find_each do |u|
  next if u.bot?

  puts "Setting #{u.username}'s currently empty public email to #{u.email}…"
  u.public_email = u.email
  u.save!
end
```

## 大規模リポジトリのインポートの回避策 {#import-workarounds-for-large-repositories}

[最大インポートサイズの制限](import_export.md#import-a-project-and-its-data)により、インポートが正常に完了しない場合があります。インポートの制限を変更できない場合は、ここに記載されているいずれかの回避策を試すことができます。

### 回避策オプション1 {#workaround-option-1}

以下のローカルワークフローを使用して、別のインポート試行のためにリポジトリサイズを一時的に縮小できます:

1. エクスポートから一時的な作業ディレクトリを作成します:

   ```shell
   EXPORT=<filename-without-extension>

   mkdir "$EXPORT"
   tar -xf "$EXPORT".tar.gz --directory="$EXPORT"/
   cd "$EXPORT"/
   git clone project.bundle

   # Prevent interference with recreating an importable file later
   mv project.bundle ../"$EXPORT"-original.bundle
   mv ../"$EXPORT".tar.gz ../"$EXPORT"-original.tar.gz

   git switch --create smaller-tmp-main
   ```

1. リポジトリサイズを縮小するには、この`smaller-tmp-main`ブランチで作業します: [大きなファイルを特定して削除する](../repository/repository_size.md#methods-to-reduce-repository-size)か、[インタラクティブにリベースして修正する](../../../topics/git/git_rebase.md#interactive-rebase)ことで、コミットの数を減らします。

   ```shell
   # Reduce the .git/objects/pack/ file size
   cd project
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive

   # Prepare recreating an importable file
   git bundle create ../project.bundle <default-branch-name>
   cd ..
   mv project/ ../"$EXPORT"-project
   cd ..

   # Recreate an importable file
   tar -czf "$EXPORT"-smaller.tar.gz --directory="$EXPORT"/ .
   ```

1. この新しい、より小さいファイルをGitLabにインポートします。
1. 元のリポジトリの完全なクローンで、`git remote set-url origin <new-url> && git push --force --all`を使用してインポートを完了します。
1. インポートされたリポジトリの[ブランチ保護ルール](../repository/branches/protected.md)とその[デフォルトブランチ](../repository/branches/default.md)を更新し、一時的な`smaller-tmp-main`ブランチとローカルの一時データを削除します。

### 回避策オプション2 {#workaround-option-2}

> [!note]
> この回避策はLFSオブジェクトを考慮していません。

すべての変更を一度にプッシュするのではなく、この回避策は以下のことを行います:

- プロジェクトのインポートをGitリポジトリのインポートから分離します。
- リポジトリをGitLabに段階的にプッシュする

1. 移行するリポジトリのローカルクローンを作成します。後のステップで、このクローンをプロジェクトエクスポートの外部にプッシュする。
1. エクスポートをダウンロードし、Gitリポジトリを含む`project.bundle`を削除します:

   ```shell
   tar -czvf new_export.tar.gz --exclude='project.bundle' @old_export.tar.gz
   ```

1. Gitリポジトリなしでエクスポートをインポートします。リポジトリなしでのインポートを確認するように求められます。
1. このbashスクリプトをファイルとして保存し、適切なoriginを追加した後に実行します。

   ```shell
   #!/bin/sh

   # ASSUMPTIONS:
   # - The GitLab location is "origin"
   # - The default branch is "main"
   # - This will attempt to push in chunks of 500 MB (dividing the total size by 500 MB).
   #   Decrease this size to push in smaller chunks if you still receive timeouts.

   git gc
   SIZE=$(git count-objects -v 2> /dev/null | grep size-pack | awk '{print $2}')

   # Be conservative and try to push 2 GB at a time
   # (given this assumes each commit is the same size - which is wrong)
   BATCHES=$(($SIZE / 500000))
   TOTAL_COMMITS=$(git rev-list --count HEAD)
   if (( BATCHES > TOTAL_COMMITS )); then
       BATCHES=$TOTAL_COMMITS
   fi

   INCREMENTS=$(( ($TOTAL_COMMITS / $BATCHES) - 1 ))

   for (( BATCH=BATCHES; BATCH>=1; BATCH-- ))
   do
     COMMIT_NUM=$(( $BATCH - $INCREMENTS ))
     COMMIT_SHA=$(git log -n $COMMIT_NUM --format=format:%H | tail -1)
     git push -u origin ${COMMIT_SHA}:refs/heads/main
   done
   git push -u origin main
   git push -u origin --all
   git push -u origin --tags
   ```

## プロジェクトのインポート時にエラー: `HTTP 524 A timeout occurred` {#error-http-524-a-timeout-occurred-when-importing-a-project}

GitLab.comでは、プロジェクトのインポートが`HTTP 524 A timeout occurred`エラーで失敗する場合があります。このエラーは、数ギガバイトのサイズのアーカイブで発生する可能性があります。

各アップロードは制限時間内に完了する必要があります。サイズの大きいアーカイブはその制限を超過する可能性があり、その場合、アップロードが完了する前に接続が閉じられます。

このエラーを回避するには、アーカイブをHTTPSロケーション（例: AWS S3バケット）でホストし、GitLabがインポート中にダウンロードするようにします。次のいずれかのエンドポイントを使用します:

- [`POST /api/v4/projects/remote-import`](../../../api/project_import_export.md#import-a-project-from-a-remote-archive)は、S3の事前署名済みURLを含む、あらゆるHTTPS URLで動作します。
- [`POST /api/v4/projects/remote-import-s3`](../../../api/project_import_export.md#import-a-project-from-an-aws-s3-bucket)は、認証情報を使用してAWS S3で動作します。

GitLabがバックグラウンドでアーカイブをダウンロードするため、アーカイブのサイズがタイムアウトの原因になることはありません。

## Sidekiqプロセスがプロジェクトのエクスポートに失敗しました {#sidekiq-process-fails-to-export-a-project}

Sidekiqプロセスは、実行中に終了した場合など、プロジェクトのエクスポートに失敗することがあります。

GitLab.comユーザーは、このイシューを解決するために[サポートに連絡](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#contact-support)してください。

GitLab Self-Managedの管理者は、Railsコンソールを使用してSidekiqプロセスをバイパスすることで、プロジェクトのエクスポートを手動でトリガーすることができます:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

::Projects::ImportExport::ExportService.new(project, current_user, params).execute(nil)
```

これにより、UIを通じてエクスポートが利用可能になりますが、ユーザーへのメールはトリガーされません。プロジェクトのエクスポートを手動でトリガーする、およびメールを送信するには:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

ProjectExportWorker.new.perform(current_user.id, project.id)
```

## エクスポートステップを手動で実行する {#manually-execute-export-steps}

プロジェクトは通常、[Webインターフェース](import_export.md#export-a-project-and-its-data)または[プロジェクトインポートおよびエクスポートAPI](../../../api/project_import_export.md)を介してエクスポートします。これらの方法を使用してエクスポートすると、トラブルシューティングを行うのに十分な情報が得られずに失敗する場合があります。これらの場合、[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開き、[定義されているすべてのexporter](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/projects/import_export/export_service.rb)をループします。各コマンドが返すエラーを確認できるように、ブロック全体を一度に貼り付けるのではなく、各行を個別に実行してください。

```ruby
# User needs to have permission to export
u = User.find_by_username('someuser')
p = Project.find_by_full_path('some/project')
e = Projects::ImportExport::ExportService.new(p,u)

e.send(:version_saver).send(:save)
e.send(:repo_saver).send(:save)
e.send(:avatar_saver).send(:save)
e.send(:project_tree_saver).send(:save)
e.send(:uploads_saver).send(:save)
e.send(:wiki_repo_saver).send(:save)
e.send(:lfs_saver).send(:save)
e.send(:snippets_repo_saver).send(:save)
e.send(:design_repo_saver).send(:save)
## continue using `e.send(:exporter_name).send(:save)` going through the list of exporters

# The following line should show you the export_path similar to /var/opt/gitlab/gitlab-rails/shared/tmp/gitlab_exports/@hashed/49/94/4994....
s = Gitlab::ImportExport::Saver.new(exportable: p, shared: p.import_export_shared, user: u)

# Prior to GitLab 17.0, the `user` parameter was not supported. If you encounter an
# error with the above or are unsure whether or not to supply the `user`
# argument, use the following check:
Gitlab::ImportExport::Saver.instance_method(:initialize).parameters.include?([:keyreq, :user])
# If the preceding check returns false, omit the user argument:
s = Gitlab::ImportExport::Saver.new(exportable: p, shared: p.import_export_shared)

# To try and upload use:
s.send(:compress_and_save)
s.send(:save_upload)
```

プロジェクトが正常にアップロードされると、エクスポートされたプロジェクトは`/var/opt/gitlab/gitlab-rails/uploads/-/system/import_export_upload/export_file/`の`.tar.gz`ファイルにあります。

## エラー: `PG::QueryCanceled: ERROR: canceling statement due to statement timeout` {#error-pgquerycanceled-error-canceling-statement-due-to-statement-timeout}

一部の移行は、`PG::QueryCanceled: ERROR: canceling statement due to statement timeout`というエラーでタイムアウトすることがあります。この問題を回避する1つの方法は、移行のバッチサイズを小さくすることです。これにより、移行がタイムアウトする可能性は低くなりますが、移行は遅くなります。

バッチサイズを小さくするには、機能フラグを有効にする必要があります。詳細については、[イシュー456948](https://gitlab.com/gitlab-org/gitlab/-/issues/456948)を参照してください。

## エラー: `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]` {#error-command-exited-with-error-code-15-and-unable-to-save-filtered-into-filtered}

ファイルエクスポートを使用してプロジェクトを移行するときに、ログに次のエラーが表示される場合があります:

```plaintext
command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]
```

このエラーは、エクスポートまたはインポート中にSidekiqが`SIGTERM`を受信したときに発生します。これは、多くの場合、`tar`コマンドの実行中に発生します。

GitLab.comやGitLab DedicatedのようなKubernetes環境では、メモリまたはディスク不足、コードデプロイ、あるいはインスタンスのアップグレードにより、オペレーティングシステムが`SIGTERM`シグナルをトリガーします。根本原因を特定するには、管理者がKubernetesがインスタンスを終了した理由を調査する必要があります。

非Kubernetes環境では、`tar`コマンドの実行中にインスタンスが終了した場合にこのエラーが発生する可能性があります。ただし、このエラーはディスク不足によるものではないため、メモリ不足が最も可能性の高い原因です。

このエラーが発生した場合:

- ファイルをエクスポートすると、GitLabは最大再試行回数に達するまでエクスポートを再試行し、その後エクスポートを失敗としてマークします。GitLab.comの場合、インスタンスへの負荷が少ない週末にエクスポートを試してください。
- ファイルをインポートする場合は、自分でインポートを再試行する必要があります。GitLabはインポートを自動的に再試行しません。

## パフォーマンスイシューのトラブルシューティング {#troubleshooting-performance-issues}

以下のインポート/エクスポートを使用して、現在のパフォーマンスの問題を確認してください。

### OOMエラー {#oom-errors}

Out-of-memory（OOM）エラーは通常、[Sidekiqメモリキラー](../../../administration/sidekiq/sidekiq_memory_killer.md)によって引き起こされます:

```shell
SIDEKIQ_MEMORY_KILLER_MAX_RSS = 2000000
SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS = 3000000
SIDEKIQ_MEMORY_KILLER_GRACE_TIME = 900
```

インポートステータスが`started`であり、以下のSidekiqログはメモリイシューを示しています:

```shell
WARN: Work still in progress <struct with JID>
```

### タイムアウト {#timeouts}

タイムアウトエラーは、`Gitlab::Import::StuckProjectImportJobsWorker`がプロセスを失敗としてマークするために発生します:

```ruby
module Gitlab
  module Import
    class StuckProjectImportJobsWorker
      include Gitlab::Import::StuckImportJob
      # ...
    end
  end
end

module Gitlab
  module Import
    module StuckImportJob
      # ...
      IMPORT_JOBS_EXPIRATION = 15.hours.to_i
      # ...
      def perform
        stuck_imports_without_jid_count = mark_imports_without_jid_as_failed!
        stuck_imports_with_jid_count = mark_imports_with_jid_as_failed!

        track_metrics(stuck_imports_with_jid_count, stuck_imports_without_jid_count)
      end
      # ...
    end
  end
end
```

```shell
Marked stuck import jobs as failed. JIDs: xyz
```

```plaintext
  +-----------+    +-----------------------------------+
  |Export Job |--->| Calls ActiveRecord `as_json` and  |
  +-----------+    | `to_json` on all project models   |
                   +-----------------------------------+

  +-----------+    +-----------------------------------+
  |Import Job |--->| Loads all JSON in memory, then    |
  +-----------+    | inserts into the DB in batches    |
                   +-----------------------------------+
```

### 問題と解決策 {#problems-and-solutions}

データベースからの[JSONの低速な読み込み/ダンプモデル](https://gitlab.com/gitlab-org/gitlab/-/issues/25251):

- [ワーカーを分割する](https://gitlab.com/gitlab-org/gitlab/-/issues/25252)
- バッチエクスポート
- SQLを最適化する
- `ActiveRecord`コールバックから離れる（難しい）

高いメモリ使用量（一部の[分析](https://gitlab.com/gitlab-org/gitlab/-/issues/18857)も参照）:

- メモリ使用量を抑えるコミットの最適なポイント
- [Netflix Fast JSON API](https://github.com/Netflix/fast_jsonapi)が役立つ可能性があります
- ディスクへのバッチ読み取り/書き込みとあらゆるSQL

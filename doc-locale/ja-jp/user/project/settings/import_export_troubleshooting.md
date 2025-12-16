---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ファイルエクスポートプロジェクトの移行のトラブルシューティング
description: "ファイルエクスポートプロジェクトの移行のトラブルシューティング。一般的なエラー、パフォーマンスの問題、および解決策について説明します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ファイルエクスポートを使用して[プロジェクトを移行する](import_export.md)際に問題が発生した場合は、以下の解決策をご覧ください。

## トラブルシューティングコマンド {#troubleshooting-commands}

[Railsコンソール](../../../administration/operations/rails_console.md)を使用して、インポートのステータスに関する情報と、JIDを使用した詳細ログを検索します:

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

## 不一致が原因でプロジェクトのインポートに失敗する {#project-fails-to-import-due-to-mismatch}

[インスタンスRunnerの有効化](../../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project)が、エクスポートされたプロジェクトとプロジェクトのインポートの間で一致しない場合、プロジェクトのインポートは失敗します。[イシュー276930](https://gitlab.com/gitlab-org/gitlab/-/issues/276930)を確認して、次のいずれかの操作を行います:

- ソースプロジェクトと宛先プロジェクトの両方でインスタンスランナーが有効になっていることを確認します。
- プロジェクトをインポートするときに、親グループのインスタンスランナーを無効にします。

## インポートされたプロジェクトからユーザーが見つからない {#users-missing-from-imported-project}

インポートされたプロジェクトでユーザーがインポートされない場合は、[ユーザーのコントリビュートを保持する](import_export.md#preserving-user-contributions)ための要件を参照してください。

ユーザーが見つからない一般的な理由は、[公開メールの設定](../../profile/_index.md#set-your-public-email)がユーザーに設定されていないことです。この問題を解決するには、GitLabユーザーインターフェースを使用してこの設定を設定するようにユーザーに依頼してください。

手動での設定が現実的ではないほどユーザーが多い場合は、[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を使用して、すべてのユーザープロファイルが公開メールアドレスを使用するように設定できます:

```ruby
User.where("public_email IS NULL OR public_email = '' ").find_each do |u|
  next if u.bot?

  puts "Setting #{u.username}'s currently empty public email to #{u.email}…"
  u.public_email = u.email
  u.save!
end
```

## 大規模なリポジトリのインポートの回避策 {#import-workarounds-for-large-repositories}

[最大インポートサイズ制限](import_export.md#import-a-project-and-its-data)により、インポートが成功しない場合があります。インポート制限の変更が不可能な場合は、ここにリストされている回避策のいずれかを試すことができます。

### 回避策オプション1 {#workaround-option-1}

次のローカルワークフローを使用して、別のインポートを試みるために、一時的にリポジトリのサイズを縮小できます:

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

1. リポジトリのサイズを縮小するには、この`smaller-tmp-main`ブランチで作業します。[サイズの大きいファイルを特定して削除する](../repository/repository_size.md#methods-to-reduce-repository-size)か、[インタラクティブにリベースして修正する](../../../topics/git/git_rebase.md#interactive-rebase)して、コミットの数を減らします。

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

1. この新しい、より小さなファイルをGitLabにインポートします。
1. 元のリポジトリの完全なクローンで、`git remote set-url origin <new-url> && git push --force --all`を使用してインポートを完了します。
1. インポートされたリポジトリの[ブランチ保護ルール](../repository/branches/protected.md)とその[デフォルト](../repository/branches/default.md)ブランチを更新し、一時的な`smaller-tmp-main`ブランチとローカルの一時データを削除します。

### 回避策オプション2 {#workaround-option-2}

{{< alert type="note" >}}

この回避策では、LFSオブジェクトは考慮されません。

{{< /alert >}}

すべての変更を一度にプッシュするのではなく、この回避策では、次のことを行います:

- プロジェクトのインポートをGitリポジトリのインポートから分離します
- リポジトリをGitLabに段階的にプッシュします

1. 移行するリポジトリのローカルクローンを作成します。後の手順で、このクローンをプロジェクトエクスポートの外部にプッシュします。
1. エクスポートをダウンロードし、`project.bundle`（Gitリポジトリが含まれています）を削除します:

   ```shell
   tar -czvf new_export.tar.gz --exclude='project.bundle' @old_export.tar.gz
   ```

1. Gitリポジトリなしでエクスポートをインポートします。リポジトリなしでインポートすることを確認するように求められます。
1. このbashスクリプトをファイルとして保存し、適切なoriginを追加した後で実行します。

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

## Sidekiqプロセスがプロジェクトをエクスポートできない {#sidekiq-process-fails-to-export-a-project}

Sidekiqプロセスがプロジェクトをエクスポートできない場合があります。たとえば、実行中に終了した場合などです。

GitLab.comのユーザーは、この問題を解決するために[サポート](https://about.gitlab.com/support/#contact-support)にお問い合わせください。

GitLab Self-Managed管理者は、Railsコンソールを使用してSidekiqプロセスを回避し、プロジェクトエクスポートを手動でトリガーできます:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

::Projects::ImportExport::ExportService.new(project, current_user, params).execute(nil)
```

これにより、ユーザーインターフェースからエクスポートを使用できるようになりますが、ユーザーにメールはトリガーされません。プロジェクトエクスポートを手動でトリガーし、メールを送信するには:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

ProjectExportWorker.new.perform(current_user.id, project.id)
```

## エクスポート手順を手動で実行する {#manually-execute-export-steps}

通常、[Webインターフェース](import_export.md#export-a-project-and-its-data)または[API](../../../api/project_import_export.md)を介してプロジェクトをエクスポートします。これらのメソッドを使用してエクスポートすると、トラブルシューティングに十分な情報が得られずに失敗する場合があります。これらの場合は、[Railsコンソールセッションを開き](../../../administration/operations/rails_console.md#starting-a-rails-console-session) 、[定義されているすべてのエクスポーター](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/projects/import_export/export_service.rb)をループします。各コマンドが返すエラーを確認できるように、ブロック全体を一度に貼り付けるのではなく、各行を個別に実行します。

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

プロジェクトが正常にアップロードされると、エクスポートされたプロジェクトは`.tar.gz`ファイル`/var/opt/gitlab/gitlab-rails/uploads/-/system/import_export_upload/export_file/`にあります。

## グループアクセストークンを使用すると、REST APIを使用したインポートが失敗する {#import-using-the-rest-api-fails-when-using-a-group-access-token}

[グループアクセストークン](../../group/settings/group_access_tokens.md)は、プロジェクトまたはグループインポート操作では機能しません。グループアクセストークンがインポートを開始すると、インポートはこのメッセージで失敗します:

```plaintext
Error adding importer user to Project members.
Validation failed: User project bots cannot be added to other groups / projects
```

[インポートREST API](../../../api/project_import_export.md)を使用するには、[パーソナルアクセストークン](../../profile/personal_access_tokens.md)などの通常のユーザーアカウント認証情報を渡します。

## エラー: `PG::QueryCanceled: ERROR: canceling statement due to statement timeout` {#error-pgquerycanceled-error-canceling-statement-due-to-statement-timeout}

一部の移行は、エラー`PG::QueryCanceled: ERROR: canceling statement due to statement timeout`でタイムアウトになる可能性があります。この問題を回避する方法の1つは、移行バッチサイズを縮小することです。これにより、移行がタイムアウトになる可能性が低くなりますが、移行が遅くなります。

バッチサイズを縮小するには、機能フラグを有効にする必要があります。詳細については、[issue 456948](https://gitlab.com/gitlab-org/gitlab/-/issues/456948)を参照してください。

## エラー: `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]` {#error-command-exited-with-error-code-15-and-unable-to-save-filtered-into-filtered}

ファイルエクスポートを使用してプロジェクトを移行すると、ログに次のエラーが表示される場合があります:

```plaintext
command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]
```

このエラーは、エクスポートまたはインポート中に、Sidekiqが`SIGTERM`を受信したときに発生します。多くの場合、`tar`コマンドの実行中に発生します。

GitLab.comやGitLab DedicatedなどのKubernetes環境では、メモリーまたはディスクの不足、コードのデプロイ、またはインスタンスのアップグレードにより、オペレーティングシステムが`SIGTERM`シグナルをトリガーします。根本原因を特定するには、管理者がKubernetesがインスタンスを終了した理由を調査する必要があります。

Kubernetes以外の環境では、`tar`コマンドの実行中にインスタンスが終了した場合、このエラーが発生する可能性があります。ただし、このエラーはディスクの不足が原因で発生するのではなく、メモリーの不足が最も可能性の高い原因です。

このエラーが発生した場合:

- ファイルをエクスポートすると、GitLabは、最大再試行回数に達するまでエクスポートを再試行し、その後、エクスポートを失敗としてマークします。GitLab.comの場合は、インスタンスの負荷が少ない週末にエクスポートを試してください。
- ファイルをインポートする場合は、自分でインポートを再試行する必要があります。GitLabは、インポートを自動的に再試行しません。

## パフォーマンスに関する問題のトラブルシューティング {#troubleshooting-performance-issues}

以下のインポート/エクスポートを使用して、現在のパフォーマンスの問題を読んでください。

### OOMエラー {#oom-errors}

メモリー不足（OOM）エラーは、通常、[Sidekiq Memory Killer](../../../administration/sidekiq/sidekiq_memory_killer.md)によって発生します:

```shell
SIDEKIQ_MEMORY_KILLER_MAX_RSS = 2000000
SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS = 3000000
SIDEKIQ_MEMORY_KILLER_GRACE_TIME = 900
```

インポートステータス`started`、および次のSidekiqログは、メモリーの問題を示しています:

```shell
WARN: Work still in progress <struct with JID>
```

### タイムアウト {#timeouts}

タイムアウトエラーは、プロセスを失敗としてマークする`Gitlab::Import::StuckProjectImportJobsWorker`が原因で発生します:

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

データベースからモデルを読み込む/ダンプする[低速JSON](https://gitlab.com/gitlab-org/gitlab/-/issues/25251):

- [ワーカーを分割する](https://gitlab.com/gitlab-org/gitlab/-/issues/25252)\|
- バッチエクスポート
- SQLを最適化する
- `ActiveRecord`コールバックから離れる（困難）

メモリー使用量が多い（一部の[分析](https://gitlab.com/gitlab-org/gitlab/-/issues/18857)も参照）:

- メモリー使用量を削減するDBコミットスイートスポット
- [Netflix Fast JSON API](https://github.com/Netflix/fast_jsonapi)が役立つ場合があります
- ディスクとSQLへのバッチ読み取り/書き込み

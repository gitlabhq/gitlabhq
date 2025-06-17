---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Troubleshooting help for merge requests.
title: マージリクエストのトラブルシューティング
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストの作業中に、次のイシューが発生する可能性があります。

## マージリクエストがパイプラインの状態を取得できない

これは、Sidekiqが変更を十分に速く取得しない場合に発生する可能性があります。

### Sidekiq

SidekiqがCIの状態変更を十分に速く処理しませんでした。数秒待つと、状態が自動的に更新されます。

### パイプラインの状態を取得できません

次の状況が発生した場合、マージリクエストのパイプラインの状態を取得できません:

1. マージリクエストが作成された
1. マージリクエストがクローズした
1. プロジェクトに変更が加えられた
1. マージリクエストが再開した

パイプラインの状態を適切に取得できるようにするには、マージリクエストを閉じて再度開いてください。

## Railsコンソールからマージリクエストをリベースする

{{< details >}}

- プラン:Free、Premium、Ultimate

{{< /details >}}

`/rebase` [クイック アクション](../quick_actions.md#issues-merge-requests-and-epics)に加えて、[Railsコンソール](../../../administration/operations/rails_console.md)へのアクセス権を持つユーザーは、Railsコンソールからマージリクエストをリベースできます。`<username>`、`<namespace/project>`、`<iid>`を適切な値に置き換えます:

{{< alert type="warning" >}}

データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::RebaseService.new(project: m.target_project, current_user: u).execute(m)
```

## 正しくないマージリクエストの状態を修正する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

変更がマージされた後もマージリクエストが**開いた**ままの場合、[Railsコンソール](../../../administration/operations/rails_console.md)へのアクセス権を持つユーザーは、マージリクエストの状態を修正できます。`<username>`、`<namespace/project>`、`<iid>`を適切な値に置き換えます:

{{< alert type="warning" >}}

データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::PostMergeService.new(project: p, current_user: u).execute(m)
```

マージされていない変更を含むマージリクエストに対してこのコマンドを実行すると、マージリクエストに正しくないメッセージが表示されます:`merged into <branch-name>`。

## Railsコンソールからマージリクエストを閉じる

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

UIまたはAPIでマージリクエストを閉じることができない場合は、[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)で閉じてみてください:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にTest環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
MergeRequests::CloseService.new(project: p, current_user: u).execute(m)
```

## Railsコンソールからマージリクエストを削除する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

UIまたはAPIでマージリクエストを削除できない場合は、[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)で削除してみてください:

{{< alert type="warning" >}}

データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

{{< /alert >}}

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<namespace/project>')
m = p.merge_requests.find_by(iid: <iid>)
Issuable::DestroyService.new(container: m.project, current_user: u).execute(m)
```

## マージリクエストの事前受信フックが失敗しました

マージリクエストがタイムアウトした場合、Puma作業者のタイムアウトの問題を示すメッセージが表示されることがあります:

- GitLab UIの場合:

  ```plaintext
  Something went wrong during merge pre-receive hook.
  500 Internal Server Error. Try again.
  ```

- `gitlab-rails/api_json.log`logファイルの場合:

  ```plaintext
  Rack::Timeout::RequestTimeoutException
  Request ran for longer than 60000ms
  ```

このエラーは、マージリクエストが次の条件に該当する場合に発生する可能性があります:

- 多くの差分が含まれている。
- ターゲットブランチより多くのコミットが遅れている。
- ロックされているGit LFSファイルを参照している。

GitLab Self-Managedのユーザーは、管理者にサーバーlogのレビューをリクエストして、エラーの原因を特定できます。GitLab SaaSのユーザーは、[サポートにお問い合わせ](https://about.gitlab.com/support/#contact-support)ください。

## キャッシュされたマージリクエスト数

グループでは、サイドバーにオープンマージリクエストの合計数が表示されます。この値は、1000を超える場合にキャッシュされます。キャッシュされた値は、数千（または数百万）に丸められ、24時間ごとに更新されます。

## `head` refを使用して、ローカルでマージリクエストをチェックアウトする

{{< history >}}

- GitLab 16.4で、マージリクエストがクローズまたはマージされてから14日後に`head` refsの削除[がGitLab Self-ManagedおよびGitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130098)。
- GitLab 16.6では、マージリクエストがクローズまたはマージされてから14日後に`head` refsの削除[が一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/336070)されます。機能フラグ`merge_request_refs_cleanup`が削除されました。

{{< /history >}}

マージリクエストには、リポジトリからのすべての履歴に加えて、マージリクエストに関連付けられたブランチに追加された追加のコミットが含まれています。ローカルでマージリクエストをチェックアウトするいくつかの方法を次に示します。

ソースプロジェクトがターゲットプロジェクトのフォーク（プライベートフォークでも）であっても、ローカルでマージリクエストをチェックアウトできます。

これは、各マージリクエストで使用可能なマージリクエスト`head` ref（`refs/merge-requests/:iid/head`）に依存します。これにより、ブランチの代わりにIDを使用してマージリクエストをチェックアウトできます。

GitLab 16.6以降では、マージリクエスト`head` refは、マージリクエストがクローズまたはマージされてから14日後に削除されます。マージリクエストは、マージリクエスト`head` refからローカルチェックアウトできなくなります。マージリクエストは再度開くことができます。マージリクエストのブランチが存在する場合、影響を受けないため、ブランチをチェックアウトできます。

### `glab`を使用してローカルでチェックアウトする

```plaintext
glab mr checkout <merge_request_iid>
```

[GitLabターミナルクライアント](../../../editor_extensions/gitlab_cli/_index.md)の詳細。

### Gitエイリアスを追加してローカルでチェックアウトする

次のエイリアスを`~/.gitconfig`に追加します:

```plaintext
[alias]
    mr = !sh -c 'git fetch $1 merge-requests/$2/head:mr-$1-$2 && git checkout mr-$1-$2' -
```

これで、任意のリポジトリおよび任意のremoteから特定のマージリクエストをチェックアウトできます。たとえば、GitLabに示されているID 5のマージリクエストを`origin`remoteからチェックアウトするには、次のようにします:

```shell
git mr origin 5
```

これにより、マージリクエストがローカルの`mr-origin-5`ブランチにフェッチされ、チェックアウトされます。

### 特定のリポジトリの`.git/config`を変更してローカルでチェックアウトする

`.git/config`ファイルでGitLab remoteのセクションを見つけます。次のようになります:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

次のコマンドでファイルを開くことができます:

```shell
git config -e
```

ここで、次の行を上記のセクションに追加します:

```plaintext
fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

最終的には、次のようになります:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
  fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

次に、すべてのマージリクエストをフェッチできます:

```shell
git fetch origin

...
From https://gitlab.com/gitlab-org/gitlab-foss.git
 * [new ref]         refs/merge-requests/1/head -> origin/merge-requests/1
 * [new ref]         refs/merge-requests/2/head -> origin/merge-requests/2
...
```

特定のマージリクエストをチェックアウトするには:

```shell
git checkout origin/merge-requests/1
```

上記はすべて、[`git-mr`](https://gitlab.com/glensc/git-mr)スクリプトで実行できます。

## ブランチが存在する場合のエラー: 「ソースブランチ`<branch_name>`が存在しません。」

このエラーは、GitLabキャッシュがGitリポジトリの実際の状態を反映していない場合に発生する可能性があります。これは、Gitデータフォルダーが`noexec`フラグでマウントされている場合に発生する可能性があります。

前提要件:

- 管理者である必要があります。

キャッシュの更新を強制するには:

1. このコマンドでGitLab Railsコンソールを開きます:

   ```shell
   sudo gitlab-rails console
   ```

1. Railsコンソールで、このスクリプトを実行します:

   ```ruby
   # Get the project
   project = Project.find_by_full_path('affected/project/path')

   # Check if the affected branch exists in cache (it may return `false`)
   project.repository.branch_names.include?('affected_branch_name')

   # Expire the branches cache
   project.repository.expire_branches_cache

   # Check again if the affected branch exists in cache (this time it should return `true`)
   project.repository.branch_names.include?('affected_branch_name')
   ```

1. マージリクエストをリロードします。

---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: リポジトリチェック
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

リポジトリにコミットされたすべてのデータの整合性を確認するには、[`git fsck`](https://git-scm.com/docs/git-fsck)を使用できます。GitLab管理者は、次のことができます:

- プロジェクトのこのチェックを[手動でトリガーする](#check-a-projects-repository-using-gitlab-ui)。
- すべてのプロジェクトに対して自動的に実行されるように、[このチェックをスケジュールします](#enable-repository-checks-for-all-projects)。
- [コマンドラインからこのチェックを実行します](#run-a-check-using-the-command-line)。
- Gitリポジトリをチェックするための[Rakeタスク](raketasks/check.md#repository-integrity)を実行します。これは、すべてのリポジトリに対して`git fsck`を実行し、リポジトリのチェックサムを生成し、異なるサーバー上のリポジトリを比較する方法として使用できます。

コマンドラインで手動で実行されないチェックは、Gitalyノードを介して実行されます。Gitalyリポジトリの一貫性チェック、一部の無効なチェック、および一貫性チェックの構成方法については、[リポジトリの一貫性チェック](gitaly/consistency_checks.md)を参照してください。

## GitLab UIを使用したプロジェクトのリポジトリのチェック {#check-a-projects-repository-using-gitlab-ui}

GitLab UIを使用してプロジェクトのリポジトリをチェックするには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **プロジェクト**を選択します。
1. チェックするプロジェクトを選択します。
1. **リポジトリチェック**セクションで、**リポジトリチェックをトリガー**を選択します。

チェックは非同期で実行されるため、プロジェクトページの**管理者**エリアにチェック結果が表示されるまでに数分かかる場合があります。チェックが失敗した場合は、[対処方法](#what-to-do-if-a-check-failed)を参照してください。

## すべてのプロジェクトのリポジトリチェックを有効にする {#enable-repository-checks-for-all-projects}

リポジトリを手動でチェックする代わりに、定期的にチェックを実行するようにGitLabを構成できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリの保守**を展開します。
1. **リポジトリチェックを有効にする**を有効にします。

有効にすると、GitLabはすべてのプロジェクトリポジトリとWikiリポジトリでリポジトリチェックを定期的に実行して、発生する可能性のあるデータ破損を検出します。プロジェクトがチェックされるのは月に1回までで、新しいプロジェクトは少なくとも24時間はチェックされません。

GitLab Self-Managed管理者は、リポジトリチェックの頻度を設定できます。頻度を編集するには:

- Linuxパッケージインストールの場合は、`gitlab_rails['repository_check_worker_cron']`の`/etc/gitlab/gitlab.rb`を編集してください。
- ソースベースのインストールの場合、`/home/git/gitlab/config/gitlab.yml`の`[gitlab.cron_jobs.repository_check_worker]`を編集します。

リポジトリチェックに失敗したプロジェクトがある場合、すべてのGitLab管理者は、状況に関するメール通知を受信します。デフォルトでは、この通知は、日曜日の開始時に週に1回深夜に送信されます。

チェックの失敗が確認されているリポジトリは、`/admin/projects?last_repository_check_failed=true`にあります。

## コマンドラインを使用してチェックを実行する {#run-a-check-using-the-command-line}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

[Gitalyサーバー](gitaly/_index.md)上のリポジトリで、コマンドラインを使用して[`git fsck`](https://git-scm.com/docs/git-fsck)を実行できます。リポジトリの場所を特定するには:

1. リポジトリのストレージの場所に移動します:
   - Linuxパッケージインストールの場合、リポジトリはデフォルトで`/var/opt/gitlab/git-data/repositories`ディレクトリに保存されます。
   - GitLab Helmチャートインストールの場合、リポジトリはデフォルトでGitalyポッド内の`/home/git/repositories`ディレクトリに保存されます。
1. チェックする必要があるリポジトリを含む[サブディレクトリを特定します](repository_storage_paths.md#from-project-name-to-hashed-path)。
1. チェックを実行します。次に例を示します: 

   ```shell
   sudo -u git /opt/gitlab/embedded/bin/git \
      -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck --no-dangling
   ```

   エラー`fatal: detected dubious ownership in repository`は、間違ったアカウントを使用してコマンドを実行していることを意味します。たとえば`root`などです。

## チェックが失敗した場合の対処方法 {#what-to-do-if-a-check-failed}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

リポジトリチェックが失敗した場合は、ディスク上の[`repocheck.log`ファイル](logs/_index.md#repochecklog)のエラーを次の場所で特定します:

- Linuxパッケージインストールの場合: `/var/log/gitlab/gitlab-rails`。
- 自己コンパイルによるインストールの場合: `/home/git/gitlab/log`。
- GitLab HelmチャートインストールのSidekiqポッドの`/var/log/gitlab`。

定期的なリポジトリチェックが誤ったアラームを引き起こす場合は、すべてのリポジトリチェック状態をクリアできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリの保守**を展開します。
1. **すべてのリポジトリのチェックをクリアする**を選択します。

## トラブルシューティング {#troubleshooting}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

リポジトリチェックの操作中に、次の問題が発生する可能性があります。

### エラー: `failed to parse commit <commit SHA> from object database for commit-graph` {#error-failed-to-parse-commit-commit-sha-from-object-database-for-commit-graph}

リポジトリチェックログに`failed to parse commit <commit SHA> from object database for commit-graph`エラーが表示されることがあります。このエラーは、`commit-graph`キャッシュが古くなっている場合に発生します。`commit-graph`キャッシュは補助キャッシュであり、通常のGit操作には必要ありません。

メッセージは安全に無視できますが、詳細については、[エラー：commit-graphのオブジェクトデータベースから読み取れませんでした](https://gitlab.com/gitlab-org/gitaly/-/issues/2359)を参照してください。

### Danglingコミット、タグ、またはバイナリラージオブジェクトメッセージ {#dangling-commit-tag-or-blob-messages}

リポジトリチェックの出力には、プルーニングする必要のあるタグ、バイナリラージオブジェクト、コミットが含まれていることがよくあります:

```plaintext
dangling tag 5c6886c774b713a43158aae35c4effdb03a3ceca
dangling blob 3e268c23fcd736db92e89b31d9f267dd4a50ac4b
dangling commit 919ff61d8d78c2e3ea9a32701dff70ecbefdd1d7
```

これはGitリポジトリでは一般的です。これらは、強制プッシュのような操作によって生成されます。これは、ブランチへの操作によって、refsまたは別のコミットによって参照されなくなったリポジトリにコミットが生成されるためです。

リポジトリチェックが失敗した場合、出力にこれらの警告が含まれる可能性があります。

これらのメッセージを無視して、他の出力からリポジトリチェックの失敗の根本原因を特定します。

[GitLab 15.8以降](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5230)では、チェック出力にこれらのメッセージは含まれなくなりました。コマンドラインから実行する場合、`--no-dangling`オプションを使用して、それらを抑制します。

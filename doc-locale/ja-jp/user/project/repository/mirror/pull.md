---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プルミラーを作成して、リモートリポジトリからGitLabに変更をプルし、コピーを最新の状態に保ちます。
title: リモートリポジトリからのプル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

GitLabでホストされていなくても、GitLabインターフェースを使用して、リポジトリのコンテンツとアクティビティーを閲覧できます。アップストリームリポジトリからブランチ、タグ、コミットをコピーするには、プル[ミラー](_index.md)を作成します。

[プッシュミラー](push.md)とは異なり、プルミラーはスケジュールに基づいてアップストリーム（リモート）リポジトリから変更を取得します。ミラーがアップストリームリポジトリから分岐するのを防ぐために、ダウンストリームミラーにコミットを直接プッシュしないでください。代わりに、コミットをアップストリームリポジトリにプッシュします。リモートリポジトリの変更は、GitLabリポジトリにプルされます:

- 前回のプルから30分後に自動的に行われます。これは無効にできません。
- 管理者が[ミラーを強制的に更新する](_index.md#force-an-update)場合。
- [APIコールが更新をトリガーする](#trigger-an-update-by-using-the-api)場合。

UIとAPIの更新は、デフォルトの5分間の[プルミラーリング間隔](../../../../administration/instance_limits.md#pull-mirroring-interval)の対象となります。この間隔は、GitLab Self-Managedインスタンスで設定できます。

デフォルトでは、ダウンストリームのプルミラー上のブランチまたはタグがローカルリポジトリから分岐した場合、GitLabはブランチの更新を停止します。これにより、データ損失が防止されます。アップストリームリポジトリで削除されたブランチとタグは、ダウンストリームリポジトリには反映されません。

{{< alert type="note" >}}

ダウンストリームのプルミラーリポジトリから削除されたが、アップストリームリポジトリにはまだ存在する項目は、次回のプル時に復元されます。例: ミラーリングされたリポジトリのみで削除されたブランチは、次回のプル後に再び表示されます。

{{< /alert >}}

## プルミラーリングの仕組み {#how-pull-mirroring-works}

GitLabリポジトリをプルミラーとして設定した後:

1. GitLabは、リポジトリをキューに追加します。
1. 1分に1回、Sidekiq cronジョブは、以下に基づいてリポジトリミラーを更新するようにスケジュールします:
   - Sidekiqの設定によって決定される利用可能な容量。GitLab.comについては、[GitLab.com Sidekiqの設定](../../../gitlab_com/_index.md#sidekiq)をお読みください。
   - キュー内にあり、更新が必要なミラーの数。期限がいつになるかは、リポジトリミラーが最後に更新された時期と、更新が再試行された回数によって異なります。
1. Sidekiqが更新を処理できるようになると、ミラーが更新されます。更新プロセスが次のようになる場合:
   - 成功: 少なくとも30分待ってから、更新が再びキューに入れられます。
   - 失敗: 更新は後で再び試行されます。14回失敗すると、ミラーは[ハード障害](#fix-hard-failures-when-mirroring)としてマークされ、更新のためにキューに入れられなくなります。ブランチがアップストリームの対応するものから分岐すると、障害が発生する可能性があります。ブランチの分岐を防ぐには、ミラーの作成時に[分岐したブランチを上書き](#overwrite-diverged-branches)するように設定します。

## プルミラーリングを設定する {#configure-pull-mirroring}

前提要件:

- リモートリポジトリがGitHub上にあり、[2要素認証（2FA）が設定されている](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa)場合は、`repo`スコープで[GitHubのパーソナルアクセストークン](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)を作成します。2FAが有効になっている場合、このパーソナルアクセストークンはGitHubパスワードとして機能します。
- [GitLabサイレントモード](../../../../administration/silent_mode/_index.md)が有効になっていません。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. **GitリポジトリのURL**を入力します。

   {{< alert type="note" >}}

   `gitlab`リポジトリをミラーリングするには、`gitlab.com:gitlab-org/gitlab.git`または`https://gitlab.com/gitlab-org/gitlab.git`を使用します。

   {{< /alert >}}

1. **ミラーの方向**で、**プル**を選択します。
1. **認証方法**で、認証方法を選択します。詳細については、[ミラーの認証方法](_index.md#authentication-methods-for-mirrors)を参照してください。
1. 必要なオプションを選択します:
   - [**分岐したブランチを上書き**](#overwrite-diverged-branches)
   - [**ミラーの更新のためにパイプラインをトリガー**](#trigger-pipelines-for-mirror-updates)
   - **Only mirror protected branches**（保護ブランチのみをミラーリング）
1. 設定を保存するには、**ミラーリポジトリ**を選択します。

### 分岐したブランチを上書き {#overwrite-diverged-branches}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

リモートから分岐している場合でも、リモートバージョンでローカルブランチを常に更新するには、ミラーの作成時に**分岐したブランチを上書き**を選択します。

{{< alert type="warning" >}}

ミラーリングされたブランチの場合、このオプションを有効にすると、ローカルの変更が失われます。

{{< /alert >}}

### ミラーの更新のためにパイプラインをトリガー {#trigger-pipelines-for-mirror-updates}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

リモートリポジトリがブランチまたはタグを更新したときに、パイプラインを自動的にトリガーするようにミラーを設定できます。この機能を有効にする前に:

- CI Runnerがリモートリポジトリアクティビティーからの追加の負荷を処理できることを確認します。
- セキュリティへの影響を考慮してください。パイプラインはプルミラーリングからの認証情報を使用し、レビューされていないコードを実行します。

  この機能は、自分のプロジェクトまたは信頼できるメンテナーのいるプロジェクトに対してのみ有効にしてください。

## APIを使用して更新をトリガーする {#trigger-an-update-by-using-the-api}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

プルミラーリングは、ポーリングを使用してアップストリームに追加された新しいブランチとコミットを検出します。これは多くの場合、数分後です。[APIコール](../../../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)を使用してGitLabに通知できますが、[プルミラーリング制限の最小間隔](_index.md#force-an-update)は引き続き適用されます。

詳細については、[プロジェクトのプルミラーリングプロセスの開始](../../../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)をお読みください。

## ミラーリング時にハード障害を修正する {#fix-hard-failures-when-mirroring}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

14回連続して再試行が失敗すると、ミラーリングプロセスはハード障害としてマークされ、ミラーリングの試行は停止します。この障害は、次のいずれかで確認できます:

- プロジェクトのメインダッシュボード。
- プルミラー設定ページ。

プロジェクトのミラーリングを再開するには、[更新を強制](_index.md#force-an-update)します。

ネットワークやサーバーの長期的な停止後など、複数のプロジェクトがこの問題の影響を受けている場合は、[Railsコンソール](../../../../administration/operations/rails_console.md)を使用して、このコマンドで影響を受けるすべてのプロジェクトを特定して更新できます:

```ruby
Project.find_each do |p|
  if p.import_state && p.import_state.retry_count >= 14
    puts "Resetting mirroring operation for #{p.full_path}"
    p.import_state.reset_retry_count
    p.import_state.set_next_execution_to_now(prioritized: true)
    p.import_state.save!
  end
end
```

## 関連トピック {#related-topics}

- リポジトリのミラーリングに関する[トラブルシューティング](troubleshooting.md)。
- [プルミラーリング間隔](../../../../administration/instance_limits.md#pull-mirroring-interval)
- [プロジェクトプルミラーリングAPI](../../../../api/project_pull_mirroring.md#configure-pull-mirroring-for-a-project)

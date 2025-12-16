---
stage: Data Access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiqジョブ移行Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

この操作は非常にまれであるはずです。ほとんどのGitLabインスタンスでは推奨されません。

{{< /alert >}}

Sidekiqルーティングルールを使用すると、管理者は、特定のバックグラウンドジョブを通常のキューから代替キューに再ルーティングできます。デフォルトでは、GitLabはバックグラウンドジョブタイプごとに1つのキューを使用します。GitLabには400を超えるバックグラウンドジョブタイプがあるため、対応して400を超えるキューがあります。

ほとんどの管理者は、この設定を変更する必要はありません。特に大規模なバックグラウンドジョブ処理ワークロードの場合、GitLabがリッスンするキューの数により、Redisのパフォーマンスが低下する可能性があります。

Sidekiqルーティングルールが変更された場合、管理者は、ジョブを完全に失うことを避けるために、移行に注意する必要があります。基本的な移行手順は次のとおりです:

1. 古いキューと新しいキューの両方をリッスンします。
1. ルーティングルールを更新します。
1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. [キューおよび将来のジョブを移行するためのRakeタスクを実行します](#migrate-queued-and-future-jobs)。
1. 古いキューへのリスンを停止します。

## キューおよび将来のジョブを移行する {#migrate-queued-and-future-jobs}

ステップ4では、Redisにすでに保存されているが、将来実行されるジョブの一部のSidekiqジョブデータを書き換えます。将来実行される予定のジョブの2つのセット: スケジュールされたジョブと再試行されるジョブ。各セットを移行するために、個別のRakeタスクを提供します:

- 再試行されるジョブの`gitlab:sidekiq:migrate_jobs:retry`。
- スケジュールされたジョブの`gitlab:sidekiq:migrate_jobs:schedule`。

まだ実行されていないキューに入れられたジョブも、Rakeタスクで移行できます（[GitLab 15.6で利用可能](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348)以降）:

- 非同期で実行されるキューに入れられたジョブの`gitlab:sidekiq:migrate_jobs:queued`。

ほとんどの場合、3つすべてを同時に実行することが正しい選択です。3つの個別のタスクにより、必要に応じて、よりきめ細かい制御が可能になります。3つすべてを一度に実行するには（[GitLab 15.6で利用可能](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348)以降）:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued

# source installations
bundle exec rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued RAILS_ENV=production
```

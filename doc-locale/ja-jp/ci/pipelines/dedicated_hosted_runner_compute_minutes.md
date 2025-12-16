---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab DedicatedのGitLabホストRunnerのコンピューティング時間、使用状況追跡、クォータ管理。
title: GitLab DedicatedのGitLabホストRunnerのコンピューティング使用量
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedインスタンスは、GitLab Self-ManagedインスタンスRunnerとGitLabホストインスタンスRunnerの両方を持つことができます。

管理者として、GitLab Dedicatedインスタンスでは、いずれかのタイプのインスタンスRunnerでジョブを実行しているネームスペースで使用されているコンピューティング時間を追跡し、監視できます。

GitLabでホストされるRunnerの場合:

- 見積もり使用量は、[GitLabホストRunnerの使用状況ダッシュボード](#view-compute-usage)で確認できます。
- クォータの適用と通知は利用できません。

GitLab Dedicatedインスタンスに登録されているGitLab Self-ManagedインスタンスRunnerについては、[インスタンスRunnerの使用状況](instance_runner_compute_minutes.md#view-usage)を参照してください。

## コンピューティング使用量の表示 {#view-compute-usage}

{{< history >}}

- GitLabホストRunnerのコンピューティング使用量データは、GitLab 18.0で[導入](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524)されました。

{{< /history >}}

前提要件: 

- GitLab Dedicatedインスタンスの管理者である必要があります。

コンピューティング使用量を確認できます:

- 当月のコンピューティング総使用量。
- 月別（年およびRunnerでフィルタリング可能）。
- ネームスペース別（月およびRunnerでフィルタリング可能）。

GitLabインスタンス全体のすべてのネームスペースについて、GitLabホストRunnerのコンピューティング使用量を表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **使用量クォータ**を選択します。

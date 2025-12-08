---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner
description: 設定とジョブの実行。
---

Runnerは、パイプライン内でGitLab CI/CDジョブを実行するために[GitLab Runner](https://docs.gitlab.com/runner/)アプリケーションを実行するエージェントです。`.gitlab-ci.yml`ファイルで定義されたビルド、テスト、デプロイ、その他のCI/CDタスクを実行する役割を担います。

## Runnerの実行フロー {#runner-execution-flow}

Runnerの基本的なワークフローを以下に示します:

1. Runnerは、まずGitLabに[登録](https://docs.gitlab.com/runner/register/)する必要があります。これにより、RunnerとGitLab間の永続的な接続が確立されます。
1. パイプラインがトリガーされると、GitLabは登録済みのRunnerに対してジョブを利用可能にします。
1. 条件に一致する各Runnerがジョブを1つずつ取得して実行します。
1. 結果はリアルタイムでGitLabに報告されます。

詳細については、[Runnerの実行フロー](https://docs.gitlab.com/runner/#runner-execution-flow)を参照してください。

## Runnerのジョブスケジューリングと実行 {#runner-job-scheduling-and-execution}

CI/CDジョブを実行する必要がある場合、GitLabは`.gitlab-ci.yml`ファイルで定義されたタスクに基づいてジョブを作成します。ジョブはキューに配置されます。GitLabは、次の条件に一致する利用可能なRunnerを確認します:

- Runnerタグ
- Runnerタイプ（共有またはグループなど）
- Runnerのステータスと処理能力
- 必要な機能

割り当てられたRunnerがジョブの詳細を受け取ります。Runnerは環境を準備し、`.gitlab-ci.yml`ファイルで指定されたジョブのコマンドを実行します。

## Runnerのカテゴリ {#runner-categories}

CI/CDジョブを実行するRunnerを決定する際には、以下から選択できます:

- GitLab.comまたはGitLab Dedicatedユーザー向けの[GitLabでホストされるRunner](hosted_runners/_index.md)。
- すべてのGitLabインストール向けの[Self-Managed Runner](https://docs.gitlab.com/runner/)。

Runnerは、グループRunner、プロジェクトRunner、インスタンスRunnerのいずれかとして利用できます。GitLabでホストされるRunnerはインスタンスRunnerです。

### GitLabでホストされるRunner {#gitlab-hosted-runners}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

GitLabでホストされるRunnerの特長:

- GitLabが完全に管理している。
- セットアップなしですぐに利用できる。
- ジョブごとに新しいVMで実行される。
- Linux、Windows、macOSのオプションを含む。
- 需要に応じて自動的にスケールする。

GitLabでホストされるRunnerを選択するのは、以下の場合です:

- メンテナンス不要のCI/CDが必要な場合。
- インフラストラクチャの管理なしで迅速にセットアップする必要がある場合。
- ジョブごとに独立した実行環境が必要な場合。
- 標準的なビルド環境で作業している場合。
- GitLab.comまたはGitLab Dedicatedを使用している場合。

### Self-Managed Runner {#self-managed-runners}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Self-Managed Runnerの特長:

- ユーザー自身がインストールおよび管理する。
- 独自のインフラストラクチャ上で実行する。
- ニーズに合わせてカスタマイズできる。
- さまざまなexecutor（Shell、Docker、Kubernetesなど）をサポートする。
- 共有することも、特定のプロジェクトやグループ専用にもできる。

Self-Managed Runnerを選択するのは、以下の場合です:

- カスタム設定が必要な場合。
- プライベートネットワークでジョブを実行する場合。
- 特定のセキュリティ制御が必要な場合。
- プロジェクトまたはグループRunnerが必要な場合。
- Runnerを再利用して処理速度を最適化する必要がある場合。
- 独自のインフラストラクチャを管理する場合。

## 関連トピック {#related-topics}

- [GitLab Runnerをインストールする](https://docs.gitlab.com/runner/install/)
- [GitLab Runnerを設定する](https://docs.gitlab.com/runner/configuration/)
- [GitLab Runnerを管理する](https://docs.gitlab.com/runner/)
- [GitLab Dedicated用のホストされるRunner](../../administration/dedicated/hosted_runners.md)

---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner
---

Runnerは、パイプライン内でGitLab CI/CDジョブを実行するために[GitLab Runner](https://docs.gitlab.com/runner/)アプリケーションを実行するエージェントです。これらは、`.gitlab-ci.yml`ファイルで定義されたビルド、テスト、デプロイ、その他のCI/CDタスクを実行する役割を担います。

## Runnerの実行フロー

Runnerの基本的なワークフローを以下に示します。

1. Runnerは、まずGitLabに[登録](https://docs.gitlab.com/runner/register/)する必要があります。これにより、RunnerとGitLab間の永続的な接続が確立されます。
1. パイプラインがトリガーされると、GitLabは登録済みのRunnerに対してジョブを利用可能にします。
1. 一致する各Runnerがジョブを1つずつ取得して実行します。
1. 結果はリアルタイムでGitLabに報告されます。

詳細については、[Runnerの実行フロー](https://docs.gitlab.com/runner/#runner-execution-flow)を参照してください。

## Runnerのジョブスケジューリングと実行

CI/CDジョブを実行する必要がある場合、GitLabは`.gitlab-ci.yml`ファイルで定義されたタスクに基づいてジョブを作成します。ジョブはキューに配置されます。GitLabは、一致する利用可能なRunnerを確認します。

- Runnerタグ
- Runnerタイプ（共有またはグループなど）
- Runnerのステータスと容量
- 必要な機能

割り当てられたRunnerはジョブの詳細を受信します。Runnerは環境を準備し、`.gitlab-ci.yml`ファイルで指定されたジョブのコマンドを実行します。

## Runnerのカテゴリ

CI/CDジョブを実行するRunnerを決定する際に、以下を選択できます。

- GitLab.comまたはGitLab Dedicatedユーザー向けの[GitLabでホストされるRunner](hosted_runners/_index.md)。
- すべてのGitLabインストール向けの[Self-Managed Runner](https://docs.gitlab.com/runner/)。

Runnerは、グループ、プロジェクト、またはインスタンスのRunnerにすることができます。GitLabでホストされるRunnerはインスタンスRunnerです。

### GitLabでホストされるRunner

{{< details >}}

- プラン: Free, Premium, Ultimate
- 提供: GitLab.com、GitLab Dedicated

{{< /details >}}

GitLabでホストされるRunnerの特長:

- GitLabがすべて管理します。
- セットアップなしですぐに利用できます。
- 各ジョブに対して新しいVMで実行されます。
- Linux、Windows、macOSのオプションを含みます。
- 需要に基づいて自動的にスケーリングします。

以下のような場合にGitLabでホストされるRunnerを選択します。

- メンテナンス不要のCI/CDが必要な場合。
- インフラストラクチャ管理なしで迅速にセットアップする必要がある場合。
- ジョブ実行間で分離が必要な場合。
- 標準的なビルド環境を使用している場合。
- GitLab.comまたはGitLab Dedicatedを使用している場合。

### Self-Managed Runner

{{< details >}}

- プラン: Free, Premium, Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Self-Managed Runnerの特長:

- お客様がインストールおよび管理できます。
- 独自のインフラストラクチャ上で実行できます。
- ニーズに合わせてカスタマイズできます。
- さまざまなexecutor（Shell、Docker、Kubernetesなど）をサポートします。
- 共有することも、特定のプロジェクトまたはグループ用に設定することもできます。

以下のような場合にSelf-Managed Runnerを選択します。

- カスタム設定が必要な場合。
- プライベートネットワークでジョブを実行する場合。
- 特定のセキュリティ制御が必要な場合。
- プロジェクトまたはグループRunnerが必要な場合。
- Runnerを再利用してスピードを最適化する必要がある場合。
- 独自のインフラストラクチャを管理する場合。

## 関連トピック

- [GitLab Runnerをインストールする](https://docs.gitlab.com/runner/install/)
- [GitLab Runnerを設定する](https://docs.gitlab.com/runner/configuration/)
- [GitLab Runnerを管理する](https://docs.gitlab.com/runner/)
- [GitLab Dedicated用のホストされるRunner](../../administration/dedicated/hosted_runners.md)

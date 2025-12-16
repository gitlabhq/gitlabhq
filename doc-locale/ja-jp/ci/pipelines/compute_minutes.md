---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 計算、割り当て、購入情報
title: コンピューティング時間
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で「CI/CD時間」から「コンピューティングクォータ」または「コンピューティング時間」に[名前が変更](https://gitlab.com/groups/gitlab-com/-/epics/2150)されました。

{{< /history >}}

CI/CDジョブを実行するプロジェクトによるインスタンスRunnerの使用量は、コンピューティング時間で測定されます。

一部のインストールタイプでは、[ネームスペース](../../user/namespace/_index.md)に[コンピューティングクォータ](instance_runner_compute_minutes.md#compute-quota-enforcement)があり、それにより使用できるコンピューティング時間が制限されます。

コンピューティングクォータは、[管理者が管理するインスタンスRunner](instance_runner_compute_minutes.md)のすべてに適用できます。

- GitLab.comまたはGitLab Self-Managed上のすべてのインスタンスRunner
- GitLab Dedicated上のすべてのセルフホストインスタンスRunner

コンピューティングクォータはデフォルトで無効になっていますが、トップレベルグループおよびユーザーネームスペースに対して有効にすることができます。GitLab.comでは、Freeネームスペースでの使用量を制限するために、そのクォータがデフォルトで有効になっています。有料サブスクリプションを購入すると、上限が上がります。

GitLabでホスティングされているGitLab Dedicated上のインスタンスRunnerに、インスタンスRunnerのコンピューティングクォータを適用することはできません。

## インスタンスRunner {#instance-runners}

GitLab.comとGitLab Self-Managed上のインスタンスRunner、およびGitLab Dedicated上のセルフホストインスタンスRunnerの場合:

- [インスタンスRunnerの使用状況ダッシュボード](instance_runner_compute_minutes.md#view-usage)で使用状況を確認できます。
- クォータが有効になっている場合:
  - クォータの上限に近づくと、通知が届きます。
  - クォータを超えると、強制措置が適用されます。

GitLab.comの場合:

- 基本月間コンピューティングクォータは、サブスクリプションプランによって決まります。
- 必要に応じて、[追加のコンピューティング時間](../../subscriptions/gitlab_com/compute_minutes.md)を購入できます。

## コンピューティング時間の使用状況 {#compute-minute-usage}

### コンピューティング使用量の計算 {#compute-usage-calculation}

各ジョブのコンピューティング時間の使用量は、次の式で計算されます。

```plaintext
Job duration / 60 * Cost factor
```

- **ジョブの実行時間**: ジョブの実行時間（秒単位）。`created`または`pending`ステータスで費やされた時間は含まれません。
- **コスト係数**: [Runnerタイプ](#cost-factors)と[プロジェクトタイプ](#cost-factors)に基づく数値。

この値がコンピューティング時間に換算され、ジョブのトップレベルネームスペースの消費ユニット数に加算されます。

たとえば、ユーザー`alice`がパイプラインを実行した場合:

- `gitlab-org`ネームスペースのプロジェクトでは、パイプライン内の各ジョブで使用されるコンピューティング時間は、`alice`ネームスペースではなく、`gitlab-org`ネームスペースの全体的な使用量に加算されます。
- `alice`ネームスペースのパーソナルプロジェクトでは、コンピューティング時間は、ネームスペースの全体的な使用量に加算されます。

1つのパイプラインで使用されたコンピューティング時間は、そのパイプラインで実行されたすべてのジョブに要したコンピューティング時間の合計です。ジョブは同時に実行できるため、パイプラインのエンドツーエンドの実行時間よりも、合計コンピューティング使用量が多くなる可能性があります。

[トリガージョブ](../yaml/_index.md#trigger)はRunner上で実行されないため、[`strategy:depend`](../yaml/_index.md#triggerstrategy)を使用して[ダウンストリームパイプライン](downstream_pipelines.md)のステータスを待機する場合でも、コンピューティング時間は消費されません。トリガーされたダウンストリームパイプラインは、他のパイプラインと同じようにコンピューティング時間を消費します。

使用量は月単位で追跡されます。各月の初日に、その月のすべてのネームスペースの使用量が`0`になります。

### コスト係数 {#cost-factors}

コンピューティング時間の消費率は、Runnerタイプとプロジェクト設定に応じて異なります。

#### GitLab.comでホストされるRunnerのコスト係数 {#cost-factors-of-hosted-runners-for-gitlabcom}

GitLabでホストされるRunnerのコスト係数は、Runnerタイプ（Linux、Windows、macOS）と仮想マシンの設定によって異なります。

| Runnerタイプ                | マシンサイズ           | コスト係数             |
|:---------------------------|:-----------------------|:------------------------|
| Linux x86-64（デフォルト）     | `small`                | `1`                     |
| Linux x86-64               | `medium`               | `2`                     |
| Linux x86-64               | `large`                | `3`                     |
| Linux x86-64               | `xlarge`               | `6`                     |
| Linux x86-64               | `2xlarge`              | `12`                    |
| Linux x86-64 + GPU対応 | `medium`、GPU standard | `7`                     |
| Linux Arm64                | `small`                | `1`                     |
| Linux Arm64                | `medium`               | `2`                     |
| Linux Arm64                | `large`                | `3`                     |
| macOS M1                   | `medium`               | `6`（**ステータス**: ベータ版）  |
| macOS M2 Pro               | `large`                | `12`（**ステータス**: ベータ版） |
| Windows                    | `medium`               | `1`（**ステータス**: ベータ版）  |

これらのコスト係数は、GitLab.comでホストされるRunnerに適用されます。

プロジェクトタイプに応じて一定の割引が適用されます。

| プロジェクトタイプ | コスト係数 | 使用されるコンピューティング時間 |
|--------------|-------------|---------------------|
| 標準プロジェクト | [Runnerタイプに基づく](#cost-factors-of-hosted-runners-for-gitlabcom) | （ジョブの実行時間 / 60 × コスト係数）を1分として換算 |
| [オープンソース団体向けGitLabプログラム](../../subscriptions/community_programs.md#gitlab-for-open-source)のパブリックプロジェクト | `0.5` | ジョブ時間2分を1分として換算 |
| [GitLab Open Sourceプログラムプロジェクト](../../subscriptions/community_programs.md#gitlab-for-open-source)のパブリックフォーク | `0.008` | ジョブ時間125分を1分として換算 |
| [GitLabプロジェクトへのコミュニティコントリビュート](#community-contributions-to-gitlab-projects) | 動的割引 | 次のセクションを参照してください |

#### GitLabプロジェクトへのコミュニティコントリビュート {#community-contributions-to-gitlab-projects}

コミュニティコントリビューターは、GitLabが管理するオープンソースプロジェクトにコントリビュートする際に、インスタンスRunnerで最大300,000分まで使用できます。300,000分の上限は、GitLab製品の一部であるプロジェクトにコントリビュートする場合にのみ適用されます。

インスタンスRunnerで利用できる合計分数は、他のプロジェクトのパイプラインで使用されたコンピューティング時間分だけ減少します。300,000分は、すべてのGitLab.comプランに適用されます。

コスト係数の計算式は次のとおりです。

- `Monthly compute quota / 300,000 job duration minutes = Cost factor`

たとえば、Premiumプランの月次コンピューティングクォータが10,000の場合:

- 10,000 / 300,000 = 0.03333333333コスト係数。

この割引されたコスト係数を適用するには、次の条件を満たす必要があります。

- マージリクエストのソースプロジェクトは、[`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com)や[`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab)など、GitLabが管理するプロジェクトのフォークでなければなりません。
- マージリクエストのターゲットプロジェクトは、そのフォークの親プロジェクトである必要があります。
- パイプラインは、マージリクエストパイプライン、マージ結果パイプライン、またはマージトレインパイプラインである必要があります。

### コンピューティング時間の使用量を削減する {#reduce-compute-minute-usage}

プロジェクトで消費するコンピューティング時間が多すぎる場合は、次の方法を試して使用量を削減してください。

- プロジェクトミラーを使用している場合は、[ミラー更新のパイプライン](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates)が無効になっていることを確認してください。
- [スケジュールされたパイプライン](schedules.md)の頻度を減らします。
- 不要な場合は、[パイプラインをスキップ](_index.md#skip-a-pipeline)します。
- 新しいパイプラインが開始された場合に自動的にキャンセルできる[中断可能な](../yaml/_index.md#interruptible)ジョブを使用します。
- すべてのパイプラインで実行する必要がないジョブは、[`rules`](../jobs/job_control.md)を使用して、必要な場合にのみ実行するようにします。
- 一部のジョブに[プライベートRunnerを使用](../runners/runners_scope.md#group-runners)します。
- フォークから作業して親プロジェクトにマージリクエストを送信する場合は、メンテナーに[親プロジェクトで](merge_request_pipelines.md#run-pipelines-in-the-parent-project)パイプラインを実行するように依頼できます。

オープンソースプロジェクトを管理している場合、これらの改善により、コントリビューターのフォークプロジェクトにおけるコンピューティング時間の使用量も削減され、より多くのコントリビュートが可能になります。

詳細については、[パイプライン効率性ガイド](pipeline_efficiency.md)を参照してください。

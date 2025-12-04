---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Runnerのセットアップと管理を行います。
title: GitLab Runnerを始める
---

GitLab Runnerの管理は、CI/CDジョブ実行インフラストラクチャの管理のライフサイクル全体を包含します:

- Runnerのデプロイと登録
- 特定のワークロードに対するexecutorの設定
- 組織の成長に合わせてキャパシティをスケールすること

Runnerの管理プロセスは、より大規模なワークフローの一部です:

![Plan、Create、Verify（Runnerの管理を含む）、Secure、Release、MonitorのGitLabワークフロー](img/get_started_runner_v18_3.png)

スコープとタグを使用してRunnerアクセスを管理し、パフォーマンスをモニタリングし、Runnerフリートを維持します。

## ステップ1: Runnerをインストール {#step-1-install-runners}

CI/CDジョブを実行するアプリケーションを作成するには、GitLab Runnerをインストールします。

インストールでは、ターゲットインフラストラクチャにGitLab Runnerをダウンロードしてセットアップする必要があります。インストールプロセスは、対象となるオペレーティングシステムによって異なります。GitLabは、Linux、Windows、macOS、およびz/OS用のバイナリとインストール手順を提供します。プラットフォームと要件に基づいてインストール方法を選択します。

詳細については、[GitLab Runnerのインストール](https://docs.gitlab.com/runner/install/)を参照してください。

## ステップ2: Runnerを登録 {#step-2-register-runners}

Runnerを登録して、GitLabインスタンスとGitLab Runnerがインストールされているマシン間の認証された通信を確立します。登録により、認証トークンを使用して、個々のRunnerがGitLabインスタンスに接続されます。登録中に、Runnerのスコープ、executorタイプ、およびRunnerの動作を決定するその他の設定パラメータを指定します。

Runnerを登録する前に、特定のGitLabグループまたはプロジェクトに制限するかどうかを決定する必要があります。登録時に異なるアクセススコープでセルフマネージドRunnerを設定して、利用可能なプロジェクトを決定できます:

- インスタンスRunner: GitLabインスタンス上のすべてのプロジェクトで利用可能
- グループRunner: 特定のグループとそのサブグループ内のすべてのプロジェクトで利用可能
- プロジェクトRunner: 特定のプロジェクトでのみ利用可能

Runnerを登録するときに、タグを追加して、適切なRunnerにジョブをルーティングします。意味のあるタグを割り当て、`.gitlab-ci.yml`ファイルでそれらを参照することで、必要な機能を備えたRunnerでジョブが実行されるようにします。

CI/CDジョブは、割り当てられたタグを確認して、どのRunnerを使用するかを判断します。タグは、ジョブで利用可能なRunnerのリストをフィルタリングする唯一の方法です。

詳細については、以下を参照してください:

- [Runnerを登録する](https://docs.gitlab.com/runner/register/)
- [新しいRunner登録ワークフローに移行する](../../ci/runners/new_creation_workflow.md)
- [インスタンスRunner](../../ci/runners/runners_scope.md#instance-runners)
- [グループRunner](../../ci/runners/runners_scope.md#group-runners)
- [プロジェクトRunner](../../ci/runners/runners_scope.md#project-runners)
- [タグ](../../ci/yaml/_index.md#tags)

## ステップ3: executorの選択 {#step-3-choose-executors}

GitLab Runner executorは、GitLab RunnerがCI/CDジョブを実行するために使用できるさまざまな環境とメソッドです。これらは、パイプラインジョブが実際にどこでどのように実行されるかを決定します。適切な設定により、ジョブが適切な環境で、正しいセキュリティ境界で実行されるようになります。

Runnerを登録する際には、executorを選択する必要があります。GitLab Runnerは、executorシステムを使用して、ジョブがどこでどのように実行されるかを判断します。executorは、各ジョブが実行される環境を決定します。インフラストラクチャとジョブの要件に一致するexecutorを選択します。

例: 

- CI/CDジョブでPowerShellコマンドを実行したい場合は、WindowsサーバーにGitLab Runnerをインストールし、Shell executorを使用するRunnerを登録します。
- CI/CDジョブで、カスタムDockerコンテナにおいてコマンドを実行したい場合は、LinuxサーバーにGitLab Runnerをインストールし、Docker executorを使用するRunnerを登録します。

これらの例は、いくつかの可能な設定のほんの一例です。仮想マシンにGitLab Runnerをインストールし、別の仮想マシンをexecutorとして使用することもできます。

詳細については、[executor](https://docs.gitlab.com/runner/executors/)を参照してください。

## ステップ4: Runnerを設定し、ジョブの実行を開始 {#step-4-configure-runners-and-start-running-jobs}

GitLab Runnerは、`config.toml`ファイルを編集することで設定できます。このファイルは、Runnerをインストールして登録するときに自動的に生成されます。このファイルでは、特定のRunnerの設定、またはすべてのRunnerの設定を編集できます。並行処理制限、ログレベル、キャッシュ設定、CPU制限、およびexecutor固有のパラメータを設定するように設定します。Runnerフリート全体で一貫した設定を使用します。

Runnerが設定され、プロジェクトで利用可能になると、CI/CDジョブでそのRunnerを使用できるようになります。

通常、RunnerはGitLab Runnerをインストールしたマシンでジョブを処理します。ただし、コンテナ内、Kubernetesクラスター内、またはクラウド上のオートスケールインスタンスでジョブを処理するようにRunnerを設定することも可能です。

詳細については、以下を参照してください:

- [GitLab Runnerを設定する](https://docs.gitlab.com/runner/configuration/advanced-configuration/)
- [CI/CDジョブ](../../ci/jobs/_index.md)

## ステップ5: Runnerの設定、スケール、および最適化を継続 {#step-5-continue-to-configure-scale-and-optimize-your-runners}

高度なRunner機能により、ジョブの実行効率性が向上し、複雑なCI/CDワークフローのための特殊な機能が提供されます。これらの最適化により、ジョブのランタイムが短縮され、オートスケール、パフォーマンスモニタリング、Runnerフリート管理、および特殊な設定を通じて、DevExが向上します。

オートスケールは、ジョブの需要に基づいてRunnerの容量を自動的に調整し、パフォーマンスの最適化により、リソースの効率性の高い利用が保証されます。これらの機能は、インフラストラクチャのコストを制御しながら、変動するワークロードを処理するのに役立ちます。

Runnerフリート管理は、複数のRunnerに対する一元化された制御とモニタリングを提供し、企業規模のRunnerデプロイを可能にします。Runnerフリートのスケールには、複数のRunnerにわたる容量の調整と、運用上のベストプラクティスの実装が含まれます。

組み込みのPrometheusメトリクスを使用して、Runnerのヘルスとパフォーマンスをモニタリングします。アクティブなジョブ数、CPU使用率、メモリ使用量、ジョブ成功率、キューの長さなどの主要なメトリクスを追跡することで、Runnerが効率的に動作することを確認できます。

詳細については、以下を参照してください:

- [オートスケールの設定](https://docs.gitlab.com/runner/runner_autoscale/)
- [Runnerフリートのスケール](https://docs.gitlab.com/runner/fleet_scaling/)
- [Runnerフリートの設定とベストプラクティス](../../topics/runner_fleet_design_guides/_index.md)
- [Runnerのパフォーマンスをモニタリングする](https://docs.gitlab.com/runner/monitoring/)
- [Runnerフリートダッシュボード](../../ci/runners/runner_fleet_dashboard.md)
- [ロングポーリング](../../ci/runners/long_polling.md)
- [Docker-in-Dockerの設定](https://docs.gitlab.com/runner/executors/docker/)
- [GitLab Runnerインフラストラクチャツールキット（GRIT）](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit)

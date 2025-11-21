---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Runnerフリート。
title: Google Kubernetes EngineでのGitLab Runnerフリートの設計と設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

これらの推奨事項を参考にしてCI/CDのビルド要件を分析し、Google Kubernetes Engine（GKE）でホストされているGitLab Runnerフリートを設計、設定、検証します。

以下の図は、Runnerフリートの実装過程を示しています。このガイドでは、次の手順について説明します。:

![Runnerフリートの手順の図](img/runner_fleet_steps_diagram_v17_5.png)

このフレームワークを使用して、組織全体をサポートする単一のグループまたはGitLabインスタンスのRunnerのデプロイを計画できます。

このフレームワークには、次の手順が含まれています。:

1. [予想されるCI/CDワークロードの評価](#assess-the-expected-cicd-workloads)
1. [Runnerフリート設定の計画](#plan-the-runner-fleet-configuration)
1. [GKEへのRunnerのデプロイ](#deploy-the-runner-on-gke)
1. [最適化](#optimize)

## 予想されるCI/CDワークロードの評価 {#assess-the-expected-cicd-workloads}

このフェーズでは、サポートする開発チームのCI/CDビルド要件を収集します。該当する場合は、使用されているプログラミング言語、スクリプト言語、マークアップ言語のインベントリを作成します。

複数の開発チーム、さまざまなプログラミング言語、およびビルド要件をサポートしている場合があります。最初の詳細な分析セットとして、1つのチーム、1つのプロジェクト、および1セットのCI/CDビルド要件から開始します。

予想されるCI/CDワークロードを評価するには、次のようにします。:

- サポートする予定のCI/CDジョブの需要（1時間ごと、毎日、毎週）を見積もります。
- 特定のプロジェクトの代表的なサンプルCI/CDジョブに必要なCPUとRAMリソースを見積もります。これらの見積もりは、サポートする可能性のあるさまざまなプロファイルを特定するのに役立ちます。これらのプロファイルの特性は、要件をサポートするために必要な適切なGKEクラスタリングを特定するために重要です。CPUとRAMの要件を判断する方法については、この例を参照してください。
- グループまたはプロジェクトごとに特定のRunnerへのアクセスをセグメント化する必要があるセキュリティまたはポリシー要件があるかどうかを判断します。

### CI/CDジョブに必要なCPUとRAMの見積もり {#estimate-the-cpu-and-ram-requirements-for-a-cicd-job}

CPUとRAMのリソース要件は、プログラミング言語の種類やCI/CDジョブの種類（ビルド、インテグレーションテスト、単体テスト、セキュリティスキャン）などの要因によって異なります。次のセクションでは、CI/CDジョブのCPUとリソースの要件を収集する方法について説明します。このアプローチを採用して、独自のニーズに合わせて構築できます。

たとえば、FastAPIプロジェクトフォークで定義されているものと同様のCI/CDジョブを実行するには、[ra-group / fastapi · GitLab](https://gitlab.com/ra-group2/fastapi)を実行します。この例のジョブは、Pythonイメージを使用し、プロジェクトの要件をダウンロードして、既存の単体テストを実行します。ジョブの`.gitlab-ci.yml`は次のとおりです。:

```yaml
tests:
  image: python:3.11.10-bookworm
  parallel: 25
  script:
  - pip install -r requirements.txt
  - pytest
```

必要なコンピューティングリソースとRAMリソースを特定するには、Dockerを使用して、以下を実行します。:

- FastAPIフォークとCI/CDジョブスクリプトをエントリポイントとして使用する特定のイメージを作成します。
- ビルドされたイメージでコンテナを実行し、リソースの使用量を監視します。

必要なコンピューティングリソースとRAMリソースを特定するには、次の手順を実行します。:

1. すべてのCIコマンドを含むスクリプトファイルをプロジェクトに作成します。スクリプトファイルの名前は`entrypoint.sh`です。

   ```shell
   #!/bin/bash
   cd /fastapi || exit
   pip install -r requirements.txt
   pytest

1. `entrypoint.sh`ファイルがCIスクリプトを実行するイメージを作成するためのDockerfileを作成します。

   ```dockerfile
   FROM python:3.11.10-bookworm
   RUN mkdir /fastapi
   COPY . /fastapi
   RUN chmod +x /fastapi/entrypoint.sh
   CMD [ "bash", "/fastapi/entrypoint.sh" ]
   ```

1. イメージをビルドします。プロセスを簡素化するには、ビルド、保存、イメージのローカルマシンでの実行など、すべての操作を実行します。このアプローチにより、イメージをプルおよびプッシュするためのオンラインレジストリの必要性がなくなります。

   ```shell
   ❯ docker build . -t my-project_dir/fastapi:testing
   ...
   Successfully tagged my-project_dir/fastapi:testing
   ```

1. ビルドされたイメージでコンテナを実行し、コンテナの実行中にリソースの使用状況を同時に監視します。次のコマンドを使用して、`metrics.sh`という名前のスクリプトを作成します。:

   ```shell
   #! /bin/bash

   container_id=$(docker run -d --rm my-project_dir/fastapi:testing)

   while true; do
       echo "Collecting metrics..."
       metrics=$(docker stats --no-trunc --no-stream --format "table {{.ID}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep "$container_id")
       if [ -z "$metrics" ]; then
           exit 0
       fi
       echo "Saving metrics..."
       echo "$metrics" >> metrics.log
       sleep 1
   done
   ```

   このスクリプトは、ビルドされたイメージを使用して、デタッチされたコンテナを実行します。次に、コンテナIDを使用して、正常に完了するまで`CPU`と`Memory`の使用状況を収集します。収集されたメトリクスは、`metrics.log`という名前のファイルに保存されます。

   {{< alert type="note" >}}

   この例では、CI/CDジョブの存続期間が短いため、各コンテナポーリング間のスリープは1秒に設定されています。必要に応じて、この値を調整してください。

   {{< /alert >}}

1. `metrics.log`ファイルを分析して、テストコンテナのピーク時の使用量を特定します。

   この例では、CPUの最大使用率は`107.50%`で、メモリの最大使用率は`303.1Mi`です。

   ```log
   223e93dd05c6   94.98%    83.79MiB / 15.58GiB
   223e93dd05c6   28.27%    85.4MiB / 15.58GiB
   223e93dd05c6   53.92%    121.8MiB / 15.58GiB
   223e93dd05c6   70.73%    171.9MiB / 15.58GiB
   223e93dd05c6   20.78%    177.2MiB / 15.58GiB
   223e93dd05c6   26.19%    180.3MiB / 15.58GiB
   223e93dd05c6   77.04%    224.1MiB / 15.58GiB
   223e93dd05c6   97.16%    226.5MiB / 15.58GiB
   223e93dd05c6   98.52%    259MiB / 15.58GiB
   223e93dd05c6   98.78%    303.1MiB / 15.58GiB
   223e93dd05c6   100.03%   159.8MiB / 15.58GiB
   223e93dd05c6   103.97%   204MiB / 15.58GiB
   223e93dd05c6   107.50%   207.8MiB / 15.58GiB
   223e93dd05c6   105.96%   215.7MiB / 15.58GiB
   223e93dd05c6   101.88%   226.2MiB / 15.58GiB
   223e93dd05c6   100.44%   226.7MiB / 15.58GiB
   223e93dd05c6   100.20%   226.9MiB / 15.58GiB
   223e93dd05c6   100.60%   227.6MiB / 15.58GiB
   223e93dd05c6   100.46%   228MiB / 15.58GiB
   ```

### 収集されたメトリクスの分析 {#analyzing-the-metrics-collected}

収集されたメトリクスに基づいて、このジョブプロファイルでは、Kubernetesエクゼキューターのジョブを`1 CPU`と`~304 Mi of Memory`に制限できます。この結論が正確であっても、すべてのユースケースに実用的とは限りません。

ジョブを実行するために3つの`e2-standard-4`ノードのノードプールを持つクラスタリングを使用する場合、`1 CPU`制限では、同時に**12個のジョブ**しか実行できません（`e2-standard-4`ノードには**4つのvCPU**と**16 GB**のメモリがあります）。ジョブの追加は、実行中のジョブが完了し、リソースが解放されるまで待機してから開始されます。

Kubernetesは、設定された制限またはクラスタリングで使用可能なメモリよりも多くのメモリを使用するすべてのポッドを終了するため、要求されるメモリは重要です。ただし、CPU制限はより柔軟性がありますが、ジョブの期間に影響します。CPU制限を低く設定すると、ジョブが完了するまでの時間が長くなります。前の例では、CPU制限を`250m`（または`0.25`）の代わりに`1`に設定すると、ジョブの期間が4倍に増加しました（約2分から8〜10分）。

メトリクス収集方式はポーリングメカニズムを使用するため、特定された最大使用量を切り上げる必要があります。たとえば、メモリ使用量の`303 Mi`の代わりに、`400 Mi`に丸めます。

前の例に関する重要な考慮事項：:

- メトリクスはローカルマシンで収集されました。これには、Google Kubernetes Engineクラスタリングよりも同じCPU設定はありません。ただし、これらのメトリクスは、`e2-standard-4`ノードを使用してKubernetesクラスタリングで監視することで検証されました。
- これらのメトリクスを正確に表現するには、Google Compute Engine VMで[評価フェーズ](#assess-the-expected-cicd-workloads)で説明されているテストを実行します。

## Runnerフリート設定の計画 {#plan-the-runner-fleet-configuration}

計画フェーズでは、組織に適したRunnerフリート設定をマップします。Runnerスコープ（インスタンス、グループ、プロジェクト）と、以下に基づくKubernetesクラスタリングの設定を検討してください。:

- CI/CDジョブリソース需要の評価
- CI/CDジョブタイプのインベントリ

### Runnerのスコープ {#runner-scope}

Runnerスコープを計画するには、次の質問を検討してください。:

- プロジェクトオーナーとグループオーナーに、独自のRunnerを作成および管理させますか？

  - デフォルトでは、プロジェクトとグループのオーナーは、Runner設定を作成し、GitLabのプロジェクトまたはグループにRunnerを登録済みのランナー登録できます。
  - この設計により、デベロッパーはビルド環境を迅速に作成できます。このアプローチにより、GitLab CI/CDを使い始める際のデベロッパーの摩擦が軽減されます。ただし、大規模な組織では、このアプローチにより、環境全体で十分に活用されていない、または未使用のRunnerが多数発生する可能性があります。

- 組織に、特定の種類のRunnerへのアクセスを特定のグループまたはプロジェクトにセグメント化する必要があるセキュリティまたはその他のポリシーはありますか？

GitLabセルフマネージド環境にRunnerをデプロイする最も簡単な方法は、インスタンス用に作成することです。インスタンスのスコープが設定されたRunnerは、デフォルトですべてのグループおよびプロジェクトで使用できます。

組織のニーズをすべてインスタンスRunnerで満たすことができる場合、このデプロイパターンは最も効率性の高いパターンです。これにより、CI/CDビルドフリートを大規模に効率性よく、費用対効果の高い方法で運用できます。

特定のRunnerへのアクセスを特定のグループまたはプロジェクトにセグメント化する要件がある場合は、それらを計画プロセスに組み込みます。

#### Runnerフリート設定の例 - インスタンスRunner {#example-runner-fleet-configuration---instance-runners}

テーブルの設定は、組織のRunnerフリートを設定する際に利用できる柔軟性を示しています。この例では、インスタンスサイズとジョブタグ付けが異なる複数のRunnerを使用しています。これらのRunnerを使用すると、それぞれ特定のCPUとRAMのリソース要件を持つさまざまなタイプのCI/CDジョブをサポートできます。ただし、Kubernetesを使用する場合、これは最も効率性の高いパターンではない可能性があります。

| Runnerタイプ | Runnerタグ | スコープ | 提供するRunnerタイプの数 | Runnerワーカーの仕様 | Runnerホスト環境 | 環境設定 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| インスタンス | ci-runner-small | デフォルトでは、すべてのグループおよびプロジェクトのCI/CDジョブを実行できます。 | 5 | 2 vCPU、8 GB RAM | Kubernetes | → 3ノード <br> → Runnerワーカーのコンピューティングノード = **e2-standard-2**  |
| インスタンス | ci-runner-medium | デフォルトでは、すべてのグループおよびプロジェクトのCI/CDジョブを実行できます。 | 2 | 4 vCPU、16 GB RAM | Kubernetes | → 3ノード <br> → Runnerワーカーのコンピューティングノード = **e2-standard-4**   |
| インスタンス | ci-runner-large | デフォルトでは、すべてのグループおよびプロジェクトのCI/CDジョブを実行できます。 | 1 | 8 vCPU、32 GB RAM | Kubernetes | → 3ノード <br> → Runnerワーカーのコンピューティングノード = **e2-standard-8**   |

Runnerフリート設定の例では、合計3つのRunner設定と、CI/CDジョブをアクティブに実行している8つのRunnerがあります。

Kubernetesエクゼキューターを使用すると、Kubernetesスケジューラを使用して、コンテナリソースを上書きできます。理論的には、適切なリソースを備えたKubernetesクラスタリングに単一のGitLab Runnerをデプロイできます。次に、コンテナリソースを上書きして、各CI/CDジョブに適切なコンピューティングタイプを選択できます。このパターンを実装すると、デプロイおよび運用する必要がある個別のRunner設定の数が削減されます。

### ベストプラクティス {#best-practices}

- 常にノードプールをRunnerマネージャーに割り当てます。
  - ログ処理とキャッシュまたはアーティファクトの管理は、CPUを大量に消費する可能性があります。
- 常に`config.toml`ファイルに、デフォルトの制限（ビルド/ヘルパー/サービスコンテナのCPU/メモリ）を設定します。
- 常に`config.toml`ファイルのリソースの最大上書きを許可します。
- ジョブ定義（`.gitlab-ci.yml`）で、ジョブに必要な適切な制限を指定します。
  - 指定しない場合は、`config.toml`ファイルで設定されたデフォルト値が使用されます。
  - コンテナがメモリ制限を超えると、システムは自動的にOut of Memory（OOM）強制終了プロセスを使用して終了します。
- 機能フラグ`FF_RETRIEVE_POD_WARNING_EVENTS`と`FF_PRINT_POD_EVENTS`を使用します。詳細については、[機能フラグに関するドキュメント](https://docs.gitlab.com/runner/configuration/feature-flags.html)を参照してください。

## GKEへのRunnerのデプロイ {#deploy-the-runner-on-gke}

Google Kubernetes EngineクラスタリングにGitLab Runnerをインストールする準備ができたら、多くのオプションがあります。GKEでクラスタリングを作成した場合は、GitLab Runner HelmチャートまたはKubernetes Operatorを使用して、クラスタリングにRunnerをインストールできます。

まだGKEにクラスタリングをセットアップしていない場合は、GitLabはGitLab Runner Infrastructure Toolkit（GRIT）を提供します。これは、同時に以下を実行します。:

- マルチノードプールGKEクラスタリングを作成します。: **Standard Edition**と**Standard Mode**。
- GitLab Runner Kubernetes operatorを使用して、GitLab Runnerをクラスタリングにインストールします

次の例では、GRITを使用してGoogle Kubernetes EngineクラスタリングとGitLab Runnerマネージャーをデプロイします。

クラスタリングとGitLab Runnerが適切に設定されるようにするには、次の情報を検討してください。:

- **カバーする必要のあるジョブタイプの数はいくつですか**？この情報は、評価フェーズから得られます。評価フェーズでは、メトリクスが集計され、組織の制約を考慮して、結果として得られるグループの数が特定されます。**ジョブタイプ**とは、アクセスフェーズ中に識別された分類されたジョブのコレクションです。この分類は、ジョブに必要な最大リソースに基づいています。
- **実行する必要のあるGitLab Runnerマネージャーの数はいくつですか**？この情報は、計画フェーズから得られます。組織がプロジェクトを個別に管理する場合は、このフレームワークを各プロジェクトに個別に適用します。このアプローチは、複数のジョブプロファイルが特定された場合（組織全体または特定のプロジェクトの場合）、およびそれらがすべて個人またはGitLab Runnerのフリートによって処理される場合にのみ関連します。基本的な設定では、通常、GKEクラスタリングごとに1つのGitLab Runnerマネージャーを使用します。
- **推定される同時CI/CDジョブの最大数はいくつですか**？この情報は、任意の時点で実行される同時CI/CDジョブの最大数の見積もりを表します。この情報は、`Prepare`ステージ中に待機する時間を指定することにより、GitLab Runnerマネージャーを設定するときに必要です。リソースの使用可能なリソースが制限されているノードでのジョブポッドのスケジュール。

### FastAPIフォークの実際のアプリケーション {#real-life-applications-for-the-fastapi-fork}

FastAPIの場合は、次の情報を検討してください。:

- **カバーする必要のあるジョブプロファイルの数はいくつですか**？次の特性を持つジョブプロファイルは1つしかありません。`1 CPU`と`303 Mi`のメモリ。[メトリクス収集の分析](#analyzing-the-metrics-collected)セクションで説明したように、これらのrawの値を次のように変更します。:
  - メモリー制限によるジョブの失敗を避けるために、`303 Mi`の代わりにメモリー制限に`400 Mi`を使用します。
  - `1 CPU`の代わりに、CPUに`0.20`を使用します。ジョブの完了に時間がかかっても構いません。タスクを完了する際は、速度よりも精度と品質を優先します。
- **実行する必要があるGitLab Runner Managerの数はいくつですか**。テストには、1つのGitLab Runner Managerで十分です。
- **予想されるワークロードは何ですか**。常に最大20個のジョブを同時に実行したいと考えています。

これらの入力に基づいて、次の最小特性を持つ任意のGKEクラスターで十分です。:

- 最小CPU: **(0.20 + ヘルパーCPU使用量) * 同時ジョブ数**。この例では、ヘルパーコンテナの制限を**0.15 CPU**に設定すると、**7 vCPU**になります。
- 最小メモリ: **(400Mi + ヘルパーメモリー使用量) * 同時ジョブ数**。この例では、ヘルパーの制限を**100 Mi**に設定すると、少なくとも**10 Gi**になります。

必要な最小ストレージなどの他の特性も考慮する必要があります。ただし、この例では考慮していません。

GKEクラスターの構成の可能性は次のとおりです（どちらの構成でも、**20個以上のジョブ**を同時に実行できます）。:

- `12 vCPU`および`48 GiB`のメモリーの合計に対して、`3 e2-standard-4`ノードのノードプールを持つGKEクラスター
- `8 vCPU`および`32 GiB`のメモリーの合計に対して、`e2-standard-8`ノードでのみノードプールを持つGKEクラスター

この例では、最初の構成を使用します。GitLab Runner Managerのログ処理が全体的なログ処理に影響を与えないようにするには、GitLab Runnerがインストールされている専用ノードプールを使用します。

#### GKE GRIT設定 {#gke-grit-configuration}

GRITのGKEの構成は次のようになります。:

```terraform
google_project     = "GCLOUD_PROJECT"
google_region      = "GCLOUD_REGION"
google_zone        = "GCLOUD_ZONE"
name               = "my-grit-gke-cluster"
node_pools = {
  "runner-manager" = {
    node_count = 1,
    node_config = {
      machine_type = "e2-standard-2",
      image_type   = "cos_containerd",   #Linux OS container only. Change to windows_ltsc_containerd for Windows OS container
      disk_size_gb = 50,
      disk_type    = "pd-balanced",
      labels = {
        "app" = "gitlab-runner",
      }
    },
  },
  "worker-pool" = {
    node_count = 3,
    node_config = {
      machine_type = "e2-standard-4",    #4 vCPU, 16 GB each
      image_type   = "cos_containerd",   #Linux OS container only. Change to windows_ltsc_containerd for Windows OS container
      disk_size_gb = 150,
      disk_type    = "pd-balanced",
      labels = {
        "app" = "gitlab-runner-job"
      }
    },
  },
}
```

前の設定では:

- `runner-manager`ブロックは、GitLab Runnerがインストールされているノードプールを指します。この例では、`e2-standard-2`で十分です。
- `runner-manager`ブロックのラベルセクションは、GitLabでGitLab Runnerをインストールする際に役立ちます。オペレーター構成を介してノードセレクターが構成され、GitLab Runnerがこのノードプールのノードにインストールされるようになります。
- `worker-pool`ブロックは、CI/CDジョブのポッドが作成されるノードプールを指します。指定された設定により、`"app" = "gitlab-runner-job"`というラベルが付けられた`3 e2-standard-4`ノードのノードプールが作成され、ジョブのポッドがホストされます。
- `image_type`パラメータを使用すると、ノードで使用されるイメージを設定できます。ワークロードが主にWindowsイメージに依存する場合は、`windows_ltsc_containerd`に設定できます。

この設定の図を次に示します。:

![イラスト構成クラスター](img/nodepool_illustration_example_v17_5.png)

#### GitLab Runner GRIT設定 {#gitlab-runner-grit-configuration}

GRITのGitLab Runner構成の結果は次のようになります。:

```terraform
gitlab_pat         = "glpat-REDACTED"
gitlab_project_id  = GITLAB_PROJECT_ID
runner_description = "my-grit-gitlab-runner"
runner_image       = "registry.gitlab.com/gitlab-org/ci-cd/gitlab-runner-ubi-images/gitlab-runner-ocp:amd64-v17.3.1"
helper_image       = "registry.gitlab.com/gitlab-org/ci-cd/gitlab-runner-ubi-images/gitlab-runner-helper-ocp:x86_64-v17.3.1"
concurrent     = 20
check_interval = 1
runner_tags    = ["my-custom-tag"]
config_template    = <<EOT
[[runners]]
  name = "my-grit-gitlab-runner"
  shell = "bash"
  environment = [
    "FF_RETRIEVE_POD_WARNING_EVENTS=true",
    "FF_PRINT_POD_EVENTS=true",
  ]
  [runners.kubernetes]
    image = "alpine"
    cpu_limit = "0.25"
    memory_limit = "400Mi"
    helper_cpu = "150m"
    helper_memory = "150Mi"
    cpu_limit_overwrite_max_allowed = "0.25"
    memory_limit_overwrite_max_allowed = "400Mi"
    helper_cpu_limit_overwrite_max_allowed = "150m"
    helper_memory_limit_overwrite_max_allowed = "150Mi"
  [runners.kubernetes.node_selector]
    "app" = "gitlab-runner-job"
EOT
pod_spec = [
  {
    name      = "selector",
    patchType = "merge",
    patch     = <<EOT
nodeSelector:
  app: "gitlab-runner"
EOT
  }
]
```

前の設定では:

- `pod_spec`パラメータを使用すると、GitLab Runnerを実行しているポッドのノードセレクターを設定できます。設定では、ノードセレクターは`"app" = "gitlab-runner"`に設定され、GitLab RunnerがRunnerマネージャーノードプールにインストールされるようになります。
- `config_template`パラメータは、GitLab Runner Managerが実行するすべてのジョブのデフォルト制限を提供します。また、設定された値がデフォルト値を超えない限り、これらの制限の上書きも許可します。
- 機能フラグ`FF_RETRIEVE_POD_WARNING_EVENTS`と`FF_PRINT_POD_EVENTS`は、ジョブの失敗が発生した場合のデバッグを容易にするためにも設定されています。詳細については、[機能フラグのドキュメント](https://docs.gitlab.com/runner/configuration/feature-flags.html)を参照してください。

### 仮想ユースケースの実際のアプリケーション {#real-life-applications-for-a-hypothetical-use-case}

次の情報を考慮してください:

- **カバーする必要があるジョブプロファイルの数はいくつですか**。2つのプロファイル（指定された仕様は、ヘルパーの制限を考慮に入れています）:
  - 中規模ジョブ: `300m CPU`および`200 MiB`
  - CPU負荷の高いジョブ: `1 CPU`および`1 GiB`
- **実行する必要があるGitLab Runner Managerの数はいくつですか**。1つ。
- **予想されるワークロードは何ですか**。
  - 最大**50個の中規模**ジョブを同時に実行
  - 最大**25個のCPU負荷の高い**ジョブを同時に実行

#### GKE設定 {#gke-configuration}

- 中規模ジョブのニーズ:
  - CPU: 300m * 50 = 5 CPU（概算）
  - メモリ: 200 MiB * 50 = 10 GiB
- CPU負荷の高いジョブのニーズ:
  - CPU: 1 * 25 = 25
  - メモリ: 1 GiB * 25 = 25 GiB

GKEクラスターには、以下が必要です。:

- GitLab Runner Managerのノードプール（ログ処理は要求が厳しくないことを考慮しましょう）: **1つのe2-standard-2**ノード
- 中規模ジョブのノードプール: **3つのe2-standard-4**ノード
- CPU負荷の高いジョブのノードプール: **1つのe2-highcpu-32**ノード（`32 vCPU`および`32 GiB`メモリ）

```terraform
google_project     = "GCLOUD_PROJECT"
google_region      = "GCLOUD_REGION"
google_zone        = "GCLOUD_ZONE"
name               = "my-grit-gke-cluster"
node_pools = {
  "runner-manager" = {
    node_count = 1,
    node_config = {
      machine_type = "e2-standard-2",
      image_type   = "cos_containerd",   #Linux OS container only. Change to windows_ltsc_containerd for Windows OS container
      disk_size_gb = 50,
      disk_type    = "pd-balanced",
      labels = {
        "app" = "gitlab-runner",
      }
    },
  },
  "medium-pool" = {
    node_count = 3,
    node_config = {
      machine_type = "e2-standard-4",    #4 vCPU, 16 GB each
      image_type   = "cos_containerd",   #Linux OS container only. Change to windows_ltsc_containerd for Windows OS container
      disk_size_gb = 150,
      disk_type    = "pd-balanced",
      labels = {
        "app" = "gitlab-runner-job"
      }
    },
  },
  "cpu-intensive-pool" = {
    node_count = 1,
    node_config = {
      machine_type = "e2-highcpu-32", #32 vCPU, 32 GB each
      image_type   = "cos_containerd",
      disk_size_gb = 150,
      disk_type    = "pd-balanced",
      labels = {
        "app" = "gitlab-runner-job"
      }
    },
  },
}
```

#### GitLab Runnerの設定 {#gitlab-runner-configuration}

GRITの現在の実装では、一度に複数のRunnerをインストールできません。提供される`config_template`では、前の例で行ったように、`node_selection`などの構成やその他の制限は設定されていません。簡単な構成では、CPU負荷の高いジョブに対して許可される最大の上書き値を設定し、`.gitlab-ci.yml`ファイルに正しい値を設定します。GitLab Runner構成の結果は次のようになります。:

```terraform
gitlab_pat         = "glpat-REDACTED"
gitlab_project_id  = GITLAB_PROJECT_ID
runner_description = "my-grit-gitlab-runner"
runner_image       = "registry.gitlab.com/gitlab-org/ci-cd/gitlab-runner-ubi-images/gitlab-runner-ocp:amd64-v17.3.1"
helper_image       = "registry.gitlab.com/gitlab-org/ci-cd/gitlab-runner-ubi-images/gitlab-runner-helper-ocp:x86_64-v17.3.1"
concurrent     = 100
check_interval = 1
runner_tags    = ["my-custom-tag"]
config_template    = <<EOT
[[runners]]
  name = "my-grit-gitlab-runner"
  shell = "bash"
  environment = [
    "FF_RETRIEVE_POD_WARNING_EVENTS=true",
    "FF_PRINT_POD_EVENTS=true",
  ]
  [runners.kubernetes]
    image = "alpine"
    cpu_limit_overwrite_max_allowed = "0.75"
    memory_limit_overwrite_max_allowed = "900Mi"
    helper_cpu_limit_overwrite_max_allowed = "250m"
    helper_memory_limit_overwrite_max_allowed = "100Mi"
EOT
pod_spec = [
  {
    name      = "selector",
    patchType = "merge",
    patch     = <<EOT
nodeSelector:
  app: "gitlab-runner"
EOT
  }
]
```

`.gitlab-ci.yml`ファイルは次のようになります。:

- 中規模ジョブの場合:

```yaml
variables:
  KUBERNETES_CPU_LIMIT: "200m"
  KUBERNETES_MEMORY_LIMIT: "100Mi"
  KUBERNETES_HELPER_CPU_LIMIT: "100m"
  KUBERNETES_HELPER_MEMORY_LIMIT: "100Mi"

tests:
  image: some-image:latest
  script:
  - command_1
  - command_2
  # ...
  - command_n
  tags:
    - my-custom-tag
```

- CPU負荷の高いジョブの場合:

```yaml
variables:
  KUBERNETES_CPU_LIMIT: "0.75"
  KUBERNETES_MEMORY_LIMIT: "900Mi"
  KUBERNETES_HELPER_CPU_LIMIT: "150m"
  KUBERNETES_HELPER_MEMORY_LIMIT: "100Mi"

tests:
  image: custom-cpu-intensive-image:latest
  script:
  - cpu_intensive_command_1
  - cpu_intensive_command_2
  # ...
  - cpu_intensive_command_n
  tags:
    - my-custom-tag
```

{{< alert type="note" >}}

設定を簡単にするには、ジョブプロファイルごとに1つのGitLab Runnerをクラスターごとに使用します。このアプローチは、GitLabが同じクラスター上での複数のGitLab Runnerのインストール、または`config.toml`テンプレートでの複数の`[[runners]]`セクションをサポートするまで推奨されます。

{{< /alert >}}

### モニタリングと可観測性の設定 {#set-up-monitoring-and-observability}

デプロイフェーズの最後の手順として、Runnerホスト環境とGitLab Runnerをモニタリングするためのソリューションを確立する必要があります。インフラストラクチャレベル、Runner、およびCI/CDジョブメトリクスは、CI/CDビルドインフラストラクチャの効率性と信頼性に関するインサイトを提供します。また、Kubernetesクラスター、GitLab Runner、およびCI/CDジョブ構成を調整および最適化するために必要なインサイトも提供します。

#### モニタリングのベストプラクティス {#monitoring-best-practices}

- ジョブレベルのメトリクスをモニタリングします。ジョブの実行時間、ジョブの成功率と失敗率。
  - ジョブレベルのメトリクスを分析するには、どのCI/CDジョブが最も頻繁に実行され、集計で最も多くのコンピューティングおよびRAMリソースを消費するかを理解します。このジョブプロファイルは、最適化の機会を評価するための良い出発点です。
- Kubernetesクラスターのリソース使用率をモニタリングします:
  - CPU使用率:
  - メモリ使用量
  - ネットワーク使用率
  - ディスク使用率

続行方法の詳細については、[専用のGitLab Runnerモニタリングページ](https://docs.gitlab.com/runner/monitoring/)を参照してください。

## 最適化 {#optimize}

CI/CDビルド環境の最適化は継続的なプロセスです。CI/CDジョブのタイプと量は常に進化しており、積極的な関与が必要です。

CI/CDとCI/CDビルドインフラストラクチャには、特定の組織目標がある可能性があります。したがって、最初の手順は、最適化要件と定量化可能な目標を定義することです。

次に、顧客ベース全体の最適化要件の例を示します。:

- CI/CDジョブのジョブの起動時間
- CI/CDジョブの実行時間
- CI/CDジョブの信頼性
- CI/CDコンピューティングコストの最適化

次のステップでは、Kubernetesクラスターのインフラストラクチャメトリクスと組み合わせて、CI/CDメトリクスの分析を開始します。分析する重要な相関関係は次のとおりです。:

- Kubernetesネームスペース別のCPU使用率
- Kubernetesネームスペース別のメモリ使用量
- ノード別のCPU使用率
- ノード別のメモリ使用量
- CI/CDジョブの失敗率

通常、Kubernetesでは、(Flakyテストによる失敗とは無関係に)高いCI/CDジョブの失敗率は、Kubernetesクラスターのリソース制約に起因します。これらのメトリクスを分析して、Kubernetesクラスター構成におけるCI/CDジョブの起動時間、ジョブの実行時間、ジョブの信頼性、およびインフラストラクチャリソースの使用率の最適なバランスを実現します。

### ベストプラクティス {#best-practices-1}

- ジョブの種類ごとに、組織全体のCI/CDジョブを分類するプロセスを確立します。
- KubernetesおよびCI/CDジョブの種類におけるGitLab CI/CDビルドインフラストラクチャのモニタリング構成と最適化へのアプローチの両方を簡素化するジョブタイプ分類フレームワークを確立します。
- 各ジョブタイプにクラスター上の独自のノードを割り当てると、CI/CDジョブのパフォーマンス、ジョブの信頼性、およびインフラストラクチャの使用率の最適なバランスが得られる可能性があります。

CI/CDビルド環境のインフラストラクチャスタックとしてKubernetesを使用すると、大きなメリットが得られます。ただし、Kubernetesインフラストラクチャの継続的なモニタリングと最適化が必要です。可観測性と最適化のフレームワークを確立すると、1か月に数百万ものCI/CDジョブをサポートできます。リソースの競合を排除し、決定論的なCI/CDジョブの実行と最適なリソース使用率を実現できます。これらの改善により、運用効率性とコストの最適化が実現します。

## 次の手順 {#next-steps}

より良いユーザーエクスペリエンスを提供するために、次のステップを実行してください:

- 同じクラスター上での複数のGitLab Runnerインストールのサポート。これにより、複数のジョブプロファイルを処理する必要があるシナリオのより良い管理が可能になります（リソースの誤用を防ぐために、GitLab Runnerを適切に構成できます）。
- GKEノードのオートスケールのサポート。これにより、GKEはワークロードに応じてスケールアップおよびスケールダウンできるため、コストを節約できます。
- ジョブメトリクスモニタリングを有効にします。これにより、管理者は実際の使用状況に基づいてクラスターとGitLab Runnerをより適切に最適化できます。

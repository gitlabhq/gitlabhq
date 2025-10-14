---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linux上でホストされるRunner
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.com向けのLinux上でホストされるRunnerは、Google Cloud Compute Engineで実行されます。各ジョブは、完全に分離された一時的な仮想マシン（VM）を取得します。デフォルトのリージョンは`us-east1`です。

VMは、Google Container-Optimized OS（COS）と、`docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor)を実行するDocker Engineの最新バージョンを使用します。マシンタイプと基盤となるプロセッサタイプが異なる可能性があります。また、ジョブが特定のプロセッサ設計に最適化されている場合、動作に一貫性がない可能性があります。

[タグなし](../../yaml/_index.md#tags)ジョブは、`small` Linux x86-64 Runnerで実行されます。

## Linux - x86-64で使用可能なマシンタイプ {#machine-types-available-for-linux---x86-64}

GitLabは、Linux x86-64上のホストされたRunnerに対して、次のマシンタイプを提供しています。

<table id="x86-runner-specs" aria-label="Linux x86-64で使用可能なマシンタイプ">
  <thead>
    <tr>
      <th>Runnerタグ</th>
      <th>vCPU</th>
      <th>メモリ</th>
      <th>ストレージ</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-amd64</code>（デフォルト）
      </td>
      <td class="vcpus">2</td>
      <td>8 GB</td>
      <td>30 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-medium-amd64</code>
      </td>
      <td class="vcpus">4</td>
      <td>16 GB</td>
      <td>50 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-amd64</code>（PremiumおよびUltimateのみ）
      </td>
      <td class="vcpus">8</td>
      <td>32 GB</td>
      <td>100 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-xlarge-amd64</code>（PremiumおよびUltimateのみ）
      </td>
      <td class="vcpus">16</td>
      <td>64 GB</td>
      <td>200 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-2xlarge-amd64</code>（PremiumおよびUltimateのみ）
      </td>
      <td class="vcpus">32</td>
      <td>128 GB</td>
      <td>200 GB</td>
    </tr>
  </tbody>
</table>

## Linux - Arm64で使用可能なマシンタイプ {#machine-types-available-for-linux---arm64}

GitLabは、Linux Arm64上のホストされたRunnerに対して、次のマシンタイプを提供しています。

<table id="arm64-runner-specs" aria-label="Linux Arm64で使用可能なマシンタイプ">
  <thead>
    <tr>
      <th>Runnerタグ</th>
      <th>vCPU</th>
      <th>メモリ</th>
      <th>ストレージ</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-arm64</code>
      </td>
      <td class="vcpus">2</td>
      <td>8 GB</td>
      <td>30 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-medium-arm64</code>（PremiumおよびUltimateのみ）
      </td>
      <td class="vcpus">4</td>
      <td>16 GB</td>
      <td>50 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-arm64</code>（PremiumおよびUltimateのみ）
      </td>
      <td class="vcpus">8</td>
      <td>32 GB</td>
      <td>100 GB</td>
    </tr>
  </tbody>
</table>

{{< alert type="note" >}}

Linux Arm上でホストされるRunnerでDocker-in-Dockerを使用すると、ネットワーク接続の問題が発生する可能性があります。この問題は、Google CloudとDockerの最大伝送単位（MTU）値が一致しない場合に発生します。この問題を解決するには、クライアント側のDocker設定で`--mtu=1400`を設定してください。詳細については、[イシュー473739](https://gitlab.com/gitlab-org/gitlab/-/issues/473739#workaround)を参照してください。

{{< /alert >}}

## コンテナイメージ {#container-images}

Linux上のRunnerは`docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor)を使用しているため、`.gitlab-ci.yml`ファイルで[`image`](../../yaml/_index.md#image)を定義することで、任意のコンテナイメージを選択できます。選択したDockerイメージが、プロセッサアーキテクチャと互換性があることを確認してください。

イメージが設定されていない場合、デフォルトは`ruby:3.1`です。

## Docker-in-Dockerのサポート {#docker-in-docker-support}

いずれかの`saas-linux-<size>-<architecture>`タグが付いたRunnerは、[Docker-in-Docker](../../docker/using_docker_build.md#use-docker-in-docker)をサポートするために、`privileged`モードで実行するように設定されています。これらのRunnerを使用すると、Dockerイメージをネイティブにビルドしたり、分離されたジョブで複数のコンテナを実行したりできます。

`gitlab-org`タグが付いたRunnerは、`privileged`モードで実行されず、Docker-in-Dockerビルドには使用できません。

## `.gitlab-ci.yml`ファイルの例 {#example-gitlab-ciyml-file}

`small`以外のマシンタイプを使用するには、ジョブに`tags:`キーワードを追加します。次に例を示します。

```yaml
job_small:
  script:
    - echo "This job is untagged and runs on the default small Linux x86-64 instance"

job_medium:
  tags:
    - saas-linux-medium-amd64
  script:
    - echo "This job runs on the medium Linux x86-64 instance"

job_large:
  tags:
    - saas-linux-large-arm64
  script:
    - echo "This job runs on the large Linux Arm64 instance"
```

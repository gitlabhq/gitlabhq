---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linux上のホストされたRunner
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com

{{< /details >}}

GitLab.com向けのLinux上のホストされたRunnerは、Google Cloud Compute Engineで実行されます。各ジョブは、完全に分離された一時的な仮想マシン（VM）を取得します。デフォルトのリージョンは`us-east1`です。

各仮想マシン（VM）は、Google Container-Optimized OS(COS)と、`docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor) を実行するDocker Engineの最新バージョンを使用します。マシンタイプと基盤となるプロセッサタイプが異なる可能性があります。また、ジョブが特定のプロセッサ設計に最適化されている場合、動作に一貫性がない可能性があります。

[タグなし](../../yaml/_index.md#tags)ジョブは、`small` Linux x86-64 Runnerで実行されます。

## Linux - x86-64で使用可能なマシンタイプ

GitLabは、Linux x86-64上のホストされたRunnerに対して、次のマシンタイプを提供しています。

| Runnerタグ                                             | vCPU | メモリ | ストレージ |
|--------------------------------------------------------|-------|--------|---------|
| `saas-linux-small-amd64` (デフォルト)                     | 2     | 8 GB   | 30 GB   |
| `saas-linux-medium-amd64`                              | 4     | 16 GB  | 50 GB   |
| `saas-linux-large-amd64` (Premium および Ultimate のみ)   | 8     | 32 GB  | 100 GB  |
| `saas-linux-xlarge-amd64` (Premium および Ultimate のみ)  | 16    | 64 GB  | 200 GB  |
| `saas-linux-2xlarge-amd64` (Premium および Ultimate のみ) | 32    | 128 GB | 200 GB  |

## Linux - Arm64で使用可能なマシンタイプ

GitLabは、Linux Arm64上のホストされた Runnerに対して、次のマシンタイプを提供しています。

| Runnerタグ                                            | vCPU | メモリ | ストレージ |
|-------------------------------------------------------|-------|--------|---------|
| `saas-linux-small-arm64`                              | 2     | 8 GB   | 30 GB   |
| `saas-linux-medium-arm64` (Premium および Ultimate のみ) | 4     | 16 GB  | 50 GB   |
| `saas-linux-large-arm64` (Premium および Ultimate のみ)  | 8     | 32 GB  | 100 GB  |

{{< alert type="note" >}}

Linux Arm上のホストされたRunnerでDocker-in-Dockerを使用すると、ユーザーはネットワーク接続の問題が発生する可能性があります。この問題は、Google Cloud と Dockerの最大伝送ユニット(MTU)値が一致しない場合に発生します。この問題を解決するには、クライアント側のDocker設定で`--mtu=1400`を設定してください。詳細については、[イシュー473739](https://gitlab.com/gitlab-org/gitlab/-/issues/473739#workaround)を参照してください。

{{< /alert >}}

## コンテナイメージ

Linux上のRunner は`docker+machine` [executor](https://docs.gitlab.com/runner/executors/#docker-machine-executor)を使用しているため、[`image`](../../yaml/_index.md#image)を`.gitlab-ci.yml`ファイルで定義することで、任意のコンテナイメージを選択できます。選択したDockerイメージが、プロセッサアーキテクチャと互換性があることを確認してください。

イメージが設定されていない場合、デフォルトは`ruby:3.1`です。

## Docker-in-Dockerのサポート

いずれかの`saas-linux-<size>-<architecture>`タグが付いたRunnerは、[Docker-in-Docker](../../docker/using_docker_build.md#use-docker-in-docker)をサポートするために、`privileged`モードで実行するように構成されています。これらのRunnerを使用すると、Dockerイメージをネイティブにビルドしたり、分離されたジョブで複数のコンテナを実行したりできます。

`gitlab-org`タグが付いたRunnerは、`privileged`モードで実行されず、Docker-in-Dockerビルドには使用できません。

## `.gitlab-ci.yml`ファイルの例

`small`以外のマシンタイプを使用するには、ジョブに`tags:`キーワードを追加します。例は次のとおりです。

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

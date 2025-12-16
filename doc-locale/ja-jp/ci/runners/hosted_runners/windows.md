---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Windows上でホストされるRunner
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

Windows上のRunnerは、Google Cloud Platform上で仮想マシンを起動することで、オートスケールします。このソリューションでは、GitLabが[custom executor](https://docs.gitlab.com/runner/executors/custom.html)用に開発した[オートスケーリングドライバー](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/blob/main/docs/README.md)を使用します。Windows上のホストされたRunnerは、[ベータ](../../../policy/development_stages_support.md#beta)版です。

安定した状態でWindows Runnerを取得し、[一般提供](../../../policy/development_stages_support.md#generally-available)するために、イテレーションを継続したいと考えています。この目標に向けた取り組みは、[関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/2162)で追跡できます。

## Windowsで使用可能なマシンタイプ {#machine-types-available-for-windows}

GitLabは、Windows上のホストされたRunnerに対して、次のマシンタイプを提供しています。

| Runnerタグ                  | vCPU | メモリ | ストレージ |
| --------------------------- | ----- | ------ | ------- |
| `saas-windows-medium-amd64` | 2     | 7.5 GB | 75 GB   |

## サポートされているWindowsバージョン {#supported-windows-versions}

Windows Runnerの仮想マシンインスタンスは、GitLab Docker executorを使用しません。つまり、[`image`](../../yaml/_index.md#image)または[`services`](../../yaml/_index.md#services)をパイプライン設定で指定できません。

以下のWindowsバージョンのいずれかでジョブを実行できます:

| バージョン      | ステータス |
|--------------|--------|
| Windows 2022 | `GA`   |

利用可能なプリインストール済みソフトウェアの完全なリストは、[プリインストール済みソフトウェアのドキュメント](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/attributes/default.rb)にあります。

## サポートされているShell {#supported-shell}

Windows上のホストされたRunnerは、ShellとしてPowerShellが設定されています。したがって、`.gitlab-ci.yml`ファイルの`script`セクションには、PowerShellコマンドが必要です。

## `.gitlab-ci.yml`ファイルの例 {#example-gitlab-ciyml-file}

この`.gitlab-ci.yml`ファイルを使用して、Windows上のホストされたRunnerの使用を開始します:

```yaml
.windows_job:
  tags:
    - saas-windows-medium-amd64
  before_script:
    - Set-Variable -Name "time" -Value (date -Format "%H:%m")
    - echo ${time}
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

build:
  extends:
    - .windows_job
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .windows_job
  stage: test
  script:
    - echo "running scripts in the test job"
```

## 既知の問題 {#known-issues}

- ベータ機能のサポートの詳細については、[ベータ](../../../policy/development_stages_support.md#beta)を参照してください。
- 新しいWindows仮想マシン（VM）の平均プロビジョニング時間は5分であるため、ベータ版ではWindows Runnerフリートでのビルドの開始時間が遅くなることがあります。仮想マシンの事前プロビジョニングを有効にするためにオートスケーラーを更新することは、将来のリリースで提案されています。この更新は、Windowsフリート上のVMをプロビジョニングするのにかかる時間を大幅に短縮することを目的としています。詳細については、[イシュー32](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/issues/32)を参照してください。
- Windowsフリートは、メンテナンスまたはアップデートのために一時的に利用できなくなる場合があります。
- ジョブは、Linux Runnerよりも長く保留状態になる場合があります。
- Windows Runnerフリートを使用しているパイプラインのアップデートを必要とする破壊的な変更を導入する可能性があります。

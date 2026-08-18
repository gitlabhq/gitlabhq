---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Windows의 호스팅된 러너
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태: 베타

{{< /details >}}

Windows의 호스팅된 러너는 Google Cloud Platform에서 가상 머신을 시작하여 자동 크기 조정합니다. 이 솔루션은 [자동 크기 조정 드라이버](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/blob/main/docs/README.md)를 사용하며 이는 GitLab에서 [사용자 지정 실행기](https://docs.gitlab.com/runner/executors/custom/)를 위해 개발되었습니다. Windows의 호스팅된 러너는 [베타](../../../policy/development_stages_support.md#beta) 상태입니다.

GitLab은 Windows 러너를 안정적인 상태로 만들기 위해 계속 반복하고 있으며 [일반적으로 사용 가능](../../../policy/development_stages_support.md#generally-available)하게 하고자 합니다. [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/2162)에서 이 목표를 향한 작업을 추적할 수 있습니다.

## Windows에서 사용 가능한 머신 유형 {#machine-types-available-for-windows}

GitLab은 Windows의 호스팅된 러너를 위해 다음 머신 유형을 제공합니다.

| 러너 태그                  | vCPU | 메모리 | 스토리지 |
| --------------------------- | ----- | ------ | ------- |
| `saas-windows-medium-amd64` | 2     | 7.5 GB | 75 GB   |

## 지원되는 Windows 버전 {#supported-windows-versions}

Windows 러너 가상 머신 인스턴스는 GitLab Docker 실행기를 사용하지 않습니다. 이는 파이프라인 구성에서 [`image`](../../yaml/_index.md#image) 또는 [`services`](../../yaml/_index.md#services)를 지정할 수 없다는 의미입니다.

다음 Windows 버전 중 하나에서 작업을 실행할 수 있습니다:

| 버전      | 상태 |
|--------------|--------|
| Windows 2022 | `GA`   |

[사전 설치된 소프트웨어 설명서](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/blob/main/cookbooks/preinstalled-software/attributes/default.rb)에서 사용 가능한 사전 설치된 소프트웨어의 전체 목록을 확인할 수 있습니다.

## 지원되는 셸 {#supported-shell}

Windows의 호스팅된 러너에는 PowerShell이 셸로 구성되어 있습니다. `script` 섹션(your `.gitlab-ci.yml` 파일의)은 따라서 PowerShell 명령이 필요합니다.

## `.gitlab-ci.yml` 파일 예제 {#example-gitlab-ciyml-file}

이 `.gitlab-ci.yml` 파일 예제를 사용하여 Windows의 호스팅된 러너를 시작하세요:

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

## 알려진 이슈 {#known-issues}

- 베타 기능 지원에 대한 자세한 내용은 [베타](../../../policy/development_stages_support.md#beta)를 참조하세요.
- 새로운 Windows 가상 머신(VM)의 평균 프로비저닝 시간은 5분이므로 베타 기간에 Windows 러너 플릿에서 빌드의 시작 시간이 더 길어질 수 있습니다. 가상 머신의 사전 프로비저닝을 활성화하도록 자동 크기 조정 프로그램을 업데이트하는 것이 향후 릴리스에서 제안되었습니다. 이 업데이트는 Windows 플릿에서 VM을 프로비저닝하는 데 걸리는 시간을 크게 줄이기 위한 것입니다. 자세한 내용은 [이슈 32](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/autoscaler/-/issues/32)를 참조하세요.
- Windows 러너 플릿은 유지보수 또는 업데이트를 위해 가끔 사용할 수 없을 수 있습니다.
- 작업은 Linux 러너보다 더 오래 보류 중 상태로 유지될 수 있습니다.
- Windows 러너 플릿을 사용하는 파이프라인 업데이트를 필요로 하는 주요 변경 사항을 도입할 가능성이 있습니다.

---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux의 호스팅된 러너
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

GitLab.com의 Linux용 호스팅된 러너는 Google Cloud Compute Engine에서 실행됩니다. 각 작업은 완전히 격리되고 임시적인 가상 머신(VM)을 받습니다. 기본 영역은 `us-east1`입니다.

각 VM은 Google Container-Optimized OS(COS)와 최신 버전의 Docker Engine을 사용하며 `docker+machine` [실행기](https://docs.gitlab.com/runner/executors/#docker-machine-executor)를 실행합니다. 머신 타입과 기본 프로세서 타입이 변경될 수 있습니다. 특정 프로세서 설계에 최적화된 작업은 일관성 없이 작동할 수 있습니다.

[태그가 지정되지 않은](../../yaml/_index.md#tags) 작업은 `small` Linux x86-64 러너에서 실행됩니다.

## Linux - x86-64에서 사용 가능한 머신 타입 {#machine-types-available-for-linux---x86-64}

GitLab은 Linux x86-64의 호스팅된 러너에 대해 다음과 같은 머신 타입을 제공합니다.

<table id="x86-runner-specs" aria-label="Linux x86-64에서 사용 가능한 머신 타입">
  <thead>
    <tr>
      <th>러너 태그</th>
      <th>vCPU</th>
      <th>메모리</th>
      <th>스토리지</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-small-amd64</code> (기본값)
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
        <code class="runner-tag">saas-linux-large-amd64</code> (Premium 및 Ultimate만 해당)
      </td>
      <td class="vcpus">8</td>
      <td>32GB</td>
      <td>100 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-xlarge-amd64</code> (Premium 및 Ultimate만 해당)
      </td>
      <td class="vcpus">16</td>
      <td>64 GB</td>
      <td>200 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-2xlarge-amd64</code> (Premium 및 Ultimate만 해당)
      </td>
      <td class="vcpus">32</td>
      <td>128 GB</td>
      <td>200 GB</td>
    </tr>
  </tbody>
</table>

## Linux - Arm64에서 사용 가능한 머신 타입 {#machine-types-available-for-linux---arm64}

GitLab은 Linux Arm64의 호스팅된 러너에 대해 다음과 같은 머신 타입을 제공합니다.

<table id="arm64-runner-specs" aria-label="Linux Arm64에서 사용 가능한 머신 타입">
  <thead>
    <tr>
      <th>러너 태그</th>
      <th>vCPU</th>
      <th>메모리</th>
      <th>스토리지</th>
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
        <code class="runner-tag">saas-linux-medium-arm64</code> (Premium 및 Ultimate만 해당)
      </td>
      <td class="vcpus">4</td>
      <td>16 GB</td>
      <td>50 GB</td>
    </tr>
    <tr>
      <td>
        <code class="runner-tag">saas-linux-large-arm64</code> (Premium 및 Ultimate만 해당)
      </td>
      <td class="vcpus">8</td>
      <td>32GB</td>
      <td>100 GB</td>
    </tr>
  </tbody>
</table>

> [!note]
> 사용자는 Linux Arm에서 호스팅된 러너와 함께 Docker-in-Docker를 사용할 때 네트워크 연결 문제를 경험할 수 있습니다. 이 문제는 Google Cloud와 Docker의 최대 전송 단위(MTU) 값이 일치하지 않을 때 발생합니다. 이 문제를 해결하려면 클라이언트 측 Docker 구성에서 `--mtu=1400`을 설정합니다. 자세한 내용은 [이슈 473739](https://gitlab.com/gitlab-org/gitlab/-/issues/473739#workaround)를 참조하세요.

## 컨테이너 이미지 {#container-images}

Linux의 러너가 `docker+machine` [실행기](https://docs.gitlab.com/runner/executors/#docker-machine-executor)를 사용하고 있으므로 `.gitlab-ci.yml` 파일에서 [`image`](../../yaml/_index.md#image)를 정의하여 모든 컨테이너 이미지를 선택할 수 있습니다. 선택한 Docker 이미지가 프로세서 아키텍처와 호환되는지 확인합니다.

이미지를 설정하지 않으면 기본값은 `ruby:3.1`입니다.

## Docker-in-Docker 지원 {#docker-in-docker-support}

`saas-linux-<size>-<architecture>` 태그가 있는 러너는 [Docker-in-Docker](../../docker/using_docker_build.md#use-docker-in-docker)를 지원하기 위해 `privileged` 모드에서 실행되도록 구성되어 있습니다. 이러한 러너를 사용하면 Docker 이미지를 기본적으로 빌드하거나 격리된 작업에서 여러 컨테이너를 실행할 수 있습니다.

`gitlab-org` 태그가 있는 러너는 `privileged` 모드에서 실행되지 않으며 Docker-in-Docker 빌드에 사용할 수 없습니다.

## `.gitlab-ci.yml` 파일 예제 {#example-gitlab-ciyml-file}

`small` 이외의 머신 타입을 사용하려면 작업에 `tags:` 키워드를 추가합니다. 예를 들어:

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

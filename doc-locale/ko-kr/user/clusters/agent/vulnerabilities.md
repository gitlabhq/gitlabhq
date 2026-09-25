---
stage: Application Security Testing
group: Composition analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Kubernetes 클러스터의 컨테이너 이미지를 취약성에 대해 검사합니다.
title: 운영 컨테이너 스캔
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 지원되는 아키텍처 {#supported-architectures}

운영 컨테이너 검사(OCS)는 `linux/arm64` 및 `linux/amd64`에 지원됩니다.

## 운영 컨테이너 검사 활성화 {#enable-operational-container-scanning}

OCS를 사용하여 클러스터의 컨테이너 이미지를 보안 취약성에 대해 검사할 수 있습니다. OCS는 [래퍼 이미지](https://gitlab.com/gitlab-org/security-products/analyzers/trivy-k8s-wrapper) 주변의 [Trivy](https://github.com/aquasecurity/trivy)를 사용하여 취약성에 대한 이미지를 검사합니다.

OCS는 `agent config` 또는 프로젝트의 검사 실행 정책을 사용하여 주기에 맞춰 실행되도록 구성할 수 있습니다.

> [!note]
> `agent config` 및 `scan execution policies` 모두 구성되어 있으면 `scan execution policy`의 구성이 우선합니다.

### 에이전트 구성을 통해 활성화 {#enable-via-agent-configuration}

에이전트 구성을 통해 Kubernetes 클러스터 내의 이미지 검사를 활성화하려면 `container_scanning` 구성 블록을 에이전트 구성에 추가하고 검사가 실행될 때를 나타내는 [CRON 식](https://en.wikipedia.org/wiki/Cron)을 포함하는 `cadence` 필드를 추가합니다.

```yaml
container_scanning:
  cadence: '0 0 * * *' # Daily at 00:00 (Kubernetes cluster time)
```

`cadence` 필드는 필수입니다. GitLab은 주기 필드에 대해 다음 유형의 CRON 구문을 지원합니다:

- 지정된 시간에 시간당 한 번의 일일 주기입니다. 예: `0 18 * * *`
- 지정된 요일 및 지정된 시간에 주당 한 번의 주간 주기입니다. 예: `0 13 * * 0`

> [!note]
> [CRON 구문](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)의 다른 요소들은 구현에 사용되는 [cron](https://github.com/robfig/cron)에서 지원하는 경우 주기 필드에서 작동할 수 있습니다. 그러나 GitLab은 공식적으로 이들을 테스트하거나 지원하지 않습니다.
>
> CRON 식은 Kubernetes 에이전트 pod의 시스템 시간을 사용하여 [UTC](https://www.timeanddate.com/worldclock/timezone/utc)로 평가됩니다.

기본적으로 운영 컨테이너 검사는 취약성에 대해 어떤 워크로드도 검사하지 않습니다. `vulnerability_report` 블록을 검사할 네임스페이스를 선택하는 데 사용할 수 있는 `namespaces` 필드로 설정할 수 있습니다. 예를 들어 `default`, `kube-system` 네임스페이스만 검사하려는 경우 다음 구성을 사용할 수 있습니다:

```yaml
container_scanning:
  cadence: '0 0 * * *'
  vulnerability_report:
    namespaces:
      - default
      - kube-system
```

모든 대상 네임스페이스에 대해 다음 워크로드 리소스의 모든 이미지가 기본적으로 검사됩니다:

- Pod
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- Job

이는 [Trivy Kubernetes 리소스 감지 구성](#configure-trivy-kubernetes-resource-detection)으로 사용자 지정할 수 있습니다.

### 검사 실행 정책을 통해 활성화 {#enable-via-scan-execution-policies}

검사 실행 정책을 사용하여 Kubernetes 클러스터에서 이미지 검사를 활성화하려면 [검사 실행 정책 편집기](../../application_security/policies/scan_execution_policies.md#scan-execution-policy-editor)를 사용하여 새 일정 규칙을 만듭니다.

> [!note]
> 실행 중인 컨테이너 이미지를 검사하려면 Kubernetes 에이전트가 클러스터에서 실행 중이어야 합니다

운영 컨테이너 검사는 GitLab 파이프라인과 독립적으로 작동합니다. 검사 실행 정책에서 구성된 예약된 시간에 새 검사를 시작하는 Kubernetes 에이전트에 의해 완전히 자동화되고 관리됩니다. 에이전트는 클러스터 내에 전용 작업을 생성하여 검사를 수행하고 결과를 GitLab에 다시 보고합니다.

다음은 Kubernetes 에이전트가 연결된 클러스터 내에서 운영 컨테이너 검사를 활성화하는 정책의 예입니다:

```yaml
- name: Enforce container scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

일정 규칙의 키는 다음과 같습니다:

- `cadence` (필수): 검사가 실행될 때를 나타내는 [CRON 식](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)
- `agents:<agent-name>` (필수): 검사에 사용할 에이전트의 이름
- `agents:<agent-name>:namespaces` (필수): 검사할 Kubernetes 네임스페이스입니다.

> [!note]
> [CRON 구문](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm)의 다른 요소들은 구현에 사용되는 [cron](https://github.com/robfig/cron)에서 지원하는 경우 주기 필드에서 작동할 수 있습니다. 그러나 GitLab은 공식적으로 이들을 테스트하거나 지원하지 않습니다.
>
> CRON 식은 Kubernetes 에이전트 pod의 시스템 시간을 사용하여 [UTC](https://www.timeanddate.com/worldclock/timezone/utc)로 평가됩니다.

[검사 실행 정책 설명서](../../application_security/policies/scan_execution_policies.md#scan-execution-policies-schema) 내에서 전체 스키마를 볼 수 있습니다.

## 다중 클러스터 구성을 위한 OCS 취약성 해결 {#ocs-vulnerability-resolution-for-multi-cluster-configuration}

OCS로 정확한 취약성 추적을 보장하려면 각 클러스터에 대해 OCS가 활성화된 별도의 GitLab 프로젝트를 만들어야 합니다. 여러 클러스터가 있으면 각 클러스터에 하나의 프로젝트를 사용해야 합니다.

OCS는 현재 검사 취약성을 이전에 감지된 취약성과 비교하여 각 검사 후 클러스터에서 더 이상 발견되지 않는 취약성을 해결합니다. 이전 검사의 취약성 중 현재 검사에 더 이상 존재하지 않는 항목은 GitLab 프로젝트에 대해 해결됩니다.

여러 클러스터가 동일한 프로젝트에서 구성되어 있으면 한 클러스터(예: 프로젝트 A)의 OCS 검사가 다른 클러스터(예: 프로젝트 B)에서 이전에 감지된 취약성을 해결하여 부정확한 취약성 보고가 발생합니다.

## 스캐너 리소스 요구 사항 구성 {#configure-scanner-resource-requirements}

기본적으로 스캐너 pod의 기본 리소스 요구 사항은 다음과 같습니다:

```yaml
requests:
  cpu: 100m
  memory: 100Mi
  ephemeral_storage: 1Gi
limits:
  cpu: 500m
  memory: 500Mi
  ephemeral_storage: 3Gi
```

`resource_requirements` 필드로 사용자 지정할 수 있습니다.

```yaml
container_scanning:
  resource_requirements:
    requests:
      cpu: '0.2'
      memory: 200Mi
      ephemeral_storage: 2Gi
    limits:
      cpu: '0.7'
      memory: 700Mi
      ephemeral_storage: 4Gi
```

CPU에 분수 값을 사용할 때 값을 문자열로 형식화합니다.

> [!note]
>
> - 검사 실행 정책을 통해 운영 컨테이너 검사가 활성화된 경우에도 에이전트 구성 파일을 사용하여 리소스 요구 사항을 설정해야 합니다.
> - Kubernetes 오케스트레이션에 GKE(Google Kubernetes Engine)를 사용할 때 [임시 스토리지 제한이 자동으로 요청과 같게 설정됩니다](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests#resource-limits).

## Trivy K8s 래퍼의 사용자 지정 리포지토리 {#custom-repository-for-trivy-k8s-wrapper}

검사 중에 OCS는 [Trivy K8s 래퍼 리포지토리](https://gitlab.com/security-products/trivy-k8s-wrapper/container_registry/5992609)의 이미지를 사용하여 pod를 배포합니다. 이는 [Trivy Kubernetes](https://aquasecurity.github.io/trivy/v0.54/docs/target/kubernetes)에서 생성한 취약성 보고서를 OCS에 전송합니다.

클러스터 방화벽이 Trivy K8s 래퍼 리포지토리에 대한 액세스를 제한하면 OCS를 구성하여 사용자 지정 리포지토리에서 이미지를 가져올 수 있습니다. 호환성을 위해 사용자 지정 리포지토리가 Trivy K8s 래퍼 리포지토리를 미러링하는지 확인합니다.

```yaml
container_scanning:
  trivy_k8s_wrapper_image:
    repository: "your-custom-registry/your-image-path"
```

## 검사 시간 제한 구성 {#configure-scan-timeout}

{{< history >}}

- GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/497460)되었습니다.

{{< /history >}}

기본적으로 Trivy 검사는 5분 후에 시간 제한됩니다. 에이전트 자체는 체인 configmaps를 읽고 취약성을 전송하기 위해 추가 15분을 제공합니다.

Trivy 시간 제한 기간을 사용자 지정하려면:

- `scanner_timeout` 필드로 시간(초)을 지정합니다.

예를 들어:

```yaml
container_scanning:
  scanner_timeout: "3600s" # 60 minutes
```

## Trivy 보고서 크기 구성 {#configure-trivy-report-size}

{{< history >}}

- GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/497460)되었습니다.

{{< /history >}}

기본적으로 Trivy 보고서는 100MB로 제한되며, 이는 대부분의 검사에 충분합니다. 그러나 워크로드가 많으면 제한을 늘려야 할 수도 있습니다.

이렇게 하려면 다음을 수행합니다.

- `report_max_size` 필드로 바이트 단위의 제한을 지정합니다.

예를 들어:

```yaml
container_scanning:
  report_max_size: "300000000" # 300 MB
```

## Trivy Kubernetes 리소스 감지 구성 {#configure-trivy-kubernetes-resource-detection}

{{< history >}}

- GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/431707)되었습니다.

{{< /history >}}

기본적으로 Trivy는 스캔 가능한 이미지를 발견하기 위해 다음 Kubernetes 리소스 유형을 찾습니다:

- Pod
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- Job
- Deployment

Trivy가 발견하는 Kubernetes 리소스 유형을 제한할 수 있습니다. 예를 들어 "활성" 이미지만 검사합니다.

이렇게 하려면 다음을 수행합니다.

- `resource_types` 필드로 리소스 유형을 지정합니다:

  ```yaml
  container_scanning:
    vulnerability_report:
      resource_types:
        - Deployment
        - Pod
        - Job
  ```

## Trivy 보고서 아티팩트 삭제 구성 {#configure-trivy-report-artifact-deletion}

{{< history >}}

- GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/480845)되었습니다.

{{< /history >}}

기본적으로 Kubernetes용 GitLab 에이전트는 검사 완료 후 Trivy 보고서 아티팩트를 삭제합니다.

에이전트를 구성하여 보고서 아티팩트를 보존할 수 있으므로 보고서를 원시 상태로 볼 수 있습니다.

이렇게 하려면 다음을 수행합니다.

- `delete_report_artifact`을 `false`로 설정합니다:

  ```yaml
  container_scanning:
    delete_report_artifact: false
  ```

## Trivy 심각도 임계값 필터 구성 {#configure-trivy-severity-threshold-filter}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)되었습니다.

{{< /history >}}

OCS는 기본적으로 모든 [심각도](../../application_security/vulnerabilities/severities.md) 수준에 대해 취약성을 검사합니다.

특정 심각도 수준 이상의 취약성만 보고하려면 구성 변수 `severity_threshold`을 해당 값으로 설정합니다. 심각도 임계값을 설정한 후, 선택한 심각도 이하의 취약성은 더 이상 취약성 보고서, API 페이로드 및 기타 보고 메커니즘에서 반환되지 않습니다.

이를 통해 조직의 위험 허용도 요구 사항을 충족하는 취약성에 집중할 수 있습니다.

지원되는 임계값은 `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`입니다.

예를 들어 높은 심각도 및 중대 심각도의 취약성을 보고하려면:

```yaml
container_scanning:
  severity_threshold: "HIGH"
```

## 클러스터 취약성 보기 {#view-cluster-vulnerabilities}

GitLab에서 취약성 정보를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 에이전트 구성 파일이 포함된 프로젝트를 찾습니다.
1. **운영** > **Kubernetes 클러스터**를 선택합니다.
1. **에이전트** 탭을 선택합니다.
1. 클러스터 취약성을 보려면 에이전트를 선택합니다.

![클러스터 에이전트 보안 탭 UI](img/cluster_agent_security_tab_v14_8.png)

이 정보는 [운영 취약성](../../application_security/vulnerability_report/_index.md#operational-vulnerabilities) 아래에서도 확인할 수 있습니다.

> [!note]
> 개발자, 유지보수 또는 소유자 역할이 있어야 합니다.

## 프라이빗 이미지 검사 {#scanning-private-images}

프라이빗 이미지를 검사하려면 스캐너가 이미지 풀 시크릿(직접 참조 및 서비스 계정)에 의존하여 이미지를 가져옵니다.

## 알려진 이슈 {#known-issues}

GitLab Kubernetes 에이전트 16.9 이상에서는 운영 컨테이너 검사:

- 최대 100MB의 Trivy 보고서를 처리합니다. 이전 릴리스의 경우 이 제한은 10MB입니다.
- GitLab Kubernetes 에이전트가 `fips` 모드에서 실행될 때 비활성화됩니다.

## 문제 해결 {#troubleshooting}

### `Error running Trivy scan. Container terminated reason: OOMKilled` {#error-running-trivy-scan-container-terminated-reason-oomkilled}

스캔할 리소스가 너무 많거나 스캔 중인 이미지가 크면 OCS가 OOM 오류로 실패할 수 있습니다.

이를 해결하려면 [리소스 요구 사항을 구성](#configure-scanner-resource-requirements)하여 사용 가능한 메모리를 늘립니다.

### `Pod ephemeral local storage usage exceeds the total limit of containers` {#pod-ephemeral-local-storage-usage-exceeds-the-total-limit-of-containers}

기본 임시 스토리지가 낮은 Kubernetes 클러스터의 경우 OCS 검사가 실패할 수 있습니다. 예를 들어 [GKE 자동 조종장치](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests#defaults)는 기본 임시 스토리지를 1GB로 설정합니다. OCS가 큰 이미지가 있는 네임스페이스를 검사할 때 OCS에 필요한 모든 데이터를 저장할 충분한 공간이 없을 수 있으므로 이는 OCS에 대한 문제입니다.

이를 해결하려면 [리소스 요구 사항을 구성](#configure-scanner-resource-requirements)하여 사용 가능한 임시 스토리지를 늘립니다.

이 문제를 나타내는 또 다른 메시지는 `OCS Scanning pod evicted due to low resources. Please configure higher resource limits.`일 수 있습니다.

### `Error running Trivy scan due to context timeout` {#error-running-trivy-scan-due-to-context-timeout}

Trivy가 검사를 완료하는 데 너무 오래 걸리면 OCS가 검사 완료에 실패할 수 있습니다. 기본 검사 시간 제한은 5분이며 에이전트가 결과를 읽고 취약성을 전송하는 데 15분이 추가됩니다.

이를 해결하려면 [스캐너 시간 제한을 구성](#configure-scan-timeout)하여 사용 가능한 메모리를 늘립니다.

### `trivy report size limit exceeded` {#trivy-report-size-limit-exceeded}

생성된 Trivy 보고서 크기가 기본 최대 제한보다 크면 OCS가 이 오류로 실패할 수 있습니다.

이를 해결하려면 [최대 Trivy 보고서 크기를 구성](#configure-trivy-report-size)하여 Trivy 보고서의 최대 허용 크기를 늘립니다.

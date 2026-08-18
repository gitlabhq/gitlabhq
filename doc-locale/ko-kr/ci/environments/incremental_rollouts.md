---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD를 사용한 점진적 롤아웃
description: "Kubernetes, CI/CD, 위험 완화 및 배포."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

애플리케이션에 변경 사항을 롤아웃할 때 위험 완화 전략으로 Kubernetes 파드의 일부에만 프로덕션 변경 사항을 릴리스할 수 있습니다. 프로덕션 변경 사항을 점진적으로 릴리스하면 오류율이나 성능 저하를 모니터링할 수 있으며, 문제가 없으면 모든 파드를 업데이트할 수 있습니다.

GitLab은 점진적 롤아웃을 사용하여 Kubernetes 프로덕션 시스템에 수동으로 트리거되는 롤아웃과 타이머가 설정된 롤아웃을 모두 지원합니다. 수동 롤아웃을 사용할 때 각 파드 트렌치의 릴리스가 수동으로 트리거됩니다. 타이머가 설정된 롤아웃에서는 기본 일시 중지 5분 후에 트렌치 단위로 릴리스가 수행됩니다. 타이머가 설정된 롤아웃은 일시 중지 기간이 만료되기 전에 수동으로 트리거할 수도 있습니다.

수동 및 타이머가 설정된 롤아웃은 [Auto DevOps](../../topics/autodevops/_index.md)로 제어되는 프로젝트에 자동으로 포함되지만 `.gitlab-ci.yml` 구성 파일을 통해 GitLab CI/CD에서도 구성할 수 있습니다.

수동으로 트리거되는 롤아웃은 지속적 배포로 구현할 수 있으며, 타이머가 설정된 롤아웃은 개입이 필요하지 않으므로 지속적 배포 전략의 일부가 될 수 있습니다. 필요한 경우 앱이 자동으로 배포되도록 두 가지 방법을 결합하고 필요하면 수동으로 개입할 수 있습니다.

다음 샘플 애플리케이션은 세 가지 옵션을 보여줍니다. 이를 참고하여 자신만의 애플리케이션을 빌드할 수 있습니다:

- [수동 점진적 롤아웃](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml)
- [타이머가 설정된 점진적 롤아웃](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml)
- [수동 및 타이머가 설정된 롤아웃 모두](https://gitlab.com/gl-release/incremental-timed-rollout-example/blob/master/.gitlab-ci.yml)

## 수동 롤아웃 {#manual-rollouts}

`.gitlab-ci.yml`을 통해 GitLab에서 점진적 롤아웃을 수동으로 수행하도록 구성할 수 있습니다. 수동 구성을 사용하면 이 기능을 더 효과적으로 제어할 수 있습니다. 점진적 롤아웃의 단계는 배포를 위해 정의된 파드의 수에 따라 달라지며, Kubernetes 클러스터를 생성할 때 구성됩니다.

예를 들어 애플리케이션에 10개의 파드가 있고 10% 롤아웃 작업이 실행되면 새 애플리케이션 인스턴스가 단일 파드에 배포되고 나머지 파드는 이전 애플리케이션 인스턴스를 표시합니다.

먼저 [템플릿을 수동으로 정의](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml#L100-103)합니다:

```yaml
.manual_rollout_template: &manual_rollout_template
  <<: *rollout_template
  stage: production
  when: manual
```

다음으로 [각 단계에 대한 롤아웃 양 정의](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml#L152-155)합니다:

```yaml
rollout 10%:
  <<: *manual_rollout_template
  variables:
    ROLLOUT_PERCENTAGE: 10
```

작업이 빌드된 후 작업의 이름 옆의 **실행**({{< icon name="play" >}})을 선택하여 각 스테이지의 파드를 릴리스합니다. 백분율이 낮은 작업을 실행하여 롤백할 수도 있습니다. 100%에 도달하면 이 방법을 사용하여 롤백할 수 없습니다. 배포를 롤백하려면 [배포 재시도 또는 롤백](deployments.md#retry-or-roll-back-a-deployment)을 참조하세요.

[배포 가능한 애플리케이션](https://gitlab.com/gl-release/incremental-rollout-example)을 사용할 수 있으며 수동으로 트리거되는 점진적 롤아웃을 보여줍니다.

## 타이머가 설정된 롤아웃 {#timed-rollouts}

타이머가 설정된 롤아웃은 수동 롤아웃과 동일한 방식으로 작동하지만 각 작업은 배포 전에 지정된 시간(분)의 지연으로 정의됩니다. 작업을 선택하면 카운트다운이 표시됩니다.

![진행 중인 타이머가 설정된 롤아웃입니다.](img/timed_rollout_v17_9.png)

이 기능을 수동 점진적 롤아웃과 결합하여 작업이 카운트다운을 수행한 후 배포하도록 할 수 있습니다.

먼저 [템플릿을 타이머가 설정된 것으로 정의](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L86-89)합니다:

```yaml
.timed_rollout_template: &timed_rollout_template
  <<: *rollout_template
  when: delayed
  start_in: 1 minutes
```

`start_in` 키를 사용하여 지연 기간을 정의할 수 있습니다:

```yaml
start_in: 1 minutes
```

다음으로 [각 단계에 대한 롤아웃 양 정의](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L97-101)합니다:

```yaml
timed rollout 30%:
  <<: *timed_rollout_template
  stage: timed rollout 30%
  variables:
    ROLLOUT_PERCENTAGE: 30
```

[배포 가능한 애플리케이션](https://gitlab.com/gl-release/timed-rollout-example)을 사용할 수 있으며 [타이머가 설정된 롤아웃의 구성을 보여줍니다](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L86-95).

## 블루-그린 배포 {#blue-green-deployment}

> [!note]
> 팀은 Ingress 주석을 활용하고 [트래픽 가중치 설정](../../user/project/canary_deployments.md#how-to-change-the-traffic-weight-on-a-canary-ingress-deprecated)을 하여 여기에 설명된 블루-그린 배포 전략의 대체 방식으로 사용할 수 있습니다.

A/B 배포 또는 빨강-검정 배포라고도 하는 이 기술은 배포 중에 다운타임과 위험을 줄이는 데 사용됩니다. 점진적 롤아웃과 결합하면 배포로 인한 이슈의 영향을 최소화할 수 있습니다.

이 기술에서는 두 가지 배포("블루" 및 "그린"이지만 모든 이름을 사용할 수 있음)가 있습니다. 점진적 롤아웃 중을 제외한 주어진 시간에 이러한 배포 중 하나만 활성화됩니다.

예를 들어 블루 배포는 프로덕션에서 활성화될 수 있고 그린 배포는 테스트를 위해 "활성화"되지만 프로덕션에 배포되지 않습니다. 이슈가 발견되면 프로덕션 배포(현재 블루)에 영향을 주지 않고 그린 배포를 업데이트할 수 있습니다. 테스트에서 이슈가 없으면 프로덕션을 그린 배포로 전환하고 블루는 다음 릴리스를 테스트할 수 있습니다.

이 프로세스는 프로덕션 배포를 중단하지 않고도 다른 배포로 전환할 필요가 없으므로 다운타임을 줄입니다. 두 배포는 병렬로 실행되며 언제든지 전환할 수 있습니다.

[배포 가능한 애플리케이션 예제](https://gitlab.com/gl-release/blue-green-example)를 사용할 수 있으며 [`.gitlab-ci.yml` CI/CD 구성 파일](https://gitlab.com/gl-release/blue-green-example/blob/master/.gitlab-ci.yml)은 블루-그린 배포를 보여줍니다.

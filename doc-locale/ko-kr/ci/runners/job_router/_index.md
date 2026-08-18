---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 라우터
description: 고급 작업 오케스트레이션을 위해 작업 라우터를 통해 CI/CD 작업을 라우팅합니다.
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/19607)되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `job_router`및 `job_router_instance_runners`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.9에서 [승인 제어 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/584394)되었으며 [플래그](../../../administration/feature_flags/_index.md) `job_router_admission_control`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

작업 라우터는 GitLab CI/CD를 위한 고급 작업 오케스트레이션 기능을 제공하는 GitLab Relay(KAS)의 구성 요소입니다. GitLab에서 직접 러너를 폴링하는 대신 러너가 작업 라우터에 연결하며, 이는 작업 배포를 관리하고 승인 제어 같은 기능을 제공합니다.

## 아키텍처 {#architecture}

```plaintext
GitLab Instance → Job Router (KAS) → Runner
                        ↓
              Runner Controller (optional)
```

작업 라우터의 기능:

- 러너에서 작업 요청을 수신합니다.
- 러너에 실행할 작업으로 응답합니다.
- 선택적으로 승인 결정을 위해 러너 컨트롤러와 협의합니다.

## 전제 조건 {#prerequisites}

작업 라우터를 사용하려면 다음이 필요합니다:

- 다음 기능 플래그가 `true`로 설정된 GitLab 인스턴스:
  - `job_router`: 그룹 및 프로젝트 러너용
  - `job_router_instance_runners`: 인스턴스 러너용
  - `job_router_admission_control`: 승인 제어용(선택 사항)
- `FF_USE_JOB_ROUTER` 환경 변수가 `true`로 설정된 GitLab Runner 18.9 이상.

## 작업 라우터 정보 검색 {#discover-job-router-information}

러너는 [작업 라우터 검색 API](../../../api/runners.md#discover-job-router-information)를 사용하여 작업 라우터 URL을 검색할 수 있습니다.

## 러너 컨트롤러 {#runner-controllers}

러너 컨트롤러는 작업 라우터를 통해 라우팅된 작업에 대한 승인 제어를 활성화합니다. 자세한 내용은 [러너 컨트롤러](runner_controllers.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [러너 컨트롤러](runner_controllers.md)
- [러너 컨트롤러 API](../../../api/runner_controllers.md)
- [러너 컨트롤러 범위 API](../../../api/runner_controllers.md#runner-controller-scopes)
- [러너 컨트롤러 토큰 API](../../../api/runner_controller_tokens.md)
- [튜토리얼: 러너 승인 컨트롤러 빌드](../../../tutorials/build_runner_admission_controller/_index.md)

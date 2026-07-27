---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 러너 컨트롤러
description: 러너 컨트롤러로 작업 승인을 제어합니다.
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 상태: 실험적 기능

{{< /details >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

{{< history >}}

- GitLab 18.9에서 [플래그](../../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229)되었으며 `job_router_admission_control`라고 이름이 지정됩니다. 기본적으로 비활성화되어 있습니다. 이 기능은 [실험](../../../policy/development_stages_support.md)이며 [GitLab 테스팅 동의](https://handbook.gitlab.com/handbook/legal/testing-agreement/)에 따릅니다.
- [러너 범위가 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/586417)되었습니다. GitLab 18.10.

{{< /history >}}

러너 컨트롤러는 [작업 라우터](_index.md)를 통해 라우팅되는 CI/CD 작업에 대한 승인 제어를 활성화합니다. 작업이 실행되려고 할 때 작업 라우터는 연결된 러너 컨트롤러에 승인 요청을 전송하며, 이는 커스텀 정책을 기반으로 작업을 승인하거나 거부할 수 있습니다.

러너 컨트롤러는 인스턴스 수준이며 [범위](#scoping) 지정에 따라 작업에 적용됩니다.

러너 컨트롤러를 사용하여:

- 이미지 허용 목록, 리소스 할당량 또는 보안 요구 사항과 같은 커스텀 승인 정책을 적용합니다.
- 작업 대기열 관리 및 용량 관리를 위한 리소스 할당을 제어합니다.
- 규정 준수 실행을 위해 작업이 실행 전에 조직 정책을 충족하는지 확인합니다.
- 비용 제어를 위해 예산 또는 리소스 제약 조건에 따른 작업 실행을 제한합니다.

## 승인 제어 워크플로우 {#admission-control-workflow}

러너 컨트롤러를 작업 라우터로 구성할 때 승인 제어 워크플로우는 다음과 같이 작동합니다:

1. 러너 컨트롤러가 작업 라우터에 연결됩니다.
1. 컨트롤러는 자신을 등록하고 승인 요청 처리를 시작합니다.
1. 작업에 승인이 필요하면 작업 라우터는 연결된 컨트롤러에 작업 세부정보를 전송합니다.
1. 컨트롤러는 커스텀 정책에 대해 작업을 평가합니다.
1. 컨트롤러는 승인 결정(승인 또는 사유와 함께 거부)을 전송합니다.
1. 작업 라우터는 작업 실행을 진행하거나 거부를 보고합니다.

## 거부 사유 보기 {#view-rejection-reasons}

러너 컨트롤러가 작업을 거부하면 작업은 `job_router_failure` 실패 사유로 인해 실패합니다. 작업 세부정보 페이지에는 다음을 포함하는 메시지가 표시됩니다:

- 작업 라우터 정보
- 러너 컨트롤러 정보
- 러너 컨트롤러에서 제공한 거부 사유

![러너 컨트롤러 거부 사유를 보여주는 작업 거부 메시지](img/job_rejection_message_v18_9.png)

### 드라이 런 모드 로깅 {#dry-run-mode-logging}

러너 컨트롤러가 `dry_run` 상태일 때 거부 결정은 적용되지 않지만 작업 라우터(KAS) 백엔드 로그에 정보 메시지로 기록됩니다. 이 로그를 사용하여 적용을 활성화하기 전에 컨트롤러의 동작을 검증합니다.

## 러너 컨트롤러 상태 {#runner-controller-states}

러너 컨트롤러는 다음 3가지 상태 중 하나입니다:

| 상태 | 설명 |
|-------|-------------|
| `disabled` | 러너 컨트롤러는 승인 요청을 수신하지 않습니다. 이것이 기본 상태입니다. |
| `enabled` | 러너 컨트롤러는 승인 요청을 수신하고 해당 결정이 작업 실행에 영향을 미칩니다. |
| `dry_run` | 러너 컨트롤러는 승인 요청을 수신합니다. 작업 라우터는 결정을 기록하지만 결정은 적용되지 않습니다. 적용을 활성화하기 전에 컨트롤러 동작을 검증하고 배포 위험을 줄이기 위해 이 상태를 전략적 롤아웃에 사용합니다. |

## 범위 {#scoping}

러너 컨트롤러는 활성화되려면 범위를 지정해야 합니다. 범위가 없는 러너 컨트롤러는 상태가 `enabled` 또는 `dry_run`일 때도 승인 요청을 수신하지 않습니다.

러너 컨트롤러는 상호 배타적인 2가지 범위 지정 유형을 지원합니다:

| 범위 | 설명 |
|-------|-------------|
| 인스턴스 | 러너 컨트롤러는 GitLab 인스턴스의 모든 러너에 대한 작업을 평가합니다. 이 범위는 러너 범위와 결합될 수 없습니다. |
| 러너 | 러너 컨트롤러는 특정 러너에만 작업을 평가합니다. 컨트롤러를 하나 이상의 러너로 범위 지정할 수 있습니다. 러너는 인스턴스 러너여야 합니다. |

추가 범위 유형(그룹, 프로젝트)은 [이슈 586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419)에서 제안되었습니다.

러너 컨트롤러 범위 지정을 관리하려면 [러너 컨트롤러 API](../../../api/runner_controllers.md)를 참조하세요.

## 러너 컨트롤러 관리 {#manage-runner-controllers}

러너 컨트롤러는 REST API를 통해 관리됩니다. 아직 러너 컨트롤러를 관리하는 UI가 없습니다.

- 러너 컨트롤러를 생성, 나열, 업데이트 또는 삭제하려면 [러너 컨트롤러 API](../../../api/runner_controllers.md)를 참조하세요.
- 러너 컨트롤러의 범위를 생성, 나열 또는 삭제하려면 [러너 컨트롤러 범위 API](../../../api/runner_controllers.md#runner-controller-scopes)를 참조하세요.
- 러너 컨트롤러의 인증 토큰을 관리하려면 [러너 컨트롤러 토큰 API](../../../api/runner_controller_tokens.md)를 참조하세요.

전제 조건:

- GitLab 인스턴스에 대한 관리자(administrator) 액세스 권한이 있어야 합니다.

## 러너 컨트롤러 구현 {#implement-a-runner-controller}

단계별 가이드는 [튜토리얼: 러너 승인 컨트롤러 빌드](../../../tutorials/build_runner_admission_controller/_index.md)

자신의 러너 컨트롤러를 구현하려면 다음을 수행해야 합니다:

1. GitLab에서 러너 컨트롤러를 생성합니다.
1. 러너 컨트롤러의 범위를 지정합니다.
1. 러너 컨트롤러 토큰을 가져옵니다.
1. 토큰을 사용하여 작업 라우터에 연결합니다.
1. 작업 라우터에 컨트롤러를 등록합니다.
1. 승인 요청을 처리하고 결정을 전송합니다.

기술 사양 및 protobuf 정의는 GitLab Agent for Kubernetes 리포지토리의 [러너 컨트롤러 설명서](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [작업 라우터](_index.md)
- [러너 컨트롤러 API](../../../api/runner_controllers.md)
- [러너 컨트롤러 범위 API](../../../api/runner_controllers.md#runner-controller-scopes)
- [러너 컨트롤러 토큰 API](../../../api/runner_controller_tokens.md)
- [튜토리얼: 러너 승인 컨트롤러 빌드](../../../tutorials/build_runner_admission_controller/_index.md)
- [러너 컨트롤러 예제](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example) (참조 구현)

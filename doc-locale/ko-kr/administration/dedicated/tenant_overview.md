---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated 인스턴스의 상태를 확인하고 Switchboard에서 유지 보수 윈도우를 검색합니다.
title: GitLab Dedicated 인스턴스 세부 정보
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

Switchboard **개요** 페이지에서는 GitLab Dedicated 인스턴스의 현재 상태(상태 및 유지 보수 일정 포함)를 표시합니다. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인하여 인스턴스 세부 정보를 확인합니다.

페이지에는 다음이 표시됩니다:

- 인스턴스 상태
- 테넌트 URL
- GitLab 버전
- 참조 아키텍처
- [구매한 총 스토리지](create_instance/storage_types.md#total-purchased-storage)
- 유지 보수 윈도우
- 기본 AWS 리전 및 가용 영역 ID
- 보조 AWS 리전 및 가용 영역 ID
- 백업 AWS 리전
- 테넌트 AWS 계정 ID
- 호스팅되는 러너(구성된 경우)

## 인스턴스 상태 표시기 {#instance-status-indicators}

| 상태                   | 심각도 | 영향                                                      | 설명 |
| ------------------------ | -------- | ----------------------------------------------------------- | ----------- |
| **Normal**               | 없음     | 활성 인시던트 없습니다.                                        | GitLab 인스턴스에 알려진 이슈가 없습니다. |
| **Degraded performance** | S2       | GitLab의 핵심 기능이 크게 영향을 받습니다.        | GitLab 서비스가 느리거나 응답하지 않을 수 있습니다. |
| **Service disruption**   | S1       | GitLab을 실행하는 데 필요한 하나 이상의 서비스가 완전히 중단됩니다. | GitLab 서비스를 사용할 수 없을 수 있습니다. |
| **Under maintenance**    | N/A      | 유지 보수가 진행 중입니다.                                 | GitLab 서비스가 중단될 수 있습니다. |

Switchboard는 다음을 표시하지 않습니다:

- 인스턴스에 미미한 영향을 미치는 S3 및 S4 인시던트
- 검토 중이거나 문서화되거나 취소된 인시던트와 같이 영향을 미치지 않는 수명 주기 스테이지의 인시던트
- 여러 알림이 통합될 때 기본 인시던트만 표시되는 병합된 인시던트

상태 표시기는 정보 제공 목적이며 SLA 계산에 포함되지 않습니다. 상태 업데이트는 일반적으로 인시던트 상태 변경 후 1~2분 이내에 나타납니다.

**Degraded performance** 또는 **Service disruption** 상태가 표시되면 GitLab 팀에서 이미 이 이슈를 인식하고 있으며 작업 중입니다. 워크플로에 특정 지원이 필요하지 않으면 지원 티켓을 열 필요가 없습니다. 인시던트가 진행됨에 따라 상태가 자동으로 업데이트됩니다.

상태가 **Normal**으로 표시되지만 이슈가 발생하는 경우, 이슈가 특정 구성이나 사용 패턴과 관련이 있을 수 있습니다. [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열고 발생 중인 상황 및 문제가 시작된 시점에 대한 세부 정보를 포함합니다.

## 유지 보수 {#maintenance}

Switchboard는 인스턴스가 유지 보수 중일 때 유지 보수 표시기를 표시합니다. 두 유지 보수 유형 모두 **Under maintenance** 상태를 표시합니다.

| 유지 보수 유형          | 표시 시기 |
| ------------------------- | --------------- |
| **Scheduled maintenance** | 예정된 유지 보수 윈도우 중. 자세한 내용은 [유지 보수 중 액세스](maintenance.md#access-during-maintenance)를 참조하세요. |
| **Emergency maintenance** | 예정된 윈도우 외 계획되지 않은 긴급 유지 보수 중. 자세한 내용은 [긴급 유지 보수](maintenance.md#emergency-maintenance)를 참조하세요. |

유지 보수 중에 인시던트가 발생하면 유지 보수 표시기와 인스턴스 상태 표시기가 모두 나타납니다.

**개요** 페이지에도 다음이 표시됩니다:

- 다음 예정된 유지 보수 윈도우 및 향후 GitLab 버전 업그레이드
- 가장 최근 완료된 유지 보수 윈도우
- 가장 최근 긴급 유지 보수 윈도우(해당되는 경우)

매주 금요일 아침(UTC)에 Switchboard는 향후 주의 유지 보수 윈도우에 대한 계획된 GitLab 버전 업그레이드를 표시하도록 업데이트됩니다. 자세한 내용은 [유지 보수 윈도우](maintenance.md#maintenance-windows)를 참조하세요.

## 관련 항목 {#related-topics}

- [GitLab Dedicated 유지 보수 작업](maintenance.md)
- [GitLab Dedicated 호스팅되는 러너](hosted_runners.md)
- [GitLab Dedicated 네트워크 액세스 및 보안](configure_instance/network_security.md)

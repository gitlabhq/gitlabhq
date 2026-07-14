---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 감사 이벤트 관리
description: "GitLab 인스턴스의 감사 이벤트를 보고, 내보내고, 관리합니다. CSV 인코딩 및 사용자 가장을 포함합니다."
---

[감사 이벤트](../../user/compliance/audit_events.md)에 추가로, 관리자는 추가 기능에 액세스할 수 있습니다.

## 인스턴스 감사 이벤트 {#instance-audit-events}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

전체 GitLab 인스턴스에서 사용자 작업의 감사 이벤트를 볼 수 있습니다. 인스턴스 감사 이벤트를 보려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **모니터링** > **감사 이벤트**를 선택합니다.
1. 다음으로 필터링합니다:
   - 작업을 수행한 프로젝트의 멤버(사용자)
   - 그룹
   - 프로젝트
   - 날짜 범위

인스턴스 감사 이벤트는 [인스턴스 감사 이벤트 API](../../api/audit_events.md#instance-audit-events)를 사용하여 액세스할 수도 있습니다.

## 감사 이벤트 내보내기 {#exporting-audit-events}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 엔터티 유형 `Gitlab::Audit::InstanceScope`은(는) 인스턴스 감사 이벤트로 GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418185)되었습니다.

{{< /history >}}

현재 보기(필터 포함)의 인스턴스 감사 이벤트를 CSV(쉼표로 구분된 값) 파일로 내보낼 수 있습니다. 인스턴스 감사 이벤트를 CSV로 내보내려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **모니터링** > **감사 이벤트**를 선택합니다.
1. 사용 가능한 검색 필터를 선택합니다.
1. **CSV로 내보내기**를 선택합니다.

다운로드 확인 대화상자가 나타나면 CSV 파일을 다운로드합니다. 내보낸 CSV는 최대 100,000개 이벤트로 제한됩니다. 이 제한에 도달하면 남은 레코드는 잘립니다.

### 감사 이벤트 CSV 인코딩 {#audit-event-csv-encoding}

내보낸 CSV 파일은 다음과 같이 인코딩됩니다:

- `,`은(는) 열 구분 기호로 사용됩니다.
- `"`은(는) 필요한 경우 필드를 인용하는 데 사용됩니다.
- `\n`은(는) 행을 구분하는 데 사용됩니다.

첫 번째 행에는 헤더가 포함되어 있으며, 다음 표에 값에 대한 설명과 함께 나열됩니다:

| 열                | 설명                                                                        |
| --------------------- | ---------------------------------------------------------------------------------- |
| **ID**                | 감사 이벤트 `id`입니다.                                                                  |
| **작성자 ID**         | 작성자의 ID입니다.                                                                  |
| **Author Name**       | 작성자의 전체 이름입니다.                                                           |
| **엔터티 ID**         | 범위의 ID입니다.                                                                   |
| **Entity Type**       | 범위의 유형(`Project`, `Group`, `User` 또는 `Gitlab::Audit::InstanceScope`)입니다. |
| **Entity Path**       | 범위의 경로입니다.                                                                 |
| **대상 ID**         | 대상의 ID입니다.                                                                  |
| **대상 유형**       | 대상의 유형입니다.                                                                |
| **Target Details**    | 대상의 세부 정보입니다.                                                             |
| **조치**            | 작업에 대한 설명입니다.                                                         |
| **IP 주소**        | 작업을 수행한 작성자의 IP 주소입니다.                                 |
| **Created At (UTC)**  | `YYYY-MM-DD HH:MM:SS`로 형식이 지정됩니다.                                                |

모든 항목은 `created_at`에 의해 오름차순으로 정렬됩니다.

## 사용자 가장 {#user-impersonation}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

사용자가 [가장](../admin_area.md#user-impersonation)되면, 해당 작업은 다음과 같은 추가 세부 정보를 포함한 감사 이벤트로 기록됩니다:

- 감사 이벤트에는 가장을 수행한 관리자에 대한 정보가 포함됩니다.
- 관리자의 가장 세션의 시작 및 종료에 대해 추가 감사 이벤트가 기록됩니다.

![가장된 사용자를 포함한 감사 이벤트.](img/impersonated_audit_events_v15_7.png)

## 시간대 {#time-zones}

시간대 및 감사 이벤트에 대한 정보는 [시간대](../../user/compliance/audit_events.md#time-zones)를 참조하세요.

## 감사 이벤트에 기여 {#contribute-to-audit-events}

감사 이벤트에 기여하는 방법에 대한 정보는 [감사 이벤트에 기여](../../user/compliance/audit_events.md#contribute-to-audit-events)를 참조하세요.

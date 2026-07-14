---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 라이센스 사용량
description: GitLab 라이센스와 연결된 사용량을 보고 내보냅니다.
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 라이센스와 연결된 사용량을 보고 다음 정보와 함께 라이센스 사용량 파일을 내보낼 수 있습니다:

- 라이센스 키
- 라이센스 이메일
- 라이센스 시작 날짜(UTC)
- 라이센스 종료 날짜(UTC)
- 회사
- 파일이 생성되고 내보내진 타임스탬프(UTC)
- 기간 동안 매일 사용자 수의 기록 표:
  - 수가 기록된 타임스탬프(UTC)
  - 요금 청구 대상 사용자 수

> [!note]
> CSV 파일에서 [날짜](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) 및 [시간](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13)에 사용자 지정 형식이 사용됩니다.

## 라이센스 사용량 내보내기 {#export-license-usage}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

라이센스 사용량을 CSV 파일로 내보낼 수 있습니다.

이 파일에는 GitLab에서 [분기별 조정](../subscriptions/quarterly_reconciliation.md) 및 [갱신](../subscriptions/manage_subscription.md#renew-subscription)을 수동으로 처리하기 위해 사용하는 정보가 포함되어 있습니다. 인스턴스가 방화벽으로 보호되거나 오프라인 환경인 경우 GitLab에 이 정보를 제공해야 합니다.

> [!warning]
> 라이센스 사용량 파일을 열지 마세요. 파일을 열면 [라이센스 사용량 데이터를 제출](license_file.md#submit-license-usage-data)할 때 오류가 발생할 수 있습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.
1. 오른쪽 상단 모서리에서 **라이센스 사용량 파일 내보내기**를 선택합니다.

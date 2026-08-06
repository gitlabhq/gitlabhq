---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: 애플리케이션 성능을 모니터링하고 성능 문제를 해결합니다.
ignore_in_report: true
title: GitLab.com에서 통합관찰 설정
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태: 실험적 기능

{{< /details >}}

GitLab.com에서 GitLab Observability를 설정하려면 그룹에 대해 GitLab Observability을 활성화합니다.

전제 조건:

- 그룹에 대해 Developer, Maintainer 또는 Owner 역할이 필요합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **통합관찰** > **설정**을 선택합니다.
1. **통합관찰 활성화**를 선택합니다.
1. 활성화한 후 OpenTelemetry(OTEL) 엔드포인트 URL이 생성되어 페이지에 표시됩니다.

OTEL 엔드포인트 URL을 복사하여 애플리케이션을 계측할 때 사용합니다.

## 다음 단계 {#next-steps}

- [GitLab Observability로 텔레메트리 데이터 전송](send.md).
- [CI/CD 파이프라인 텔레메트리 표시](ci_cd.md).
- [문제 해결 정보 얻기](troubleshooting.md).

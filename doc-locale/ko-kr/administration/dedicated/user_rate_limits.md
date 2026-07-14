---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Dedicated의 인증된 사용자 속도 제한, 참조 아키텍처별 기본 제한 및 처리 전략"
title: 인증된 사용자 속도 제한
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated는 인증된 사용자 속도 제한을 자동으로 적용하여 시스템 안정성을 보장하고 인스턴스의 모든 사용자를 위한 성능을 유지하도록 합니다. 속도 제한은 단일 사용자 또는 서비스 계정이 과도한 알림을 생성하거나 광범위한 인스턴스 성능 저하를 야기하는 것을 방지합니다.

사용자가 속도 제한을 초과하면 GitLab은 `429 Too Many Requests` HTTP 상태 코드를 반환하고 `Retry later`의 일반 텍스트 응답을 제공합니다.

속도 제한은 GitLab에 의해 자동으로 구성되고 관리됩니다. 다음을 수행할 수 없습니다:

- 속도 제한 값을 수정합니다.
- 속도 제한을 사용 중지합니다.
- 관리 영역을 통해 사용자 지정 속도 제한을 구성합니다.
- UI에서 속도 제한 설정에 액세스합니다.

GitLab은 인스턴스의 최적의 성능과 안정성을 보장하기 위해 이러한 설정을 관리합니다.

자세한 내용은 [속도 제한](../../security/rate_limits.md)을 참조하세요.

## 요청 유형별 속도 제한 {#rate-limits-by-request-type}

속도 제한은 일반 사용자 및 서비스 계정을 포함한 모든 인증된 사용자에게 적용됩니다. GitLab은 참조 아키텍처 크기에 따라 이러한 제한을 자동으로 설정합니다. 제한은 API 및 웹 요청에 별도로 적용됩니다:

- API 요청:  통합, CI/CD 작업, 자동화 스크립트의 요청을 포함한 REST 및 GraphQL API 호출
- 웹 요청:  GitLab UI를 통해 이루어진 요청

| 참조 아키텍처 | 분당 API 요청 | 분당 웹 요청 |
| ---------------------- | ----------------------- | ----------------------- |
| 1,000명 사용자            | 1,200                   | 120                     |
| 2,000명 사용자            | 2,400                   | 480                     |
| 3,000명 사용자            | 3,600                   | 600                     |
| 5,000명 사용자            | 6,000                   | 600                     |
| 10,000명 사용자           | 12,000                  | 1,200                   |
| 25,000명 사용자           | 30,000                  | 3,000                   |
| 50,000명 사용자           | 60,000                  | 6,000                   |

자세한 내용은 [참조 아키텍처](../reference_architectures/_index.md)를 참조하세요.

## 응답 헤더 {#response-headers}

GitLab은 모든 요청에 대한 응답 헤더에 속도 제한 정보를 포함합니다. 이 헤더를 사용하여 현재 사용량 및 남은 할당량을 모니터링할 수 있습니다.

속도 제한에 응답 헤더가 포함되고 사용 가능한 헤더에 대한 자세한 내용은 [여러 속도 제한 시스템](../settings/user_and_ip_rate_limits.md#multiple-rate-limiting-systems)을 참조하세요.

## 요청 효율성 향상 {#improve-request-efficiency}

속도 제한으로 더 효과적으로 작업하려면:

1. 요청 패턴 최적화:

   - 자동화 스크립트의 요청 사이에 지연을 추가합니다.
   - 가능할 때 API 요청을 결합합니다.
   - GraphQL을 사용하여 필요한 데이터만 가져옵니다.
   - 대용량 데이터 세트에 대한 효율적인 페이지 매김을 구현합니다.

1. 대용량 사용 현황을 감시하고 최적화합니다:

   - 가장 많은 요청을 하는 사용자 또는 서비스 계정을 검토합니다.
   - 과도한 API 호출을 하는 CI/CD 작업을 검토합니다.
   - GitLab 인스턴스에 연결하는 통합을 검토합니다.
   - 속도 제한 임계값 아래로 유지하도록 자동화된 프로세스를 업데이트합니다.

---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 리뷰 플로우
description: AI를 통해 머지 리퀘스트에서 비즈니스 로직 취약성을 파악합니다.
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/600301)되었습니다. 이 기능은 [베타](../../../../policy/development_stages_support.md#beta) 단계입니다.

{{< /history >}}

보안 리뷰 플로우는 머지 리퀘스트에서 비즈니스 로직 취약성을 감지합니다. 정적 분석 도구가 알려진 패턴을 스캔하는 것과 달리, 보안 리뷰 플로우는 코드의 의도를 분석합니다. 인증, 데이터 노출 및 제어 흐름에 대한 잘못된 가정에서 발생하는 취약성을 파악합니다.

보안 리뷰 플로우는 GitLab Duo Agent Platform을 기반으로 구축된 [기본 플로우](_index.md)입니다. [GitLab Duo 코드 리뷰](../../../gitlab_duo/code_review.md)와 함께 작동하며 스레드 diff 댓글로 발견 사항을 게시하며, 각 댓글에는 CWE 분류, 심각도 등급, 설명 및 가능한 경우 한 번의 작업으로 적용할 수 있는 인라인 제안 수정이 포함됩니다.

> [!note]
> 보안 리뷰 플로우 결과는 AI가 생성하며 권위 있거나 완전한 보안 평가가 아닌 자문 입력입니다. 발견 사항이 없다는 보고서는 머지 리퀘스트가 안전하다는 증거가 아니며, 발견 사항에는 인간의 판단이 필요한 거짓 양성이 포함될 수 있습니다. 자세한 내용은 [알려진 제한 사항](#known-limitations)을 참조하세요.

다음 중 하나가 필요할 때 보안 리뷰 플로우를 사용합니다:

- 접근 제어 검토: 상태 변경 작업에서 누락되거나 잘못 구성된 인증 확인을 파악합니다.
- 인증 격차 감지: 끊어진 객체 수준 및 함수 수준 인증 문제를 표시합니다.
- 비즈니스 로직 분석: 금융 또는 상태 저장 작업의 경쟁 조건과 같이 악용될 수 있는 애플리케이션 워크플로우의 결함을 감지합니다.
- 정보 공개: 권한이 없는 호출자에게 민감한 데이터를 유출할 수 있는 코드 경로를 파악합니다.
- 대량 할당 위험: 사용자 입력에 의도하지 않은 필드를 노출할 수 있는 엔드포인트 또는 모델에 플래그를 표시합니다.

## 전제 조건 {#prerequisites}

보안 리뷰 플로우를 사용하려면:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 최상위 그룹에서 파운데이셔널 플로우 및 **보안 리뷰**를 [활성화](_index.md#turn-foundational-flows-on-or-off)합니다.
- 그룹 또는 인스턴스에서 [GitLab Duo를 활성화](../../../gitlab_duo/turn_on_off.md)합니다.
- GitLab Duo Pro 또는 Enterprise가 없는 경우 최상위 그룹 또는 인스턴스에서 [GitLab Duo Core를 활성화](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)합니다.
- GitLab Self-Managed의 경우 인스턴스에서 [GitLab Duo를 구성](../../../../administration/gitlab_duo/configure/_index.md)합니다.
- GitLab 18.8 이상에서는 최상위 그룹에서 [에이전트 플랫폼을 활성화](../../turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)합니다. GitLab 18.7 이상에서는 [베타 및 실험 기능을 활성화](../../turn_on_off.md#turn-on-beta-and-experimental-features)합니다.

## 비용 {#cost}

보안 리뷰 플로우는 리뷰를 수행할 때마다 [GitLab Credits](../../../../subscriptions/gitlab_credits.md)를 사용합니다. 크레딧 사용량은 diff 복잡성과 선택한 모델에 따라 달라집니다.

다음 예상 값은 [기본 모델](../../../../user/duo_agent_platform/model_selection.md#default-models)에 적용됩니다:

| 리뷰 복잡성                        | 대략적인 LLM 호출 | 예상 크레딧 |
|------------------------------------------|-----------------------|-------------------|
| 작은 diff 또는 몇 개의 변경된 파일        | ~16                   | ~8                |
| 표준 브랜치 기능                  | ~28                   | ~14               |
| 크거나 로직이 많은 다중 파일 변경   | ~40                   | ~20               |

베타 릴리스 중에는 항상 수동으로 리뷰를 시작합니다. 이를 통해 더 광범위한 채택 전에 코드베이스의 전형적인 크레딧 사용량을 평가할 수 있습니다.

## 보안 리뷰 플로우 사용 {#use-security-review-flow}

### 리뷰 요청 {#request-a-review}

머지 리퀘스트를 생성한 후 언제든지 리뷰를 요청할 수 있습니다. 리뷰를 요청하면 플로우는 머지 리퀘스트 diff와 주변 컨텍스트를 분석합니다.

**Duo Security Review** 서비스 계정은 보안 리뷰 플로우가 활성화되면 최상위 그룹에 대해 생성되며 해당 그룹 내의 모든 프로젝트와 하위 그룹에서 사용할 수 있습니다. 각 서비스 계정 이름에는 연결된 최상위 그룹이 포함되어 있습니다. 예: `duo-security-review-gitlab-org`.

리뷰를 요청하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 열습니다.
1. 오른쪽 사이드바의 **검토자** 섹션에서 **편집**을 선택합니다.
1. 검색 상자에 `Duo Security Review`를 입력하고 목록에서 계정을 선택합니다.

리뷰가 완료되면 플로우가 내부 노트를 게시합니다. 노트는 모든 발견 사항과 리뷰 범위를 요약합니다. 리뷰에서 발견 사항이 없으면 플로우가 내부 노트에 이를 표시합니다.

각 발견 사항에 대해 플로우는 관련 라인에서 diff 스레드를 엽니다. 스레드에 회신하면 (예: 위험을 수락하거나 평가에 동의하지 않음) 플로우가 회신을 읽고 그에 따라 응답합니다. 공개 프로젝트에서 발견 사항은 내부 노트에만 게시되며 인라인 diff 댓글은 없습니다. 발견 사항을 비공개로 게시하면 보안 세부 정보 노출을 방지합니다.

플로우는 발견 사항의 심각도를 기반으로 검토자 상태를 설정합니다. 플로우는 문제가 없더라도 **승인** 상태를 설정하지 않습니다:

| 심각도             | 검토자 상태 |
| -------------------- | -------------- |
| `critical` 또는 `high` | **변경 요청** |
| `medium` 또는 `low`    | **댓글**    |
| 없음                 | **댓글**    |

### 발견 사항에 응답 {#respond-to-a-finding}

{{< history >}}

- 언급에 대한 회신 전달이 GitLab 19.2에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/work_items/604317)되었으며 [플래그](../../../../administration/feature_flags/_index.md)와 함께 `ai_use_messaging_adapter_for_mentions`라는 이름으로 지정됩니다. 기본적으로 비활성화되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 플래그가 비활성화되면 언급은 대상 회신 대신 전체 리뷰를 시작합니다. 자세한 내용은 [언급이 회신 대신 전체 리뷰를 시작합니다](#a-mention-starts-a-full-review-instead-of-a-reply)를 참조하세요.

수정 방식을 논의하거나 발견 사항을 거짓 양성으로 표시하기 위해 스레드에서 플로우를 언급하여 발견 사항에 대한 명확한 질문을 하세요. 플로우는 언급되었을 때 전체 재검토를 수행하지 않습니다.

발견 사항에 응답하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 열습니다.
1. 댓글 스레드에 `@duo-security-review`를 입력하고 목록에서 **Duo Security Review**를 선택합니다.
1. 메시지를 추가하고 **댓글**을 선택합니다.

보안 리뷰 플로우는 스레드 컨텍스트를 읽고 직접 회신합니다.

### 발견 사항 검토 {#review-a-finding}

보안 리뷰 플로우는 정적 분석기에서 자주 놓치는 논리 수준 취약성에 중점을 둡니다. 각 발견 사항은 변경된 코드에서 diff 스레드로 게시됩니다. 각 스레드에는 다음이 포함됩니다:

- MITRE 정의 링크가 있는 취약성 유형(CWE).
- 심각도 등급: `critical`, `high`, `medium` 또는 `low`.
- 계층 분류: 계층 1(악용 가능), 계층 2(논리 결함) 또는 계층 3(설계 문제).
- 논리 결함 설명.
- 가능한 경우 제안된 수정.

> [!note]
> 발견 사항은 [취약성 보고서](../../../application_security/vulnerability_report/_index.md)에서 추적되지 않으며 [머지 리퀘스트 승인 정책](../../../application_security/policies/merge_request_approval_policies.md)에 포함되지 않습니다. 이들은 정적 분석(SAST) 발견 사항을 보완하지만 대체하지는 않습니다.

다음 CWE 분류가 발견 사항에 나타날 수 있습니다:

| CWE | 설명 |
|-----|-------------|
| [CWE-639](https://cwe.mitre.org/data/definitions/639.html) | 사용자 제어 키를 통한 인증 우회(BOLA / IDOR) |
| [CWE-862](https://cwe.mitre.org/data/definitions/862.html) | 누락된 인증 |
| [CWE-284](https://cwe.mitre.org/data/definitions/284.html) | 부적절한 접근 제어 |
| [CWE-200](https://cwe.mitre.org/data/definitions/200.html) | 민감한 정보 노출 |
| [CWE-840](https://cwe.mitre.org/data/definitions/840.html) | 비즈니스 로직 오류 |
| [CWE-915](https://cwe.mitre.org/data/definitions/915.html) | 동적으로 결정된 객체 특성의 부적절하게 제어된 수정(대량 할당) |
| [CWE-362](https://cwe.mitre.org/data/definitions/362.html) | 경쟁 조건 및 확인 시간 / 사용 시간(TOCTOU) |

### 발견 사항 해결 {#resolve-a-finding}

발견 사항을 해결하려면:

- 수정을 적용하려면 **제안 적용**을 선택합니다. 대신 제안을 새 브랜치에 커밋하려면 **제안 적용** 옆의 드롭다운 목록을 선택합니다.
- 발견 사항을 해제하려면 발견 사항을 검토하고 거짓 양성 또는 수락된 위험임을 확인한 경우 **스레드 해결**을 선택합니다.
- 향후 수정을 위해 취약성을 추적하려면 표준 GitLab [스레드 작업](../../../../user/project/merge_requests/_index.md#move-open-threads-to-an-issue)을 사용하여 발견 사항에서 이슈를 생성합니다.
- 발견 사항의 유용성을 평가하려면 **thumbs up** 또는 **thumbs down**를 선택합니다. 이 피드백은 모델을 개선하는 데 도움이 됩니다. [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/600304)에서 자세한 피드백을 공유할 수도 있습니다.

발견 사항을 해결한 후 다른 리뷰를 요청하려면 플로우를 검토자로 다시 할당합니다. 플로우는 업데이트된 diff를 분석하고 발견 사항의 상태에 따라 작업을 수행합니다:

- 해결된 발견 사항: 플로우는 수정을 확인하고 원본 스레드를 해결합니다.
- 잘못되거나 불완전한 수정: 플로우는 원본 스레드에서 필요한 추가 변경 사항을 식별합니다.
- 해결되지 않은 발견 사항: 원본 스레드는 추가 댓글 없이 열린 상태로 유지됩니다.
- 새로운 발견 사항: 플로우는 수정으로 인해 도입된 새로운 취약성을 감지하고 이에 대한 새 댓글 스레드를 생성합니다.

## 알려진 제한 사항 {#known-limitations}

보안 리뷰 플로우 출력에 의존하기 전에 다음 제한 사항을 이해합니다.

- 발견 사항은 자문이지 범위 보장이 아닙니다. 보안 리뷰 플로우 결과는 AI가 생성합니다. 플로우는 변경 사항의 모든 취약성을 표시하지 않을 수 있습니다: 그 분석은 제한된 검색 및 읽기 예산 범위 내에서 작동하므로 매우 큰 파일 또는 diff가 완전히 검토되지 않을 수 있습니다. 발견 사항이 없다는 보고서는 머지 리퀘스트가 안전하다는 증거가 아닙니다.
- 발견 사항에는 거짓 양성이 포함될 수 있습니다. 발견 사항을 최종 판정이 아닌 인간의 판단이 필요한 입력으로 취급합니다.
- 보안 리뷰 플로우는 다른 도구를 보완합니다. 인간 보안 검토 또는 [SAST](../../../application_security/sast/_index.md) 및 [GitLab Advanced SAST](../../../application_security/sast/gitlab_advanced_sast.md)와 같은 다른 GitLab 보안 도구를 대체하지 않습니다.

## 문제 해결 {#troubleshooting}

보안 리뷰 플로우를 사용할 때 다음 이슈가 발생할 수 있습니다.

### 플로우를 할당할 수 없음 {#the-flow-is-not-available-to-assign}

**Duo Security Review** 서비스 계정은 보안 리뷰 플로우가 활성화되면 최상위 그룹에 대해 생성됩니다. 서비스 계정 이름에는 최상위 그룹 이름이 포함되어 있습니다. 예: `duo-security-review-gitlab-org`.

보안 리뷰 플로우의 상태를 확인합니다.

### 플로우가 발견 사항을 제공하지 않음 {#the-flow-does-not-provide-findings}

모든 [필수 조건](#prerequisites)을 충족하는지 확인한 다음 플로우가 올바르게 할당되었는지 확인합니다.

- **Duo Security Review** 계정을 언급했는지 확인합니다(사용자 이름이 `@duo-security-review-`로 시작함).
- [**파운데이셔널 플로우 허용**](_index.md#turn-foundational-flows-on-or-off) 및 [**코드 리뷰**](code_review.md) 설정이 최상위 그룹에서 활성화되어 있는지 확인합니다.
- GitLab Self-Managed의 경우 인스턴스가 [GitLab Duo로 구성](../../../../administration/gitlab_duo/configure/_index.md)되어 있는지 확인합니다.

### 플로우가 모든 머지 리퀘스트를 검토하지 않음 {#the-flow-does-not-review-every-merge-request}

이 보안 스캔을 실행하려면 머지 리퀘스트에서 플로우를 수동으로 트리거해야 합니다. 모든 머지 리퀘스트에서 자동으로 실행되지 않습니다. 플로우를 할당했지만 발견 사항이 없으면 [플로우가 발견 사항을 제공하지 않음](#the-flow-does-not-provide-findings)을 참조하세요.

플로우가 머지 리퀘스트를 검토할 때 발견 사항이 없는 보고서는 일반적으로 다음을 의미합니다:

- 보안 문제가 감지되지 않음: 코드 논리가 분석되었으며 취약성이 식별되지 않았습니다.
- 보안 관련 논리 없음: 변경 사항에는 보안에 영향을 미치는 코드(예: 설명서만 업데이트)가 포함되지 않습니다.

큰 변경 사항에 대한 참고: 큰 머지 리퀘스트의 경우 플로우는 제한된 검색 및 읽기 예산 범위 내에서 작동합니다. 이 경우 플로우는 발견 사항이 없다고 보고하거나 여전히 발견 사항을 출력할 수 있지만 전체 머지 리퀘스트를 다루지 못하여 중요한 취약성이 누락될 수 있습니다. 완료된 리뷰는 전체 범위를 보장하지 않습니다. 자세한 내용은 [알려진 제한 사항](#known-limitations)을 참조하세요.

### 언급이 회신 대신 전체 리뷰를 시작합니다 {#a-mention-starts-a-full-review-instead-of-a-reply}

플로우는 `ai_use_messaging_adapter_for_mentions` 기능 플래그가 활성화된 경우에만 언급에 대한 대상 회신으로 응답합니다. 플래그가 비활성화되면 언급은 대신 머지 리퀘스트의 전체 리뷰를 시작합니다.

- GitLab Self-Managed 및 GitLab Dedicated에서 관리자는 `ai_use_messaging_adapter_for_mentions` 이름의 기능 플래그를 활성화할 수 있습니다.
- GitLab.com에서는 GitLab이 회신 지원을 출시하는 동안 이 플래그가 비활성화됩니다. 롤아웃이 완료될 때까지 언급은 전체 리뷰를 시작합니다. 롤아웃 상태는 [이슈 602269](https://gitlab.com/gitlab-org/gitlab/-/issues/602269)를 참조하세요.

### 제안된 변경 사항이 깔끔하게 적용되지 않음 {#suggested-changes-do-not-apply-cleanly}

제안은 리뷰 시 diff에 대해 생성됩니다. 리뷰 후 새 커밋을 푸시한 경우 라인 번호가 이동했을 수 있습니다. 현재 diff에 대한 업데이트된 제안을 얻으려면 새 리뷰를 요청합니다.

### GitLab Credits에 대한 오류가 표시됨 {#i-received-an-error-about-gitlab-credits}

인스턴스 또는 그룹이 현재 청구 기간에 [GitLab Credits](../../../../subscriptions/gitlab_credits.md)를 소진했을 수 있습니다. 관리자에게 문의하여 추가 크레딧을 구매하거나 다음 청구 기간이 시작될 때 크레딧이 재설정될 때까지 기다립니다.

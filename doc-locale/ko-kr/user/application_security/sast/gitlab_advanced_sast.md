---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Advanced SAST는 교차 파일, 교차 함수 오염 분석을 사용하여 높은 정확도로 복잡한 취약성을 탐지합니다."
title: GitLab Advanced SAST
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1에서 Python용 [실험](../../../policy/development_stages_support.md)으로 도입되었습니다.
- Go 및 Java 지원이 17.2에 추가되었습니다.
- GitLab 17.2에서 [실험에서 베타로 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/461859)되었습니다.
- JavaScript, TypeScript 및 C# 지원이 17.3에 추가되었습니다.
- GitLab 17.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/474094)되었습니다.
- Java Server Pages(JSP) 지원이 GitLab 17.4에 추가되었습니다.
- PHP 지원이 GitLab 18.1에 [추가](https://gitlab.com/groups/gitlab-org/-/epics/14273)되었습니다.
- C/C++ 지원이 GitLab 18.6에 [추가](https://gitlab.com/groups/gitlab-org/-/work_items/14271)되었습니다.
- Swift 및 Objective-C 지원이 GitLab 19.3에서 [추가](https://gitlab.com/groups/gitlab-org/-/work_items/16318)되었으며 [베타](../../../policy/development_stages_support.md#beta)입니다.

{{< /history >}}

GitLab Advanced SAST는 교차 파일, 교차 함수 오염 분석을 사용하여 기존 SAST보다 오탐이 낮으면서 복잡한 취약성을 탐지하는 정적 애플리케이션 보안 테스팅(SAST) 분석기입니다.

GitLab Advanced SAST는 선택적 기능입니다. 사용으로 설정되면 GitLab Advanced SAST는 미리 정의된 규칙 집합을 사용하여 지원되는 모든 언어 파일을 검사하며 SAST 분석기는 계속 다른 파일을 검사합니다. 두 분석기 모두 병렬로 실행될 수 있습니다. SAST와 GitLab Advanced SAST는 완전한 패리티를 갖지 않습니다. 각 분석기는 다른 분석기가 탐지하지 못하는 일부 취약성을 탐지합니다. 자동화된 [전환 프로세스](#transitioning-from-semgrep-to-gitlab-advanced-sast)는 두 분석기가 동일한 취약성을 탐지할 때 중복을 제거합니다.

GitLab Advanced SAST는 표준 Semgrep 기반 SAST 분석기보다 더 깊은 분석을 수행합니다. 이 포괄적인 접근 방식은 정확도를 향상시키고 오탐을 줄일 수 있지만 더 많은 컴퓨팅 리소스와 더 긴 검사 시간이 필요합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [GitLab Advanced SAST: 취약성 해결 가속화](https://youtu.be/xDa1MHOcyn8)를 참조하세요.
<!-- Video published on 2025-09-19 -->

제품 투어는 [GitLab Advanced SAST 제품 투어](https://gitlab.navattic.com/advanced-sast)를 참조하세요.

## 기능 {#features}

| 기능                                                                      | SAST                                                                                                                                      | Advanced SAST                                                                                                                               |
|------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| 분석의 깊이                                                            | 복잡한 취약성을 탐지할 수 있는 제한된 기능이며, 분석은 단일 파일로 제한되고 단일 함수로(제한적인 예외가 있음) 제한됩니다. | 교차 파일, 교차 함수 오염 분석을 사용하여 복잡한 취약성을 탐지합니다.                                                            |
| 정확도                                                                     | 제한된 컨텍스트로 인해 오탐 결과가 발생할 가능성이 높습니다.                                                                      | 교차 파일, 교차 함수 오염 분석을 사용하여 실제로 악용 가능한 취약성에 집중하여 오탐을 줄입니다.      |
| 복구 안내                                                         | 취약성 발견이 줄 번호로 식별됩니다.                                                                                     | 자세한 [코드 플로우 보기](#code-flow)에서는 취약성이 프로그램을 통과하는 흐름을 보여주며, 더 빠른 수정을 가능하게 합니다. |
| GitLab Duo 취약성 설명 및 취약성 해결과 함께 작동합니다 | 예.                                                                                                                                      | 예.                                                                                                                                        |
| 언어 커버리지                                                            | [더 광범위합니다](_index.md#supported-languages-and-frameworks).                                                                           | [더 제한적입니다](#supported-languages).                                                                                                       |

## GitLab Advanced SAST 활성화 {#turn-on-gitlab-advanced-sast}

다음 단계를 따라 프로젝트에서 GitLab Advanced SAST를 활성화하세요.

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.
- 표준 SAST 분석기를 활성화합니다. 자세한 내용은 [SAST 사전 요구 사항](_index.md#getting-started)을 참조하세요.
- GitLab Self-Managed의 경우 지원되는 GitLab 버전을 사용하세요:
  - 최소 버전: GitLab 17.1 이상
  - 권장 버전: GitLab 17.4 이상(코드 플로우 보기, 취약성 중복 제거 및 업데이트된 템플릿 포함)
  - 템플릿 호환성:
    - 안정적인 템플릿: GitLab 17.3 이상
    - 최신 템플릿: GitLab 17.2 이상
    - 같은 프로젝트에서 [안정적인 템플릿과 최신 템플릿을 혼합](../detect/security_configuration.md#template-editions)하지 마세요

GitLab Advanced SAST를 활성화합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **빌드** > **파이프라인** 편집기로 이동합니다.
1. `.gitlab-ci.yml` 파일을 만들거나 편집합니다.
1. Advanced SAST를 사용으로 설정할 적절한 변수를 추가하세요.

   - C/C++를 제외한 지원되는 모든 언어: `GITLAB_ADVANCED_SAST_ENABLED: 'true'`

   - C/C++의 경우: `GITLAB_ADVANCED_SAST_CPP_ENABLED: 'true'`

1. **유효성 검사** 탭을 선택한 다음 **파이프라인 유효성 검사**를 선택합니다.

   **시뮬레이션이 성공적으로 완료**라는 메시지는 파일이 유효함을 확인합니다.
1. **편집** 탭을 선택합니다.
1. 필드를 완성하세요.
1. **이 변경 사항으로 새로운 병합 요청 시작** 확인란을 선택한 후 **변경 사항 커밋**을 선택합니다.
1. 표준 워크플로우에 따라 필드를 완성한 다음 **병합 요청 만들기**를 선택합니다.
1. 표준 워크플로에 따라 병합 요청을 검토하고 편집한 후 **병합**를 선택합니다.

이 시점에서 GitLab Advanced SAST는 파이프라인에 사용으로 설정되어 있습니다. 지원되는 소스 코드는 파이프라인이 실행될 때 취약성을 검사합니다. 해당 작업이 파이프라인의 `test` 스테이지에 나타납니다.

이 단계를 완료한 후 다음을 수행할 수 있습니다.

- [취약성 결과](#vulnerability-results)를 평가하는 방법에 대해 자세히 알아보세요.
- [검사 성능 팁](#improve-scanning-performance)을 검토하세요.
- [더 많은 프로젝트로의 롤아웃](#roll-out)을 계획합니다.

## 취약성 결과 {#vulnerability-results}

GitLab Advanced SAST 취약성은 보안 문제를 평가하고 복구하는 데 도움이 되는 자세한 정보를 포함합니다. 각 취약성은 다음을 표시합니다.

- 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
- 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
- 심각도:  영향에 따라 6가지 수준으로 분류됩니다. [심각도 수준에 대해 자세히 알아보기](../vulnerabilities/severities.md).
- 위치:  이슈가 발견된 파일 이름과 줄 번호를 표시합니다. 파일 경로를 선택하면 코드 보기에서 해당 줄이 열립니다.
- 코드 플로우: 사용자 입력(소스)에서 취약한 코드 줄까지 데이터가 이동하는 경로입니다.
- 검사기:  취약성을 탐지한 분석기를 식별합니다.
- 식별자:  CWE 식별자 및 이를 탐지한 규칙의 ID와 같은 취약성을 분류하는 데 사용되는 참조 목록입니다.

SAST 취약성은 발견된 취약성에 대한 주요 CWE(공통 약점 열거) 식별자에 따라 이름이 지정됩니다. SAST 보안 범위에 대한 자세한 내용은 [SAST 규칙](rules.md)을 참조하세요.

### 결과 보기 {#view-results}

사전 요구 사항:

- 프로젝트에 대한 보안 관리자, 개발자, 유지 관리자 또는 소유자 역할입니다.

파이프라인에서 취약성을 보려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 결과를 다운로드하거나 취약성을 선택하여 세부 정보를 봅니다(Ultimate만 해당).

#### 코드 플로우 {#code-flow}

{{< history >}}

- GitLab 17.3에서 [여러 플래그](../../../administration/feature_flags/_index.md)를 사용하여 도입되었습니다. 기본적으로 사용으로 설정되어 있습니다.
- GitLab 17.7에서 GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정되었습니다.
- GitLab 17.7에서 일반 공개되었습니다. 모든 기능 플래그가 제거되었습니다.

{{< /history >}}

특정 유형의 취약성에 대해 GitLab Advanced SAST는 코드 플로우 정보를 제공합니다. 취약성의 코드 플로우는 사용자 입력(소스)에서 취약한 코드 라인(싱크)까지 모든 할당, 조작 및 삭제를 통해 데이터가 이동하는 경로입니다. 이 정보는 취약성의 컨텍스트, 영향 및 위험을 이해하고 평가하는 데 도움이 됩니다. 코드 플로우 정보는 소스에서 싱크로 입력을 추적하여 탐지되는 취약성에 사용할 수 있으며 다음을 포함합니다:

- SQL 삽입
- 명령 삽입
- 교차 사이트 스크립팅(XSS)
- 경로 순회

코드 플로우 정보는 **데이터 플로우** 탭에 표시되며 다음을 포함합니다:

- 소스에서 싱크까지의 단계입니다.
- 코드 스니펫을 포함한 관련 파일입니다.

![SQL 인젝션의 데이터 플로우(검색 용어를 공급하는 요청 매개 변수에서 이를 실행하는 데이터베이스 쿼리까지)](img/code_flow_view_v19_3.png)

## 지원되는 언어 {#supported-languages}

{{< history >}}

- C# 버전 지원이 GitLab 18.6에서 [10.0에서 13.0으로 증가](https://gitlab.com/gitlab-org/gitlab/-/issues/570499)했습니다.

{{< /history >}}

GitLab Advanced SAST는 다음 언어를 지원합니다.

- C#(13.0 이상)
- C/C++
- Go
- Java, Java Server Pages(JSP) 포함
- JavaScript, TypeScript
- Objective-C(베타)
- PHP
- Python
- Ruby
- Swift(베타)

GitLab Advanced SAST CPP는 컴파일 데이터베이스를 포함한 추가 구성이 필요합니다. 자세한 내용은 [C/C++ 구성](advanced_sast_cpp.md)을 참조하세요. GitLab Advanced SAST CPP와 Semgrep은 모두 C/C++ 프로젝트용으로 실행되며, 각각 다른 규칙 집합을 가집니다.

Swift 및 Objective-C 지원은 [베타](../../../policy/development_stages_support.md#beta)입니다. GitLab Advanced SAST가 사용으로 설정되고 리포지토리에 Swift 또는 Objective-C 파일이 포함되면 분석이 별도의 CI/CD 작업 `gitlab-advanced-sast-ext`으로 실행됩니다. 추가 변수가 필요하지 않습니다. 자세한 내용은 [Swift 및 Objective-C 구성](advanced_sast_swift_objc.md)을 참조하세요.

### PHP 알려진 문제 {#php-known-issues}

PHP 코드를 분석할 때 GitLab Advanced SAST에는 다음과 같은 알려진 문제가 있습니다.

- 동적 파일 포함: 동적 파일 포함 문(`include`, `include_once`, `require`, `require_once`)은 파일 경로에 변수를 사용하는 경우 이 릴리스에서 지원되지 않습니다. 정적 파일 포함 경로만 교차 파일 분석에 지원됩니다. [이슈 527341](https://gitlab.com/gitlab-org/gitlab/-/issues/527341)을 참조하세요.
- 대소문자 구분: PHP의 함수 이름, 클래스 이름 및 메서드 이름에 대한 대소문자 구분 안 함은 교차 파일 분석에서 완전히 지원되지 않습니다. [이슈 526528](https://gitlab.com/gitlab-org/gitlab/-/issues/526528)을 참조하세요.

## 검사 성능 개선 {#improve-scanning-performance}

GitLab Advanced SAST 검사 성능은 주로 코드 커버리지와 러너 리소스에 의해 결정됩니다. GitLab Advanced SAST 검사 성능을 향상시키려면 코드 커버리지와 러너 리소스를 조정할 수 있습니다.

### 코드 커버리지 조정 {#tune-code-coverage}

코드 커버리지는 분석되는 코드베이스의 양을 나타냅니다. GitLab Advanced SAST는 사전 정의된 규칙 집합을 사용하여 지원되는 모든 언어 파일을 검사합니다. Semgrep 기반 SAST 분석기는 이러한 파일을 검사하지 않습니다. 자동화된 [전환 프로세스](#transitioning-from-semgrep-to-gitlab-advanced-sast)는 두 분석기가 동일한 취약성을 탐지하면 중복된 발견을 제거합니다.

선택적으로 [확인되지 않은 취약성을 보고](#report-unverified-vulnerabilities)할 수 있으며, 여기서 소스에서 싱크까지의 전체 경로가 식별되지 않습니다.

기본적으로 GitLab Advanced SAST는 전체 리포지토리를 검사합니다. 다음 방법을 사용하여 코드 커버리지를 조정할 수 있습니다.

- 분석되는 코드의 양을 줄이기 위해 리포지토리 경로를 제외합니다.
- 인라인 주석을 사용하여 특정 발견을 억제하기 위해 개별 줄을 제외합니다.
- 병합 요청에서 수정된 파일(및 해당 종속 파일)만 분석하도록 diff 기반 검사를 활성화합니다.
- 이전 검사 결과를 캐시하여 계산 부하를 줄이는 증분 검사를 활성화합니다.

Diff 기반 검사와 증분 검사는 독립적으로 또는 함께 사용하여 검사 성능을 향상시킬 수 있습니다.

Diff 기반 검사: 병합 요청과 관련된 파이프라인(병합 요청 파이프라인 또는 병합 요청과 관련된 브랜치 파이프라인)에서 변경된 파일 및 해당 종속 파일만 검사하여 전체 보안 범위보다 속도를 우선시합니다.

증분 검사: 이전 검사 결과를 캐시하고 후속 파이프라인에서 재사용하여 전체 파일 커버리지를 유지하면서 검사 시간을 줄입니다. 모든 파이프라인에서 사용 가능합니다.

| 구성                     | 병합 요청과 관련된 파이프라인              | 기타 모든 파이프라인                  |
|-----------------------------------|-------------------------------------------------|--------------------------------------|
| 최적화 없음                   | 표준입니다. 모든 파일을 검사하고 캐시가 없습니다.            | 표준입니다. 모든 파일을 검사하고 캐시가 없습니다. |
| 증분 검사만         | 빠릅니다. 캐시를 사용하여 모든 파일을 검사합니다.               | 빠릅니다. 캐시를 사용하여 모든 파일을 검사합니다.    |
| Diff 기반 검사만          | 더 빠릅니다. 변경된 파일만 검사하고 캐시가 없습니다.     | 표준입니다. 모든 파일을 검사하고 캐시가 없습니다. |
| Diff 기반 + 증분 검사 | 가장 빠릅니다. 캐시를 사용하여 변경된 파일만 검사합니다.   | 빠릅니다. 캐시를 사용하여 모든 파일을 검사합니다.    |

#### 경로 제외 {#exclude-paths}

검사 시간을 줄이기 위해 취약성을 포함할 가능성이 낮은 경로를 GitLab Advanced SAST 검사에서 제외합니다.

경로를 제외할 때는 취약성을 숨기지 않도록 선택적으로 선택하세요. 변경을 증분적으로 수행하고 각 제외 후 검사 시간에 미치는 영향을 테스트하세요.

다음을 포함하는 경로를 제외하는 것을 고려하세요:

- 데이터베이스 마이그레이션
- 단위 테스트
- `node_modules/`과 같은 종속성
- 빌드 파일
- 구성 정보
- 정적 자산
- 테스트 데이터
- 코드 기반 인프라

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.

경로를 제외하려면 다음을 수행합니다.

- 제외된 경로를 [`SAST_EXCLUDED_PATHS`](_index.md#vulnerability-filters) CI/CD 변수에 나열합니다.

#### 줄 제외 {#exclude-lines}

특정 줄의 발견을 억제하려면 소스 코드에 `gitlab-advanced-sast-exclude`를 주석으로 추가합니다. 태그는 대소문자를 구분하지 않으며 `#`, `//` 또는 `--`와 같은 주석 구문에서 작동합니다.

주석을 발견과 같은 줄에 또는 그 바로 위 줄에 배치합니다.

```python
# Suppress all findings on the next line (previous-line comment):
# gitlab-advanced-sast-exclude
result = db.execute(query)

# Suppress all findings inline:
result = db.execute(query)  # gitlab-advanced-sast-exclude
```

특정 규칙에서만 발견을 억제하려면 `:` 또는 `=`를 추가한 후 쉼표로 구분된 하나 이상의 규칙 ID를 붙입니다.

```python
# gitlab-advanced-sast-exclude: rule-id-1, rule-id-2
result = db.execute(query)
```

규칙 ID가 지정되지 않으면 해당 줄의 모든 발견이 억제됩니다.

#### Diff 기반 검사 {#diff-based-scanning}

{{< history >}}

- GitLab 18.5에서 `vulnerability_partial_scans`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16790)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 18.5에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/issues/552051)되었습니다.
- GitLab 18.6에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/552051)되었습니다. `vulnerability_partial_scans` 기능 플래그가 제거되었습니다.

{{< /history >}}

Diff 기반 검사는 병합 요청에서 수정된 파일과 해당 종속 파일만 분석합니다. 이 대상 접근 방식은 검사 시간을 줄이고 개발 중에 더 빠른 피드백을 제공합니다.

완전한 커버리지를 보장하려면 병합 요청이 병합된 후 기본 브랜치에서 전체 검사가 실행됩니다.

Diff 기반 검사는 다음 조건에서 병합 요청 파이프라인과 브랜치 파이프라인 모두에서 지원됩니다.

- 병합 요청 파이프라인: Diff 기반 검사는 GitLab Advanced SAST가 [병합 요청 파이프라인](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)에서 실행되도록 구성될 때 발생합니다.
- 브랜치 파이프라인: Diff 기반 검사는 브랜치와 관련된 정확히 하나의 열린 병합 요청이 있을 때 발생합니다. 아무것도 없거나 둘 이상이 있으면 브랜치를 어떤 커밋과 비교해야 할지 결정할 수 없으므로 검사가 전체 검사로 폴백됩니다.

Diff 기반 검사가 활성화되면:

- 병합 요청에서 수정되거나 추가된 파일과 해당 종속 파일만 검사됩니다.
- 작업 로그에는 `Running differential scan` 출력이 포함됩니다. (비활성 상태인 경우 `Running
  full scan` 출력입니다.)
- 병합 요청 보안 검사 보고서에서 전용 **Diff-기반** 탭이 관련 검사 발견을 표시합니다.
- 파이프라인 보안 탭에서 **부분적 SAST 보고서**로 레이블이 지정된 알림은 부분적 발견 사항만 포함된 것을 나타냅니다.

Diff 기반 검사에는 다음과 같은 알려진 문제가 있습니다.

- 미탐 및 오탐: Diff 기반 검사는 검사한 파일의 전체 호출 그래프를 캡처하지 못할 수 있으며, 이로 인해 놓친 취약성(미탐) 또는 해결된 취약성이 다시 발생(오탐)할 수 있습니다. 이 트레이드오프는 검사 시간을 줄이고 개발 중에 더 빠른 피드백을 제공합니다. 포괄적인 커버리지를 위해 전체 검사는 항상 기본 브랜치에서 실행됩니다.
- C/C++ 헤더 파일 커버리지: Diff 기반 검사는 C/C++ 헤더 파일을 완전히 지원하지 않습니다. 헤더 및 소스 파일 모두에 걸쳐 있는 취약성을 탐지할 수 있지만 헤더 파일에만 있는 취약성은 탐지되지 않을 수 있습니다.
- 보고되지 않은 취약성 수정: 오해의 소지가 있는 결과를 피하기 위해 수정된 취약성은 diff 기반 검사에서 제외됩니다. 파일의 하위 집합만 분석되므로 전체 호출 그래프를 사용할 수 없으므로 취약성이 수정되었는지 확인할 수 없습니다. 전체 검사는 항상 병합 후 기본 브랜치에서 실행되며, 여기서 수정된 취약성이 보고됩니다. 결과적으로 diff 기반 검사의 잠재적 격차는 기본 브랜치에의 병합 시 자동으로 실행되는 전체 검사에 의해 완화되어 포괄적인 커버리지를 보장합니다. 이 계층화된 접근 방식은 개발 중의 빠른 피드백 루프와 코드가 프로덕션에 도달하기 전의 철저한 보안 분석의 균형을 유지합니다.

##### Diff 기반 검사 활성화 {#turn-on-diff-based-scanning}

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.

병합 요청 파이프라인에서 diff 기반 검사를 활성화하려면 다음을 수행합니다.

- `ADVANCED_SAST_PARTIAL_SCAN` CI/CD 변수를 프로젝트의 `.gitlab-ci.yml` 파일에서 `differential`로 설정합니다.

##### 종속 파일 {#dependent-files}

수정된 파일 외에 교차 파일 취약성이 누락되는 것을 피하기 위해 diff 기반 검사는 해당 즉시 종속 파일을 포함합니다. 이로 인해 더 심도 있는 종속성 체인에서는 부정확한 결과가 생성될 수 있지만 빠른 검사를 유지하면서도 미탐을 줄일 수 있습니다.

검사에 포함된 파일:

- 수정된 파일(병합 요청에서 변경되거나 추가된 파일)
- 종속 파일(수정된 파일을 가져오는 파일)

이 설계는 오염된 데이터가 수정된 함수에서 이를 가져오는 호출자까지 이동하는 것과 같이 교차 파일 데이터 플로우을 탐지하는 데 도움이 됩니다.

수정된 파일로 가져온 파일은 일반적으로 수정된 코드의 동작 또는 데이터 플로우에 영향을 주지 않으므로 검사하지 않습니다.

예를 들어 파일 B를 수정하는 병합 요청을 생각해보세요:

- 파일 A가 파일 B를 가져오면 파일 A와 B가 검사됩니다.
- 파일 B가 파일 C를 가져오면 파일 B만 검사됩니다.

#### 증분 검사 {#incremental-scanning}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/15545)되었습니다.

{{< /history >}}

증분 검사는 파이프라인 실행 간 오염 서명 분석 결과를 캐시합니다. 후속 검사에서 변경되지 않은 코드는 재분석되는 대신 캐시된 서명을 재사용하며, 변경되거나 새로운 코드는 완전히 분석됩니다. 이는 대부분의 파일이 커밋 간 변경되지 않는 대규모 코드베이스에서 검사 시간을 줄입니다.

증분 검사는 다음과 같이 작동합니다.

1. 첫 검사(콜드 실행): 분석기는 전체 분석을 수행하고 오염 서명의 캐시를 만듭니다. 캐시는 CI 아티팩트 `ts-cache.sqlite.gz`으로 저장됩니다.
1. 후속 검사(웜 실행): 분석기는 캐시 아티팩트를 포함하는 성공적인 파이프라인의 이전 커밋을 검색합니다. 찾으면 캐시를 가져오고 변경되지 않은 결과가 재사용됩니다. 검사가 완료되면 업데이트된 캐시가 새 아티팩트로 저장됩니다.

##### 캐시 무효화 {#cache-invalidation}

캐시는 정확도를 보장하면서 재사용을 최대화하기 위해 무효화됩니다.

부분 무효화: 영향을 받은 항목만 다시 계산되고 캐시의 나머지 부분은 재사용됩니다.

- 새 파일 또는 변경된 파일: 파일을 추가, 수정, 삭제 또는 이름을 바꾸면 캐시된 서명이 무효화되고 다음 검사에서 재계산됩니다.
- 새 규칙 또는 변경된 규칙: 탐지 규칙을 추가하거나 수정하면 해당 특정 규칙만 코드베이스에 대해 다시 계산됩니다.

전체 무효화: 전체 캐시가 재구축됩니다.

- 엔진 변경: 엔진 수준 변경이 기존 캐시를 호환되지 않게 만들 때 전체 검사에서 자동으로 새 캐시가 생성됩니다.

##### 증분 검사를 활성화 {#turn-on-incremental-scanning}

증분 검사를 활성화하려면 다음을 수행합니다.

- `GITLAB_ADV_SAST_INCR_SCAN` CI/CD 변수를 프로젝트의 `.gitlab-ci.yml` 파일에서 `true`로 설정합니다.

  ```yaml
  gitlab-advanced-sast:
    variables:
      GITLAB_ADV_SAST_INCR_SCAN: "true"
  ```

##### 캐시 보존 구성 {#configure-cache-retention}

SAST CI/CD 템플릿은 기본 만료 기간이 3일인 캐시 아티팩트를 저장합니다. `GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD` 변수는 분석기가 캐시 아티팩트를 검색하는 범위를 제어합니다(기본값: `3 days`).

이 두 값은 정렬되어야 합니다. 검색 기간이 아티팩트 만료를 초과하지 않아야 하거나 분석기가 이미 만료된 아티팩트를 검색할 수 있습니다.

두 값을 모두 사용자 지정하려면 `artifacts:expire_in`을 재정의하고 검색 기간 변수를 설정합니다.

```yaml
gitlab-advanced-sast:
  variables:
    GITLAB_ADV_SAST_INCR_SCAN: "true"
    GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD: "7 days"
  artifacts:
    paths:
      - gl-sast-report.json
      - ts-cache.sqlite.gz
    expire_in: 7 days
```

검색 기간은 `d`, `day` 또는 `days` 뒤에 오는 숫자를 지원합니다(예: `7 days`, `14d`).

##### 사용자 지정 작업 이름 구성 {#configure-custom-job-name}

분석기는 CI/CD 작업 이름을 사용하여 어떤 작업의 아티팩트에 캐시가 있는지 식별합니다. `gitlab-advanced-sast` 작업을 이름을 바꾸면 캐시 조회가 올바른 작업을 찾도록 `GITLAB_ADV_SAST_INCR_SCAN_CUSTOM_JOB_NAME`을 사용자 지정 이름으로 설정합니다.

```yaml
my-custom-sast-job:
  variables:
    GITLAB_ADV_SAST_INCR_SCAN: "true"
    GITLAB_ADV_SAST_INCR_SCAN_CUSTOM_JOB_NAME: "my-custom-sast-job"
```

##### 캐시 크기 제한 {#cache-size-limits}

캐시는 압축된 CI/CD 아티팩트로 저장됩니다. 아티팩트 크기 제한이 적용됩니다.

- GitLab.com: 최대 1GB 아티팩트 크기입니다.
- GitLab Self-Managed: 기본 최대 아티팩트 크기 100MB입니다. 관리자는 [CI/CD 설정](../../../administration/cicd/limits.md#maximum-artifacts-size)에서 이 제한을 조정할 수 있습니다.

##### 외부 객체 저장소에 캐시 저장 {#store-cache-in-external-object-storage}

CI/CD 아티팩트 저장소의 대체로 외부 객체 저장소에 증분 검사 캐시를 저장할 수 있습니다. 아티팩트 저장소 제한이 제약이거나 캐시 수명 주기를 독립적으로 관리하려는 경우 이 저장소 방법을 사용하세요. AWS S3이 지원됩니다.

인증은 [OpenID Connect(OIDC)](../../../ci/cloud_services/_index.md)를 사용하여 클라우드 공급자와 단기 토큰을 교환합니다. 장기 자격 증명을 CI/CD 변수로 저장할 필요가 없습니다.

사전 요구 사항:

- S3 버킷입니다.
- GitLab용으로 구성된 [IAM OIDC 자격 공급자](../../../ci/cloud_services/aws/_index.md).
- 버킷에 대한 다음 권한이 있는 IAM 역할:
  - `s3:GetObject`
  - `s3:PutObject`
  - `s3:HeadObject`
- IAM 역할의 신뢰 정책은 액세스가 필요한 프로젝트 또는 그룹으로 범위를 지정해야 합니다(예: `project_path:myorg/*`, 그룹의 모든 프로젝트).

S3에 캐시를 저장하려면 다음을 수행합니다.

1. 이 구성을 `.gitlab-ci.yml`에 추가하세요:

   ```yaml
   gitlab-advanced-sast:
     id_tokens:
       GITLAB_ADV_SAST_INCR_SCAN_OIDC_TOKEN:
         aud: https://gitlab.com
     variables:
       GITLAB_ADV_SAST_INCR_SCAN: "true"
       GITLAB_ADV_SAST_INCR_SCAN_STORAGE: "s3"
       GITLAB_ADV_SAST_INCR_SCAN_S3_BUCKET: "advanced-sast-cache"
       GITLAB_ADV_SAST_INCR_SCAN_S3_REGION: "us-east-1"
       GITLAB_ADV_SAST_INCR_SCAN_S3_ROLE_ARN: "arn:aws:iam::<account-id>:role/<role-name>"
   ```

1. GitLab Self-Managed 또는 GitLab Dedicated의 경우 `aud: https://gitlab.com`을 GitLab 인스턴스 URL로 바꾸세요.
1. [S3 수명 주기 정책](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)을 구성하여 캐시 객체를 자동 만료합니다.

   만료는 `GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD` 값(기본값: 3일)과 정렬되어 부실 캐시 파일을 보유하지 않도록 해야 합니다.

캐시는 S3에 `<project-path>/<commit-sha>/ts-cache.sqlite.gz`에 저장됩니다. 분석기는 아티팩트 기반 캐싱 동작과 일치하는 상위 커밋에서 가장 최근 캐시를 검색합니다.

### 확인되지 않은 취약성 보고 {#report-unverified-vulnerabilities}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/15649)된 [베타](../../../policy/development_stages_support.md#beta).

{{< /history >}}

GitLab Advanced SAST는 오염 분석을 사용하여 신뢰할 수 없는 소스에서 취약한 싱크까지 데이터 플로우을 추적합니다. 기본적으로 분석기는 완전한 경로를 추적할 수 있을 때만 취약성을 보고하며, 이는 커버리지보다 정확도를 우선시합니다. 더 많은 잠재적 데이터 플로우를 탐지하려면 확인되지 않은 취약성을 사용으로 설정할 수 있습니다. 이 기능은 완전한 데이터 플로우 경로를 수립할 수 없을 때에도 발견 사항을 보고하며 이로 인해 보안 범위를 증가시키지만 오탐의 수가 증가할 수도 있습니다.

확인되지 않은 취약성 보고를 사용으로 설정하면 분석기는 부분적 오염 플로우가 탐지되었지만 소스에서 싱크까지 완전히 확인할 수 없는 발견 사항도 보고합니다. 이러한 거의 실패한 발견은 위험한 코드가 악용 가능해지기 전에 식별하고 사전에 수정하는 데 도움이 됩니다. 확인되지 않은 발견은 보안 심각도가 중간 이상인 규칙에 대해서만 보고됩니다.

확인되지 않은 발견은 다음과 같은 방식으로 완전히 확인된 취약성과 명확하게 구분됩니다.

- 파이프라인 **보안** 탭에서 취약성 설명은 **(Unverified)** 접두사로 시작합니다.
- **취약성 보고서**에서 확인되지 않은 발견 사항도 유사하게 접두사가 붙습니다.
- **데이터 플로우** 탭에서 확인되지 않은 취약성에는 소스 노드가 없습니다. 플로우의 첫 번째 노드는 부분적 추적이 시작되는 위치를 나타내는 **진입점 추적**입니다.

#### 확인되지 않은 취약성 보고 활성화 {#turn-on-unverified-vulnerability-reporting}

검사 결과에 확인되지 않은 발견을 포함하려면 `REPORT_UNVERIFIED_VULNS` CI/CD 변수를 `.gitlab-ci.yml` 파일에서 신뢰할 수 있는 값으로 설정합니다.

```yaml
gitlab-advanced-sast:
  variables:
    REPORT_UNVERIFIED_VULNS: "true"
```

> [!warning]
> 확인되지 않은 취약성 보고를 활성화하면 분석기가 생성하는 발견 수가 크게 증가할 수 있습니다. 이러한 발견은 취약성 데이터베이스에 저장되며 분류 노력 및 보고를 포함한 취약성 관리 워크플로우에 영향을 미칠 수 있습니다.

### 러너 리소스 조정 {#tune-runner-resources}

러너 리소스는 검사 시간에 직접 영향을 미칩니다. GitLab Advanced SAST는 기본적으로 병렬로 검사를 실행하며, 여러 CPU 코어와 코어당 최소 4GB의 메모리가 필요합니다. 러너 리소스는 자동으로 탐지되지만 필요한 경우 일부 설정을 미세 조정할 수 있습니다.

분석기는 다음 우선 순위에 따라 사용 가능한 CPU 및 메모리를 결정합니다.

1. GitLab SaaS 러너 태그(`CI_RUNNER_TAGS`):
   - GitLab에서 호스팅하는 러너에서 분석기는 러너 태그(예: `saas-linux-large-amd64`)를 읽고 해당 러너 유형의 알려진 CPU 및 메모리 값을 조회합니다.
1. 컨테이너 리소스 제한(`/sys/fs/cgroup/cpu.max`, `/sys/fs/cgroup/memory.max`):
   - 자체 관리 러너에서 분석기는 Linux cgroup에서 컨테이너 리소스 제한을 읽습니다. 리소스 제한만 cgroup에 반영됩니다. 요청은 컨테이너 수준에서 적용되지 않으며 영향을 주지 않습니다.
1. CI/CD 변수 재정의(`ADVANCED_SAST_AVAILABLE_CPUS`, `ADVANCED_SAST_AVAILABLE_MEMORY`):
   - 설정된 경우 이러한 값은 단계 1 또는 2에서 탐지된 값을 재정의합니다.

단계 1 및 2에서 탐지하지 못하면 분석기는 1개 코어 및 4GB 메모리로 기본값을 설정합니다.

CPU 및 메모리 할당을 확인하려면 `gitlab-advanced-sast` 작업 로그를 보고 GitLab Advanced SAST 항목을 찾으세요. 예를 들어 다음과 같습니다.

```plaintext
[INFO] [GitLab Advanced SAST] [2026-03-30T02:38:09Z] ▶ Detected 2 CPU Cores
[INFO] [GitLab Advanced SAST] [2026-03-30T02:38:09Z] ▶ No Memory limit is detected
```

#### 러너 리소스 설정 구성 {#configure-runner-resource-settings}

다음의 경우 CI/CD 변수를 사용하여 분석기의 CPU 및 메모리 설정을 수동으로 조정할 수 있습니다.

- 러너에 cgroup 제한이 설정되지 않은 경우(예: 베어메탈 또는 제약이 없는 VM).
- 탐지된 값이 러너의 실제 용량과 일치하지 않습니다.
- 분석기가 사용하는 리소스를 사용 가능한 것보다 제한하려고 합니다.

다음 CI/CD 설정을 사용하여 GitLab Advanced SAST 러너 리소스를 조정합니다.

- `ADVANCED_SAST_AVAILABLE_CPUS` - 분석기가 사용할 수 있는 CPU 코어를 지정합니다
- `ADVANCED_SAST_AVAILABLE_MEMORY` - 분석기가 사용할 수 있는 총 메모리를 지정합니다
- `MAX_UNVERIFIED_CORES` - 자동 코어 탐지의 상한을 설정합니다
- `DISABLE_MULTI_CORE` - 멀티코어 검사를 완전히 사용 중지합니다

자체 관리 러너의 경우 [보안 검사기 구성](_index.md#security-scanner-configuration)에서 `--multi-core` 플래그를 사용하여 `requested` 코어 수를 지정할 수 있습니다.

자세한 내용은 [구성](#configuration)을 참조하세요.

프로젝트의 최적 구성을 찾으려면 한 번에 하나의 설정만 변경하고 검사 시간을 모니터링하세요.

다음 예에서 4개의 CPU 코어와 16GB의 메모리를 GitLab Advanced SAST 분석기에서 사용할 수 있습니다. 4명의 각 워커는 4GB의 메모리를 사용할 수 있습니다.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
  ADVANCED_SAST_AVAILABLE_CPUS: '4'
  ADVANCED_SAST_AVAILABLE_MEMORY: '16384'  # 16 GB for 4 cores
```

## 구성 {#configuration}

다음 변수를 사용하여 GitLab Advanced SAST 동작을 조정할 수 있습니다.

| CI/CD 변수                              | 기본값                | 설명                                                                                                                                                                                     |
|---------------------------------------------|------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GITLAB_ADVANCED_SAST_ENABLED`              | `false`                | C 및 C++를 제외한 지원되는 모든 언어에 대해 GitLab Advanced SAST 검사를 사용으로 설정합니다. Swift 및 Objective-C 분석이 별도의 `gitlab-advanced-sast-ext` 작업으로 실행됩니다. |
| `GITLAB_ADVANCED_SAST_CPP_ENABLED`          | `false`                | C 및 C++ 프로젝트에 대해 특별히 GitLab Advanced SAST 검사를 사용으로 설정합니다.                                                                                                                       |
| `GITLAB_ADVANCED_SAST_EXT_INCREMENTAL_ENABLED` | `true` | `false`로 설정하여 Swift 및 Objective-C(`gitlab-advanced-sast-ext`) 분석기에 대해 [증분 검사](advanced_sast_swift_objc.md#incremental-scanning)를 비활성화합니다. |
| `ADVANCED_SAST_PARTIAL_SCAN`                | `false`                | `differential`로 설정하여 GitLab Advanced SAST diff 검사 모드를 사용으로 설정합니다.                                                                                                                    |
| `GITLAB_ADVANCED_SAST_RULE_TIMEOUT`         | `30`                   | 파일당 규칙당 시간 초과(초). 초과되면 해당 분석을 건너뜁니다.                                                                                                                  |
| `REPORT_UNVERIFIED_VULNS`                   | `false`                | 검사 결과에 확인되지 않은 발견을 포함합니다. `true`, `1` 또는 `True`으로 설정하여 사용합니다.                                                                                                           |
| `GITLAB_ADV_SAST_INCR_SCAN`                 | `false`                | 파이프라인 실행 간 오염 서명을 캐시하려면 [증분 검사](#incremental-scanning)를 사용으로 설정합니다.                                                                                           |
| `GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD`   | `3 days`               | 캐시된 오염 서명 아티팩트를 검색하는 범위입니다. 지원되는 형식: `d`, `day` 또는 `days` 뒤에 오는 숫자(예: `7 days`). 아티팩트 만료 기간을 초과하지 않아야 합니다. |
| `GITLAB_ADV_SAST_INCR_SCAN_CUSTOM_JOB_NAME` | `gitlab-advanced-sast` | 캐시 아티팩트 조회용 사용자 지정 작업 이름입니다. `gitlab-advanced-sast` 작업의 이름을 바꾼 경우 이를 설정하세요.                                                                                              |
| `GITLAB_ADV_SAST_INCR_SCAN_STORAGE`         | 설정 안 함                | 캐시 저장소 백엔드입니다. CI/CD 아티팩트 대신 캐시를 AWS S3에 저장하려면 `s3`로 설정합니다. 자세한 내용은 [외부 객체 저장소에 캐시 저장](#store-cache-in-external-object-storage)을 참조하세요.           |
| `GITLAB_ADV_SAST_INCR_SCAN_S3_BUCKET`       | 설정 안 함                | 캐시 저장소용 S3 버킷 이름입니다. `GITLAB_ADV_SAST_INCR_SCAN_STORAGE`이 `s3`일 때 필수입니다.                                                                                                   |
| `GITLAB_ADV_SAST_INCR_SCAN_S3_REGION`       | 설정 안 함                | S3 버킷의 AWS 리전입니다. `GITLAB_ADV_SAST_INCR_SCAN_STORAGE`이 `s3`일 때 필수입니다.                                                                                                        |
| `GITLAB_ADV_SAST_INCR_SCAN_S3_ROLE_ARN`     | 설정 안 함                | OIDC를 통해 가정할 IAM 역할의 ARN입니다. `GITLAB_ADV_SAST_INCR_SCAN_STORAGE`이 `s3`일 때 필수입니다.                                                                                              |

GitLab Advanced SAST 검사는 기본적으로 사용 중지됩니다. 더 높은 수준(예: 그룹)에서 사용으로 설정된 경우 명시적으로 사용 중지하려면 `GITLAB_ADVANCED_SAST_ENABLED`를 (또는 C/C++ 프로젝트의 경우 `GITLAB_ADVANCED_SAST_CPP_ENABLED`를) `false`로 설정합니다.

## 롤아웃 {#roll-out}

한 프로젝트에 대해 GitLab Advanced SAST 결과를 확신할 수 있으면 추가 프로젝트 및 그룹으로 확장합니다. GitLab Advanced SAST를 포함하고 원하는 그룹 및 프로젝트에 적용하는 공유 CI/CD 구성을 만들어야 합니다.

자세한 내용은 [보안 구성](../detect/security_configuration.md)을 참조하세요.

## 취약성 탐지 기준 {#vulnerability-detection-criteria}

GitLab Advanced SAST는 교차 파일, 교차 함수 검사와 오염 분석을 함께 사용하여 사용자 입력에서 프로그램으로 플로우를 추적합니다. SQL 삽입 및 교차 사이트 스크립팅(XSS)과 같은 삽입 취약성이 여러 함수와 파일에 걸쳐 있을 때도 탐지되도록 합니다.

분석기는 신뢰할 수 없는 사용자 입력을 소스에서 신뢰할 수 없는 데이터가 보안 취약성을 일으킬 수 있는 지점으로 가져오는 확인 가능한 플로우가 있을 때만 오염 기반 취약성을 보고합니다. 이 접근 방식은 더 적은 유효성 검사로 취약성을 보고할 수 있는 다른 제품과 비교하여 노이즈를 최소화합니다.

탐지는 HTTP 요청에서 소싱된 값과 같은 신뢰 경계를 교차하는 입력을 강조하지만 프로그램을 운영하는 사용자가 제공하는 일반적으로 명령줄 인수, 환경 변수 또는 기타 입력을 제외합니다.

GitLab Advanced SAST가 탐지하는 취약성 유형의 세부 사항은 [GitLab Advanced SAST CWE 범위](advanced_sast_coverage.md)를 참조하세요.

## Semgrep에서 GitLab Advanced SAST로 전환 {#transitioning-from-semgrep-to-gitlab-advanced-sast}

Semgrep에서 GitLab Advanced SAST로 마이그레이션할 때 자동화된 전환 프로세스는 취약성을 중복 제거합니다. 이 프로세스는 이전에 탐지된 Semgrep 취약성을 해당 GitLab Advanced SAST 발견 사항과 연결하여 일치가 발견되면 대체합니다.

Advanced SAST 검사를 기본 브랜치에서 사용으로 설정한 후에 검사가 실행되고 취약성을 탐지하면 다음 조건을 기반으로 기존 Semgrep 취약성을 대체해야 하는지 확인합니다.

### 중복 제거 조건 {#conditions-for-deduplication}

1. **Matching Identifier**:
   - GitLab Advanced SAST 취약성의 식별자 중 최소 하나(CWE 및 OWASP 제외)는 기존 Semgrep 취약성의 **primary identifier**와 일치해야 합니다.
   - 주 식별자는 [SAST 보고서](_index.md#download-a-sast-report)의 취약성 식별자 배열의 첫 번째 식별자입니다.
   - 예를 들어 GitLab Advanced SAST 취약성에 `bandit.B506`을 포함하는 식별자가 있고 Semgrep 취약성의 주 식별자도 `bandit.B506`이면 이 조건이 충족됩니다.

1. **Matching Location**:
   - 취약성은 코드의 **same location**와 관련되어야 합니다. 이는 [SAST 보고서](_index.md#download-a-sast-report)의 취약성에서 다음 필드 중 하나를 사용하여 결정됩니다.
     - 추적 필드(있는 경우)
     - 위치 필드(추적 필드가 없는 경우)

### 취약성 변경 {#vulnerability-changes}

조건이 충족되면 기존 Semgrep 취약성은 GitLab Advanced SAST 취약성으로 변환됩니다. 이 업데이트된 취약성은 [취약성 보고서](../vulnerability_report/_index.md)에 다음 변경 사항을 포함하여 표시됩니다.

- 검사기 유형이 Semgrep에서 GitLab Advanced SAST로 업데이트됩니다.
- GitLab Advanced SAST 취약성에 있는 모든 추가 식별자가 기존 취약성에 추가됩니다.
- 취약성의 다른 모든 세부 사항은 변경되지 않습니다.

조건이 충족되지 않으면 기존 Semgrep 취약성은 기본 코드 문제가 수정되었더라도 취약성 대시보드에 남아 있습니다. 이러한 수정된 취약성을 GitLab에서 해결됨으로 표시하려면 취약성 대시보드에서 수동으로 해결하거나 Semgrep 분석기를 다시 실행해야 합니다.

### 중복 취약성 해결 {#resolve-duplicate-vulnerabilities}

[중복 제거 조건](#conditions-for-deduplication)이 충족되지 않으면 일부 경우에 Semgrep 취약성이 여전히 중복으로 나타날 수 있습니다. [취약성 보고서](../vulnerability_report/_index.md)에서 이를 해결하려면 다음과 같이 설정합니다.

1. Advanced SAST 검사기별로 [취약성을 필터링](../vulnerability_report/_index.md#filtering-vulnerabilities)하고 [CSV 형식으로 결과를 내보냅니다](../vulnerability_report/_index.md#export-details).
1. Semgrep 검사기별로 [취약성 필터링](../vulnerability_report/_index.md#filtering-vulnerabilities)합니다. 이들은 중복 제거되지 않은 취약성일 가능성이 높습니다.
1. 각 Semgrep 취약성에 대해 내보낸 Advanced SAST 결과에서 해당 일치 항목이 있는지 확인합니다.
1. 중복이 있으면 Semgrep 취약성을 적절하게 해결합니다.

## GitLab Advanced SAST의 LGPL 라이선스 구성 요소의 소스 코드 요청 {#request-source-code-of-lgpl-licensed-components-in-gitlab-advanced-sast}

GitLab Advanced SAST의 LGPL 라이선스 구성 요소의 소스 코드에 대한 정보를 요청하려면 [GitLab 지원팀에 문의](https://support.gitlab.com/)하세요.

빠른 응답을 보장하려면 요청에 GitLab Advanced SAST 분석기 버전을 포함하세요.

이 기능은 Ultimate 티어에서만 사용 가능하므로 해당 수준의 지원 자격을 가진 조직과 연결되어야 합니다.
